# app/models/record/searchable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods for accessing records.
#
module Record::Searchable

  extend ActiveSupport::Concern

  include Record
  include Record::EmmaIdentification

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ActiveRecord::FinderMethods
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Name of the column on which pagination is based.
  #
  # @return [Symbol, nil]
  #
  # === Implementation Notes
  # This has to be a column with unique values for every record which can be
  # ordered (that is, #minimum_id and #maximum_id have to be non-nil).
  #
  def pagination_column(*)
    id_column
  end

  # The database column currently associated with the workflow state of the
  # record.
  #
  # @return [Symbol, nil]
  #
  def state_column(*)
    Log.debug { "#{__method__}: not defined for #{self_class}" }
  end

  # Sort order applied by default in #get_relation.
  #
  # @return [Symbol, String, Hash]
  #
  def default_sort
    implicit_order_column || pagination_column
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get a record by either :id or :submission_id.
  #
  # @param [String, Symbol, Integer, Hash, Model, nil] item
  # @param [Hash]                                      opt   Passed to #id_term
  #
  # @return [Model, nil]
  #
  # @note From Upload::LookupMethods#get_record
  #
  def get_record(item, **opt)
    find_by(**id_term(item, **opt))
  end

  # Get records specified by either :id or :submission_id.
  #
  # @param [Array<Model, String, Integer, Array>] identifiers
  # @param [Hash]                                 opt  Passed to #get_relation
  #
  # @return [Array<Model>]
  #
  # @note From Upload::LookupMethods#get_records
  #
  def get_records(*identifiers, **opt)
    get_relation(*identifiers, **opt).records
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Local options consumed by #search_records.
  #
  # @type [Array<Symbol>]
  #
  # @note From Upload::LookupMethods#SEARCH_RECORDS_OPTIONS
  #
  SEARCH_RECORDS_OPTIONS = %i[offset limit page groups sort].freeze

  # URL parameters that are not directly used in searches.
  #
  # @type [Array<Symbol>]
  #
  # @note From Upload::LookupMethods#NON_SEARCH_PARAMS
  #
  NON_SEARCH_PARAMS =
    (SEARCH_RECORDS_OPTIONS + Paginator::NON_SEARCH_KEYS)
      .excluding(:sort).uniq.freeze

  # Get the records specified by either :id or :submission_id.
  #
  # Additional constraints may be supplied via *opt*.  If no *identifiers* are
  # supplied then this method is essentially an invocation of #where which
  # returns the matching records.
  #
  # @param [Array<Model, String, Integer, Array>] items
  # @param [Hash]                                 opt  To #get_relation except
  #                                                    #SEARCH_RECORDS_OPTIONS:
  #
  # @option opt [String,Symbol,Hash,Boolean,nil] :sort No sort if nil or false.
  # @option opt [Integer,nil]    :offset
  # @option opt [Integer,nil]    :limit
  # @option opt [Integer,nil]    :page
  # @option opt [Boolean,Symbol] :groups  Return state group counts; if :only
  #                                        then do not return :list.
  # @option opt [String,Symbol]  :meth    Calling method for diagnostics.
  #
  # @raise [RangeError]                   If :page is not valid.
  #
  # @return [Paginator::Result]
  #
  # @see ActiveRecord::Relation#where
  #
  # @note From Upload::LookupMethods#search_records
  #
  def search_records(*items, **opt)
    result = Paginator::Result.new

    # If a range of items has been specified which resolves to an empty set of
    # identifiers, return now.  Otherwise, #get_relation would yield results
    # for a general search.
    return result if items.present? && (items = expand_ids(*items)).blank?

    # Define a relation for all matches (without :limit or :offset).
    opt[:meth] ||= "#{self_class}.#{__method__}"
    arg = opt.extract!(*SEARCH_RECORDS_OPTIONS)
    all = get_relation(*items, **opt, sort: :id)

    # Generate a :groups summary if requested, returning if that was the only
    # value of interest.
    if (groups = arg[:groups])
      result[:groups] = group_counts(all)
      return result if groups == :only
    end

    # Record set information.
    if pagination_column
      all_ids = all.pluck(pagination_column)
      result[:min_id], result[:max_id] = all_ids.minmax
      result[:total] = item_count = all_ids.size
    else
      result[:total] = item_count = all.count
    end

    # Setup pagination; explicit page number overrides :limit/:offset.
    limit  = positive(arg[:limit])
    offset = positive(arg[:offset])
    if (page = positive(arg[:page]))
      page_size = limit ||= Paginator.default_page_size
      offset    = (page - 1) * page_size
      last_page = (item_count / page_size) + 1
      result[:page]  = page
      result[:first] = (page == 1)
      result[:last]  = (page >= last_page)
    end
    result[:limit]  = limit  if limit
    result[:offset] = offset if offset
    opt.merge!(limit: limit, offset: offset)

    # Setup sorting.
    opt[:sort] = arg[:sort] if arg.key?(:sort)

    # Get the specific set of results.
    result[:list] = get_relation(*items, **opt)

    result
  end

  # Local options consumed by #get_relation.
  #
  # @type [Array<Symbol>]
  #
  # @note From Upload::LookupMethods#GET_RELATION_OPTIONS
  #
  GET_RELATION_OPTIONS = %i[id_key sid_key].freeze

  # Generate an ActiveRecord relation for records specified by either
  # :id or :submission_id.
  #
  # Additional constraints may be supplied via *opt*.  If no *items* are
  # supplied then this method is essentially an invocation of #where which
  # returns the matching records.
  #
  # @param [Array<Model, String, Integer, Array>] items
  # @param [Hash]                                 opt  Passed to #where except
  #
  # @option opt [String,Symbol,Hash,Boolean,nil] :sort No sort if nil or false.
  # @option opt [Integer, nil]      :offset
  # @option opt [Integer, nil]      :limit
  # @option opt [String, Date]      :start_date   Earliest :updated_at.
  # @option opt [String, Date]      :end_date     Latest :updated_at.
  # @option opt [String, Date]      :after        All :updated_at after this.
  # @option opt [String, Date]      :before       All :updated_at before this.
  # @option opt [Symbol, nil]       :id_key       Default: `#id_column`.
  # @option opt [Symbol, nil]       :sid_key      Default: `#sid_column`.
  # @option opt [String,Symbol,nil] :meth         Caller for diagnostics.
  #
  # @return [ActiveRecord::Relation]
  #
  # @see Record::EmmaIdentification#expand_ids
  # @see ActiveRecord::Relation#where
  #
  # @note From Upload::LookupMethods#get_relation
  #
  def get_relation(*items, **opt)
    terms  = []
    _meth  = opt[:meth] ||= "#{self_class}.#{__method__}"
    arg    = opt.extract!(*GET_RELATION_OPTIONS)

    # === Record specifiers
    id_opt = arg.compact.transform_values(&:to_sym)
    i_key  = id_opt[:id_key]  ||= id_column
    s_key  = id_opt[:sid_key] ||= sid_column
    ids    = Array.wrap(opt.delete(i_key))
    sids   = Array.wrap(opt.delete(s_key))
    if items.present?
      recs = expand_ids(*items).map! { |term| id_term(term, **id_opt) }
      ids  = recs.map { |rec| rec[i_key] }.concat(ids)  if i_key
      sids = recs.map { |rec| rec[s_key] }.concat(sids) if s_key
    end
    ids  = ids.compact_blank!.uniq.presence
    sids = sids.compact_blank!.uniq.presence
    if ids && sids
      terms << sql_terms(i_key => ids, s_key => sids, join: :or)
    elsif ids
      opt[i_key] = ids
    elsif sids
      opt[s_key] = sids
    end

    # === Sort order
    # Avoid applying a sort order if identifiers were specified or if
    # opt[:sort] was explicitly *nil* or *false*. Permit :asc as shorthand for
    # the default sort order ascending; :desc as shorthand for the default sort
    # order descending.
    if (sort = opt.key?(:sort) ? opt.delete(:sort) : (ids || sids).blank?)
      case sort
        when Hash                 then col, dir = sort.first
        when TrueClass            then col, dir = [nil, nil]
        when /^ASC$/i, /^DESC$/i  then col, dir = [nil, sort]
        else                           col, dir = [sort, nil]
      end
      col ||= implicit_order_column || pagination_column
      col &&= "#{table_name}.#{col}"
      dir &&= dir.to_s.upcase
      sort  = col && "#{col} #{dir}".squish
      Log.info { "#{meth}: no default sort" } unless sort
    end

    # === Filter by user
    user_opt = opt.extract!(:user, :user_id)
    if user_column && user_opt.present?
      users = user_opt.values.flatten.map! { |u| User.id_value(u) }.uniq
      users = users.first unless users.many?
      terms << sql_terms(user_column => users, join: :or)
    end

    # === Filter by state
    state_opt = state_column && opt.extract!(state_column)
    if state_opt.present?
      terms << sql_terms(state_opt, join: :or)
    end

    # === Update time lower bound
    exclusive, inclusive = [opt.delete(:after), opt.delete(:start_date)]
    lower = exclusive || inclusive
    day, month, year = day_string(lower)
    lower = day if day
    if (lower &&= (lower.to_datetime rescue nil))
      lower += 1.month if exclusive && month
      lower += 1.year  if exclusive && year
      on_or_after = (exclusive && !month && !year) ? '>' : '>='
      terms << "updated_at #{on_or_after} '#{lower}'::date"
    end

    # === Update time upper bound
    exclusive, inclusive = [opt.delete(:before), opt.delete(:end_date)]
    upper = exclusive || inclusive
    day, month, year = day_string(upper)
    upper = day if day
    if (upper &&= (upper.to_datetime rescue nil))
      upper += 1.month - 1.day if inclusive && month
      upper += 1.year  - 1.day if inclusive && year
      on_or_before = exclusive ? '<' : '<='
      terms << "updated_at #{on_or_before} '#{upper}'::date"
    end

    # === Record limit/offset
    limit  = positive(opt.delete(:limit))
    offset = positive(opt.delete(:offset))

    # === Filter by association
    assoc = opt.keys.map(&:to_s).select { |k| k.include?('.') }.presence
    assoc&.map! { |k| k.split('.').first.singularize.to_sym }

    # === Generate the relation
    query  = sql_terms(opt, *terms, join: :and)
    result = assoc ? joins(*assoc).where(query) : where(query)
    result.order!(sort)  if sort.present?
    result.limit!(limit) if limit.present?
    result
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A table of counts for items in each state group.
  #
  # @param [ActiveRecord::Relation] relation
  # @param [Symbol]                 column
  #
  # @raise [RuntimeError] If the current model does not have a :state_column.
  #
  # @return [Hash{Symbol=>Integer}]
  #
  # @note From Upload::LookupMethods#group_counts
  #
  def group_counts(relation, column = state_column)
    raise "no :state_column for #{self.class}" unless column
    group_count = {}
    relation.group(column).count.each_pair do |state, count|
      group = Upload::WorkflowMethods.state_group(state)
      group_count[group] = group_count[group].to_i + count
    end
    group_count[:all] = group_count.values.sum
    group_count
  end

  # Generate a Date-parseable string from a string that indicates either a day,
  # (YYYYMMDD), a month (YYYYMM), or a year (YYYY) -- with or without date
  # separator punctuation.
  #
  # @param [*] value
  #
  # @return [nil,    false, false]    If *value* is not a date string.
  # @return [String, false, false]    If *value* specifies a day.
  # @return [String, true,  false]    If *value* specifies a month.
  # @return [String, false, true]     If *value* specifies a year
  #
  # @note From Upload::LookupMethods#day_string
  #
  def day_string(value)
    day = month = year = nil
    if value.is_a?(String)
      case (value = value.strip)
        when /^\d{4}$/           then day = year  = "#{value}-01-01"
        when /^\d{4}(\D?)\d{2}$/ then day = month = "#{value}#{$1}01"
        else                          day = value
      end
    end
    # noinspection RubyMismatchedReturnType
    return day, !!month, !!year
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Class methods automatically added to the including record class.
  #
  module ClassMethods

    include Record::Searchable

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Locate records matching the submission ID given as either *sid* or
    # `opt[:submission_id]`.
    #
    # @param [Model, Hash, String, Symbol, nil] sid
    # @param [Integer, nil]    max      Log error if matches exceed this.
    # @param [Boolean, Symbol] log      Calling method for logging.
    # @param [Boolean]         fatal    If *false*, return *nil* on error.
    # @param [Hash]            opt      Passed to #where.
    #
    # @raise [Record::StatementInvalid] If *sid*/opt[:submission_id] invalid.
    # @raise [Record::NotFound]         If record not found.
    #
    # @return [ActiveRecord::Relation]
    # @return [nil]                     If invalid and *fatal* is *false*.
    #
    # @note From Upload#matching_sid
    #
    def matching_sid(sid = nil, max: nil, log: false, fatal: true, **opt)
      msg = log.present?
      err = fatal.present?
      sid = opt[:submission_id] = sid_value(sid || opt)
      if sid.blank?
        err &&= Record::StatementInvalid
        msg &&= 'No submission ID given'
      elsif (result = where(**opt)).empty?
        err &&= Record::NotFound
        msg &&= "No %{type} record for submission ID #{sid}"
      elsif max && (max = positive(max)) && (max < (total = result.size))
        err &&= nil
        msg &&= "#{total} %{type} records for submission ID #{sid}"
      else
        return result
      end
      msg &&= msg % { type: [base_class, opt[:type]].compact.join('::') }
      meth  = msg && (log.is_a?(Symbol) ? log : "#{self_class}.#{__method__}")
      Log.warn("#{meth}: #{msg}") if msg
      # noinspection RubyMismatchedArgumentType
      raise err, msg if err
    end

    # Get the latest record matching the submission ID given as either *sid* or
    # `opt[:submission_id]`.
    #
    # @param [Model, Hash, String, Symbol, nil] sid
    # @param [Symbol, String] sort    In case of multiple SIDs (:created_at).
    # @param [Hash]           opt     Passed to #matching_sid.
    #
    # @raise [Record::StatementInvalid]   If *sid*/opt[:submission_id] invalid.
    # @raise [Record::NotFound]           If record not found.
    #
    # @return [Model]
    # @return [nil]                       On error if `opt[:fatal]` is *false*.
    #
    # @note From Upload#latest_for_sid
    #
    def latest_for_sid(sid = nil, sort: nil, **opt)
      result = matching_sid(sid, **opt) or return
      sort ||= :created_at
      # noinspection RubyMismatchedReturnType
      result.order(sort).last
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
