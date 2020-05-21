# app/models/upload.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A file object uploaded from the client.
#
# @!attribute [r] file
#   A de-serialized representation of the :file_data column for this model.
#   @return [FileUploader::UploadedFile]
#
# @!attribute [r] file_attacher
#   Inserted by Shrine::Plugins:Activerecord.
#   @return [FileUploader::Attacher]
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

  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The default repository for uploads.
  #
  # @type [String]
  #
  DEFAULT_REPO = Search::Api::Common::DEFAULT_REPOSITORY.to_s.freeze

  # Non decimal-digit character(s) leading all repository ID's.
  #
  # This prefix serves to guarantee that repository ID's are distinct from
  # database ID's (which are only decimal digits).
  #
  # @type [String]
  #
  REPO_ID_PREFIX = 'u'

  # The maximum age (in seconds) allowed for download links which are meant to
  # be valid only for a single time.
  #
  # This should be generous to allow for network delays.
  #
  # @type [Integer]
  #
  ONE_TIME_USE_EXPIRATION = 10

  # The maximum age (in seconds) allowed for download links.
  #
  # This allows the link to be reused for a while, but not long enough to allow
  # sharing of content URLs for distribution.
  #
  # @type [Integer]
  #
  DOWNLOAD_EXPIRATION = 1800

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

  before_validation { note_cb(:before_validation) } if DEBUG_SHRINE
  after_validation  { note_cb(:after_validation) }  if DEBUG_SHRINE
  before_save       { note_cb(:before_save) }       if DEBUG_SHRINE
  before_create     { note_cb(:before_create) }     if DEBUG_SHRINE
  after_create      { note_cb(:after_create) }      if DEBUG_SHRINE
  after_save        { note_cb(:after_save) }        if DEBUG_SHRINE
  after_commit      { note_cb(:after_commit) }      if DEBUG_SHRINE

  # :before_save # should be triggering:
  #   Shrine::Plugins::Activerecord::AttacherMethods#activerecord_before_save
  #     Shrine::Attacher::InstanceMethods#save
  #
  # :after_commit, on: %i[create update] # should be triggering:
  #   Shrine::Plugins::Activerecord::AttacherMethods#activerecord_after_save
  #     Shrine::Attacher::InstanceMethods#finalize
  #       Shrine::Attacher::InstanceMethods#destroy_previous
  #       Shrine::Attacher::InstanceMethods#promote_cached
  #         Shrine::Attacher::InstanceMethods#promote
  #     Shrine::Plugins::Activerecord::AttacherMethods#activerecord_persist
  #       ActiveRecord::Persistence#save
  #
  # :after_commit, on: %i[destroy] # should be triggering:
  #   Shrine::Plugins::Activerecord::AttacherMethods#activerecord_after_destroy
  #     Shrine::Attacher::InstanceMethods#destroy_attached
  #       Shrine::Attacher::InstanceMethods#destroy

  before_save :promote_file
  #  after_commit :promote_file, on: %i[create update]
  #  after_commit :delete_file,  on: %i[destroy]

=begin
  # TODO: this might need to be removed.
  # Shrine actually leaves the cached version of the file around (based on the
  # assumption that there will be a age-based cleanup of that directory).  But
  # for now we're only working from the cached version, so this allows deletion
  # of the upload to also clean up the cached.
  after_destroy do
    file_attacher.destroy if file_attacher.attached?
  end
