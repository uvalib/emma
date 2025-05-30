# app/models/record/identification.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

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

  # The type of record for the current context.
  #
  # (This will be Upload unless within an instance of another type of Record.)
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
  # @param [any, nil] item
  #
  # @return [Class<ApplicationRecord>]
  #
  def record_class_for(item)
    case
      when Record.model_class?(item)       then item
      when Record.model_class?(item.class) then item.class
      else                                      Upload
    end
  end

  # Name of the type of record for the given item.
  #
  # @param [any, nil] item
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
    IdMethods::ID_COLUMN
  end

  # Indicate whether the value could be a valid #id_column value.
  #
  # @param [any, nil] value
  #
  def valid_id?(value)
    digits_only?(value)
  end

  # Extract the database ID from the given item.
  #
  # @param [any, nil] item            Model, Hash, String
  # @param [Hash]     opt
  #
  # @option opt [Symbol] :id_key      Default: `#id_column`.
  #
  # @return [String]                  Record ID Array(:id).
  # @return [nil]                     No valid :id specified.
  #
  def id_value(item, **opt)
    if valid_id?(item)
      item.to_s
    elsif valid_id?((item = get_value(item, (opt[:id_key] || id_column))))
      item.to_s
    end
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
    IdMethods::USER_COLUMN
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the indicated value from an object accessed as either a Hash key or
  # an instance method.
  #
  # The value of *default* is returned if `*item*` doesn't respond to `*key*`.
  #
  # @param [any, nil]                           item  Model,Hash,String,Symbol
  # @param [Symbol,String,Array<Symbol,String>] key
  # @param [any, nil]                           default
  #
  # @return [any, nil]
  #
  # @note From Upload#get_value
  #
  def get_value(item, key, default: nil, **)
    if key.is_a?(Array)
      key.find { (v = get_value(item, _1)) and (break v) }
    elsif (key = key&.to_sym).blank?
      nil
    elsif item.is_a?(Hash)
      item[key] || item[key.to_s]
    elsif item.respond_to?(key)
      item.send(key)
    elsif item.try(:field_names)&.include?(key)
      item[key]
    elsif item.respond_to?(:emma_metadata) # Upload, ManifestItem
      item.emma_metadata[key]
    end.presence || default
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A foreign-key reference to the current record.
  #
  # @param [Hash] opt
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
  # If *item* is a `*self*`, it is returned; otherwise an instance is generated
  # from a database lookup.
  #
  # @param [any, nil]    item         String, Integer, Hash, Model
  # @param [Boolean]     fatal        If *false*, do not raise exceptions.
  # @param [Symbol, nil] meth         Calling method (for logging).
  # @param [Hash]        opt          Used if *item* is *nil* except for:
  #
  # @option opt [Symbol] :id_key      Default: `#id_column`.
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
    meth ||= __method__
    record = error = id = nil

    id_key = opt.key?(:id_key) ? opt[:id_key] : id_column
    if id_key
      opt.merge!(item) if item.is_a?(Hash)
      alt = alt_id_key(opt)
      opt = id_term(item, **opt).merge!(opt.slice(alt))
      id  = opt[id_key] || opt[alt]
      if id
        record = record_class.find_by(id_key => id)
        error  = "for #{id_key} #{id.inspect}" unless record
      else
        error  = "#{id_key} value given"
      end
      error &&= "No #{record_name} #{error}"
    else
      error = "#{record_name}: :id_key set to nil"
    end

    if record
      record
    elsif !id
      Log.info { "#{meth}: #{error} (no record specified)" }
      raise_failure(:file_id) if fatal
    elsif !fatal
      Log.warn { "#{meth}: #{error} (skipping)" }
    else
      Log.error { "#{meth}: #{error}" }
      raise_failure(:find, item)
    end
  end

  # Find all of the specified records (return records if none were specified).
  #
  # @param [Array<Model,String,Array>] items
  # @param [Symbol]                    id_key       Default: `#id_column`.
  # @param [Symbol, nil]               alt_id_key   E.g. :entry_id
  # @param [Hash]                      opt          Passed to #collect_records
  #
  # @option opt []
  #
  # @return [Array<Model>]            Fresh records from a database query.
  #
  # @note From UploadWorkflow::External#find_records
  #
  def find_records(*items, id_key: nil, alt_id_key: nil, **opt)
    id_key ||= id_column
    unless opt[:all]
      opt_items = id_key     && opt.delete(id_key)
      opt_items = alt_id_key && opt.delete(alt_id_key) || opt_items
      if opt_items
        items.concat(Array.wrap(opt_items))
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
  # @return [Array<(Array<Model>,Array)>]      Record instances and failed ids.
  # @return [Array<(Array<Model,String>,[])>]  If *force* is *true*.
  #
  # @see Record::Searchable#fetch_records
  #
  # @note From UploadWorkflow::External#collect_records
  #
  # === Usage Notes
  # If *force* is true, the returned list of failed records will be empty but
  # the returned list of items may contain a mixture of Model and String
  # elements.
  #
  def collect_records(*items, all: false, force: false, type: nil, **opt)
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
      identifiers = items.reject { _1.is_a?(type) }
      if identifiers.present?
        found   = {}
        id_key  = id_column.to_s
        sid_key = self.class.safe_const_get(:SID_COLUMN).to_s
        type.fetch_records(*identifiers, **opt).each do |record|
          id  = record.try(id_key)  and found.merge!(id.to_s  => record)
          sid = record.try(sid_key) and found.merge!(sid.to_s => record)
        end
        items.map! { |item| !item.is_a?(type) && found[item] || item }
        items, failed = items.partition { _1.is_a?(type) } unless force
      end
    elsif all
      # Searching for non-identifier criteria (e.g. { user: @user }).
      items = type.fetch_records(**opt)
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
  # @param [any, nil] v               String, Symbol, Integer, Hash, Model
  # @param [Hash]     opt
  #
  # @option opt [Symbol] :id_key      Default: `#id_column`.
  # @option opt [Symbol] :sid_key     Default: nil.
  #
  # @return [Hash{Symbol=>Integer,String,nil}] Exactly one key-value pair.
  #
  def id_term(v = nil, **opt)
    i_key = opt.key?(:id_key) ? opt.delete(:id_key) : id_column
    s_key = opt.delete(:sid_key)
    v = opt     if v.nil?
    v = v.strip if v.is_a?(String)
    v = v.to_s  if v.is_a?(Symbol)
    v = v.presence
    id = sid = nil
    if valid_id?(v)
      id  = v if i_key
    elsif v.is_a?(String)
      sid = v if s_key
    elsif v
      id  = get_value(v, i_key) if i_key
      sid = get_value(v, s_key) if s_key && !id
    end
    if sid
      { s_key => sid.to_s }
    else
      { i_key => (digits_only?(id) ? id.to_i : id) }
    end
  end

  # Transform a mixture of ID representations into a set of one or more
  # non-overlapping range representations followed by non-identifiers (if any).
  #
  # @param [Array<String, Integer, Model, Array>] items
  # @param [Hash]                                 opt
  #
  # @option opt [Integer] :min_id     Default: `#minimum_id`
  # @option opt [Integer] :max_id     Default: `#maximum_id`
  #
  # @return [Array<String>]
  #
  def compact_ids(*items, **opt)
    ids, non_ids = expand_ids(*items, **opt).partition { valid_id?(_1) }
    group_ids(*ids, **opt) + non_ids.sort.uniq
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
  # === Examples
  #
  # @example Single
  #   expand_ids('123') -> %w[123]
  #
  # @example Sequence
  #   expand_ids('123,789') -> %w[123 789]
  #
  # @example Range
  #   expand_ids('123-126') -> %w[123 124 125 126]
  #
  # @example Mixed
  #   expand_ids('125,789-791,123-126') -> %w[125 789 790 791 123 124 126]
  #
  # @example Implicit range
  #   expand_ids('-3')  -> %w[1 2 3]
  #   expand_ids('*-3') -> %w[1 2 3]
  #
  # @example Open-ended range
  #   expand_ids('3-')  -> %w[3 4 5 6]
  #   expand_ids('3-*') -> %w[3 4 5 6]
  #   expand_ids('3-$') -> %w[3 4 5 6]
  #
  # @example All records
  #   expand_ids('*')   -> %w[1 2 3 4 5 6]
  #   expand_ids('-$')  -> %w[1 2 3 4 5 6]
  #   expand_ids('*-$') -> %w[1 2 3 4 5 6]
  #   expand_ids('1-$') -> %w[1 2 3 4 5 6]
  #
  # @example Last record only
  #   expand_ids('$')   -> %w[6]
  #   expand_ids('$-$') -> %w[6]
  #
  def expand_ids(*ids, **opt)
    opt[:min_id] ||= minimum_id
    opt[:max_id] ||= maximum_id
    ids.flatten.flat_map { |id|
      id.is_a?(String) ? id.strip.split(/\s*,\s*/) : id
    }.compact_blank.flat_map { expand_id_range(_1, **opt) }.uniq
  end

  # Condense an array of identifiers by replacing runs of contiguous number
  # values like "first", "first+1", "first+2", ..., "last" with "first-last".
  #
  # If the array represents all identifiers, ['*'] is returned.
  #
  # @param [Array<String>] ids
  # @param [Integer, nil]  min_id     Default: `#minimum_id`
  # @param [Integer, nil]  max_id     Default: `#maximum_id`
  #
  # @return [Array<String>]
  #
  def group_ids(*ids, min_id: nil, max_id: nil, **)
    min = (min_id ||= minimum_id).to_s
    max = (max_id ||  maximum_id).to_s
    ids.map! { [_1.to_i, min_id].max }.sort!.uniq!
    ids =
      ids.chunk_while { |prev, this| (prev + 1) == this }.map do |range|
        first = range.shift
        last  = range.pop || first
        (first == last) ? first.to_s : "#{first}-#{last}"
      end
    all   = (ids == [max] if min == max)
    all ||= (ids == [min]) || (ids == [min, max])
    all ||= ids.first&.match?(/^(0|1|#{min}|\*)?-(#{max}|\$)$/)
    all ? %w[*] : ids
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A valid ID range term for interpolation into a Regexp.
  #
  # @type [String]
  #
  RNG_TERM = '(\d+|\$|\*)'

  # Interpret an ID string as a range of IDs if possible.
  #
  # The method supports a mixture of database IDs (which are only decimal
  # digits) and submission IDs (which always start with a non-digit), however a
  # submission ID cannot be part of a range.
  #
  # @param [String, Integer, Model] id
  # @param [Hash]                   opt
  #
  # @option opt [Integer]     :min_id   Default: `#minimum_id`.
  # @option opt [Integer]     :max_id   Default: `#maximum_id`.
  # @option opt [Symbol]      :id_key   Default: `#id_column`.
  # @option opt [Symbol, nil] :sid_key  Default: nil.
  #
  # @return [Array<String>]
  #
  # @see #expand_ids
  #
  def expand_id_range(id, **opt)
    id_key  = opt[:id_key]&.to_sym || id_column
    sid_key = opt[:sid_key]
    min = max = nil
    case id
      when Numeric, /^\d+$/, '$'       then min = id
      when Model                       then min = id.id
      when Hash                        then min = id[id_key] || id[id_key.to_s]
      when '*'                         then min, max = [1,  '$']
      when /^-#{RNG_TERM}/             then min, max = [1,  $1 ]
      when /^#{RNG_TERM}-$/            then min, max = [$1, '$']
      when /^#{RNG_TERM}-#{RNG_TERM}$/ then min, max = [$1, $2 ]
    end
    min = (opt[:max_id] ||= maximum_id) if (min == '$')
    min = [1, min.to_i].max             if digits_only?(min)
    max = (opt[:max_id] ||= maximum_id) if (max == '$') || (max == '*')
    max = [1, max.to_i].max             if digits_only?(max)
    if min.is_a?(Integer) && max.is_a?(Integer)
      (min..max).to_a.map!(&:to_s)
    else
      min ||= sid_key && get_value(id, sid_key) || id
      Array.wrap(min&.to_s)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The database ID of the first record associated with the including class.
  #
  # @param [Symbol, nil] id_key       Default: `#id_column`.
  #
  # @return [Integer]                 If 0 then the table is empty.
  # @return [nil]                     Not supported by the current schema.
  #
  def minimum_id(id_key: nil)
    record_class.minimum(id_key || id_column)&.to_i
  end

  # The database ID of the last record associated with the including class.
  #
  # @param [Symbol, nil] id_key       Default: `#id_column`.
  #
  # @return [Integer]                 If 0 then the table is empty.
  # @return [nil]                     Not supported by the current schema.
  #
  def maximum_id(id_key: nil)
    record_class.maximum(id_key || id_column)&.to_i
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
      item ? super : self[id_column]&.to_s
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

    if Record.record_class?(base)

      include InstanceMethods

      # Non-functional hints for RubyMine type checking.
      # :nocov:
      unless ONLY_FOR_DOCUMENTATION
        include Model
      end
      # :nocov:

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
