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

  # The #search_records method returns a hash with these fields in this order.
  #
  #   :offset   The list offset for display purposes (not the SQL OFFSET).
  #   :limit    The page size.
  #   :page     The ordinal number of the current page.
  #   :first    If the given :page is the first page of the record set.
  #   :last     If the given :page is the last page of the record set.
  #   :total    Count of all matching records.
  #   :min_id   The #pagination_column value of the first matching record.
  #   :max_id   The #pagination_column value of the last matching record.
  #   :groups   Table of counts for each state group.
  #   :pages    An array of arrays where each element has the IDs for that page
  #   :list     An array of matching Entry records.
  #
  # @type [Hash{Symbol=>Any}]
  #
  # @note From Upload::LookupMethods#SEARCH_RECORDS_TEMPLATE
  #
  SEARCH_RECORDS_TEMPLATE = {
    offset: 0,
    limit:  0,
    page:   0,
    first:  true,
    last:   true,
    total:  0,
    min_id: 0,
    max_id: 0,
    groups: {},
    pages:  [],
    list:   [],
  }.freeze

  # Local options consumed by #search_records.
  #
  # @type [Array<Symbol>]
  #
  # @note From Upload::LookupMethods#SEARCH_RECORDS_OPTIONS
  #
  SEARCH_RECORDS_OPTIONS = %i[offset limit page pages groups sort].freeze

  # URL parameters that are not directly used in searches.
  #
  # @type [Array<Symbol>]
  #
  # @note From Upload::LookupMethods#NON_SEARCH_PARAMS
  #
  NON_SEARCH_PARAMS =
    [*SEARCH_RECORDS_OPTIONS, *Paginator::NON_SEARCH_KEYS]
      .excluding(:sort).uniq.freeze

  # Get the records specified by either :id or :submission_id.
  #
  # Additional constraints may be supplied via *opt*.  If no *identifiers* are
  # supplied then this method is essentially an invocation of #where which
  # returns the matching records.
  #
  # @param [Array<Model, String, Integer, Array>] identifiers
  # @param [Hash]                                 opt  To #get_relation except
  #                                                    #SEARCH_RECORDS_OPTIONS:
  #
  # @option opt [String,Symbol,Hash,Boolean,nil] :sort No sort if nil or false.
  # @option opt [Integer,nil]    :offset
  # @option opt [Integer,nil]    :limit
  # @option opt [Integer,nil]    :page
  # @option opt [Boolean]        :pages   Return array of arrays of record IDs.
  # @option opt [Boolean,Symbol] :groups  Return state group counts; if :only
  #                                        then do not return :list.
  # @option opt [String,Symbol]  :meth    Calling method for diagnostics.
  #
  # @raise [RangeError]                   If :page is not valid.
  #
  # @return [Hash{Symbol=>Any}]           @see #SEARCH_RECORDS_TEMPLATE
  #
  # @see ActiveRecord::Relation#where
  #
  # @note From Upload::LookupMethods#search_records
  #
  def search_records(*identifiers, **opt)
    prop   = opt.extract!(*SEARCH_RECORDS_OPTIONS)
    sort   = pagination_column || implicit_order_column
    sort   = prop.key?(:sort) ? prop.delete(:sort) : sort
    groups = prop.delete(:groups)
    result = SEARCH_RECORDS_TEMPLATE.dup

    # Handle the case where a range has been specified which resolves to an
    # empty set of identifiers.  Otherwise, #get_relation will treat this case
    # identically to one where no identifiers where specified to limit results.
    if identifiers.present?
      identifiers = expand_ids(*identifiers).presence or return result
    end

    # Start by looking at results for all matches (without :limit or :offset).
    opt[:meth] ||= "#{self_class}.#{__method__}"
    all = get_relation(*identifiers, **opt, sort: (identifiers.blank? && sort))

    # Handle the case where only a :groups summary is expected.
    return result.merge!(groups: group_counts(all)) if groups == :only

    if pagination_column

      # Group record IDs into pages.
      all_ids = all.pluck(pagination_column)
      limit   = positive(prop[:limit])
      pg_size = limit || 10 # TODO: fall-back page size for grouping
      pages   = all_ids.in_groups_of(pg_size).to_a.map(&:compact)

      result[:total]  = all_ids.size
      result[:min_id] = all_ids.first
      result[:max_id] = all_ids.last

      if (page = prop[:page]&.to_i)
        if page > 1
          offset = pages[page - 2]&.last
          raise RangeError, "Page #{page} is invalid" if offset.nil?
        else
          page   = 1
          offset = nil
        end
        result[:page]   = page
        result[:first]  = (page == 1)
        result[:last]   = (page >= pages.size)
        result[:limit]  = limit = pg_size
        result[:offset] = (page - 1) * pg_size
      else
        result[:limit]  = limit
        result[:offset] = offset = prop[:offset]
      end
      opt.merge!(limit: limit, offset: offset)

      # Include the array of arrays of database IDs if requested.
      result[:pages] = pages if prop[:pages]

    else
      # The record type explicitly does not support pagination.
      Log.info("#{opt[:meth]}: pagination not supported") if prop.present?
    end

    # Generate a :groups summary if requested.
    result[:groups] = group_counts(all) if groups

    # Finally, get the specific set of results.
    result[:list] = get_relation(*identifiers, **opt, sort: sort).records

    result
  end

  # Generate an ActiveRecord relation for records specified by either
  # :id or :submission_id.
  #
  # Additional constraints may be supplied via *opt*.  If no *identifiers* are
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
    terms   = []
    meth    = opt.delete(:meth) || "#{self_class}.#{__method__}"
    id_opt  = opt.extract!(:id_key, :sid_key).transform_values!(&:to_sym)
    id_key  = id_opt[:id_key]  ||= id_column
    sid_key = id_opt[:sid_key] ||= sid_column

    # === Record specifiers
    ids  = id_key  ? Array.wrap(opt.delete(id_key))  : []
    sids = sid_key ? Array.wrap(opt.delete(sid_key)) : []
    if items.present?
      recs = expand_ids(*items).map { |term| id_term(term, **id_opt) }
      ids  = recs.map { |rec| rec[id_key]  } + ids  if id_key
      sids = recs.map { |rec| rec[sid_key] } + sids if sid_key
    end
    ids  = ids.compact_blank!.uniq.presence
    sids = sids.compact_blank!.uniq.presence
    if ids && sids
      terms << sql_terms(id_key => ids, sid_key => sids, join: :or)
    elsif ids
      opt[id_key]  = ids
    elsif sids
      opt[sid_key] = sids
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
      dir &&= dir.to_s.upcase
      sort  = col && "#{col} #{dir}".squish
      Log.info { "#{meth}: no default sort" } unless sort
    end

    # === Filter by user
    user_opt = opt.extract!(:user, :user_id)
    if user_column && user_opt.present?
      users = user_opt.values.flatten.map { |u| User.id_value(u) }.uniq
      users = users.first if users.size == 1
      terms << sql_terms(user_column => users, join: :or)
    end

    # === Filter by state
    state_opt = state_column && opt.extract!(state_column)
    terms << sql_terms(state_opt, join: :or) if state_opt.present?

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
    if offset && pagination_column
      terms << "#{pagination_column} > #{offset}"
    elsif offset
      Log.warn { "#{meth}: pagination not supported" }
    end

    # === Filter by association
    assoc = opt.keys.map(&:to_s).select { |k| k.include?('.') }
    assoc.map! { |k| k.split('.').first.singularize.to_sym }
    assoc = assoc.presence

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
