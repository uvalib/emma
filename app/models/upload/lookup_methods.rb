# app/models/upload/lookup_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Class methods for accessing Upload records.
#
module Upload::LookupMethods

  include Upload::WorkflowMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the Upload record by either :id or :submission_id.
  #
  # @param [String, Symbol, Integer, Hash, Upload, nil] identifier
  #
  # @return [Upload, nil]
  #
  def get_record(identifier)                                                    # NOTE: to Record::Searchable
    find_by(**id_term(identifier))
  end

  # Get Upload records specified by either :id or :submission_id.
  #
  # @param [Array<Upload, String, Integer, Array>] identifiers
  # @param [Hash]                                  opt  Passed to #get_relation
  #
  # @return [Array<Upload>]
  #
  def get_records(*identifiers, **opt)                                          # NOTE: to Record::Searchable
    get_relation(*identifiers, **opt).records
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The #search_records method returns a hash with these fields in this order.  # NOTE: to Record::Searchable
  #
  #   :offset   The list offset for display purposes (not the SQL OFFSET).
  #   :limit    The page size.
  #   :page     The ordinal number of the current page.
  #   :first    If the given :page is the first page of the record set.
  #   :last     If the given :page is the last page of the record set.
  #   :total    Count of all matching records.
  #   :min_id   The :id of the first matching record.
  #   :max_id   The :id of the last matching record.
  #   :groups   Table of counts for each state group.
  #   :pages    An array of arrays where each element has the IDs for that page
  #   :list     An array of matching Upload records.
  #
  # @type [Hash{Symbol=>Any}]
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

  # Local options consumed by #search_records.                                  # NOTE: to Record::Searchable
  #
  # @type [Array<Symbol>]
  #
  SEARCH_RECORDS_OPTIONS = %i[offset limit page pages groups].freeze

  # URL parameters that are not directly used in searches.
  #
  # @type [Array<Symbol>]
  #
  NON_SEARCH_PARAMS =
    (SEARCH_RECORDS_OPTIONS + Paginator::NON_SEARCH_KEYS).uniq.freeze

  # Get the Upload records specified by either :id or :submission_id.
  #
  # Additional constraints may be supplied via *opt*.  If no *identifiers* are
  # supplied then this method is essentially an invocation of #where which
  # returns the matching records.
  #
  # @param [Array<Upload, String, Integer, Array>] identifiers
  # @param [Hash]                                  opt  Passed to #where except
  #
  # @option opt [Integer,nil]    :offset
  # @option opt [Integer,nil]    :limit
  # @option opt [Integer,nil]    :page
  # @option opt [Boolean]        :pages   Return array of arrays of record IDs.
  # @option opt [Boolean,Symbol] :groups  Return state group counts; if :only
  #                                        then do not return :list.
  #
  # @raise [RangeError]                   If :page is not valid.
  #
  # @return [Hash{Symbol=>Any}]           @see #SEARCH_RECORDS_TEMPLATE
  #
  # @see ActiveRecord::Relation#where
  #
  def search_records(*identifiers, **opt)                                       # NOTE: to Record::Searchable
    prop   = extract_hash!(opt, *SEARCH_RECORDS_OPTIONS)
    result = SEARCH_RECORDS_TEMPLATE.dup

    # Handle the case where a range has been specified which resolves to an
    # empty set of identifiers.  Otherwise, #get_relation will treat this case
    # identically to one where no identifiers where specified to limit results.
    if identifiers.present?
      identifiers = expand_ids(*identifiers).presence or return result
    end

    # Start by looking at results for all matches (without :limit or :offset).
    all = get_relation(*identifiers, **opt, sort: nil)

    # Handle the case where only a :groups summary is expected.
    return result.merge!(groups: group_by_state(all)) if prop[:groups] == :only

    # Group record IDs into pages.
    # noinspection RailsParamDefResolve
    all_ids = all.pluck(:id)
    limit   = positive(prop[:limit])
    pg_size = limit || 10 # TODO: fall-back page size for grouping
    pages   = all_ids.in_groups_of(pg_size).to_a.map(&:compact)

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

    result[:total]  = all_ids.size
    result[:min_id] = all_ids.first
    result[:max_id] = all_ids.last

    # Include the array of arrays of database IDs if requested.
    result[:pages]  = pages if prop[:pages]

    # Generate a :groups summary if requested.
    result[:groups] = group_by_state(all) if prop[:groups]

    # Finally, get the specific set of results.
    opt.merge!(limit: limit, offset: offset)
    result[:list] = get_relation(*identifiers, **opt).records

    result
  end

  # Generate an ActiveRecord relation for Upload records specified by either
  # :id or :submission_id.
  #
  # Additional constraints may be supplied via *opt*.  If no *identifiers* are
  # supplied then this method is essentially an invocation of #where which
  # returns the matching records.
  #
  # @param [Array<Upload, String, Integer, Array>] items
  # @param [Hash]                                  opt  Passed to #where except
  #
  # @option opt [String,Symbol,Hash,Boolean,nil] :sort No sort if nil or false.
  # @option opt [Integer, nil]      :offset
  # @option opt [Integer, nil]      :limit
  # @option opt [String, Date]      :start_date   Earliest :updated_at.
  # @option opt [String, Date]      :end_date     Latest :updated_at.
  # @option opt [String, Date]      :after        All :updated_at after this.
  # @option opt [String, Date]      :before       All :updated_at before this.
  # @option opt [String,Symbol,nil] :meth         Caller for diagnostics.
  #
  # @return [ActiveRecord::Relation]
  #
  # @see Upload#expand_ids
  # @see ActiveRecord::Relation#where
  #
  def get_relation(*items, **opt)                                               # NOTE: to Record::Searchable
    terms = []
    meth  = opt.delete(:meth) || "#{self_class}.#{__method__}"

    # == Record specifiers
    ids  = Array.wrap(opt.delete(:id))
    sids = Array.wrap(opt.delete(:submission_id))
    if items.present?
      recs = expand_ids(*items).map { |term| id_term(term) }
      ids  = recs.map { |rec| rec[:id]            } + ids
      sids = recs.map { |rec| rec[:submission_id] } + sids
    end
    ids  = ids.compact_blank!.uniq.presence
    sids = sids.compact_blank!.uniq.presence
    if ids && sids
      terms << sql_terms(id: ids, submission_id: sids, join: :or)
    elsif ids
      opt[:id] = ids
    elsif sids
      opt[:submission_id] = sids
    end

    # == Sort order
    # Avoid applying a sort order if identifiers were specified or if
    # opt[:sort] was explicitly *nil* or *false*. Permit :asc as shorthand for
    # the default sort order ascending; :desc as shorthand for the default sort
    # order descending.
    sort = opt.key?(:sort) ? opt.delete(:sort) : (:id unless ids || sids)
    if (sort = opt.key?(:sort) ? opt.delete(:sort) : (ids || sids).blank?)
      case sort
        when Hash                 then col, dir = sort.first
        when TrueClass            then col, dir = [nil, nil]
        when /^ASC$/i, /^DESC$/i  then col, dir = [nil, sort]
        else                           col, dir = [sort, nil]
      end
      col ||= implicit_order_column
      dir &&= dir.to_s.upcase
      sort  = col && "#{col} #{dir}".squish
      Log.info { "#{meth}: no default sort" } unless sort
    end

    # == Limit by user
    user_opt = opt.extract!(*(USER_COLUMNS - %i[review_user]))
    terms << sql_terms(user_opt, join: :or) if user_opt.present?

    # == Limit by state
    state_opt = opt.extract!(*STATE_COLUMNS)
    terms << sql_terms(state_opt, join: :or) if state_opt.present?

    # == Update time lower bound
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

    # == Update time upper bound
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

    # == Record limit/offset
    limit  = positive(opt.delete(:limit))
    offset = positive(opt.delete(:offset))
    terms << "id > #{offset}" if offset

    # == Generate the relation
    query = sql_terms(opt, *terms, join: :and)
    where(query).tap do |result|
      result.order!(sort)  if sort.present?
      result.limit!(limit) if limit.present?
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # group_by_state
  #
  # @param [ActiveRecord::Relation] relation
  #
  # @return [Hash{Symbol=>Integer}]
  #
  def group_by_state(relation)                                                  # NOTE: to Record::Searchable
    group_count = {}
    relation.group(*STATE_COLUMNS).count.each_pair do |states, count|
      # Use :edit_state if present; use :state otherwise.
      state = states.pop.presence || states.pop.presence || :nil
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

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)
