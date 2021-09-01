# app/models/record/identification.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'exceptions'

# Record utility methods related to identifiers.
#
module Record::Identification

  extend ActiveSupport::Concern

  include Emma::Common

  include Record::Exceptions

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  ID_COLUMN   = :id
  USER_COLUMN = :user_id

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The type of record for the current context.
  #
  # (This will be Entry unless within an instance of another type of Record.)
  #
  # @return [Class<ApplicationRecord>]
  #
  def record_class
    @record_class ||= record_class_for(self)
  end

  # Name of the type of record for the current context.
  #
  # @return [String]
  #
  def record_name
    @record_name ||= record_name_for(record_class)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The type of record for the given item.
  #
  # @param [*] item
  #
  # @return [Class<ApplicationRecord>]
  #
  def record_class_for(item)
    return item       if Record.model_class?(item)
    return item.class if Record.model_class?(item.class)
    Entry
  end

  # Name of the type of record for the given item.
  #
  # @param [*] item
  #
  # @return [String]
  #
  def record_name_for(item)
    record_class_for(item).name.demodulize.to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Column name for the record identifier.
  #
  # @return [Symbol]
  #
  def id_column
    ID_COLUMN
  end

  # Extract the database ID from the given item.
  #
  # @param [Model, Hash, String, *] item
  # @param [Hash]                   opt
  #
  # @option opt [Symbol] :id_key      Default: `#id_column`.
  #
  # @return [String]                  Record ID (:id).
  # @return [nil]                     No valid :id specified.
  #
  def id_value(item, **opt)                                                     # NOTE: from Upload::IdentifierMethods#id_for
    return if item.blank?
    value = positive(item) || get_value(item, (opt[:id_key] || id_column)).to_i
    value.to_s if value.positive?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Column name for the identifier of the associated user.
  #
  # @return [Symbol]
  #
  def user_column
    USER_COLUMN
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the indicated value from an object accessed as either a Hash key or
  # an instance method.
  #
  # The value of *default* is returned if *item* doesn't respond to *key*.
  #
  # @param [Model, Hash, *]                       item
  # @param [Symbol, String, Array<Symbol,String>] key
  # @param [*]                                    default
  #
  # @return [*]
  #
  def get_value(item, key, default: nil, **)                                    # NOTE: from Upload
    return if key.blank?
    if key.is_a?(Array)
      key.find { |k| (v = get_value(item, k)) and break v }
    elsif item.respond_to?((key = key.to_sym))
      item.send(key)
    elsif item.respond_to?(:emma_metadata) # Entry, Phase, etc.
      item.emma_metadata&.dig(key)
    elsif item.is_a?(Hash)
      item[key] || item[key.to_s]
    end.presence || default
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A foreign-key reference to the current record.
  #
  #
  #
  # E.g., :entry_id would indicate an Entry ID.
  #
  # @return [Symbol]
  #
  def alt_id_key(opt)
    alt_key = opt[:alt_id_key] || record_name.underscore
    alt_key = "#{alt_key}_id" unless alt_key.end_with?('_id')
    alt_key.to_sym
  end

  # Return with the specified record or *nil* if one could not be found.
  #
  # @param [String, Hash, Model, *] item
  # @param [Boolean]     no_raise     If *true*, do not raise exceptions.
  # @param [Symbol, nil] meth         Calling method (for logging).
  # @param [Hash]        opt          Used if *item* is *nil* except for:
  #
  # @option opt [Symbol] :id_key      Default: `#id_column`.
  # @option opt [Symbol] :alt_id_key  E.g. :entry_id, :phase_id, :action_id
  #
  # @raise [Record::StatementInvalid]   If :id/:sid not given.
  # @raise [Record::NotFound]           If *item* was not found.
  #
  # @return [ApplicationRecord<Model>]
  #
  def find_record(item, no_raise: false, meth: nil, **opt)                      # NOTE: from UploadWorkflow::External#get_record
    return item if item.nil? || item.is_a?(record_class)
    meth  ||= __method__
    record = error = id = nil

    id_key = opt.key?(:id_key) ? opt[:id_key] : id_column
    if id_key
      opt.merge!(item) if item.is_a?(Hash)
      opt.reverse_merge!(id_term(item, **opt))
      id = opt[id_key] || opt[alt_id_key(opt)]
      if id && (id_key == id_column)
        record = record_class.find(id)
        error  = "for #{id_key} #{id.inspect}" unless record
      elsif id
        record = record_class.find_by(id_key => id)
        error  = "for #{id_key} #{id.inspect}" unless record
      else
        error  = "#{id_key} value given"
      end
      error &&= "No #{record_name} #{error}"
    else
      error = "#{record_name}: :id_key set to nil"
    end

    # noinspection RubyMismatchedReturnType
    if record
      record
    elsif !id
      Log.info { "#{meth}: #{error} (no record specified)" }
      failure(:file_id) unless no_raise
    elsif no_raise
      Log.warn { "#{meth}: #{error} (skipping)" }
    else
      Log.error { "#{meth}: #{error}" }
      failure(:find, item) unless no_raise
    end
  end

  # Find all of the specified records (return records if none were specified).
  #
  # @param [Array<Model,String,Array>] items
  # @param [Symbol]                    id_key       Default: `#id_column`.
  # @param [Symbol, nil]               alt_id_key   E.g. :entry_id, :phase_id
  # @param [Hash]                      opt          Passed to #collect_records
  #
  # @option opt []
  #
  # @return [Array<Model>]
  #
  def find_records(*items, id_key: nil, alt_id_key: nil, **opt)                 # NOTE: from UploadWorkflow::External
    id_key ||= id_column
    unless opt[:all]
      opt_items = id_key     && opt.delete(id_key)
      opt_items = alt_id_key && opt.delete(alt_id_key) || opt_items
      if opt_items
        items += Array.wrap(opt_items)
      elsif items.empty?
        opt[:all] = true
      end
    end
    collect_records(*items, **opt).first || []
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Transform a mixture of record objects and record identifiers into a list of
  # record objects.
  #
  # @param [Array<Model,String,Array>] items  @see #expand_ids
  # @param [Boolean]                   all    If *true*, empty *items* is OK.
  # @param [Boolean]                   force  See Usage Notes
  # @param [Class<Record>]             type   Default: `#record_class`.
  # @param [Hash]                      opt
  #
  # @raise [StandardException] If *all* is *true* and *items* were supplied.
  #
  # @return [(Array<Model>,Array)]      Record instances and failed ids.
  # @return [(Array<Model,String>,[])]  If *force* is *true*.
  #
  # @see Record::Searchable#get_records
  #
  # == Usage Notes
  # If *force* is true, the returned list of failed records will be empty but
  # the returned list of items may contain a mixture of Model and String
  # elements.
  #
  def collect_records(*items, all: false, force: false, type: nil, **opt)       # NOTE: from UploadWorkflow::External
    raise 'If :all is true then no items are allowed'  if all && items.present?
    opt = items.pop if items.last.is_a?(Hash) && opt.blank?
    Log.warn { "#{__method__}: no criteria supplied" } if all && opt.blank?
    type ||= record_class
    items  = items.flatten.compact
    failed = []
    if items.present?
      # Searching by identifier (possibly modified by other criteria).
      items =
        items.flat_map { |item|
          item.is_a?(type) ? item : expand_ids(item) if item.present?
        }.compact
      identifiers = items.reject { |item| item.is_a?(type) }
      if identifiers.present?
        found = {}
        type.get_records(*identifiers, **opt).each do |record|
          (id  = record.id.to_s).present?       and (found[id]  = record)
          (sid = record.submission_id).present? and (found[sid] = record)
        end
        items.map! { |item| !item.is_a?(type) && found[item] || item }
        items, failed = items.partition { |i| i.is_a?(type) } unless force
      end
    elsif all
      # Searching for non-identifier criteria (e.g. { user: @user }).
      items = type.get_records(**opt)
    end
    return items, failed
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Interpret an identifier as either an :id or :submission_id, generating a
  # field/value pair for use with #find_by or #where.
  #
  # If :sid_key set to *nil* then the result will always be in terms of :id_key
  # (which cannot be set to *nil*).
  #
  # @param [String, Symbol, Integer, Hash, Model, *] v
  # @param [Hash]                                    opt
  #
  # @option opt [Symbol] :id_key      Default: `#id_column`.
  #
  # @return [Hash{Symbol=>Integer,String,nil}] Result will have only one entry.
  #
  def id_term(v, **opt)                                                         # NOTE: from Upload::IdentifierMethods
    result = {}
    id_key = opt.key?(:id_key) ? opt.delete(:id_key) : id_column
    v = opt     if v.nil? && opt.present?
    v = v.strip if v.is_a?(String)
    if v.is_a?(Model) || v.is_a?(Hash)
      result[id_key] = get_value(v, id_key) if id_key
    elsif digits_only?(v)
      result[id_key] = v if id_key
    end
    result.compact.presence || { (id_key || id_column) => nil }
  end

  # Transform a mixture of ID representations into a set of one or more
  # non-overlapping range representations.
  #
  # @param [Array<String, Integer, Model, Array>] items
  # @param [Hash]                                 opt
  #
  # @option opt [Integer] :min_id     Default: `#minimum_id`
  # @option opt [Integer] :max_id     Default: `#maximum_id`
  #
  # @return [Array<String>]
  #
  def compact_ids(*items, **opt)                                                # NOTE: from Upload::IdentifierMethods
    opt[:min_id] ||= minimum_id
    opt[:max_id] ||= maximum_id
    ids, non_ids = expand_ids(*items, **opt).partition { |v| digits_only?(v) }
    non_ids.sort!.uniq!
    ids.map! { |id| [id.to_i, opt[:min_id]].max }.sort!.uniq!
    ids =
      ids.chunk_while { |prev, this| (prev + 1) == this }.map do |range|
        first = range.shift
        last  = range.pop || first
        (first == last) ? first.to_s : "#{first}-#{last}"
      end
    min, max = opt.values_at(:min_id, :max_id).map(&:to_s)
    all = (ids == [max] if min == max)
    all ||= (ids == [min, '$']) || (ids == [min, max])
    all ||= ids.first&.match?(/^(0|1|#{min}|\*)?-(#{max}|\$)$/)
    ids = %w(*) if all
    ids + non_ids
  end

  # Transform a mixture of ID representations into a list of single IDs.
  #
  # Any parameter may be (or contain):
  # - A single ID as a String or Integer
  # - A set of IDs as a string of the form /\d+(,\d+)*/
  # - A range of IDs as a string of the form /\d+-\d+/
  # - A range of the form /-\d+/ is interpreted as /0-\d+/
  #
  # @param [Array<Model, String, Integer, Array>] ids
  # @param [Hash]                                 opt   For #expand_id_range.
  #
  # @option opt [Integer] :min_id     Default: `#minimum_id`
  # @option opt [Integer] :max_id     Default: `#maximum_id`
  #
  # @return [Array<String>]
  #
  # == Examples
  #
  # @example Single
  #   expand_ids('123') -> %w(123)
  #
  # @example Sequence
  #   expand_ids('123,789') -> %w(123 789)
  #
  # @example Range
  #   expand_ids('123-126') -> %w(123 124 125 126)
  #
  # @example Mixed
  #   expand_ids('125,789-791,123-126') -> %w(125 789 790 791 123 124 126)
  #
  # @example Implicit range
  #   expand_ids('-3')  -> %w(1 2 3)
  #   expand_ids('*-3') -> %w(1 2 3)
  #
  # @example Open-ended range
  #   expand_ids('3-')  -> %w(3 4 5 6)
  #   expand_ids('3-*') -> %w(3 4 5 6)
  #   expand_ids('3-$') -> %w(3 4 5 6)
  #
  # @example All records
  #   expand_ids('*')   -> %w(1 2 3 4 5 6)
  #   expand_ids('-$')  -> %w(1 2 3 4 5 6)
  #   expand_ids('*-$') -> %w(1 2 3 4 5 6)
  #   expand_ids('1-$') -> %w(1 2 3 4 5 6)
  #
  # @example Last record only
  #   expand_ids('$')   -> %w(6)
  #   expand_ids('$-$') -> %w(6)
  #
  def expand_ids(*ids, **opt)                                                   # NOTE: from Upload::IdentifierMethods
    opt[:min_id] ||= minimum_id
    opt[:max_id] ||= maximum_id
    ids.flatten.flat_map { |id|
      id.is_a?(String) ? id.strip.split(/\s*,\s*/) : id
    }.flat_map { |id|
      expand_id_range(id, **opt) if id.present?
    }.compact.uniq
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A valid ID range term for interpolation into a Regexp.                      # NOTE: from Upload::IdentifierMethods::RANGE_TERM
  #
  # @type [String]
  #
  RNG_TERM = '(\d+|\$|\*)'

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
  #
  # @return [Array<String>]
  #
  # @see #expand_ids
  #
  def expand_id_range(id, **opt)                                                # NOTE: from Upload::IdentifierMethods
    id_key = opt[:id_key] || id_column
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
    result ||= id
    Array.wrap(result).compact_blank.map(&:to_s)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The database ID of the first record associated with the including class.
  #
  # @param [Symbol] id_key            Default: `#id_column`.
  #
  # @return [Integer]                 If 0 then the table is empty.
  #
  def minimum_id(id_key: nil)                                                   # NOTE: from Upload::IdentifierMethods
    record_class.minimum(id_key || id_column).to_i
  end

  # The database ID of the last record associated with the including class.
  #
  # @param [Symbol] id_key            Default: `#id_column`.
  #
  # @return [Integer]                 If 0 then the table is empty.
  #
  def maximum_id(id_key: nil)                                                   # NOTE: from Upload::IdentifierMethods
    record_class.maximum(id_key || id_column).to_i
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Class methods automatically added to the including record class.
  #
  module ClassMethods
    include Record::Identification
  end

  # Methods which are only appropriate if the including class is an
  # ApplicationRecord.
  #
  #--
  # noinspection RubyMismatchedParameterType
  #++
  module InstanceMethods

    include Record::Identification
    extend  Record::Identification

    # =========================================================================
    # :section: Record::Identification overrides
    # =========================================================================

    public

    # @see Record::Identification#record_class
    #
    def self.record_class
      self
    end

    # =========================================================================
    # :section: Record::Identification overrides
    # =========================================================================

    public

    # @see Record::Identification#record_class
    #
    def record_class
      self.class
    end

    # =========================================================================
    # :section: Record::Identification overrides
    # =========================================================================

    public

    # @see Record::Identification#id_value
    #
    def id_value(item = nil, **opt)
      item ? super : self[id_column]
    end

    # =========================================================================
    # :section: Record::Identification overrides
    # =========================================================================

    public

    # @see Record::Identification#get_value
    #
    def get_value(*item_key, **opt)
      item, key = *item_key
      item, key = [nil, item] if key.blank?
      super((item || self), key, **opt)
    end

    # =========================================================================
    # :section: Record::Identification overrides
    # =========================================================================

    public

    # @see Record::Identification#minimum_id
    #
    def minimum_id(**opt)
      self.class.send(__method__, **opt)
    end

    # @see Record::Identification#maximum_id
    #
    def maximum_id(**opt)
      self.class.send(__method__, **opt)
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)

    include InstanceMethods if Record.record_class?(base)

    if Record.record_class?(base)

      include InstanceMethods

      # Non-functional hints for RubyMine type checking.
      unless ONLY_FOR_DOCUMENTATION
        # :nocov:
        include Model
        # :nocov:
      end

      # =======================================================================
      # :section: Model overrides
      # =======================================================================

      public

      # A unique identifier for this model instance.
      #
      # @return [String]
      #
      def identifier
        id_value || super
      end

    end

  end

end

__loading_end(__FILE__)
