# app/models/upload/search_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Class methods for accessing Upload records.
#
module Upload::SearchMethods

  include Upload::SortMethods
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
  def get_record(identifier)
    find_by(**id_term(identifier))
  end

  # Get Upload records specified by either :id or :submission_id.
  #
  # @param [Array<Upload, String, Integer, Array>] identifiers
  # @param [Hash]                                  opt  Passed to #get_relation
  #
  # @return [Array<Upload>]
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
  SEARCH_RECORDS_OPTIONS = %i[offset limit page groups sort].freeze

  # URL parameters that are not directly used in searches.
  #
  # @type [Array<Symbol>]
  #
  NON_SEARCH_PARAMS =
    (SEARCH_RECORDS_OPTIONS + Paginator::NON_SEARCH_KEYS)
      .excluding(:sort).uniq.freeze

  # Get the Upload records specified by either :id or :submission_id.
  #
  # Additional constraints may be supplied via *opt*.  If no *identifiers* are
  # supplied then this method is essentially an invocation of #where which
  # returns the matching records.
  #
  # @param [Array<Upload, String, Integer, Array>] items
  # @param [Hash]                                  opt To #get_relation except
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
    # noinspection RailsParamDefResolve
    all_ids = all.pluck(:id)
    result[:min_id], result[:max_id] = all_ids.minmax
    result[:total] = item_count = all_ids.size

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
  GET_RELATION_OPTIONS = %i[id_key sid_key].freeze

  # Generate an ActiveRecord relation for records specified by either
  # :id or :submission_id.
  #
  # Additional constraints may be supplied via *opt*.  If no *items* are
  # supplied then this method is essentially an invocation of #where which
  # returns the matching records.
  #
  # @param [Array<Upload, String, Integer, Array>] items
  # @param [Hash]                                  opt To #make_relation except
  #
  # @option opt [Integer, Array] :id              Added items by ID.
  # @option opt [String, Array]  :submission_id   Added items by submission ID.
  #
  # @return [ActiveRecord::Relation]
  #
  # @see Upload#expand_ids
  #
  def get_relation(*items, **opt)
    terms = []
    _meth = opt[:meth] ||= "#{self_class}.#{__method__}"

    # === Record specifiers
    i_key = :id
    s_key = :submission_id
    ids   = Array.wrap(opt.delete(i_key))
    sids  = Array.wrap(opt.delete(s_key))
    if items.present?
      recs = expand_ids(*items).map! { |term| id_term(term) }
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
    # opt[:sort] was explicitly *nil* or *false*.
    opt[:sort] = (ids || sids).blank? unless opt.key?(:sort)

    make_relation(*terms, **opt)
  end

  # Local options consumed by #make_relation.
  #
  # @type [Array<Symbol>]
  #
  MAKE_RELATION_OPTIONS =
    %i[sort offset limit start_date end_date after before].freeze

  # make_relation
  #
  # @param [Array<String,Array,Hash>] terms
  # @param [Hash,String,Boolean,nil]  sort  No sort if *nil*, *false* or blank.
  # @param [Hash]                     opt   Passed to #where except:
  #
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
  def make_relation(*terms, sort: nil, **opt)
    meth = opt.delete(:meth)

    # === Sort order
    # Honor :asc as shorthand for the default sort order ascending, and :desc
    # as shorthand for the default sort order descending.
    outer = []
    group = []
    order = []
    sort  = normalize_sort_order(sort)
    if sort&.sql_only?
      order << sort
    elsif sort&.is_a?(Hash)
      sort.each_pair do |col, dir|
        dir = dir.to_s.upcase
        if col.end_with?('_item_count')
          tbl = :manifest_items
          cnt = "COUNT(1) FILTER (WHERE %s) #{dir}" % sort_scope(col, tbl)
        else
          tbl =
            case col.to_sym
              when :upload_count    then :uploads
              when :manifest_count  then :manifests
              when :item_count      then :manifest_items
            end
          cnt = ("COUNT(#{tbl}.id) #{dir}" if tbl)
        end
        outer << tbl                if tbl
        group << "#{table_name}.id" if tbl
        order << (cnt ? Arel.sql(cnt) : "#{table_name}.#{col} #{dir}")
      end
    end

    # === Filter by user
    user_opt = opt.extract!(*USER_COLUMNS.excluding(:review_user))
    if user_opt.present?
      terms << sql_terms(user_opt, join: :or)
    end

    # === Filter by state
    c_states, e_states =
      STATE_COLUMNS.map do |key|
        value = opt.delete(key)
        next if value.blank? || false?(value)
        Array.wrap(value).compact_blank.map!(&:to_sym)
      end
    if c_states || e_states
      phase, state, edit_state = [WORKFLOW_PHASE_COLUMN, *STATE_COLUMNS]
      parts    = []
      aborted  = %i[suspended failed canceled]
      e_states = (e_states || c_states).excluding(*aborted) if c_states
      if e_states.present?
        edited  = "#{phase} = 'edit'"
        parts << "((#{edited}) AND (#{edit_state} IN %s))" % sql_list(e_states)
      end
      if c_states.present?
        aborted = sql_list(aborted)
        created = "(#{phase} != 'edit') OR (#{edit_state} IN #{aborted})"
        parts << "((#{created}) AND (#{state} IN %s))" % sql_list(c_states)
      end
      terms << '(%s)' % parts.map { |term| "(#{term})" }.join(' OR ').squish
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
    inner = opt.keys.map(&:to_s).select { |k| k.include?('.') }.presence
    inner&.map! { |k| k.split('.').first.singularize.to_sym }

    # === Generate the SQL query
    if opt[:columns]
      query = sql_match(*terms, **opt)
    else
      query = sql_terms(*terms, **opt)
    end

    # === Generate the relation
    self.all.dup.tap do |result|
      result.left_outer_joins!(*outer)  if outer.present?
      result.group!(*group)             if group.present?
      result.joins!(*inner)             if inner.present?
      result.where!(query)              if query.present?
      result.order!(*order)             if order.present?
      result.limit!(limit)              if limit.present?
      result.offset!(offset)            if offset.present?
      __debug_line(meth, leader: "\t>>>", separator: "\n") do
        {
          outer:  outer,
          group:  group,
          inner:  inner,
          query:  query,
          order:  order,
          limit:  limit,
          offset: offset,
          SQL:    (result.to_sql rescue 'FAILED')
        }.compact_blank
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A table of counts for items in each state group.
  #
  # @param [ActiveRecord::Relation] relation
  #
  # @return [Hash{Symbol=>Integer}]
  #
  def group_counts(relation)
    relation.pluck(WORKFLOW_PHASE_COLUMN, *STATE_COLUMNS).map { |array|
      phase, state, edit = array.map { |v| v.to_sym if v.present? }
      state = edit if (phase == :edit) && edit && (edit != :canceled)
      Upload.state_group(state) if state
    }.compact.group_by(&:itself).transform_values(&:size).tap do |group_count|
      group_count[:all] = group_count.values.sum
    end
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
