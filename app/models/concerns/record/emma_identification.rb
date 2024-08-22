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

  # @type [String]
  SID_PREFIX = 'u'

  # @type [(Integer,Integer)]
  SID_LETTERS = ('g'..'z').minmax.map(&:ord).deep_freeze

  # @type [Integer]
  # noinspection RubyMismatchedArgumentType
  SID_LETTER_SPAN = SID_LETTERS.then { |pr| pr.last - pr.first + 1 }

  # @type [String]
  SID_LETTER_MATCH = ('[%c-%c]' % SID_LETTERS).freeze

  # @type [Regexp]
  SID_PATTERN = /^#{SID_PREFIX}\h{8,}#{SID_LETTER_MATCH}\d\d$/.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Column name for the submission ID.
  #
  # @return [Symbol, nil]
  #
  def sid_column
    if defined?(@sid_column)
      @sid_column
    elsif respond_to?(SID_COLUMN) || try(:field_names)&.include?(SID_COLUMN)
      @sid_column = SID_COLUMN
    else
      @sid_column = nil
    end
  end

  # Extract the submission ID from the given item.
  #
  # @param [any, nil] item            Model, Hash, String
  # @param [Hash]     opt
  #
  # @option opt [Symbol] :sid_key     Default: `#sid_column`.
  #
  # @return [String]                  The submission ID.
  # @return [nil]                     No submission ID could be determined.
  #
  def sid_value(item, **opt)
    item = item.is_a?(Hash) ? item.merge(opt) : opt unless item.is_a?(Model)
    return      if item.blank?
    return item if match_sid?(item)
    sid   = key = opt[:sid_key] || sid_column
    sid &&= get_value(item, [key, :sid])
    sid ||= record_id(item)&.split('-')&.second
    sid if match_sid?(sid)
  end

  # Indicate whether *value* could be an EMMA submission ID.
  #
  # @param [any, nil] value           String
  #
  def valid_sid?(value)
    match_sid?(value)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether *value* could be an EMMA submission ID.
  #
  # (Unlike #valid_sid? this is not overridden in InstanceMethods so it is not
  # subject to problems with recursive definitions.)
  #
  # @param [any, nil] value
  #
  def match_sid?(value)
    value.is_a?(String) && value.match?(SID_PATTERN)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the record is an EMMA-native item.
  #
  # @param [any, nil] item            Model, Hash, String, Symbol
  #
  def emma_native?(item)
    repo = repository_value(item)
    !EmmaRepository.partner.include?(repo&.to_sym)
  end

  # Indicate whether the item should involve requests queued through an
  # S3 bucket.
  #
  # @param [any, nil] item            Model, Hash, String, Symbol
  #
  def s3_queue?(item)
    repo = repository_value(item)
    repo = nil if repo && EmmaRepository.default?(repo)
    repo = get_value(item, :rem_source) if repo.nil?
    EmmaRepository.s3_queue.include?(repo&.to_sym)
  end

  # Extract the repository associated with the item.
  #
  # @param [any, nil] item            Model, Hash, String, Symbol
  #
  # @return [String]                  One of EmmaRepository#values.
  # @return [nil]                     If *item* did not indicate a repository.
  #
  # === Usage Notes
  # Depending on the context, the caller may need to validate the result with
  # EmmaRepository#valid?.
  #
  def repository_value(item)
    if (item = item.presence) && !item.is_a?(String) && !item.is_a?(Symbol)
      r    = get_value(item, %i[repository emma_repository repo]) and return r
      item = get_value(item, :emma_recordId)
    end
    item.to_s.strip.split('-').first.presence if item.present?
  end

  # The full name of the indicated repository.
  #
  # @param [any, nil] item            Model, Hash, String, Symbol
  #
  # @return [String]                  The name of the associated repository.
  # @return [nil]                     If *src* did not indicate a repository.
  #
  def repository_name(item)
    repo = repository_value(item) and EmmaRepository.pairs[repo]
  end

  # Extract the EMMA index entry identifier from the item.
  #
  # @param [any, nil] item            Model, Hash, String, Symbol
  #
  # @return [String]
  # @return [nil]
  #
  # === Usage Notes
  # If *item* is a String, it is assumed to be good.  Depending on the context,
  # the caller may need to validate the result with #valid_record_id?.
  #
  def record_id(item)
    result   = (item.to_s if item.nil?)
    result ||= (item.to_s.strip if item.is_a?(String) || item.is_a?(Symbol))
    result ||= get_value(item, :emma_recordId)
    result ||=
      if (repo = get_value(item, :emma_repository))
        rid    = get_value(item, :emma_repositoryRecordId)
        format = get_value(item, :dc_format)
        parts  = [repo, rid, format].compact_blank!
        ver    = (get_value(item, :emma_formatVersion) if parts.size == 3)
        parts << ver if ver.present?
        parts.join('-')
      end
    result.presence
  end

  # Indicate whether *item* is or contains a valid EMMA index record ID.
  #
  # @param [any, nil]              item       Model, Hash, String, Symbol
  # @param [String, Array<String>] add_repo
  # @param [String, Array<String>] add_fmt
  #
  def valid_record_id?(item, add_repo: nil, add_fmt: nil, **)
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
  # === Implementation Notes
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
  def generate_submission_id(time = nil, prefix: true)
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
  def sid_counter
    Upload.sid_counter
  end

  # ===========================================================================
  # :section: Record::Identification overrides
  # ===========================================================================

  public

  # Return with the specified record or *nil* if one could not be found.
  # If *item* is a *self*, it is returned; otherwise an instance is generated
  # from a database lookup.
  #
  # @param [any, nil]    item         String, Integer, Hash, Model
  # @param [Boolean]     fatal        If *false*, do not raise exceptions.
  # @param [Symbol, nil] meth         Calling method (for logging).
  # @param [Hash]        opt          Used if *item* is *nil* except for:
  #
  # @option opt [Symbol] :id_key      Default: `#id_column`.
  # @option opt [Symbol] :sid_key     Default: `#sid_column`.
  # @option opt [Symbol] :alt_id_key  E.g. :entry_id
  #
  # @raise [Record::StatementInvalid]   If :id/:sid not given.
  # @raise [Record::NotFound]           If *item* was not found.
  #
  # @return [ApplicationRecord<Model>]  A new instance or *item*.
  # @return [nil]                       Only if *fatal* is *false*.
  #
  # @note From UploadWorkflow::External#find_record
  #
  def find_record(item, fatal: true, meth: nil, **opt)
    return item if item.is_a?(record_class)
    meth  ||= __method__
    record  = error = id = sid = nil

    id_key  = opt.key?(:id_key)  ? opt[:id_key]  : id_column
    sid_key = opt.key?(:sid_key) ? opt[:sid_key] : sid_column
    if id_key || sid_key
      # noinspection RubyMismatchedArgumentType
      opt.merge!(item) if item.is_a?(Hash)
      alt = id_key && alt_id_key(opt)
      opt = id_term(item, **opt).merge!(opt.slice(alt))
      id  = id_key  && (opt[id_key] || opt[alt])
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
      if id
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
      raise_failure(:file_id) if fatal
    elsif !fatal
      Log.warn { "#{meth}: #{error} (skipping)" }
    else
      Log.error { "#{meth}: #{error}" }
      raise_failure(:find, item)
    end
  end

  # Interpret an identifier as either an :id or :submission_id, generating a
  # field/value pair for use with #find_by or #where.
  #
  # If :sid_key set to *nil* then the result will always be in terms of :id_key
  # (which cannot be set to *nil*).
  #
  # @param [String, Symbol, Integer, Hash, Model, nil] v
  # @param [Hash]                                      opt
  #
  # @option opt [Symbol] :id_key      Default: `#id_column`.
  # @option opt [Symbol] :sid_key     Default: `#sid_column`.
  #
  # @return [Hash{Symbol=>Integer,String,nil}] Exactly one key-value pair.
  #
  def id_term(v = nil, **opt)
    opt.reverse_merge!(sid_key: sid_column)
    super
  end

  # Interpret an ID string as a range of IDs if possible.
  #
  # The method supports a mixture of database IDs (which are comprised only of
  # decimal digits) and submission IDs (which always start with a non-digit),
  # however a submission ID cannot be part of a range.
  #
  # @param [String, Integer, Model] id
  # @param [Hash]                   opt
  #
  # @return [Array<String>]
  #
  def expand_id_range(id, **opt)
    opt.reverse_merge!(sid_key: sid_column)
    super
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
      item ||= self
      super
    end

    # @see Record::EmmaIdentification#valid_sid?
    #
    def valid_sid?(value = nil)
      value ||= sid_value
      super
    end

    # =========================================================================
    # :section: Record::EmmaIdentification overrides
    # =========================================================================

    public

    # @see Record::EmmaIdentification#emma_native?
    #
    def emma_native?(item = nil)
      item ||= self
      super
    end

    # @see Record::EmmaIdentification#s3_queue?
    #
    def s3_queue?(item = nil)
      item ||= self
      super
    end

    # @see Record::EmmaIdentification#repository_value
    #
    def repository_value(item = nil)
      item ||= self
      super
    end

    # @see Record::EmmaIdentification#repository_name
    #
    def repository_name(item = nil)
      item ||= self
      super
    end

    # @see Record::EmmaIdentification#record_id
    #
    def record_id(item = nil)
      item ||= self
      super
    end

    # @see Record::EmmaIdentification#valid_record_id?
    #
    def valid_record_id?(item = nil, **opt)
      item ||= self
      super
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
      #--
      # noinspection RbsMissingTypeSignature
      #++
      def identifier
        sid_value || super
      end

    end

  end

end

__loading_end(__FILE__)
