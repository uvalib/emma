# app/controllers/concerns/model_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for controllers that implement CRUD semantics.
#
# === Usage Notes
# This module is expected to be included by a concern which selective overrides
# these methods to accommodate model-specific variations to this base logic.
#
#--
# noinspection RubyTooManyMethodsInspection
#++
module ModelConcern

  extend ActiveSupport::Concern

  include ExceptionHelper
  include FlashHelper
  include IdentityHelper
  include ParamsHelper

  include OptionsConcern
  include PaginationConcern
  include ParamsConcern
  include ResponseConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  delegate :model_class, :model_key, :model_id_key, to: :model_options

  def search_records_keys
    model_class.const_get(:SEARCH_RECORDS_OPTIONS)
  end

  def search_only_keys
    search_records_keys.excluding(:offset, :limit)
  end

  def find_or_match_keys
    result = [*search_records_keys, model_key, model_id_key]
    result << :org   << :org_id
    result << :user  << :user_id
    result << :group << :state
    result.uniq!
    result
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The model record identified in URL parameters by #id_param_keys.
  #
  # @return [Integer, String, nil]
  #
  def identifier
    current_params unless defined?(@identifier) && @identifier
    @identifier
  end

  # The database ID of a model record identified in URL parameters.
  #
  # @return [Integer, nil]
  #
  def db_id
    current_params unless defined?(@db_id) && @db_id
    @db_id
  end

  # Only allow a list of trusted parameters through.
  #
  # @return [Hash]
  #
  def current_params(&blk)
    @current_params ||=
      request.get? ? current_get_params(&blk) : current_post_params(&blk)
  end

  # Get URL parameters relevant to the current operation.
  #
  # @return [Hash{Symbol=>*}]
  #
  def current_get_params
    model_options.get_model_params.tap do |prm|
      yield(prm) if block_given?
      @identifier ||= extract_identifier(prm)
    end
  end

  # Extract POST parameters that are usable for creating/updating a model
  # record instance.
  #
  # @return [Hash{Symbol=>*}]
  #
  def current_post_params
    model_options.model_post_params.tap do |prm|
      prm.extract!(*model_options.data_keys).each_pair do |_, v|
        next unless (v &&= safe_json_parse(v)).is_a?(Hash)
        next unless (id = positive(v[:id]))
        prm[:id] = id
      end
      yield(prm) if block_given?
      @identifier ||= extract_identifier(prm)
    end
  end

  # model_request_params
  #
  # @param [Model, Hash{Symbol=>*}, *] item
  # @param [Hash{Symbol=>*}, nil]      prm
  #
  # @return [Array<(Model, Hash{Symbol=>*})>]
  # @return [Array<(*,     Hash{Symbol=>*})>]
  #
  def model_request_params(item, prm = nil, &blk)
    item, prm = [nil, item] if item.is_a?(Hash)
    prm ||= current_params(&blk)
    return item, prm
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # extract_identifier
  #
  # @param [Hash] prm
  #
  # @return [Integer, String, nil]
  #
  def extract_identifier(prm)
    ids = prm.values_at(*model_options.identifier_keys)
    identifier_list(*ids).first
  end

  # If a user was not already specified, add the current user to the given
  # parameters.
  #
  # @param [Hash]      prm
  # @param [User, nil] user           Default: #current_user
  #
  # @return [Hash]
  #
  def current_user!(prm, user = nil)
    user ||= current_user
    case
      when prm.key?(:user_id) then prm
      when prm.key?(:user)    then prm.merge!(user_id: prm.delete(:user))
      when (id = user&.id)    then prm.merge!(user_id: id)
      else                         prm
    end
  end

  # If an organization was not already specified, add the organization of the
  # current user to the given parameters.
  #
  # @param [Hash]     prm
  # @param [Org, nil] org             Default: #current_org
  #
  # @return [Hash]
  #
  def current_org!(prm, org = nil)
    org ||= current_org
    case
      when prm.key?(:org_id) then prm
      when prm.key?(:org)    then prm.merge!(org_id: prm.delete(:org))
      when (id = org&.id)    then prm.merge!(org_id: id)
      else                        prm
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return with the specified model record.
  #
  # @param [String, Integer, Hash, Model, *] item   Default: #identifier.
  # @param [Hash]                            opt    To Model#find_record.
  #
  # @raise [Record::StatementInvalid] If :id not given.
  # @raise [Record::NotFound]         If *item* was not found.
  #
  # @return [Model, nil]
  #
  def get_record(item = nil, **opt)
    id = opt.delete(:id)
    id = item            if item.is_a?(String) || item.is_a?(Integer)
    id = item[:id] || id if item.is_a?(Model)  || item.is_a?(Hash)
    id = identifier      if id.blank?
    model_class.find_record(id, **opt)
  end

  # Locate and filter model records.
  #
  # @param [Array]         items    Default: #identifier.
  # @param [Array<Symbol>] filters  Filter methods to limit/modify params
  # @param [Hash]          opt      To Record::Searchable#search_records;
  #                                   default: `#current_params` if no *items*
  #                                   are given.
  #
  # @raise [Record::SubmitError]    If :page is not valid.
  #
  # @return [Hash{Symbol=>*}]
  #
  def find_or_match_records(*items, filters: [], **opt)
    items = items.flatten.compact
    items << identifier if items.blank? && identifier.present?

    # If neither items nor field queries were given, use request parameters.
    if items.blank? && (opt[:groups] != :only)
      opt = current_params.merge(opt) if opt.except(*search_only_keys).blank?
    end
    opt[:limit] ||= paginator.page_size
    opt[:page]  ||= paginator.page_number

    # Prepare terms.
    normalize_predicates!(opt)

    # Disallow experimental database WHERE predicates unless privileged.
    filters.prepend(:filter_predicates!) unless administrator?
    filters << :filter_by_user!          if opt.include?(:user_id)
    filters << :filter_by_org!           if opt.include?(:org_id)

    filters.uniq!
    filters.each do |filter|
      if respond_to?(filter)
        send(filter, opt)
      else
        Log.warn { "#{__method__}: #{filter}: not a method" }
      end
    end

    model_class.search_records(*items, **opt)

  rescue RangeError => error

    # Re-cast as a SubmitError so that #index redirects to the controller main
    # index page instead of the root page.
    raise Record::SubmitError.new(error)

  end

  # Transform options into predicates usable for database lookup.
  #
  # @param [Hash] opt
  #
  # @return [Hash]                    The argument, possibly modified.
  #
  def normalize_predicates!(opt)
    opt.replace(normalize_predicates(opt))
  end

  # Transform options into predicates usable for database lookup.
  #
  # @param [Hash] opt
  #
  # @return [Hash]                    A possibly-modified copy of the argument.
  #
  def normalize_predicates(opt)
    key_map = ApplicationRecord.model_id_key_map
    opt.map { |k, v|
      k = k.to_sym   if k.is_a?(String)
      k = key_map[k] if key_map[k]
      case k
        when :org_id  then v = current_org  if v == CURRENT_ID
        when :user_id then v = current_user if v == CURRENT_ID
      end
      case v
        when ApplicationRecord then v = v.id
        when Hash              then v = v.deep_symbolize_keys
        else                        v = positive(v) || v
      end
      [k, v]
    }.compact.to_h
  end

  # Remove options that would otherwise be sent as SQL search term predicates.
  #
  # @param [Hash]  opt                May be modified.
  #
  # @return [Boolean]                 True if keys were removed.
  #
  def filter_predicates!(opt)
    opt.slice!(*find_or_match_keys).present?
  end

  # Select records for the current user unless a different user has been
  # specified (or all records if specified as '*', 'all', or 'false').
  #
  # @param [Hash]  opt                May be modified.
  #
  def filter_by_user!(opt)
    if model_class == User
      filter_by_model!(opt, id_key: :id)
    else
      filter_by_model!(opt, model: User)
    end
  end

  # Select records for the current organization unless a different one has
  # been specified (or all records if specified as '*', 'all', or 'false').
  #
  # @param [Hash]  opt                May be modified.
  #
  def filter_by_org!(opt)
    if model_class == Org
      filter_by_model!(opt, id_key: :id)
    elsif model_class.respond_to?(:for_org)
      org = opt.extract!(:org, :org_id).compact.values.first
      org = org.id if org.respond_to?(:id)
      opt[:'users.org_id'] = org if org
    else
      filter_by_model!(opt, model: Org)
    end
  end

  # Select records for a specific model record (or all records if specified as
  # '*', 'all', or 'false').
  #
  # @param [Hash]  opt                May be modified.
  # @param [Class] model
  #
  def filter_by_model!(opt, id_key: nil, model: model_class)
    m_key = model.model_key
    i_key = model.model_id_key
    keys  = [m_key, i_key, id_key].compact
    item  = opt.extract!(*keys).compact_blank!.values.first.presence
    id    =
      if item.is_a?(model)
        item.id
      elsif item && !%w[* 0 all false].include?(item)
        case model.columns_hash['id']&.type
          when :uuid    then item if uuid?(item)
          when :integer then item if digits_only?(item)
          else               model.find_record(item)&.id
        end
      end
    opt[(id_key || i_key)] = id if id.present?
  end

  # Limit records to those in the given state (or records with an empty state
  # field if specified as 'nil', 'empty', or 'missing').
  #
  # @param [Hash]   opt               May be modified.
  # @param [Symbol] key               State URL parameter.
  #
  # @return [Hash, nil]               *opt* if changed.
  #
  def filter_by_state!(opt, key: :state)
    state = opt.delete(key).to_s.strip.downcase.presence or return
    state = nil if %w[empty false missing nil none null].include?(state)
    opt.merge!(key => state)
  end

  # Limit by workflow status group.
  #
  # @param [Hash]                 opt     May be modified.
  # @param [Symbol]               key     Group URL parameter.
  # @param [Symbol|Array<Symbol>] state   State parameter(s).
  #
  # @return [Hash, nil]                   *opt* if changed.
  #
  def filter_by_group!(opt, key: :group, state: :state)
    group = opt.delete(key)
    group = group.split(/\s*,\s*/) if group.is_a?(String)
    group = Array.wrap(group).compact_blank
    return if group.blank?

    group.map!(&:downcase).map!(&:to_sym)
    return opt.except!(*state) if group.include?(:all)

    states = group.flat_map { |g| Upload::STATE_GROUP.dig(g, :states) }.compact
    return if states.blank?

    Array.wrap(state).each do |k|
      opt[k] = [*opt[k], *states].compact.map(&:to_s).uniq
      opt.delete(k) if opt[k].blank?
    end
    opt
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Start a new (un-persisted) model instance.
  #
  # @param [Hash, nil]       attr       Default: `#current_params`.
  # @param [Boolean, String] force_id   If *true*, allow setting of :id.
  #
  # @return [Model]                     Un-persisted model record instance.
  #
  def new_record(attr = nil, force_id: false, **, &blk)
    attr ||= current_params
    blk&.(attr)
    attr.delete(:id) unless true?(force_id)
    __debug_items("WF #{self.class} #{__method__}") { { attr: attr } }
    model_class.new(attr)
  end

  # Create and persist a new model record.
  #
  # @param [Hash, nil]       attr       Default: `#current_params`.
  # @param [Boolean, String] force_id   If *true*, allow setting of :id.
  # @param [Boolean]         fatal      If *false*, use #save not #save!.
  #
  # @return [Model]                     New persisted model record instance.
  #
  def create_record(attr = nil, force_id: false, fatal: true, **, &blk)
    __debug_items("WF #{self.class} #{__method__}") { { attr: attr } }
    new_record(attr, force_id: force_id, &blk).tap do |record|
      fatal ? record.save! : record.save
    end
  end

  # Start editing an existing model record.
  #
  # @param [*]         item           If present, used as a template.
  # @param [Hash, nil] prm            Default: `#current_params`
  # @param [Hash]      opt            Passed to #get_record.
  #
  # @raise [Record::StatementInvalid]   If :id not given.
  # @raise [Record::NotFound]           If *item* was not found.
  #
  # @return [Model, nil]
  #
  def edit_record(item = nil, prm = nil, **opt, &blk)
    item, prm = model_request_params(item, prm)
    __debug_items("WF #{self.class} #{__method__}") {{ prm: prm, item: item }}
    get_record(item, **opt)&.tap do |record|
      blk&.(record)
    end
  end

  # Persist changes to an existing model record.
  #
  # @param [*]         item           If present, used as a template.
  # @param [Boolean]   fatal          If *false* use #update not #update!.
  # @param [Hash, nil] prm            Default: `#current_params`
  #
  # @raise [Record::NotFound]               If the record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Model record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Model record update halted.
  #
  # @return [Model, nil]
  #
  def update_record(item = nil, fatal: true, **prm, &blk)
    item, attr = model_request_params(item, prm.presence)
    __debug_items("WF #{self.class} #{__method__}") {{ prm: attr, item: item }}
    # noinspection RubyScope
    edit_record(item)&.tap do |record|
      blk&.(record, attr)
      fatal ? record.update!(attr) : record.update(attr)
    end
  end

  # Retrieve the indicated record(s) for the '/delete' page.
  #
  # @param [String, Model, Array, nil] items
  # @param [Hash, nil]                 prm    Default: `#current_params`
  #
  # @raise [RangeError]                       If :page is not valid.
  #
  # @return [Hash{Symbol=>*}] From Record::Searchable#search_records.
  #
  def delete_records(items = nil, prm = nil, **)
    items, prm = model_request_params(items, prm)
    __debug_items("WF #{self.class} #{__method__}") {{ prm: prm, item: item }}
    ids     = prm.extract!(:ids, :id).compact.values.first
    items ||= ids
    model_class.search_records(*items, **prm)
  end

  # Remove the indicated record(s).
  #
  # @param [String, Model, Array, nil] items
  # @param [Hash, nil]                 prm    Default: `#current_params`
  # @param [Boolean]                   fatal  If *false* do not #raise_failure.
  #
  # @raise [Record::SubmitError]              If there were failure(s).
  #
  # @return [Array]                           Destroyed entries.
  #
  def destroy_records(items = nil, prm = nil, fatal: true, **)
    items, prm = model_request_params(items, prm)
    prm.reverse_merge!(model_options.all)
    __debug_items("WF #{self.class} #{__method__}") {{ prm: prm, item: item }}
    ids     = prm.extract!(:ids, :id).compact.values.first
    items   = [*items, *ids].map! { |item| item.try(:id) || item }
    success = []
    failure = []
    model_class.where(id: items).each do |item|
      if item.destroy
        success << item.id
      else
        failure << item.id
      end
    end
    raise_failure(:destroy, failure.uniq) if fatal && failure.present?
    success
  end

  # ===========================================================================
  # :section: ExceptionHelper overrides
  # ===========================================================================

  protected

  # Raise an exception.
  #
  # @param [Symbol, String, Array<String>, ExecReport, Exception, nil] problem
  # @param [*]                                                         value
  #
  # @raise [Record::SubmitError]
  # @raise [ExecError]
  #
  # @see ExceptionHelper#raise_failure
  #
  def raise_failure(problem, value = nil)
    super(problem, value, model: model_key)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
