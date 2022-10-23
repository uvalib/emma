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

  STATE_COLUMN = Record::Steppable::STATE_COLUMN

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
  def get_record(item, **opt)                                                   # NOTE: from Upload::LookupMethods
    find_by(**id_term(item, **opt))
  end

  # Get records specified by either :id or :submission_id.
  #
  # @param [Array<Model, String, Integer, Array>] identifiers
  # @param [Hash]                                 opt  Passed to #get_relation
  #
  # @return [Array<Model>]
  #
  def get_records(*identifiers, **opt)                                          # NOTE: from Upload::LookupMethods
    get_relation(*identifiers, **opt).records
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The #search_records method returns a hash with these fields in this order.  # NOTE: from Upload::LookupMethods
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
  #   :list     An array of matching Entry records.
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

  # Local options consumed by #search_records.                                  # NOTE: from Upload::LookupMethods
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

  # Get the records specified by either :id or :submission_id.
  #
  # Additional constraints may be supplied via *opt*.  If no *identifiers* are
  # supplied then this method is essentially an invocation of #where which
  # returns the matching records.
  #
  # @param [Array<Model, String, Integer, Array>] identifiers
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
  def search_records(*identifiers, **opt)                                       # NOTE: from Upload::LookupMethods
    prop   = extract_hash!(opt, *SEARCH_RECORDS_OPTIONS)
    result = SEARCH_RECORDS_TEMPLATE.dup

    # Handle the case where a range has been specified which resolves to an
    # empty set of identifiers.  Otherwise, #get_relation will treat this case
    # identically to one where no identifiers where specified to limit results.
    if identifiers.present?
      identifiers = expand_ids(*identifiers).presence or return result
    end

    # Start by looking at results for all matches (without :limit or :offset).
    all = get_relation(*identifiers, **opt, sort: false)

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
  # @option opt [Symbol,Boolean,nil] :sort      No sort if explicitly *nil*.
  # @option opt [Integer,nil]        :offset
  # @option opt [Integer,nil]        :limit
  # @option opt [Symbol,nil]         :id_key    Default: `#id_column`.
  # @option opt [Symbol,nil]         :sid_key   Default: `#sid_column`.
  #
  # @return [ActiveRecord::Relation]
  #
  # @see Record::EmmaIdentification#expand_ids
  # @see ActiveRecord::Relation#where
  #
  def get_relation(*items, **opt)                                               # NOTE: from Upload::LookupMethods
    id_opt  = extract_hash!(opt, :id_key, :sid_key).transform_values!(&:to_sym)
    id_key  = id_opt[:id_key]  ||= id_column
    sid_key = id_opt[:sid_key] ||= sid_column
    ids     = id_key  ? Array.wrap(opt.delete(id_key))  : []
    sids    = sid_key ? Array.wrap(opt.delete(sid_key)) : []
    if items.present?
      items = expand_ids(*items).map { |term| id_term(term, **id_opt) }
      ids   = items.map { |term| term[id_key]  } + ids  if id_key
      sids  = items.map { |term| term[sid_key] } + sids if sid_key
    end
    ids   = ids.compact_blank!.uniq.presence
    sids  = sids.compact_blank!.uniq.presence
    terms = []
    if ids && sids
      terms << sql_terms(id_key => ids, sid_key => sids, join: :or)
    elsif ids
      opt[id_key]  = ids
    elsif sids
      opt[sid_key] = sids
    end

    # Avoid applying a sort order if identifiers were specified or if
    # opt[:sort] was explicitly *nil* or *false*. Permit :asc as shorthand for
    # the default sort order ascending; :desc as shorthand for the default sort
    # order descending.
    if (sort = opt.key?(:sort) ? opt.delete(:sort) : (ids || sids).blank?)
      sort_col = implicit_order_column || :id
      if sort.is_a?(TrueClass)
        sort = sort_col
      elsif %W(ASC DESC).include?((dir = sort.to_s.upcase))
        sort = "#{sort_col} #{dir}"
      end
    end

    if (user_opt = opt.extract!(:user, :user_id)).present?
      users = user_opt.values.flatten.map { |u| User.id_value(u) }.uniq
      users = users.first if users.size == 1
      terms << sql_terms(user_id: users, join: :or)
    end

    state_opt = opt.extract!(STATE_COLUMN)
    terms << sql_terms(state_opt, join: :or) if state_opt.present?

    limit  = positive(opt.delete(:limit))
    offset = positive(opt.delete(:offset))
    terms << "id > #{offset}" if offset

    query  = sql_terms(opt, *terms, join: :and)
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
  # @param [Symbol]                 column
  #
  # @return [Hash{Symbol=>Integer}]
  #
  def group_by_state(relation, column = STATE_COLUMN)                           # NOTE: from Upload::LookupMethods
    group_count = {}
    relation.group(column).count.each_pair do |state, count|
      group = Record::Steppable.state_group(state)
      group_count[group] = group_count[group].to_i + count
    end
    group_count[:all] = group_count.values.sum
    group_count
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
    # @param [Integer] max                Log error if matches exceed this.
    # @param [Symbol]  meth               Calling method for logging.
    # @param [Boolean] no_raise           If *true*, return *nil* on error.
    # @param [Hash]    opt                Passed to #where.
    #
    # @raise [Record::StatementInvalid]   If *sid*/opt[:submission_id] invalid.
    # @raise [Record::NotFound]           If record not found.
    #
    # @return [ActiveRecord::Relation]    Or *nil* on error if *no_raise*.
    #
    def matching_sid(sid = nil, max: nil, meth: nil, no_raise: false, **opt)
      sid = opt[:submission_id] = sid_value(sid || opt)
      if sid.blank?
        err = (Record::StatementInvalid unless no_raise)
        msg = 'No submission ID given'
      elsif (result = where(**opt)).empty?
        err = (Record::NotFound unless no_raise)
        msg = "No %{type} record for submission ID #{sid}"
      elsif (max = positive(max)) && (max < (total = result.size))
        err = nil
        msg = "#{total} %{type} records for submission ID #{sid}"
      else
        return result
      end
      meth ||= "#{self.class}.#{__method__}"
      msg %= { type: [base_class, opt[:type]].compact.join('::') }
      Log.warn { "#{meth}: #{msg}" }
      raise err, msg if err
    end

    # Get the latest record matching the submission ID given as either *sid* or
    # `opt[:submission_id]`.
    #
    # Returns *nil* on error if *no_raise* is *true*.
    #
    # @param [Model, Hash, String, Symbol, nil] sid
    # @param [Symbol, String] sort    In case of multiple SIDs (:created_at).
    # @param [Hash]           opt     Passed to #matching_sid.
    #
    # @raise [Record::StatementInvalid]   If *sid*/opt[:submission_id] invalid.
    # @raise [Record::NotFound]           If record not found.
    #
    # @return [Model]                     Or *nil* on error if *no_raise*.
    #
    def latest_for_sid(sid = nil, sort: nil, **opt)
      result = matching_sid(sid, **opt) or return
      sort ||= :created_at
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
