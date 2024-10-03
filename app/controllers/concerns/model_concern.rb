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
    model_class.const_get(:SEARCH_RECORDS_OPT)
  end

  def search_only_keys
    search_records_keys.excluding(:offset, :limit)
  end

  def find_or_match_keys(*added)
    search_records_keys.dup.push(
      model_key, model_id_key,
      :org,      :org_id,
      :user,     :user_id,
      :group,    :state
    ).concat(added).uniq
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
  # @return [Hash]
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
  # @return [Hash]
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
  # @param [any, nil]  item           Model, Hash
  # @param [Hash, nil] prm
  #
  # @return [Array(Model, Hash)]
  # @return [Array(*,     Hash)]
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

  # Generate arguments to ActiveRecord#order from *val*.
  #
  # @param [Hash] prm
  # @param [Hash] opt                 Passed to #normalize_sort_order.
  #
  # @return [Hash]
  #
  def normalize_sort_order!(prm, **opt)
    return prm unless prm.key?(:sort)
    sort = model_class.normalize_sort_order(prm[:sort], **opt)
    sort ? prm.merge!(sort: sort) : prm.except!(:sort)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
  # @return [Paginator::Result]
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

    # Prepare options.
    normalize_predicates!(opt)
    normalize_sort_order!(opt)

    # Disallow experimental database WHERE predicates unless privileged.
    filters = filters.dup
    filters.prepend(:filter_predicates!)  if administrator?
    filters.append(:filter_by_user!)      if opt.include?(:user_id)
    filters.append(:filter_by_org!)       if opt.include?(:org_id)
    filters.uniq.each do |filter|
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
    item  = opt.extract!(*keys).compact_blank.values.first.presence
    id    = ('' if item.nil? || %w[* 0 all false].include?(item))
    id  ||=
      if item.is_a?(model)
        item.id
      else
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

    states = group.flat_map { Upload::STATE_GROUP.dig(_1, :states) }.compact
    return if states.blank?

    states.map!(&:to_s)
    Array.wrap(state).each do |k|
      opt_k  = opt[k] && Array.wrap(opt[k]).compact.presence
      opt[k] = opt_k&.map(&:to_s)&.concat(states)&.uniq || states
    end
    opt
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return with the specified model record.
  #
  # @param [any, nil] item      String, Integer, Hash, Model; def: #identifier.
  # @param [Hash]     opt       Passed to Record::Identification#find_record.
  #
  # @raise [Record::StatementInvalid] If :id not given.
  # @raise [Record::NotFound]         If *item* was not found.
  #
  # @return [Model, nil]        A fresh record unless *item* is a #model_class.
  #
  # @yield [record] Raise an exception if the record is not acceptable.
  # @yieldparam [Model] record
  # @yieldreturn [void]
  #
  # @see Record::Identification#find_record
  #
  def find_record(item = nil, **opt, &blk)
    id = opt.delete(:id) || item.try(:id) || item || identifier
    model_class.find_record(id, **opt)&.tap do |record|
      blk&.call(record)
    end
  end

  # Start a new model instance.
  #
  # @param [Hash, nil] prm            Field values (def: `#current_params`).
  # @param [Hash]      opt            Field values to supplement or replace
  #                                     #current_params values except:
  #
  # @option opt [Boolean] force       If *true* allow setting of :id.
  #
  # @return [Model]                   An un-persisted model instance.
  #
  # @yield [attr] Adjust attributes and/or raise an exception.
  # @yieldparam [Hash] attr           Supplied attributes for the new record.
  # @yieldreturn [void]
  #
  def new_record(prm = nil, **opt, &blk)
    force = opt.delete(:force)
    prm   = (prm || current_params).merge(opt)
    __debug_items("WF #{self.class} #{__method__}") { { attr: prm } }
    blk&.call(prm)
    if true?(force)
      raise 'force not authorized' unless administrator?
    else
      prm.delete(:id)
    end
    model_class.new(prm)
  end

  # Add a new model record to the database.
  #
  # @param [Hash, nil] prm            Field values (def: `#current_params`).
  # @param [Boolean]   fatal          If *false*, use #save not #save!.
  # @param [Hash]      opt            Passed to #new_record except:
  #
  # @option opt [Boolean] recaptcha   Require reCAPTCHA verification.
  #
  # @return [Model]                   The new persisted model record.
  #
  # @yield [attr] Adjust attributes and/or raise an exception.
  # @yieldparam [Hash] attr           Supplied attributes for the new record.
  # @yieldreturn [void]
  #
  def create_record(prm = nil, fatal: true, **opt, &blk)
    __debug_items("WF #{self.class} #{__method__}") { { opt: opt, prm: prm } }
    recaptcha = opt.delete(:recaptcha)
    new_record(prm, **opt, &blk).tap do |record|
      verified(record) if recaptcha
      fatal ? record.save! : record.save
    end
  end

  # Start editing an existing model record.
  #
  # @param [any, nil] item            Default: the record for #identifier.
  # @param [Hash]     opt             Passed to #find_record.
  #
  # @raise [Record::StatementInvalid] If :id not given.
  # @raise [Record::NotFound]         If *item* was not found.
  #
  # @return [Model, nil]      A fresh instance unless *item* is a #model_class.
  #
  # @yield [record] Raise an exception if the record is not acceptable.
  # @yieldparam [Model] record        May be altered by the block.
  # @yieldreturn [void]               Block not called if *record* is *nil*.
  #
  def edit_record(item = nil, **opt, &blk)
    item, _prm = model_request_params(item)
    __debug_items("WF #{self.class} #{__method__}") {{ opt: _prm, item: item }}
    find_record(item, **opt)&.tap do |record|
      blk&.call(record)
    end
  end

  # Persist changes to an existing model record.
  #
  # @param [any, nil] item            Default: the record for #identifier.
  # @param [Boolean]  fatal           If *false* use #update not #update!.
  # @param [Hash]     opt             Field values (#current_params) except:
  #
  # @option opt [Boolean] recaptcha   Require reCAPTCHA verification.
  #
  # @raise [Record::NotFound]               If the record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Model record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Model record update halted.
  #
  # @return [Model, nil]              The updated model record.
  #
  # @yield [record, attr] Raise an exception if the record is not acceptable.
  # @yieldparam [Model] record        May be altered by the block.
  # @yieldparam [Hash]  attr          New field(s) to be assigned to *record*.
  # @yieldreturn [void]               Block not called if *record* is *nil*.
  #
  def update_record(item = nil, fatal: true, **opt, &blk)
    recaptcha  = opt.delete(:recaptcha)
    item, attr = model_request_params(item, opt.presence)
    __debug_items("WF #{self.class} #{__method__}") {{ opt: attr, item: item }}
    item ||= attr[:id]
    edit_record(item)&.tap do |record|
      verified(record) if recaptcha
      blk&.call(record, attr)
      fatal ? record.update!(attr) : record.update(attr)
    end
  end

  # Retrieve the indicated model record(s) for the '/delete' page.
  #
  # @param [any, nil] items           To #search_records
  # @param [Hash]     opt             Default: `#current_params`
  #
  # @raise [RangeError]               If :page is not valid.
  #
  # @return [Paginator::Result]
  #
  # @yield [items, opt] Raise an exception unless the *items* are acceptable.
  # @yieldparam [Array] items         Identifiers of items to be deleted.
  # @yieldparam [Hash]  options       Options to #search_records.
  # @yieldreturn [void]               Block not called if *record* is *nil*.
  #
  def delete_records(items = nil, **opt, &blk)
    items, opt = model_request_params(items, opt.presence)
    __debug_items("WF #{self.class} #{__method__}") {{ opt: opt, item: item }}
    items = opt.extract!(:ids, :id).compact.values.first || items
    blk&.call(Array.wrap(items), opt)
    model_class.search_records(*items, **opt)
  end

  # Remove the indicated model record(s).
  #
  # @param [any, nil] items
  # @param [Boolean]  fatal           If *false* do not #raise_failure.
  # @param [Hash]     opt             Default: `#current_params` except:
  #
  # @option opt [Boolean] recaptcha   Require reCAPTCHA verification.
  #
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array]                   Destroyed model records.
  #
  # @yield [record] Called for each record before deleting.
  # @yieldparam [Model] record
  # @yieldreturn [String,nil]         Error message if *record* unacceptable.
  #
  def destroy_records(items = nil, fatal: true, **opt, &blk)
    verified if opt.delete(:recaptcha)
    items, opt = model_request_params(items, opt.presence)
    __debug_items("WF #{self.class} #{__method__}") {{ opt: opt, item: item }}
    opt   = model_options.all.merge(opt)
    ids   = opt.extract!(:ids, :id).compact.values.first
    items = [*items, *ids].map! { _1.try(:id) || _1 }.uniq
    done  = []
    fail  = []
    model_class.where(id: items).each do |item|
      case
        when (error = blk&.call(item)) then fail << error
        when !item.destroy             then fail << item
        else                                done << item
      end
    end
    raise_failure(:destroy, fail.uniq) if fatal && fail.present?
    done
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Action permitted if the current user is signed-in unless *record* is *nil*.
  #
  # @param [Model, Hash, nil] record
  # @param [Hash]             opt     Passed to #unauthorized.
  #
  # @raise [CanCan::AccessDenied]     Only if `opt[:fatal]` is not *false*.
  #
  # @return [Boolean]                 *false* only if `opt[:fatal]` is *false*
  #
  def authorized_session(record = :ignored, **opt)
    (record && current_user).present? or unauthorized(record, **opt)
  end

  # Action permitted if the current user owns *record* or is a manager of the
  # organization of the user that owns *record*.
  #
  # @param [Model, Hash, nil] record
  # @param [Hash]             opt     Passed to #authorized.
  #
  # @raise [CanCan::AccessDenied]     Only if `opt[:fatal]` is not *false*.
  #
  # @return [Boolean]                 *false* only if `opt[:fatal]` is *false*
  #
  def authorized_self_or_org_manager(record, **opt)
    authorized(record, **opt) do |rec|
      authorized_user?(rec) || authorized_manager?(rec)
    end
  end

  # Action permitted if the current user a manager of the organization of the
  # user that owns *record*.
  #
  # @param [Model, Hash, nil] record
  # @param [Hash]             opt     Passed to #authorized.
  #
  # @raise [CanCan::AccessDenied]     Only if `opt[:fatal]` is not *false*.
  #
  # @return [Boolean]                 *false* only if `opt[:fatal]` is *false*
  #
  def authorized_org_manager(record, **opt)
    authorized(record, **opt) do |rec|
      authorized_manager?(rec)
    end
  end

  # Action permitted if the current user owns *record* or is in the same
  # organization as the user that owns *record*.
  #
  # @param [Model, Hash, nil] record
  # @param [Hash]             opt     Passed to #authorized.
  #
  # @raise [CanCan::AccessDenied]     Only if `opt[:fatal]` is not *false*.
  #
  # @return [Boolean]                 *false* only if `opt[:fatal]` is *false*
  #
  # == Usage Notes
  # Technically this yields the same result as #authorized_org_member but it is
  # preferred in cases like ManifestItem where determining the associated user
  # is less costly than determining the associated organization.
  #
  def authorized_self_or_org_member(record, **opt)
    authorized(record, **opt) do |rec|
      authorized_user?(rec) || authorized_org?(rec)
    end
  end

  # Action permitted if the current user is in the same organization as the
  # user that owns *record*.
  #
  # @param [Model, Hash, nil] record
  # @param [Hash]             opt     Passed to #authorized.
  #
  # @raise [CanCan::AccessDenied]     Only if `opt[:fatal]` is not *false*.
  #
  # @return [Boolean]                 *false* only if `opt[:fatal]` is *false*
  #
  def authorized_org_member(record, **opt)
    authorized(record, **opt) do |rec|
      authorized_org?(rec)
    end
  end

  # Raise an exception with a tailored message.
  #
  # @param [Model, Hash, nil]    item
  # @param [Symbol, String, nil] action   Default: `params[:action]`.
  # @param [Class, nil]          subject  Default: `#model_class`.
  # @param [Symbol, nil]         key
  # @param [Boolean]             fatal    If *false* return *false*.
  # @param [Hash]                attr     Added field values.
  #
  # @raise [CanCan::AccessDenied]     Always raised unless *fatal* is *false*.
  #
  # @return [Boolean]                 Always *false* iff *fatal* is *false*.
  #
  def unauthorized(
    item =    :ignored,
    action:   nil,
    subject:  nil,
    key:      :id,
    fatal:    true,
    **attr
  )
    action  = (action || request_parameters[:action])&.to_sym
    subject = model_class if subject.nil?
    message = current_ability.unauthorized_message(action, subject)
    unless item == :ignored
      if (name = make_label(item)).nil? && key.present?
        item = item.try(:fields) || item.try(:to_h) || {}
        name = item[key].presence || attr[key].presence
      end
      message.sub!(/s\.?$/, " #{name}") if name
    end
    raise CanCan::AccessDenied.new(message, action, subject) if fatal
    Log.warn("#{__method__}: #{message}")
    false
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Action permitted if the current user is an administrator or *record* meets
  # the criteria supplied by the block.
  #
  # @param [Model, Hash, nil] record
  # @param [Hash]             opt     Passed to #unauthorized.
  #
  # @raise [CanCan::AccessDenied]     Only if `opt[:fatal]` is not *false*.
  #
  # @return [Boolean]                 *false* only if `opt[:fatal]` is *false*
  #
  # @yield [record] Determine if *record* is permitted for the current user.
  # @yieldparam [Model, Hash, nil] record
  # @yieldreturn [Boolean] *true* if permitted.
  #
  def authorized(record, **opt)
    authorized_session(record, **opt) or return false
    (administrator? || yield(record)) or unauthorized(record, **opt)
  end

  # Indicate whether the current user is a manager of the organization to which
  # the owner of *record* belongs.
  #
  # @param [Model, Hash, nil] record
  #
  def authorized_manager?(record)
    manager? && authorized_org?(record)
  end

  # Indicate whether *record* is owned by someone in the current user's
  # organization.
  #
  # @param [Model, Hash, nil] record
  #
  def authorized_org?(record)
    Org.oid(record) == current_org_id
  end

  # Indicate whether *record* is owned by the current user.
  #
  # @param [Model, Hash, nil] record
  #
  def authorized_user?(record)
    User.uid(record) == current_user.id
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Action permitted if the current session has been verified by reCAPTCHA.
  #
  # @note Always *true* for an Administrator or in the test environment.
  #
  # @param [Model, nil] record
  # @param [Hash]       opt           Passed to #verify_recaptcha.
  #
  # @raise [Record::SubmitError]      If not verified.
  #
  # @return [Boolean]                 *true* if verified.
  #
  def verified(record = nil, **opt)
    return true unless recaptcha_active?
    opt[:model] ||= record || new_record({})
    verify_recaptcha(opt) or raise_failure(opt[:model].errors.full_messages)
  end

  # ===========================================================================
  # :section: ExceptionHelper overrides
  # ===========================================================================

  protected

  # @private
  UNSET = :'unset parameter'

  # Raise Record::SubmitError for an illegal attribute.
  #
  # @param [Symbol]   key             Attribute key.
  # @param [any, nil] value           Optional attribute value.
  # @param [any, nil] reason
  # @param [Symbol]   op
  # @param [Hash]     opt             Passed to #raise_failure.
  #
  # @raise [Record::SubmitError]      Always.
  #
  def invalid_attr(key, value = UNSET, reason = nil, op: :set, **opt)
    msg = ["cannot #{op} #{key}"]
    msg << "= #{value.inspect}" unless value == UNSET
    msg << "- #{reason}"        if reason.present?
    raise_failure(msg.join(' '), **opt)
  end

  # Raise an exception.
  #
  # @param [Symbol, String, Array<String>, ExecReport, Exception, nil] problem
  # @param [any, nil]                                                  value
  # @param [Boolean, String]                                           log
  #
  # @raise [Record::SubmitError]
  # @raise [ExecError]
  #
  # @see ExceptionHelper#raise_failure
  #
  def raise_failure(problem, value = nil, log: true, **)
    log = "#{self_class}.#{calling_method}" if log.is_a?(TrueClass)
    super(problem, value, model: model_key, log: log)
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
