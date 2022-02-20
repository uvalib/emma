# app/models/record/emma_identification.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Record utility methods related to identifiers for EMMA submissions.
#
module Record::EmmaIdentification

  extend ActiveSupport::Concern

  include Record
  include Record::Identification

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  SID_COLUMN = :submission_id

  # @type [String]                                                              # NOTE: from Upload::IdentifierMethods
  SID_PREFIX = 'u'

  # @type [(Integer,Integer)]                                                   # NOTE: from Upload::IdentifierMethods
  SID_LETTERS = ('g'..'z').minmax.map(&:ord).deep_freeze

  # @type [Integer]                                                             # NOTE: from Upload::IdentifierMethods
  SID_LETTER_SPAN = SID_LETTERS.then { |pr| pr.last - pr.first + 1 }

  # @type [String]                                                              # NOTE: from Upload::IdentifierMethods
  SID_LETTER_MATCH = ('[%c-%c]' % SID_LETTERS).freeze

  # @type [Regexp]                                                              # NOTE: from Upload::IdentifierMethods
  SID_PATTERN = /^#{SID_PREFIX}\h{8,}#{SID_LETTER_MATCH}\d\d$/

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Column name for the submission ID.
  #
  # @return [Symbol]
  #
  def sid_column
    SID_COLUMN
  end

  # Extract the submission ID from the given item.
  #
  # @param [Model, Hash, String, Any] item
  # @param [Hash]                     opt
  #
  # @option opt [Symbol] :sid_key     Default: `#sid_column`.
  #
  # @return [String]                  The submission ID.
  # @return [nil]                     No submission ID could be determined.
  #
  def sid_value(item, **opt)                                                    # NOTE: from Upload::IdentifierMethods#sid_for
    # noinspection RubyMismatchedReturnType
    return item if valid_sid?(item)
    opt  = item.merge(opt) if item.is_a?(Hash)
    item = opt unless item.is_a?(Model)
    key  = opt[:sid_key] || sid_column
    get_value(item, key) || get_value(item, :sid) if item.present?
  end

  # Indicate whether *value* could be an EMMA submission ID.
  #
  # @param [Any] value                Must be a String.
  #
  def valid_sid?(value)                                                         # NOTE: from Upload::IdentifierMethods
    value.is_a?(String) && value.match?(SID_PATTERN)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the record is an EMMA-native item.
  #
  # @param [Model, Hash, String, Symbol, nil] item
  #
  def emma_native?(item)                                                        # NOTE: from Upload
    repository_value(item) == EmmaRepository.default
  end

  # Extract the repository associated with the item.
  #
  # @param [Model, Hash, String, Symbol, nil] item
  #
  # @return [String]                  One of EmmaRepository#values.
  # @return [nil]                     If *item* did not indicate a repository.
  #
  # == Usage Notes
  # Depending on the context, the caller may need to validate the result with
  # EmmaRepository#valid?.
  #
  def repository_value(item)                                                    # NOTE: from Upload#repository_of
    unless item.nil? || item.is_a?(String) || item.is_a?(Symbol)
      (repo = get_value(item, :repository))      and return repo
      (repo = get_value(item, :emma_repository)) and return repo
      (repo = get_value(item, :repo))            and return repo
      item  = get_value(item, :emma_recordId)
    end
    item.to_s.strip.split('-').first.presence if item.present?
  end

  # The full name of the indicated repository.
  #
  # @param [Model, Hash, String, Symbol, nil] item
  #
  # @return [String]                  The name of the associated repository.
  # @return [nil]                     If *src* did not indicate a repository.
  #
  def repository_name(item)                                                     # NOTE: from Upload
    repo = repository_value(item) and EmmaRepository.pairs[repo]
  end

  # Extract the EMMA index entry identifier from the item.
  #
  # @param [Model, Hash, String, Symbol, nil] item
  #
  # @return [String]
  # @return [nil]
  #
  # == Usage Notes
  # If *item* is a String, it is assumed to be good.  Depending on the context,
  # the caller may need to validate the result with #valid_record_id?.
  #
  def record_id(item)                                                           # NOTE: from Upload
    result   = (item.to_s if item.nil?)
    result ||= (item.to_s.strip if item.is_a?(String) || item.is_a?(Symbol))
    result ||= get_value(item, :emma_recordId)
    result ||=
      if (repo = get_value(item, :emma_repository))
        rid    = get_value(item, :emma_repositoryRecordId)
        format = get_value(item, :dc_format)
        parts  = [repo, rid, format].compact_blank
        ver    = (get_value(item, :emma_formatVersion) if parts.size == 3)
        parts << ver if ver.present?
        parts.join('-')
      end
    result.presence
  end

  # Indicate whether *item* is or contains a valid EMMA index record ID.
  #
  # @param [Model, Hash, String, Symbol, nil] item
  # @param [String, Array<String>]            add_repo
  # @param [String, Array<String>]            add_fmt
  #
  def valid_record_id?(item, add_repo: nil, add_fmt: nil, **)                   # NOTE: from Upload
    repo, rid, fmt, _version, remainder = record_id(item).to_s.split('-')
    rid.present? && remainder.nil? &&
      (Array.wrap(add_repo).include?(repo) || EmmaRepository.valid?(repo)) &&
      (Array.wrap(add_fmt).include?(fmt)   || DublinCoreFormat.valid?(fmt))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a unique submission item identifier.
  #
  # @param [Time, DateTime, nil] time
  # @param [String, Boolean] prefix   Character(s) leading the numeric portion,
  #                                     *true* for the default prefix, or
  #                                     *false* for no prefix.
  #
  # @return [String]
  #
  # @see #sid_counter
  #
  # == Implementation Notes
  # The result is a (single-character) prefix followed by 8 hexadecimal digits
  # which represent seconds into the epoch followed by a single random letter
  # from 'g' to 'z', followed by two decimal digits from "00" to "99" based on
  # a randomly initialized counter.  This arrangement allows bulk upload (which
  # occurs on a single thread) to be able to generate unique IDs in rapid
  # succession.
  #
  # Leading with a non-hex-digit guarantees that submission ID's are distinct
  # from database ID's (which are only decimal digits).
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def generate_submission_id(time = nil, prefix: true)                          # NOTE: from Upload::IdentifierMethods
    prefix  = SID_PREFIX if prefix.is_a?(TrueClass)
    time    = time.is_a?(DateTime) ? time.to_time : (time || Time.now)
    base_id = time.tv_sec
    letter  = SID_LETTERS.first + rand(SID_LETTER_SPAN)
    sprintf('%s%x%c%02d', prefix, base_id, letter, sid_counter)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Counter for the trailing portion of the generated submission ID.
  #
  # This provides a per-thread value in the range 0..99 which can be used to
  # differentiate submission IDs which are generated in rapid succession (e.g.,
  # for bulk upload).
  #
  # @return [Integer]
  #
  def sid_counter                                                               # NOTE: from Upload::IdentifierMethods
    # noinspection RubyMismatchedArgumentType
    Entry.send(__method__)
  end

  # ===========================================================================
  # :section: Record::Identification overrides
  # ===========================================================================

  public

  # Return with the specified record or *nil* if one could not be found.
  #
  # @param [String, Hash, Model, Any] item
  # @param [Boolean]     no_raise     If *true*, do not raise exceptions.
  # @param [Symbol, nil] meth         Calling method (for logging).
  # @param [Hash]        opt          Used if *item* is *nil* except for:
  #
  # @option opt [Symbol] :id_key      Default: `#id_column`.
  # @option opt [Symbol] :sid_key     Default: `#sid_column`.
  # @option opt [Symbol] :alt_id_key  E.g. :entry_id, :phase_id, :action_id
  #
  # @raise [Record::StatementInvalid]   If :id/:sid not given.
  # @raise [Record::NotFound]           If *item* was not found.
  #
  # @return [ApplicationRecord<Model>]
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def find_record(item, no_raise: false, meth: nil, **opt)                      # NOTE: from UploadWorkflow::External#get_record
    return item if item.nil? || item.is_a?(record_class)
    meth  ||= __method__
    record  = error = id = sid = nil
    id_key  = opt.key?(:id_key)  ? opt[:id_key]  : id_column
    sid_key = opt.key?(:sid_key) ? opt[:sid_key] : sid_column
    if id_key || sid_key
      # noinspection RubyMismatchedArgumentType
      opt.merge!(item) if item.is_a?(Hash)
      opt.reverse_merge!(id_term(item, **opt))
      id  = id_key  && (opt[id_key] || opt[alt_id_key(opt)])
      sid = sid_key && opt[sid_key]
      if valid_sid?(id)
        if sid && (id != sid)
          Log.warn { "#{meth}: id: #{id.inspect}, but sid: #{sid.inspect}" }
        end
        id, sid = [nil, id]
      elsif id && sid
        Log.debug do
          "#{meth}: choosing id: #{id.inspect} over sid: #{sid.inspect}"
        end
      end
      if id && (id_key == id_column)
        record = record_class.find(id)
        error  = "for #{id_key} #{id.inspect}" unless record
      elsif id
        record = record_class.find_by(id_key => id)
        error  = "for #{id_key} #{id.inspect}" unless record
      elsif sid
        record = record_class.find_by(sid_key => sid)
        error  = "for #{sid_key} #{sid.inspect}" unless record
      else
        error  = '%s value given' % [id_key, sid_key].compact.join(' or ')
      end
      error &&= "No #{record_name} #{error}"
    else
      error = "#{record_name}: both :id_key and :sid_key set to nil"
    end
    if record
      record
    elsif !id && !sid
      Log.info { "#{meth}: #{error} (no record specified)" }
      failure(:file_id) unless no_raise
    elsif no_raise
      Log.warn { "#{meth}: #{error} (skipping)" }
    else
      Log.error { "#{meth}: #{error}" }
      failure(:find, item) unless no_raise
    end
  end

  # ===========================================================================
  # :section: Record::Identification overrides
  # ===========================================================================

  public

  # Interpret an identifier as either an :id or :submission_id, generating a
  # field/value pair for use with #find_by or #where.
  #
  # If :sid_key set to *nil* then the result will always be in terms of :id_key
  # (which cannot be set to *nil*).
  #
  # @param [String, Symbol, Integer, Hash, Model, Any, nil] v
  # @param [Hash]                                          opt
  #
  # @option opt [Symbol] :id_key      Default: `#id_column`.
  # @option opt [Symbol] :sid_key     Default: `#sid_column`.
  #
  # @return [Hash{Symbol=>Integer,String,nil}] Result will have only one entry.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def id_term(v, **opt)                                                         # NOTE: from Upload::IdentifierMethods
    result  = {}
    id_key  = opt.key?(:id_key)  ? opt.delete(:id_key)  : id_column
    sid_key = opt.key?(:sid_key) ? opt.delete(:sid_key) : sid_column
    v = opt     if v.nil? && opt.present?
    v = v.strip if v.is_a?(String)
    if v.is_a?(Model) || v.is_a?(Hash)
      result[id_key]  = get_value(v, id_key)  if id_key
      result[sid_key] = get_value(v, sid_key) if sid_key && !result[id_key]
    elsif digits_only?(v)
      result[id_key]  = v if id_key
    else
      result[sid_key] = v if sid_key
    end
    result.compact.presence || { (id_key || sid_key || id_column) => nil }
  end

  # ===========================================================================
  # :section: Record::Identification overrides
  # ===========================================================================

  public

  # A valid ID range term for interpolation into a Regexp.                      # NOTE: from Upload::IdentifierMethods::RANGE_TERM
  #
  # @type [String]
  #
  RNG_TERM = Record::Identification::RNG_TERM

  # Interpret an ID string as a range of IDs if possible.
  #
  # The method supports a mixture of database IDs (which are comprised only of
  # decimal digits) and submission IDs (which always start with a non-digit),
  # however a submission ID cannot be part of a range.
  #
  # @param [String, Integer, Model] id
  # @param [Hash]                   opt
  #
  # @option opt [Integer]     :min_id   Default: `#minimum_id`.
  # @option opt [Integer]     :max_id   Default: `#maximum_id`.
  # @option opt [Symbol]      :id_key   Default: `#id_column`.
  # @option opt [Symbol, nil] :sid_key  Default: `#sid_column`.
  #
  # @return [Array<String>]
  #
  # @see #expand_ids
  #
  def expand_id_range(id, **opt)                                                # NOTE: from Upload::IdentifierMethods
    id_key  = opt[:id_key] || id_column
    sid_key = opt.key?(:sid_key) ? opt[:sid_key] : sid_column
    min = max = nil
    # noinspection RubyCaseWithoutElseBlockInspection
    case id
      when Numeric, /^\d+$/, '$'       then min = id
      when Model                       then min = id.id
      when Hash                        then min = id[id_key] || id[id_key.to_s]
      when '*'                         then min, max = [1,  '$']
      when /^-#{RNG_TERM}/             then min, max = [1,  $1 ]
      when /^#{RNG_TERM}-$/            then min, max = [$1, '$']
      when /^#{RNG_TERM}-#{RNG_TERM}$/ then min, max = [$1, $2 ]
    end
    min &&= (opt[:max_id] ||= maximum_id) if (min == '$')
    min &&= [1, min.to_i].max
    max &&= (opt[:max_id] ||= maximum_id) if (max == '$') || (max == '*')
    max &&= [1, max.to_i].max
    result   = max ? (min..max).to_a : min
    result ||= sid_key && get_value(id, sid_key) || id
    Array.wrap(result).compact_blank.map(&:to_s)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Class methods automatically added to the including record class.
  #
  module ClassMethods
    include Record::EmmaIdentification
  end

  # Methods which are only appropriate if the including class is an
  # ApplicationRecord.
  #
  module InstanceMethods

    include Record::EmmaIdentification

    # =========================================================================
    # :section: Record::EmmaIdentification overrides
    # =========================================================================

    public

    # @see Record::EmmaIdentification#sid_value
    #
    def sid_value(item = nil, **opt)
      super((item || self), **opt)
    end

    # @see Record::EmmaIdentification#valid_sid?
    #
    def valid_sid?(value = nil)
      super(value || sid_value)
    end

    # =========================================================================
    # :section: Record::EmmaIdentification overrides
    # =========================================================================

    public

    # @see Record::EmmaIdentification#emma_native?
    #
    def emma_native?(item = nil)
      super(item || self)
    end

    # @see Record::EmmaIdentification#repository_value
    #
    def repository_value(item = nil)
      super(item || self)
    end

    # @see Record::EmmaIdentification#repository_name
    #
    def repository_name(item = nil)
      super(item || self)
    end

    # @see Record::EmmaIdentification#record_id
    #
    def record_id(item = nil)
      super(item || self)
    end

    # @see Record::EmmaIdentification#valid_record_id?
    #
    def valid_record_id?(item = nil, **opt)
      super((item || self), **opt)
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)

    if Record.record_class?(base)

      include InstanceMethods

      # =======================================================================
      # :section: Model overrides
      # =======================================================================

      public

      # A unique identifier for this model instance.
      #
      # @return [String]
      #
      def identifier
        sid_value || super
      end

    end

  end

end

__loading_end(__FILE__)
