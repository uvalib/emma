# app/models/upload.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A file object uploaded from the client.
#
# @!attribute [r] file
#   @return [FileUploader::UploadedFile]
#
# @!attribute [r] file_attacher
#   Inserted by Shrine::Plugins:Activerecord.
#   @return [FileUploader::Attacher]
#
# @!attribute [r] cached_file_data
#   Inserted by Shrine::Plugins:CachedAttachmentData.
#   @return [String, nil]
#
class Upload < ApplicationRecord

  include ActiveModel::Validations

  include Emma::Json
  include Emma::Debug
  include FileNaming
  include FileAttributes
  include FileFormat
  include Model

  # Non-functional hints for RubyMine.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION

    # @return [FileUploader::UploadedFile]
    attr_reader :file

    # @return [FileUploader::Attacher]
    attr_reader :file_attacher

    # @return [String, nil]
    attr_reader :cached_file_data

  end
  # :nocov:

  DEFAULT_REPO = LogoHelper::DEFAULT_REPO.to_s.freeze

  # ===========================================================================
  # :section: Fields
  # ===========================================================================

  include FileUploader::Attachment(:file)

  # ===========================================================================
  # :section: Authentication
  # ===========================================================================

  # TODO: ???

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  # rolify # TODO: ???

  # ===========================================================================
  # :section: Validations
  # ===========================================================================

  validate on: %i[create] do
    $stderr.puts '*** START >>> AR create'
    attached_file_valid? if file
=begin # TODO: field validation
    required_fields_valid?
=end
    $stderr.puts "*** END   <<< AR create - errors = #{errors.values.inspect}"
  end

  validate on: %i[update] do
    $stderr.puts '*** START >>> AR update'
    attached_file_valid? if file
=begin # TODO: field validation
    required_fields_valid?
=end
    $stderr.puts "*** END   <<< AR update - errors = #{errors.values.inspect}"
  end

=begin # TODO: field validation
  validates_presence_of :user_id
  validates_presence_of :repository
  validates_presence_of :repository_id
  #validates_presence_of :file_id,       allow_nil: true
  validates_presence_of :fmt
  validates_presence_of :ext
  validates_presence_of :created_at
  validates_presence_of :updated_at

  validate(:file_data, on: %i[create update]) { attached_file_valid? }

  validate(:emma_data, on: %i[create update]) { emma_data_valid? }
=end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

=begin
  after_create :finalize_format
  after_create :update_attached_filename
=end

=begin
  after_save do
    file_attacher.promote if file_attacher.attached?
  end