=end

  # ===========================================================================
  # :section: ApplicationRecord overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [Hash] opt                 Passed to super.
  # @param [Proc] block               Passed to super.
  #
  def initialize(opt = nil, &block)
    __debug_args(binding)
    super(opt, &block)
    __debug_items(leader: 'new UPLOAD') do
      {
        id:               self[:id],
        user_id:          self[:user_id],
        repository:       self[:repository],
        repository_id:    self[:repository_id],
        fmt:              self[:fmt],
        ext:              self[:ext],
        state:            self[:state],
        emma_data:        self[:emma_data],
        file_data:        self[:file_data],
        file:             (file             || '(NOT PRESENT)'),
        file_attacher:    (file_attacher    || '(NOT PRESENT)')
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
    return if opt.blank?

    # Database fields go into *attr*; the remainder is file and EMMA data.
    attr, data = partition_options(opt, *field_names)

    # Get value for :file_data as JSON.
    fd = data.delete(:file) || attr[:file_data]
    attr[:file_data] = fd.is_a?(Hash) ? fd.to_json : fd

    __debug_items do
      {
        "#{__method__} file_data": attr[:file_data],
        "#{__method__} emma_data": attr[:emma_data],
      }
    end

    # Update :emma_data attribute directly now (and not via super).
    ed = attr.delete(:emma_data)
    ed = json_parse(ed) unless ed.is_a?(Hash)
    ed = reject_blanks(ed)
    data.reverse_merge!(ed) if ed.present?
    set_emma_data(data)

    # Adjust format/extension if a format was specified manually.
    new_fmt = new_ext = nil
    if data[:dc_format].present?
      attr[:fmt] = new_fmt = data[:dc_format]
      attr[:ext] = new_ext = fmt_to_ext(new_fmt)
      file.metadata.merge!('mime_type' => fmt_to_mime(new_fmt)) if file
    end

    # Ensure that crucial attributes are given a value.
    attr[:updated_at]      = DateTime.now
    attr[:created_at]    ||= attr[:updated_at]
    attr[:repository]    ||= data[:emma_repository] || DEFAULT_REPO
    attr[:repository_id] ||= data[:emma_repositoryRecordId]
    attr[:repository_id] ||= self.class.generate_repository_id
    attr[:fmt]           ||= file && mime_to_fmt(file.mime_type) || new_fmt
    attr[:ext]           ||= file&.extension || new_ext

    # Update attributes.
    super(attr)

  end

  # Allow :file_data and :emma_data to be seen fully when inspecting.
  #
  # @param [*] value                  Attribute value.
  #
  # @return [String]
  #
  # This method overrides:
  # @see ActiveRecord::AttributeMethods#format_for_inspect
  #
  def format_for_inspect(value)
    value.is_a?(String) ? value.inspect : super
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
        class_name = "#{fmt.to_s.camelize}Parser"
        class_name.constantize.new(attached_file&.to_io)
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
    file_attacher.load_data(file_data) unless file_attacher.attached?
    file
  end

  # Set :emma_data.
  #
  # @param [Search::Record::MetadataRecord, Hash, String, nil] data
  #
  # @return [String]
  #
  # noinspection RubyYardReturnMatch
  def set_emma_data(data)
    @emma_record   = nil # Force regeneration.
    @emma_metadata = self.class.parse_emma_data(data)
    self.emma_data = data.is_a?(String) ? data.dup : @emma_metadata.to_json
  end

  # Present :emma_data as a structured object (if it is present).
  #
  # @return [Search::Record::MetadataRecord]
  #
  def emma_record
    @emma_record ||= Search::Record::MetadataRecord.new(emma_metadata)
  end

  # Present :emma_data as a hash (if it is present).
  #
  # @return [Hash]
  #
  def emma_metadata
    @emma_metadata ||= self.class.parse_emma_data(emma_data)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # parse_emma_data
  #
  # @param [Search::Record::MetadataRecord, String, Hash] data
  #
  # @return [Hash]
  #
  # noinspection RubyYardParamTypeMatch
  def self.parse_emma_data(data)
    reject_blanks(
      case data
        when nil                            then {}
        when Search::Record::MetadataRecord then data.as_json
        when Hash                           then data.deep_symbolize_keys
        when String                         then json_parse(data)
        else raise "#{data.class}: unexpected data type"
      end
    )

  rescue => e
    Log.error do
      [__method__, e.message, ("for #{data.inspect}" if Log.debug?)].join(': ')
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
  # :section: Class methods - records
  # ===========================================================================

  public

  # Create a unique repository item identifier.
  #
  # @param [String] prefix            Character(s) leading the numeric portion.
  #
  # @return [String]
  #
  # == Implementation Notes
  # The result is a (single-character) prefix followed by 8 hexadecimal digits
  # which represent seconds into the epoch followed by a single random hex
  # digit.  (Depending on the granularity of the system clock this appears to
  # be a better tie-breaker than Time#tv_nsec).
  #
  def self.generate_repository_id(prefix = REPO_ID_PREFIX)
    sprintf("#{prefix}%x%x", Time.now.tv_sec, rand(16))
  end

  # Get the Upload record by either :id or :repository_id.
  #
  # @param [String] identifier
  #
  # @return [Upload, nil]
  #
  def self.get_record(identifier)
    find_by(**id_term(identifier))
  end

  # Get the Upload records specified by either :id or :repository_id.
  #
  # Additional constraints may be supplied via *opt*.  If no *identifiers* are
  # supplied then this method is essentially an invocation of #where which
  # returns the matching records.
  #
  # @param [Array<Upload, String, Integer, Array>] ids  @see #collect_ids
  # @param [Hash]                                  opt  Passed to #where.
  #
  # @return [Array<Upload>]
  #
  def self.get_records(*identifiers, **opt)
    ids  = []
    rids = []
    collect_ids(*identifiers).each do |identifier|
      id_term(identifier)[:id] ? (ids << identifier) : (rids << identifier)
    end
    result =
      if ids.present? && rids.present?
        terms = sql_terms(id: ids, repository_id: rids, join: :or)
        terms = sql_terms(opt, terms, join: :and) if opt.present?
        where(terms)
      else
        opt[:id]            = ids  if ids.present?
        opt[:repository_id] = rids if rids.present?
        where(**opt)               if opt.present?
      end
    result&.records || []
  end

  # Transform a mixture of ID representations into a list of single IDs.
  #
  # Any parameter may be (or contain):
  # - A single ID as a String or Integer
  # - A set of IDs as a string of the form /\d+(,\d+)*/
  # - A range of IDs as a string of the form /\d+-\d+/
  # - A range of the form /-\d+/ is interpreted as /0-\d+/
  #
  # @param [Array<Upload, String, Integer, Array>] ids
  #
  # @return [Array<String>]
  #
  # == Examples
  #
  # @example Single
  #   collect_ids('123') -> %w(123)
  #
  # @example Sequence
  #   collect_ids('123,789') -> %w(123 789)
  #
  # @example Range
  #   collect_ids('123-126') -> %w(123 124 125 126)
  #
  # @example Mixed
  #   collect_ids('125,789-791,123-126') -> %w(125 789 790 791 123 124 126)
  #
  def self.collect_ids(*ids)
    ids.flatten.flat_map { |id|
      id.is_a?(String) ? id.strip.split(/\s*,\s*/) : id
    }.flat_map { |id| id_range(id) }.compact.uniq
  end

  # Interpret an ID string as a range of IDs if possible
  #
  # @param [String, Upload, Integer] id
  #
  # @return [Array<String>]
  #
  def self.id_range(id)
    if id.is_a?(Upload)
      id = id.id
    elsif !id.is_a?(String)
      id = id.to_s
    elsif id.include?('-') && id.gsub(/[\-\d]/, '').blank?
      min, max = id.split('-')
      max = [0, max.to_i].max
      # noinspection RubyNilAnalysis
      if max.nonzero?
        min = [0, min.to_i].max
        min, max = [max, min] if max < min
        id = (min..max).map(&:to_s)
      elsif id.match?(/^0\d*$/)
        id = id.to_i.to_s
      end
    end
    Array.wrap(id.presence)
  end

  # Interpret an identifier as either an :id or :repository_id, generating a
  # field/value pair for use with #find_by or #where.
  #
  # @param [String, Symbol] id
  #
  # @return [Hash{Symbol=>String}]    Result will have only one entry.
  #
  def self.id_term(id)
    id          = id.to_s.strip
    digits_only = id.tr('0-9', '').blank?
    digits_only ? { id: id } : { repository_id: id }
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
    if emma_data.blank?
      errors.add(:emma_data, :missing)
    else
      check_required(emma_metadata, FIELD[:emma_data])
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

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Make a debug output note to mark when a callback has occurred.
  #
  # @param [Symbol] type
  #
  # @return [void]
  #
  # == Usage Notes
  # EVENT                                 SHOULD BE CALLED AUTOMATICALLY:
  # before_save:                          activerecord_before_save
  # after_commit, on: %i[create update]   activerecord_after_save
  # after_commit, on: %i[destroy]         activerecord_after_destroy
  #
  def note_cb(type)
    __debug_line("*** UPLOAD CALLBACK #{type} ***")
  end

  # Finalize a file upload by promoting the :cache file to a :store file.
  #
  # @return [void]
  #
  def promote_file
    __debug_args(binding)
    file_attacher.attach_cached(file_data) unless file_attacher.attached?
  rescue Shrine::FileNotFound => e
    Log.warn { "#{__method__}: #{e.message} [FILE_NOT_FOUND]" }
  rescue Shrine::InvalidFile => e
    Log.warn { "#{__method__}: #{e.message} [INVALID_FILE]" }
  rescue Shrine::AttachmentChanged => e
    Log.warn { "#{__method__}: #{e.message} [ATTACHMENT_CHANGED]" }
  rescue Shrine::Error => e
    Log.error { "#{__method__}: #{e.message} [unexpected Shrine error]" }
  rescue => e
    Log.error { "#{__method__}: #{e.message} [#{e.class} unexpected]" }
  end

  # Finalize a deletion by the removing the file from :cache and/or :store.
  #
  # @return [void]
  #
  def delete_file
    __debug_args(binding)
    file_attacher.attach_cached(file_data) unless file_attacher.attached?
    file_attacher.destroy
  rescue Shrine::FileNotFound => e
    Log.warn { "#{__method__}: #{e.message} [FILE_NOT_FOUND]" }
  rescue Shrine::InvalidFile => e
    Log.warn { "#{__method__}: #{e.message} [INVALID_FILE]" }
  rescue Shrine::AttachmentChanged => e
    Log.warn { "#{__method__}: #{e.message} [ATTACHMENT_CHANGED]" }
  rescue Shrine::Error => e
    Log.error { "#{__method__}: #{e.message} [unexpected Shrine error]" }
  rescue => e
    Log.error { "#{__method__}: #{e.message} [#{e.class} unexpected]" }
  end

end

__loading_end(__FILE__)
