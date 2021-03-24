# app/models/upload.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'down'

# A file object uploaded from the client.
#
class Upload < ApplicationRecord

  include ActiveModel::Validations
  include Emma::Common
  include Model

  # Include modules from "app/models/upload/**.rb".
  include_submodules(self)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Control whether field validation should occur.
  #
  # NOTE: Not currently supported
  #
  # @type [Boolean]
  #
  FIELD_VALIDATION = false

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  # rolify # TODO: ???

  # ===========================================================================
  # :section: Validations
  # ===========================================================================

  validate on: %i[create] do
    attached_file_valid?
    required_fields_valid? if FIELD_VALIDATION
  end

  validate on: %i[update] do
    attached_file_valid?
    required_fields_valid? if FIELD_VALIDATION
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  if DEBUG_SHRINE
    before_validation { note_cb(:before_validation) }
    after_validation  { note_cb(:after_validation) }
    before_save       { note_cb(:before_save) }
    before_create     { note_cb(:before_create) }
    after_create      { note_cb(:after_create) }
    before_update     { note_cb(:before_update) }
    after_update      { note_cb(:after_update) }
    before_destroy    { note_cb(:before_destroy) }
    after_destroy     { note_cb(:after_destroy) }
    after_save        { note_cb(:after_save) }
    before_commit     { note_cb(:before_commit) }
    after_commit      { note_cb(:after_commit) }
    after_rollback    { note_cb(:after_rollback) }
  end

  before_save    :promote_cached_file
  after_rollback :delete_cached_file, on: %i[create]

  after_destroy do
    delete_file
  end

  # ===========================================================================
  # :section: ApplicationRecord overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [Hash, Upload] opt         Passed to #assign_attributes via super.
  # @param [Proc]         block       Passed to super.
  #
  # This method overrides:
  # @see ActiveRecord::Core#initialize
  #
  def initialize(opt = nil, &block)
    __debug_items(binding)
    opt = opt.attributes if opt.is_a?(Upload)
    opt = opt.merge(initializing: true).except!(:reset) if opt.is_a?(Hash)
    super(opt, &block)
    __debug_items(leader: 'new UPLOAD') { self }
  end

  # ===========================================================================
  # :section: ActiveRecord overrides
  # ===========================================================================

  public

  # Mutually-exclusive modes of operation in #assign_attributes.
  #
  # @type [Array<Symbol>]
  #
  ASSIGN_MODES = %i[initializing finishing_edit reset].freeze

  # Non-field keys used to pass control information to #assign_attributes.
  #
  # @type [Array<Symbol>]
  #
  ASSIGN_CONTROL_OPTIONS = (ASSIGN_MODES + %i[base_url importer defer]).freeze

  # Update database fields, including the structured contents of the :emma_data
  # field.
  #
  # @param [Hash, Upload] opt
  #
  # @option opt [Integer, String, User] :user_id
  # @option opt [String, Symbol]        :repository
  # @option opt [String]                :submission_id
  # @option opt [String, Symbol]        :fmt
  # @option opt [String]                :ext
  # @option opt [String, Symbol]        :state
  # @option opt [String, Hash]          :file_data
  # @option opt [String, Hash]          :emma_data
  #
  # @option opt [String]         :base_url
  # @option opt [Module, String] :importer
  # @option opt [Boolean]        :defer
  # @option opt [Boolean]        :initializing
  # @option opt [Boolean]        :finishing_edit
  # @option opt [Boolean]        :reset
  #
  # == Options
  #
  # :base_url
  #
  #   Supplied to give the base URL for constructing a retrieval link from a
  #   submission ID (:emma_retrievalLink).
  #
  # :importer
  #
  #   Supplied to specify an import translation mechanism (typically for
  #   bulk import). @see Import#translate_fields
  #
  # :defer
  #
  #   Used internally to indicate whether a file indicated by an imported
  #   :file_path data field should be acquired immediately.  If *true* then
  #   @file_path will be set but the referenced file will *not* be fetched
  #   automatically via #upload_file
  #
  # == Mode Options
  #
  # :initializing
  #
  #   Indicates that the method is being executed from the initializer.
  #
  # :finishing_edit
  #
  #   Indicates that the method is being executed from #finishing_edit.
  #   This accommodates the use-case of updating record values from the fields
  #   used when editing an existing EMMA entry (:edit_file_data and/or
  #   :edit_emma_data).
  #
  # :reset
  #
  #   Provided to indicate that user-supplied record attributes should be
  #   wiped (while retaining values that were originally set by the system).
  #
  # @return [void]
  #
  # This method overrides:
  # @see ActiveModel::AttributeAssignment#assign_attributes
  #
  def assign_attributes(opt)
    __debug_items(binding)
    opt = opt.attributes if opt.is_a?(Upload)
    control, fields = partition_options(opt, *ASSIGN_CONTROL_OPTIONS)
    mode = ASSIGN_MODES.find { |m| control[m].present? }

    # Handle the :reset case separately.  If any of the fields to reset are
    # supplied, those values are used here.  If any additional data was
    # supplied it will be ignored.
    if mode == :reset
      reset_columns =
        if under_review?
          %i[review_user review_success review_comment reviewed_at]
        elsif edit_phase
          %i[edit_user edit_file_data edit_emma_data edited_at]
        else
          DATA_COLUMNS
        end
      attr = reset_columns.map { |col| [col, fields.delete(col)] }.to_h
      attr[:updated_at] = self[:created_at] if being_created?
      log_ignored('reset: ignored options', fields) if fields.present?
      delete_file unless under_review?
      super(attr)
      return
    end

    # In the general case, if no data was supplied then there's nothing to do.
    return unless fields.present?
    fields.deep_symbolize_keys!
    fetch_file = false
    new_record = being_created? && (mode == :initializing)

    # If an importer was specified, apply it to transform imported key/value
    # pairs record attributes, :file_data values and/or :emma_data values.
    importer = (control[:importer] if new_record)
    fields   = import_transform(fields, control[:importer]) if importer

    # Database fields go into *attr*; the remainder is file and EMMA data.
    attr, data = partition_options(fields, *field_names)

    # For consistency, make sure that only the appropriate fields are being
    # updated depending on the workflow state of the item.
    allowed =
      if being_created?
        DATA_COLUMNS + %i[repository submission_id updated_at]
      elsif being_modified? || (mode == :finishing_edit)
        DATA_COLUMNS + %i[edit_user edited_at]
      elsif being_removed?
        %i[updated_at]
      elsif under_review?
        %i[review_user review_success review_comment reviewed_at user_id]
      end
    if new_record
      allowed << :created_at
      allowed << :id if self[:id].nil?
    end
    attr, rejected = partition_options(attr, *allowed)
    log_ignored('rejected attributes', rejected) if rejected.present?

    # For :user_id, normalize to a 'user' table reference.  If editing,
    # ensure that :edit_user is a string, defaulting to the original
    # submitter.
    if under_review?
      u = attr[:review_user] || attr[:user_id]
      attr[:review_user] = User.find_uid(u)
    elsif edit_phase
      u = attr[:edit_user] || attr[:user_id] || self[:user_id]
      attr[:edit_user] = User.find_uid(u)
    else
      u = attr[:user_id] || self[:user_id]
      attr[:user_id] = User.find_id(u)
    end

    # Update the appropriate timestamp.
    now    = DateTime.now
    column = timestamp_column
    utime  = attr[column] || self[column] || now
    utime  = utime.to_datetime                if utime.is_a?(Time)
    utime  = DateTime.parse(utime) rescue nil if utime.is_a?(String)
    attr[column] = utime

    # New record defaults.
    if new_record
      ctime = attr[:created_at] || self[:created_at]
      ctime = ctime.to_datetime                if ctime.is_a?(Time)
      ctime = DateTime.parse(ctime) rescue nil if ctime.is_a?(String)
      attr[:created_at]      = ctime || utime
      attr[:submission_id] ||= generate_submission_id(attr[:created_at])
    end

    # Portions that apply when item metadata is expected to change.  EMMA and
    # file data should never change if the item is under review or if it is
    # currently in the process of being submitted to a member repository.

    if sealed? && (mode != :finishing_edit)

      log_ignored('ignored data parameters', data) if data.present?

    else

      # Extract the path to the file to be uploaded (provided either via
      # arguments or from bulk import data).
      if (fp = data.delete(:file_path))
        @file_path = fp
        fetch_file = !false?(control[:defer])
      end

      # Augment EMMA data fields supplied as method options with the contents
      # of :emma_data if it was supplied.
      if (ed = attr.delete(:emma_data))
        __debug_items { { "#{__method__} emma_data": ed.inspect } }
        added_data = reject_blanks(json_parse(ed))
        data.reverse_merge!(added_data) if added_data.present?
      end

      # Get value for :file_data as JSON.
      fd = data.delete(:file)
      fd = attr.delete(:file_data) || fd
      fd = fd.to_json if fd.is_a?(Hash)
      fd = fd.presence
      __debug_items { { "#{__method__} file_data": fd.inspect } } if fd
      case mode
        when :finishing_edit
          if fd && (fd != self[:file_data])
            delete_file(field: :file_data)
            attr[:file_data] = fd
          end
        when :initializing
          attr[file_data_column] = fd unless edit_phase
        else
          attr[file_data_column] = fd if fd
      end

      # Augment supplied attribute values with supplied EMMA metadata.
      if attr.key?(:repository) || self[:repository].present?
        data[:emma_repository] = attr[:repository] || self[:repository]
      elsif data[:emma_repository].present?
        attr[:repository] = data[:emma_repository]
      end
      unless attr.key?(:fmt) || data[:dc_format].blank?
        attr[:fmt] = data[:dc_format]
      end
      fields = %i[emma_lastRemediationDate emma_repositoryMetadataUpdateDate]
      fields.each { |field| data[field] ||= utime if data.key?(field) }

      # EMMA metadata defaults that are only appropriate for EMMA-native items.
      if attr[:repository] == EmmaRepository.default
        data[:emma_repositoryRecordId] ||= attr[:submission_id]
        data[:emma_retrievalLink] ||=
          begin
            rid = data[:emma_repositoryRecordId] || self[:submission_id]
            make_retrieval_link(rid, control[:base_url])
          end
      end

      # Fill in missing file information.
      fmt, ext = attr.values_at(:fmt, :ext)
      mime   = edit_phase && edit_file&.mime_type || file&.mime_type
      fmt  ||= mime_to_fmt(mime)
      ext  ||= edit_phase && edit_file&.extension || file&.extension
      ext  ||= fmt_to_ext(fmt)
      mime ||= fmt_to_mime(fmt)
      active_file.mime_type ||= mime                  if mime && active_file
      data[:dc_format] = FileFormat.metadata_fmt(fmt) if fmt
      attr[:fmt] = fmt                                if fmt
      attr[:ext] = ext                                if ext

      # Update :emma_data or :edit_emma_data, depending on the context.  When
      # incorporating editing changes, :emma_data must be updated explicitly
      # because #active_emma_data refers to :edit_emma_data.
      case mode
        when :initializing   then set_active_emma_data(data)
        when :finishing_edit then modify_emma_data(data)
        else                      modify_active_emma_data(data)
      end

    end

    super(attr)

    # Fetch the file source if named via :file_path and not deferred.
    fetch_and_upload_file(@file_path) if fetch_file

  rescue => error # TODO: remove - testing
    Log.warn { "#{__method__}: #{error.class}: #{error.message}"}
    raise error
  end

  # Formatted record contents.
  #
  # @param [Hash, nil] attr
  #
  # @return [String]
  #
  # This method overrides:
  # @see ActiveRecord::Core#inspect
  #
  def inspect(attr = nil)
    attr ||= {
      id:                 self[:id],
      repository:         self[:repository],
      submission_id:      self[:submission_id],

      phase:              ('[[%s]]' % (self[:phase]&.upcase || '---')),
      state:              self[:state],
      edit_state:         self[:edit_state],

      fmt:                self[:fmt],
      ext:                self[:ext],

      user_id:            self[:user_id],
      edit_user:          self[:edit_user],
      review_user:        self[:review_user],

      created_at:         self[:created_at],
      updated_at:         self[:updated_at],
      edited_at:          self[:edited_at],
      reviewed_at:        self[:reviewed_at],

      review_success:     self[:review_success],
      review_comment:     self[:review_comment],

      emma_data:          self[:emma_data],
      edit_emma_data:     self[:edit_emma_data],

      file_data:          self[:file_data],
      edit_file_data:     self[:edit_file_data],

      file:               file.presence,
      file_attacher:      file_attacher.class,
      edit_file:          edit_file.presence,
      edit_file_attacher: edit_file_attacher.class,
    }
    # noinspection RubyNilAnalysis
    attr = attr.transform_values { |v| v.is_a?(String) ? v.truncate(1024) : v }
    pretty_json(attr)
  end

  # ===========================================================================
  # :section: ActiveRecord overrides
  # ===========================================================================

  private

  # Allow :file_data and :emma_data to be seen fully when inspecting.
  #
  # @param [Symbol, String] name      Attribute name.
  # @param [*] value                  Attribute value.
  #
  # @return [String]
  #
  # This method overrides:
  # @see ActiveRecord::AttributeMethods#format_for_inspect
  #
  def format_for_inspect(name, value)
    if value.nil?
      value.inspect
    else
      inspected_value =
        case value
          when Date, Time then %Q("#{value.to_s(:inspect)}")
          else                 value.inspect
        end
      inspection_filter.filter_param(name, inspected_value)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # log_ignored
  #
  # @param [String] label
  # @param [Hash]   values
  # @param [Symbol, nil] caller
  #
  def log_ignored(label, values, caller = nil)
    Log.warn do
      c = caller || calling_method(3)
      p = workflow_phase || '-'
      s = active_state   || '-'
      "#{c}: [#{p}/#{s}] #{label}: #{values.inspect}"
        .tap { |m| $stderr.puts "!!! #{m}" }
    end
  end

  # ===========================================================================
  # :section: Model overrides
  # ===========================================================================

  public

  # The fields defined in the schema for this record.
  #
  # @return [Array<Symbol>]
  #
  def field_names
    attribute_names.map(&:to_sym)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the record is an EMMA-native item.
  #
  # @param [Upload, nil] item         Default: `self`.
  #
  def emma_native?(item = nil)
    self.class.emma_native?(item || self)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Indicate whether the record is an EMMA-native item.
  #
  # @param [Upload, Hash, String, #repository, #emma_repository] item
  #
  def self.emma_native?(item)
    repository_of(item) == EmmaRepository.default
  end

  # Extract the repository associated with the item.
  #
  # @param [Upload, Hash, String, #emma_repository, #emma_recordId, *] item
  #
  # @return [String]                  One of EmmaRepository#values.
  # @return [nil]
  #
  # == Usage Notes
  # Depending on the context, the caller may need to validate the result with
  # EmmaRepository#valid?.
  #
  def self.repository_of(item)
    item = item.to_s if item.is_a?(Symbol)
    if item && !item.is_a?(String)
      %i[repository emma_repository].find do |key|
        (repo = get_value(item, key)) and return repo
      end
      item = get_value(item, :emma_recordId)
    end
    item && item.strip.split('-').first.presence
  end

  # The full name of the indicated repository
  #
  # @param [Upload, Hash, String, #emma_repository, #emma_recordId, *] item
  #
  # @return [String]                  The name of the associated repository.
  # @return [nil]                     If *src* did not indicate a repository.
  #
  def self.repository_name(item)
    repo = repository_of(item)
    EmmaRepository.pairs[repo]
  end

  # Extract the EMMA index entry identifier from the item.
  #
  # @param [Upload, Hash, String, #emma_repository, #emma_recordId, *] item
  #
  # @return [String]
  # @return [nil]
  #
  # == Usage Notes
  # If *item* is a String, it is assumed to be good.  Depending on the context,
  # the caller may need to validate the result with #valid_record_id?.
  #
  def self.record_id(item)
    result   = (item.to_s if item.nil?)
    result ||= (item.to_s.strip if item.is_a?(String) || item.is_a?(Symbol))
    result ||= get_value(item, :emma_recordId)
    result ||=
      if (repo = get_value(item, :emma_repository))
        rid = get_value(item, :emma_repositoryRecordId)
        fmt = get_value(item, :dc_format)
        parts = [repo, rid, fmt].compact
        if parts.size == 3
          (ver = (get_value(item, :emma_formatVersion))) and parts << ver
        end
        parts.join('-')
      end
    result.presence
  end

  # Indicate whether *item* is or contains a valid EMMA index record ID.
  #
  # @param [String, #emma_repository, #emma_recordId, *] item
  # @param [String, Array<String>]                       add_repo
  # @param [String, Array<String>]                       add_fmt
  #
  def self.valid_record_id?(item, add_repo: nil, add_fmt: nil)
    repo, rid, fmt, _version, remainder = record_id(item).to_s.split('-')
    rid.present? && remainder.nil? &&
      (Array.wrap(add_repo).include?(repo) || EmmaRepository.valid?(repo)) &&
      (Array.wrap(add_fmt).include?(fmt)   || DublinCoreFormat.valid?(fmt))
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # Get the indicated value from an object accessed as either a Hash key or an
  # instance method.
  #
  # The value of *default* is returned if *item* doesn't respond to *key*.
  #
  # @param [Upload, Hash, #repository, #emma_repository] item
  # @param [Symbol, String]                              key
  # @param [*, nil]                                      default
  #
  # @return [*]
  #
  def self.get_value(item, key, default: nil)
    key = key.to_sym
    if item.respond_to?(key)
      item.send(key).presence
    elsif item.is_a?(Upload) && item.emma_metadata.key?(key)
      item.emma_metadata[key].presence
    elsif item.is_a?(Hash) && item.key?(key.to_s)
      item[key.to_s].presence
    elsif item.is_a?(Hash) && item.key?(key)
      item[key].presence
    else
      default
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a URL for use with :emma_retrievalLink.
  #
  # @param [String]      rid          EMMA repository record ID.
  # @param [String, nil] base_url     Default: `#BULK_BASE_URL`.
  #
  # @return [String]
  # @return [nil]                     If no repository ID was given.
  #
  def make_retrieval_link(rid, base_url = nil)
    self.class.make_retrieval_link(rid, base_url)
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Create a URL for use with :emma_retrievalLink.
  #
  # @param [String]      rid          EMMA repository record ID.
  # @param [String, nil] base_url     Default: `#BULK_BASE_URL`.
  #
  # @return [String]
  # @return [nil]                     If no repository ID was given.
  #
  def self.make_retrieval_link(rid, base_url = nil)
    base_url ||= BULK_BASE_URL
    File.join(base_url, 'download', rid).to_s if rid.present?
  end

  # ===========================================================================
  # :section: Validations
  # ===========================================================================

  protected

  # Configured requirements for Upload fields.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def upload_fields
    Model.configured_fields(:upload)[:all]
  end

  # Indicate whether all required fields have valid values.
  #
  def required_fields_valid?
    check_required(self, upload_fields)
    errors.empty?
  end

  # Indicate whether all required fields have valid values.
  #
  def emma_data_valid?
    if active_emma_data.blank?
      errors.add(:emma_data, :missing)
    else
      check_required(active_emma_metadata, upload_fields[:emma_data])
    end
    errors.empty?
  end

  # ===========================================================================
  # :section: Validations
  # ===========================================================================

  private

  # Compare the source fields against configured requirements.
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