=end

  # TODO: this might need to be removed.
  # Shrine actually leaves the cached version of the file around (based on the
  # assumption that there will be a age-based cleanup of that directory).  But
  # for now we're only working from the cached version, so this allows deletion
  # of the upload to also clean up the cached.
  after_destroy do
    file_attacher.destroy if file_attacher.attached?
  end

  # ===========================================================================
  # :section: ApplicationRecord overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [Hash] opt
  #
  def initialize(opt = nil)
    __debug_args(binding)
    super(opt)
    __debug_items do
      {
        id:               self.id,
        user_id:          self.user_id,
        repository:       self.repository,
        repository_id:    self.repository_id,
        fmt:              self.fmt,
        ext:              self.ext,
        state:            self.state,
        emma_data:        self.emma_data,
        file_data:        self.file_data,
        file:             (file || 'file NOT PRESENT'),
        file_attacher:    (file_attacher || 'file_attacher NOT PRESENT'),
        cached_file_data: (cached_file_data || 'cached_file_data NOT PRESENT')
      }
    end
  end

  # ===========================================================================
  # :section: ActiveRecord overrides
  # ===========================================================================

  public

  # Update database fields, including the structured contents of the :emma_data
  # field.
  #
  # @param [Hash] opt
  #
  # @option opt [String, User]   :user_id
  # @option opt [String, Symbol] :repository
  # @option opt [String]         :repository_id
  # @option opt [String, Symbol] :fmt
  # @option opt [String]         :ext
  # @option opt [String]         :state
  # @option opt [String]         :file_data
  # @option opt [String]         :emma_data
  #
  # @return [void]
  #
  # This method overrides:
  # @see ActiveModel::AttributeAssignment#assign_attributes
  #
  def assign_attributes(opt)
    __debug_args(binding)
    new_fmt = new_ext = nil
    if opt.present?
      # Database fields go into *attr*; the remainder is file and EMMA data.
      attr, data =
        partition_options(opt, *field_names).map { |h| reject_blanks(h) }
      if (file_data = data.delete(:file))
        file_data = file_data.to_json if file_data.is_a?(Hash)
        attr[:file_data] = file_data
      elsif (file_data = attr[:file_data]).is_a?(Hash)
        attr[:file_data] = file_data.to_json
      end
      __debug_items do
        {
          "#{__method__} file_data": attr[:file_data],
          "#{__method__} emma_data": attr[:emma_data],
        }
      end
      base = reject_blanks(json_parse(attr.delete(:emma_data)))
      data.reverse_merge!(base) if base.present?
      set_emma_data(data)       if data.present?
      if (new_fmt = data[:dc_format].presence)
        attr[:fmt] = new_fmt
        attr[:ext] = new_ext = fmt_to_ext(new_fmt)
        file.metadata.merge!('mime_type' => fmt_to_mime(new_fmt)) if file
      end
      super(attr)
    end
    @repository ||= DEFAULT_REPO
    @fmt        ||= file && mime_to_fmt(file.mime_type) || new_fmt
    @ext        ||= file&.extension || new_ext
  end

  # ===========================================================================
  # :section: Model overrides
  # ===========================================================================

  public

  # The fields defined in the schema for this record.
  #
  # @return [Array<Symbol>]
  #
  # This method overrides:
  # @see Model#field_names
  #
  def field_names
    attribute_names.map(&:to_sym)
  end

  # ===========================================================================
  # :section: FileFormat overrides
  # ===========================================================================

  public

  # parser
  #
  # @return [FileParser]
  #
  # This method overrides:
  # @see FileFormat#parser
  #
  def parser
    @parser ||=
      begin
        class_name = "#{self.fmt.to_s.camelize}Parser"
        class_name.constantize.new(attached_file_io)
      rescue => e
        # noinspection RubyScope
        __debug  { "Upload.parser: #{class_name} not valid" }
        Log.warn { "Upload.parser: #{e.message}" }
      end
  end

  # format_fields
  #
  # @return [Hash{Symbol=>Proc,Symbol}]
  #
  # This method overrides:
  # @see FileFormat#format_fields
  #
  def format_fields
    parser&.format_fields || {}
  end

  # mapped_metadata_fields
  #
  # @return [Hash{Symbol=>Symbol}]
  #
  # This method overrides:
  # @see FileFormat#mapped_metadata_fields
  #
  def mapped_metadata_fields
    parser&.mapped_metadata_fields || {}
  end

  # ===========================================================================
  # :section: FileAttributes overrides
  # ===========================================================================

  public

  # Full name of the file.
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see FileAttributes#filename
  #
  def filename
    @filename ||= attached_file&.original_filename
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the attached file, loading it if necessary.
  #
  # @return [FileUploader::UploadedFile]
  #
  def attached_file
    file_attacher.attach_cached(file_data) unless file_attacher.attached?
    file
  end

  # Set :emma_data.
  #
  # @param [Search::Record::MetadataRecord, Hash, String, nil] data
  #
  # @return [String]
  # @return [nil]
  #
  def set_emma_data(data)
    @emma_metadata = @emma_record = nil # Force regeneration.
    self.emma_data = self.class.parse_emma_data(data)&.to_json
  end

  # Present :emma_data as a structured object (if it is present).
  #
  # @return [Search::Record::MetadataRecord]
  # @return [nil]
  #
  def emma_record
    @emma_record ||= set_emma_record(self.emma_data)
  end

  # Set :emma_data indirectly via update of #emma_record.
  #
  # @param [Search::Record::MetadataRecord, Hash, String] data
  #
  # @return [Search::Record::MetadataRecord]
  # @return [nil]
  #
  def set_emma_record(data)
    hash = self.class.parse_emma_data(data)
    @emma_record &&= @emma_record.update(hash)
    @emma_record ||= Search::Record::MetadataRecord.new(hash)
    @emma_metadata = nil # Force regeneration.
    self.emma_data = self.class.parse_emma_data(@emma_record).to_json
    @emma_record
  end

  # Present :emma_data as a hash (if it is present).
  #
  # @return [Hash]
  # @return [nil]
  #
  def emma_metadata
    @emma_metadata ||= set_emma_metadata(self.emma_data)
  end

  # Set :emma_data indirectly via update of #emma_metadata.
  #
  # @param [Search::Record::MetadataRecord, Hash, String] data
  #
  # @return [Hash]
  # @return [nil]
  #
  def set_emma_metadata(data)
    @emma_metadata = self.class.parse_emma_data(set_emma_record(data))
  end

