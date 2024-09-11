# app/models/upload/search_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Class methods for accessing Upload records.
#
module Upload::SearchMethods

  include Record::Searchable

  include Upload::SortMethods
  include Upload::WorkflowMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
      terms << sql_or(user_opt)
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
      terms << '(%s)' % parts.map { "(#{_1})" }.join(' OR ').squish
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
    inner = opt.keys.map(&:to_s).select { _1.include?('.') }.presence
    inner&.map! { _1.split('.').first.singularize.to_sym }

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
      phase, state, edit = array.map { _1.to_sym if _1.present? }
      state = edit if (phase == :edit) && edit && (edit != :canceled)
      Upload.state_group(state) if state
    }.compact.group_by(&:itself).transform_values(&:size).tap do |group_count|
      group_count[:all] = group_count.values.sum
    end
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
