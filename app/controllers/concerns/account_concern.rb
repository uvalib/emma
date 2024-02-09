# app/controllers/concerns/account_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/account" controller.
#
# @!method model_options
#   @return [User::Options]
#
# @!method paginator
#   @return [User::Paginator]
#
module AccountConcern

  extend ActiveSupport::Concern

  include Emma::Common

  include SerializationConcern
  include ModelConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Columns searched for generic (:like) matches.
  #
  # @type [Array<Symbol>]
  #
  ACCT_MATCH_KEYS = %i[email last_name first_name].freeze

  # Parameter keys related to password management.
  #
  # @type [Array<Symbol>]
  #
  PASSWORD_KEYS = %i[password password_confirmation current_password].freeze

  # ===========================================================================
  # :section: ParamsConcern overrides
  # ===========================================================================

  public

  # The identifier of the current model instance which #CURRENT_ID represents
  # in the context of AccountController actions.
  #
  # @return [Integer, nil]
  #
  def current_id
    current_user&.id
  end

  # URL parameters associated with model record(s).
  #
  # @return [Array<Symbol>]
  #
  def id_param_keys
    [*super, :email].uniq
  end

  # ===========================================================================
  # :section: ModelConcern overrides
  # ===========================================================================

  public

  def find_or_match_keys
    [*super, *User.field_names, *PASSWORD_KEYS].uniq
  end

  # Start a new (un-persisted) User.
  #
  # @param [Hash, nil]       prm        Field values (def: `#current_params`).
  # @param [Boolean, String] force_id   If *true*, allow setting of :id.
  #
  # @return [User]                      Un-persisted User instance.
  #
  def new_record(prm = nil, force_id: false, **)
    # noinspection RubyMismatchedReturnType
    super do |attr|
      if administrator?
        # Allow :org_id to be nil to allow selection on the form.
      else
        attr[:org_id] = current_org&.id or raise "no org for #{current_user}"
      end
    end
  end

  # Create and persist a new User.
  #
  # @param [Hash, nil]       prm        Field values (def: `#current_params`).
  # @param [Boolean, String] force_id   If *true*, allow setting of :id.
  # @param [Boolean]         fatal      If *false*, use #save not #save!.
  #
  # @return [User]                      A new User instance.
  #
  def create_record(prm = nil, force_id: false, fatal: true, **)
    # noinspection RubyMismatchedReturnType
    super do |attr|
      if administrator?
        attr[:org_id] = Org.none.id if attr[:org_id].nil?
      else
        attr[:org_id] = current_org&.id or raise "no org for #{current_user}"
      end
    end
  end

  # Update the indicated User, ensuring that :email and :org_id are not changed
  # unless authorized.
  #
  # @param [any, nil] item            Def.: record for ModelConcern#identifier.
  # @param [Boolean]  fatal           If *false* use #update not #update!.
  # @param [Hash]     prm             Field values (default: `#current_params`)
  #
  # @raise [Record::NotFound]               Record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Record update halted.
  #
  # @return [User, nil]               The updated User instance.
  #
  def update_record(item = nil, fatal: true, **prm)
    # noinspection RubyMismatchedReturnType
    super do |record, attr|
      if administrator?
        attr[:org_id] = Org.none.id if attr[:org_id].nil?
      elsif (org = current_org&.id).blank?
        raise "no org for #{current_user}"
      else
        discard = []
        if attr.key?((k = :org_id)) && (attr[k] != org)
          discard << k
        end
        if attr.key?((k = :email)) && ((acct = attr[k]) != record.account)
          if !acct.present? || !manager?
            discard << k
          elsif User.find_by(k => acct)&.org_id != org
            discard << k
          end
        end
        if discard.present? && attr.except!(*discard).present?
          Log.info do
            # noinspection RubyScope
            list = discard.map { |k, v| "#{k}=#{v.inspect}" }.join(', ')
            "#{__method__}: discarded: #{list} for #{current_user}"
          end
        end
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get matching User account records or all records if no terms are given.
  #
  # @param [Array<String,Hash,Array,nil>] terms
  # @param [Array<Symbol>]                columns
  # @param [Hash]                         hash_terms  Added to *terms* except
  #                                                     #MAKE_RELATION_OPTIONS
  #
  # @return [ActiveRecord::Relation<User>]
  #
  def get_accounts(*terms, columns: ACCT_MATCH_KEYS, **hash_terms)
    keys  = Record::Searchable::MAKE_RELATION_OPTIONS
    opt   = normalize_sort_order!(hash_terms.extract!(*keys))
    terms = [*terms, hash_terms].flatten.compact_blank!
    terms.map! { |t| t.is_a?(Hash) ? normalize_predicates!(t) : t }
    case
      when terms.present?           then opt[:columns] = columns
      when administrator?           then # continue
      when (org = current_org&.id)  then opt[:org_id]  = org
      when (usr = current_user&.id) then opt[:id]      = usr
      else                               return User.none
    end
    User.make_relation(*terms, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # redirect_success
  #
  # @param [Symbol]            action
  # @param [String, nil]       message
  # @param [User, String, nil] redirect
  # @param [Hash]              opt        Passed to redirect.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def redirect_success(action, message = nil, redirect: nil, **opt)
    config    = account_fields
    message ||= message_for(action, :success, config)
    message &&= message % interpolation_terms(action, config)
    message ||=
      case base_action(action)
        when :new,    :create  then config_text(:account, :created)
        when :delete, :destroy then config_text(:account, :removed)
        else                        config_text(:account, :updated)
      end
    opt[:notice] = message
    if (redirect ||= params[:redirect])
      redirect_to(redirect, opt)
    else
      redirect_back(fallback_location: default_fallback_location, **opt)
    end
  end

  # redirect_failure
  #
  # @param [Symbol]                             action
  # @param [String, nil]                        message
  # @param [String, Array, ActiveModel::Errors] error
  # @param [User, String, nil]                  redirect
  # @param [Hash]                               opt       Passed to redirect.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def redirect_failure(action, message = nil, error: nil, redirect: nil, **opt)
    config    = account_fields
    message ||= message_for(action, :failure, config)
    message &&= message % interpolation_terms(action, config)
    message ||= config_text(:account, :failed)
    if error
      error   = error.full_messages if error.is_a?(ActiveModel::Errors)
      message = message&.remove(/[[:punct:]]$/)&.concat(':') || 'ERRORS:'
      message = [message, *Array.wrap(error)]
      message = safe_join(message, HTML_BREAK)
    end
    opt[:alert] = message
    redirect ||=
      case action
        when :new,    :create  then { action: :new }
        when :edit,   :update  then { action: :edit }
        when :delete, :destroy then { action: :index }
        else                        default_fallback_location
      end
    redirect_to(redirect, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Configured account record fields.
  #
  # @return [ActionConfig]            Frozen result.
  #
  def account_fields(...)
    Model.configuration_fields(:account)[:all]
  end

  # Get the appropriate message to display.
  #
  # @param [Symbol]       action
  # @param [Symbol]       outcome
  # @param [ActionConfig] config
  #
  # @return [String, nil]
  #
  def message_for(action, outcome, config = account_fields)
    # noinspection RubyMismatchedReturnType
    [action, :generic, :messages].find do |k|
      (v = config.dig(k, outcome)) and (break v)
    end
  end

  # Get the appropriate terms for message interpolations.
  #
  # @param [Symbol]       action
  # @param [ActionConfig] config
  #
  # @return [Hash]
  #
  def interpolation_terms(action, config = account_fields)
    result = config.dig(action, :terms) || config.dig(action, :term) || {}
    action = result[:action] ||= action.to_s
    result[:actioned] ||= (action + (action.end_with?('e') ? 'd' : 'ed'))
    result
  end

  # ===========================================================================
  # :section: ResponseConcern overrides
  # ===========================================================================

  public

  def default_fallback_location = account_index_path

  # ===========================================================================
  # :section: OptionsConcern overrides
  # ===========================================================================

  protected

  # Create an Options instance from the current parameters.
  #
  # @return [User::Options]
  #
  def get_model_options
    User::Options.new(request_parameters)
  end

  # ===========================================================================
  # :section: PaginationConcern overrides
  # ===========================================================================

  public

  # Create a Paginator for the current controller action.
  #
  # @param [Class<Paginator>] paginator  Paginator class.
  # @param [Hash]             opt        Passed to super.
  #
  # @return [User::Paginator]
  #
  def pagination_setup(paginator: User::Paginator, **opt)
    # noinspection RubyMismatchedReturnType
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module DeviseMethods

    # devise_mapping
    #
    # @return [Devise::Mapping]
    #
    # @see DeviseController#devise_mapping
    #
    def devise_mapping
      @devise_mapping ||=
        request.env['devise.mapping'] ||= Devise.mappings[:user]
    end

    # resource_class
    #
    # @return [Class]
    #
    # @see DeviseController#resource_class
    # @see Devise::Mapping#to
    #
    def resource_class
      devise_mapping.to
    end

    # resource_name
    #
    # @return [String]
    #
    # @see DeviseController#resource_name
    # @see Devise::Mapping#name
    #
    def resource_name
      devise_mapping.name
    end
    alias :scope_name :resource_name

    # resource
    #
    # @return [User, nil]
    #
    # @see DeviseController#resource
    #
    def resource
      instance_variable_get(:"@#{resource_name}")
    end

    # resource=
    #
    # @param [User, nil] new_resource
    #
    # @return [User, nil]
    #
    # @see DeviseController#resource=
    #
    def resource=(new_resource)
      instance_variable_set(:"@#{resource_name}", new_resource)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.helper(self) if base.respond_to?(:helper)
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)

    include DeviseMethods

  end

end

__loading_end(__FILE__)