=begin
  # Properties of the attached file object.
  #
  # @return [Hash]
  #
  # @see #extract_file_object_properties
  #
  def file_properties
    @file_prop ||= extract_file_object_properties
    @file_prop || {}
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Direct access to the contents of the attached file.
  #
  # @return [IO]
  # @return [nil]
  #
  def attached_file_io
    attached_file&.send(:io) # This is a private method.
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  extend Emma::Json
  extend Emma::Json

  # parse_emma_data
  #
  # @param [Search::Record::MetadataRecord, String, Hash] data
  #
  # @return [Hash]
  # @return [nil]
  #
  # noinspection RubyYardParamTypeMatch
  def self.parse_emma_data(data)
    return if data.blank?
    result =
      case data
        when Search::Record::MetadataRecord then data.as_json
        when Hash                           then data.deep_symbolize_keys
        when String                         then json_parse(data)
        else raise "#{data.class}: unexpected data type"
      end
    reject_blanks(result)

  rescue => e
    if Log.debug?
      Log.error { "#{__method__}: #{e.message}: for #{data.inspect}" }
    else
      Log.error { "#{__method__}: #{e.message}" }
    end
  end

  # ===========================================================================
  # :section: Class methods - fields
  # ===========================================================================

  public

  # Get configuration record fields, converting Symbol :type values into the
  # classes they represent.
  #
  # @param [Symbol, String, Hash] src
  #
  # @return [Hash]
  #
  def self.field_configuration(src)
    unless src.is_a?(Hash)
      path =
        src.to_s.split('.').tap { |parts|
          parts.unshift('emma') unless parts.first == 'emma'
          parts.push('record')  unless parts.last  == 'record'
        }.join('.')
      src = I18n.t(path)&.deep_dup || {}
    end
    src.transform_values! do |entry|
      if entry.is_a?(Hash)
        entry.map { |item, value|
          if value.is_a?(Hash)
            value = field_configuration(value)
          elsif value.is_a?(Symbol) && (item == :type)
            value = value.to_s.constantize rescue value
          end
          [item, value]
        }.to_h
      else
        entry
      end
    end
  end

  # Field property configuration values.
  #
  # @type [Hash{Symbol=>Boolean,Integer,Hash}]
  #
  FIELD = field_configuration('emma.upload.record').deep_freeze

  # Configuration properties for the given field.
  #
  # @param [Symbol, String] field
  #
  # @return [Hash]
  #
  def self.get_field_configuration(field)
    f = field&.to_sym
    FIELD[f] || FIELD.dig(:emma_data, f) || FIELD.dig(:file_data, f) || {}
  end

  # Indicate whether is field is configured to be required.
  #
  # @param [Symbol]  field
  #
  def self.required_field?(field)
    get_field_configuration(field)[:min].to_i > 0
  end

  # Indicate whether is field is configured to be multi-valued.
  #
  # @param [Symbol]  field
  #
  def self.array_field?(field)
    get_field_configuration(field)[:max].to_i != 1
  end

  # Indicate whether is field is configured to be unmodifiable by the user.
  #
  # @param [Symbol]  field
  #
  def self.readonly_field?(field)
    origin = get_field_configuration(field)[:origin]
    origin.present? && (origin != 'user')
  end

  # ===========================================================================
  # :section: Validations
  # ===========================================================================

  protected

  # Indicate whether the attached file is valid.
  #
  def attached_file_valid?
    file_attacher.validate
    file_attacher.errors.each { |e|
      errors.add(:file, :invalid, message: e)
    }.empty?
  end

  # Indicate whether all required fields have valid values.
  #
  def required_fields_valid?
    check_required(self, FIELD)
    errors.empty?
  end

  # Indicate whether all required fields have valid values.
  #
  def emma_data_valid?
    if self.emma_data.blank?
      errors.add(:emma_data, :missing)
    else
      check_required(self.emma_metadata, FIELD[:emma_data])
    end
    errors.empty?
  end

  # ===========================================================================
  # :section: Validations
  # ===========================================================================

  private

  # check_required
  #
  # @param [Upload, Hash] source
  # @param [Hash]         required_fields
  #
  # @return [void]
  #
  def check_required(source, required_fields)
    required_fields.each_pair do |field, entry|
      value = source.is_a?(Hash) ? source[field] : source.send(field)
      if entry.is_a?(Hash)
        if !value.is_a?(Hash)
          errors.add(field, :invalid, 'expecting Hash')
        elsif value.blank?
          errors.add(field, :missing)
        else
          check_required(value, entry)
        end
      elsif entry[:max] == 0
        # TODO: Should this indicate that the field is *forbidden* instead?
        next
      else
        min = entry[:min].to_i
        max = entry[:max].to_i
        if value.is_a?(Array)
          if value.size < min
            errors.add(field, :too_few, "at least #{min} is required")
          elsif (0 < max) && (max < value.size)
            errors.add(field, :too_many, "no more than #{max} is expected")
          end
        else
          if max != 1
            errors.add(field, :invalid, 'expecting Array')
          elsif !min.zero?
            errors.add(field, :missing)
          end
        end
      end
    end
  end

end

__loading_end(__FILE__)
