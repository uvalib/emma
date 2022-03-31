# app/models/upload/lookup_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Class methods for accessing Upload records.
#
module Upload::LookupMethods

  def included(base)
    base.send(:extend, self)
  end

  include Upload::WorkflowMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the Upload record by either :id or :submission_id.
  #
  # @param [String, Symbol, Integer, Hash, Upload] identifier
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
    all_ids = all.order(:id).pluck(:id)
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
  # @option opt [Symbol, nil] :sort     No sort if explicitly *nil*.
  # @option opt [Integer,nil] :offset
  # @option opt [Integer,nil] :limit
  #
  # @return [ActiveRecord::Relation]
  #
  # @see Upload#expand_ids
  # @see ActiveRecord::Relation#where
  #
  def get_relation(*items, **opt)                                               # NOTE: to Record::Searchable
    ids  = Array.wrap(opt.delete(:id))
    sids = Array.wrap(opt.delete(:submission_id))
    if items.present?
      items = expand_ids(*items).map { |term| id_term(term) }
      ids   = items.map { |term| term[:id]            } + ids
      sids  = items.map { |term| term[:submission_id] } + sids
    end
    ids   = ids.compact_blank!.uniq.presence
    sids  = sids.compact_blank!.uniq.presence
    terms = []
    if ids && sids
      terms << sql_terms(id: ids, submission_id: sids, join: :or)
    elsif ids
      opt[:id] = ids
    elsif sids
      opt[:submission_id] = sids
    end
    sort = opt.key?(:sort) ? opt.delete(:sort) : (:id unless ids || sids)

    user_opt = opt.extract!(*(USER_COLUMNS - %i[review_user]))
    terms << sql_terms(user_opt, join: :or) if user_opt.present?

    state_opt = opt.extract!(*STATE_COLUMNS)
    terms << sql_terms(state_opt, join: :or) if state_opt.present?

    limit  = positive(opt.delete(:limit))
    offset = positive(opt.delete(:offset))
    terms << "id > #{offset}" if offset

    query  = sql_terms(opt, *terms, join: :and)
    result = where(query)
    result = result.order(sort)  if sort.present?
    result = result.limit(limit) if limit.present?
    result
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

end

__loading_end(__FILE__)
