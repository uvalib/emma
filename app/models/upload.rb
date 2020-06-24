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

  # Fallback URL base. TODO: ?
  #
  # @type [String]
  #
  BULK_BASE_URL = 'https://emmadev.internal.lib.virginia.edu'

  # Default user for bulk uploads. # TODO: ?
  #
  # @type [String]
  #
  BULK_USER = 'emmadso@bookshare.org'

  # File to use as a placeholder if no file was given for the upload.
  #
  # @type [String, FalseClass, NilClass]
  #
  BULK_PLACEHOLDER_FILE =
    if application_deployed?
      "#{BULK_BASE_URL}/placeholder.pdf"
    else
      'http://localhost:3000/placeholder.pdf'
    end

  # ===========================================================================
  # :section: Fields
  # ===========================================================================

  # noinspection RubyResolve
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

  after_rollback :delete_file, on: %i[create]

  # ===========================================================================
  # :section: ApplicationRecord overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [Hash, Upload] opt         Passed to super.
  # @param [Proc]         block       Passed to super.
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

  # Fields that are expected to be included in :emma_data.
  #
  # @type [Array<Symbol>]
  #
  EMMA_DATA_FIELDS = Ingest::Record::IngestionRecord.field_names.freeze

  # Fields that are either Upload record attributes or :emma_data.
  #
  # @type [Array<Symbol>]
  #
  KNOWN_FIELDS = (field_names + EMMA_DATA_FIELDS).freeze

  # Update database fields, including the structured contents of the :emma_data
  # field.
  #
  # @param [Hash, Upload] opt
  #
  # @option opt [Integer, String, User] :user_id
  # @option opt [String, Symbol]        :repository
  # @option opt [String]                :repository_id
  # @option opt [String, Symbol]        :fmt
  # @option opt [String]                :ext
  # @option opt [String, Symbol]        :state
  # @option opt [String, Hash]          :file_data
  # @option opt [String, Hash]          :emma_data
  #
  # @option opt [String]         :base_url  To generate emma_retrievalLink.
  # @option opt [Module, String] :importer  @see Import#translate_fields
  #
  # @return [void]
  #
  # This method overrides:
  # @see ActiveModel::AttributeAssignment#assign_attributes
  #
  def assign_attributes(opt)
    __debug_args(binding)
    opt = opt.attributes if opt.is_a?(Upload)
    # noinspection RubyYardParamTypeMatch
    local, fields = partition_options(opt, :base_url, :importer)
    return if fields.blank?
    fields.deep_symbolize_keys!

    # If an importer was specified, apply it to transform imported key/value
    # pairs record attributes, :file_data values and/or :emma_data values.
    importer = local[:importer] && Import.get_importer(local[:importer])
    if importer.present?
      known_fields, added_fields = partition_options(fields, *KNOWN_FIELDS)
      __debug_items do # TODO: remove - debugging
        {
          "#{__method__} known_fields": known_fields,
          "#{__method__} added_fields": added_fields,
        }
      end
      fields = importer.translate_fields(added_fields).merge!(known_fields)
      __debug_items do # TODO: remove - debugging
        {
          "#{__method__} fields": fields
        }
      end
    end

    # Database fields go into *attr*; the remainder is file and EMMA data.
    attr, data = partition_options(fields, *field_names)
    now = DateTime.now
    url = local[:base_url]

    # Get value for :file_data as JSON.
    fd = data.delete(:file) || attr[:file_data]
    attr[:file_data] = fd.is_a?(Hash) ? fd.to_json : fd

    __debug_items do
      {
        "#{__method__} file_data": attr[:file_data],
        "#{__method__} emma_data": attr[:emma_data],
      }
    end

    # Build on :emma_data if present.
    # noinspection RubyYardParamTypeMatch
    ed = reject_blanks(json_parse(attr.delete(:emma_data)))
    data.reverse_merge!(ed) if ed.present?

    # Determine value common to database attributes and EMMA metadata.
    uid  = attr[:user_id]
    repo = attr[:repository]    || data[:emma_repository]
    rid  = attr[:repository_id] || data[:emma_repositoryRecordId]
    fmt  = attr[:fmt]           || data[:dc_format]
    ext  = attr[:ext]
    utim = attr[:updated_at]
    ctim = attr[:created_at]
    mime = file&.mime_type

    # Provide default values where needed.
    uid    = User.find_id(uid) unless uid.is_a?(Integer)
    repo ||= DEFAULT_REPO
    rid  ||= self.class.generate_repository_id
    fmt  ||= mime_to_fmt(mime)
    ext  ||= file&.extension || fmt_to_ext(fmt)
    utim ||= now
    ctim ||= now
    mime ||= fmt_to_mime(fmt)

    # Update the :emma_data attribute directly now (and not via super),
    # ensuring required metadata fields are given a value.
    data[:dc_format]                 = FileFormat.metadata_fmt(fmt)
    data[:emma_repository]           = repo
    data[:emma_repositoryRecordId]   = rid
    data[:emma_retrievalLink]      ||= self.class.make_retrieval_link(url, rid)
    data[:emma_lastRemediationDate]          ||= utim
    data[:emma_repositoryMetadataUpdateDate] ||= utim
    set_emma_data(data)

    # Adjust format/extension if a format was specified manually.
    file.mime_type ||= mime if file

    # Ensure that required attributes are given a value.
    attr[:user_id]       = uid
    attr[:repository]    = repo
    attr[:repository_id] = rid
    attr[:fmt]           = fmt
    attr[:ext]           = ext
    attr[:updated_at]    = utim
    attr[:created_at]    = ctim
    super(attr)

  rescue => error # TODO: remove - testing
    Log.error { "#{__method__}: #{error.class}: #{error.message}"}
    raise error
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
      rescue => error
        # noinspection RubyScope
        __debug  { "Upload.parser: #{class_name} not valid" }
        Log.warn { "Upload.parser: #{error.message}" }
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
  # :section:
  # ===========================================================================

  public

  # Full name of the file.
  #
  # @return [String, nil]
  #
  def filename
    @filename ||= attached_file&.original_filename
  end

  # Return the attached file, loading it if necessary.
  #
  # @return [FileUploader::UploadedFile]
  #
  def attached_file
    file_attacher.load_data(file_data) unless file_attacher.attached?
    file
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a link to the uploaded file which can be used to download the file
  # to the client browser.
  #
  # @param [Hash] opt                 Passed to Shrine::UploadedFile#url.
  #
  # @return [String]
  #
  def download_link(**opt)
    opt[:expires_in] ||= ONE_TIME_USE_EXPIRATION
    attached_file.url(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Acquire a file and upload it to storage.
  #
  # @param [String] file_path
  # @param [Hash]   opt               Passed to FileUploader::Attacher#attach
  #                                     except for:
  #
  # @option [Symbol] :meth            Calling method (for logging).
  #
  # @return [FileUploader::UploadedFile]
  #
  # == Usage Notes
  # This method is not necessary for an Upload instance which is persisted to
  # the database because Shrine adds event handlers which cause the file to be
  # copied to storage.  This method is allows this action for a "free-standing"
  # Upload instance (without needing to execute #save in order to engage Shrine
  # event handlers to copy the file to storage).
  #
  def upload_file(file_path, **opt)
    meth = opt.delete(:meth) || __method__
    result =
      if file_path =~ /^https?:/
        StringIO.open(Faraday.get(file_path).body) do |io|
          opt[:metadata] = opt[:metadata]&.dup || {}
          opt[:metadata]['filename'] ||= File.basename(file_path)
          file_attacher.attach(io, **opt)
        end
      else
        File.open(file_path) do |io|
          file_attacher.attach(io, **opt)
        end
      end
    Log.info do
      name = result&.original_filename.inspect
      size = result&.size      || 0
      type = result&.mime_type || 'unknown MIME type'
      "#{meth}: #{name} (#{size} bytes) #{type}"
    end
    result
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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

  # Set :emma_data.
  #
  # @param [Search::Record::MetadataRecord, Hash, String, nil] data
  #
  # @return [String]
  #
  #--
  # noinspection RubyYardReturnMatch
  #++
  def set_emma_data(data)
    @emma_record   = nil # Force regeneration.
    @emma_metadata = self.class.parse_emma_data(data)
    self.emma_data = data.is_a?(String) ? data.dup : @emma_metadata.to_json
  end

  # Selectively modify :emma_data.
  #
  # @param [Hash] data
  #
  # @return [String]
  #
  #--
  # noinspection RubyYardReturnMatch
  #++
  def modify_emma_data(data)
    @emma_record   = nil # Force regeneration.
    new_metadata   = self.class.parse_emma_data(data)
    @emma_metadata = emma_metadata.merge(new_metadata)
    self.emma_data = @emma_metadata.to_json
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # Metadata fields whose values should be provided as an array.
  #
  # @type [Array<Symbol>]
  #
  # Compare with:
  # @see FileFormat::FIELD_ALWAYS_ARRAY
  #
  FIELD_ALWAYS_ARRAY = %i[
    dc_creator
    dc_identifier
    dc_language
    dc_relation
    dc_subject
    emma_collection
    emma_formatFeature
    s_accessibilityControl
    s_accessibilityFeature
    s_accessibilityHazard
    s_accessMode
    s_accessModeSufficient
  ].freeze

  # parse_emma_data
  #
  # @param [Search::Record::MetadataRecord, String, Hash] data
  #
  # @return [Hash]
  #
  #--
  # noinspection RubyYardParamTypeMatch
  #++
  def self.parse_emma_data(data)
    return {} if data.blank?
    result = data
    result = result.as_json if result.is_a?(Search::Record::MetadataRecord)
    result = json_parse(result, no_raise: false)
    reject_blanks(result).map { |k, v|
      if FIELD_ALWAYS_ARRAY.include?(k)
        if v.is_a?(String)
          separator = %w( ; , ).find { |s| v.include?(s) }
          v = v.split(separator).map(&:strip).reject(&:blank?) if separator
        end
        v = Array.wrap(v)
      elsif v.is_a?(Array)
        v = (v.size > 1) ? v.join(';') : v.first
      end
      [k, v] if v.present? || v.is_a?(FalseClass)
    }.compact.sort.to_h
  rescue => error
    Log.error do
      msg = [__method__, error.message]
      msg << "for #{data.inspect}" if Log.debug?
      msg.join(': ')
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

  # Create a URL for use with :emma_retrievalLink.
  #
  # @param [String] base_url
  # @param [String] repository_id
  #
  # @return [String]
  #
  def self.make_retrieval_link(base_url, repository_id)
    base_url ||= BULK_BASE_URL
    File.join(base_url, 'download', repository_id).to_s
  end

  # Create a unique repository item identifier.
  #
  # @param [String] prefix            Character(s) leading the numeric portion.
  #
  # @return [String]
  #
  # @see #rid_counter
  #
  # == Implementation Notes
  # The result is a (single-character) prefix followed by 8 hexadecimal digits
  # which represent seconds into the epoch followed by a single random letter
  # from 'g' to 'z', followed by two decimal digits from "00" to "99" based on
  # a randomly initialized counter.  This arrangement allows bulk upload (which
  # occurs on a single thread) to be able to generate unique IDs in rapid
  # succession.
  #
  def self.generate_repository_id(prefix = REPO_ID_PREFIX)
    prefix   = REPO_ID_PREFIX if prefix.is_a?(TrueClass)
    prefix ||= ''
    base_id  = Time.now.tv_sec
    letter   = 0x67 + rand(20)
    sprintf('%s%x%c%02d', prefix, base_id, letter, rid_counter)
  end

  # Get the Upload record by either :id or :repository_id.
  #
  # @param [String, Symbol] identifier
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
        terms = sql_terms(opt, *terms, join: :and) if opt.present?
        where(terms)
      else
        opt[:id]            = ids  if ids.present?
        opt[:repository_id] = rids if rids.present?
        where(**opt)               if opt.present?
      end
    Array.wrap(result&.records)
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
  # @example Open-ended range
  #   collect_ids('3-$') -> %w(3 4 5 6)
  #
  # @example All records
  #   collect_ids('*')   -> %w(1 2 3 4 5 6)
  #   collect_ids('-$')  -> %w(1 2 3 4 5 6)
  #   collect_ids('1-$') -> %w(1 2 3 4 5 6)
  #
  def self.collect_ids(*ids)
    ids.flatten.flat_map { |id|
      id.is_a?(String) ? id.strip.split(/\s*,\s*/) : id
    }.flat_map { |id| id_range(id) }.compact.uniq
  end

  # Interpret an ID string as a range of IDs if possible.
  #
  # The method supports a mixture of database IDs (which are comprised only of
  # decimal digits) and repository IDs (which always start with a non-digit),
  # however repository IDs cannot be part of ranges.
  #
  # @param [String, Integer, Upload] id
  #
  # @return [Array<String>]
  #
  def self.id_range(id)
    # noinspection RubyCaseWithoutElseBlockInspection
    case id
      when Upload
        id = id.id.to_s
      when Hash
        id = id[:id] || id['id']
      when /[^\d$*-]/
        # Assume this is a repository ID and not a database ID (or range).
      when '*'
        max = Upload.maximum('id').to_i
        id = (1..max).map(&:to_s) if max.positive?
      when /-/
        min, max = id.split('-')
        max = Upload.maximum('id') if max == '$'
        max = max.to_i
        if max.positive?
          min = [1, min.to_i].max
          min, max = [max, min] if max < min
          id = (min..max).map(&:to_s)
        end
      when /^0\d*$/
        id = id.to_i.to_s
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
    digits_only = id.remove(/\d/).empty?
    digits_only ? { id: id } : { repository_id: id }
  end

  # ===========================================================================
  # :section: Class methods - records
  # ===========================================================================

  protected

  # Counter for the trailing portion of the generated repository ID.
  #
  # This provides a per-thread value in the range 0..99 which can be used to
  # differentiate repository IDs which are generated in rapid succession (e.g.,
  # for bulk upload).
  #
  # @return [Integer]
  #
  def self.rid_counter
    @rid_counter &&= (@rid_counter + 1) % 100
    @rid_counter ||= rand(100) % 100
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

  public

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
  # @param [Boolean] no_raise         If *true*, don't re-raise exceptions.
  #
  # @return [void]
  #
  def promote_file(no_raise: false)
    __debug_args(binding) { { file: file } }
    file_attacher.attach_cached(file_data) unless file_attacher.attached?
  rescue => error
    log_exception(error, __method__)
    raise error unless no_raise
  end

  # Finalize a deletion by the removing the file from :cache and/or :store.
  #
  # @param [Boolean] no_raise         If *true*, don't re-raise exceptions.
  #
  # @return [void]
  #
  def delete_file(no_raise: false)
    __debug_args(binding) { { file: file } }
    file_attacher.attach_cached(file_data) unless file_attacher.attached?
    file_attacher.destroy
  rescue => error
    log_exception(error, __method__)
    raise error unless no_raise
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  private

  # Add a log message for an exception.
  #
  # @param [Exception] excp
  # @param [Symbol]    method         Calling method.
  #
  # @return [nil]
  #
  def log_exception(excp, method = nil)
    error = warning = nil
    case excp
      when Shrine::FileNotFound      then warning = 'FILE_NOT_FOUND'
      when Shrine::InvalidFile       then warning = 'INVALID_FILE'
      when Shrine::AttachmentChanged then warning = 'ATTACHMENT_CHANGED'
      when Shrine::Error             then error   = 'unexpected Shrine error'
      else                                error   = "#{excp.class} unexpected"
    end
    Log.add(error ? Log::ERROR : Log::WARN) do
      "#{method || __method__}: #{excp.message} [#{error || warning}]"
    end
  end

end

__loading_end(__FILE__)
