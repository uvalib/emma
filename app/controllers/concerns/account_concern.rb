# app/controllers/concerns/account_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/account" controller.
#
module AccountConcern

  extend ActiveSupport::Concern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL parameters allowed for creating/updating a user account.
  #
  # @type [Array<Symbol>]
  #
  ACCT_PARAMETERS = (
    User.field_names + %i[password password_confirmation current_password]
  ).freeze

  # Columns searched for generic (:like) matches.
  #
  # @type [Array<Symbol>]
  #
  ACCT_MATCH_COLUMNS = %i[email last_name first_name].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Only allow a list of trusted parameters through.
  #
  # @return [Hash{Symbol=>Any}]
  #
  def account_params
    prm = params[:user] ? params.require(:user) : params
    prm = prm.permit(*ACCT_PARAMETERS, *ACCT_PARAMETERS.map(&:to_s))
    prm.to_h.symbolize_keys
  end

  # Get the User identifier(s) specified by parameters.
  #
  # @return [Array<String,Integer>]
  #
  def id_params
    ids = params[:selected] || params[:id] || params[:email]
    identifier_list(*ids)
  end

  # Normalize a list of User identifiers (:id or :email).
  #
  # @param [Array<String, Integer, nil>] ids
  # @param [Regexp]                      separator
  #
  # @return [Array<String,Integer>]
  #
  def identifier_list(*ids, separator: /\s*,\s*/)
    ids.flat_map { |part|
      part = part.strip.split(separator) if part.is_a?(String)
      Array.wrap(part).map { |v| positive(v) || v.presence }
    }.compact
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the indicated User account records.
  #
  # @param [Array<String,Integer,nil>] ids  Default: `#id_params`.
  #
  # @raise [ActiveRecord::RecordNotFound]   If *ids* is blank.
  #
  # @return [Array<User>]
  #
  def find_accounts(ids = nil)
    ids ||= id_params
    ids, uids = Array.wrap(ids).partition { |v| v.is_a?(Integer) }
    if ids.present? && uids.present?
      User.matching(id: ids, email: uids, join: :or).to_a
    elsif ids.present?
      # noinspection RubyMismatchedReturnType
      User.find(ids)
    elsif uids.present?
      User.where(email: uids).to_a
    else
      raise ActiveRecord::RecordNotFound, 'no identifier(s) given'
    end
  end

  # Get the indicated User account record.
  #
  # @param [String, Integer, nil] id    Default: `params[:id]`.
  #
  # @raise [ActiveRecord::RecordNotFound]   If *id* is blank.
  #
  # @return [User, nil]
  #
  def find_account(id = nil)
    User.find_record(id || params[:id])
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get matching User account records or all records if no terms are given.
  #
  # @param [Array<String,Hash,Array,nil>] terms
  # @param [Array, nil]                   columns     Def.: #ACCT_MATCH_COLUMNS
  # @param [Symbol, String, Hash, Array]  sort        Def.: :id
  # @param [Hash]                         hash_terms  Added to *terms*.
  #
  # @return [ActiveRecord::Relation<User>]
  #
  def get_accounts(*terms, columns: nil, sort: :id, **hash_terms)
    terms.flatten!
    terms.map! { |t| t.is_a?(Hash) ? t.deep_symbolize_keys : t if t.present? }
    terms.compact!
    terms << hash_terms if hash_terms.present?
    if terms.present?
      columns ||= ACCT_MATCH_COLUMNS
      User.matching(*terms, columns: columns, join: :or, sort: sort) # TODO: Is :or really correct here?
    elsif current_user.administrator?
      User.all.order(sort)
    #elsif current_user.group_admin? # TODO: institutional groups
      #User.where(group_id: current_user.group_id).order(sort) # TODO: groups
    else
      User.where(id: current_user.id).order(sort)
    end
  end

  # Get the indicated User account record.
  #
  # @param [String, Integer, nil] id    Default: `params[:id]`.
  #
  # @raise [ActiveRecord::RecordNotFound]   If *id* is blank.
  #
  # @return [User, nil]
  #
  def get_account(id = nil)
    find_account(id)
  end

  # Create a new User account record.
  #
  # @param [Hash,nil] attr            Initial User attributes.
  #
  # @return [User]
  #
  def new_account(attr = nil)
    User.new(attr)
  end

  # Create a new persisted User account.
  #
  # @param [Boolean]        no_raise  If *true*, use #save instead of #save!.
  # @param [Boolean,String] force_id  If *true*, allow setting of :id.
  # @param [Hash]           attr      Initial User attributes.
  #
  # @raise [ActiveRecord::RecordNotSaved]   If #save! failed.
  #
  # @return [User]
  #
  def create_account(no_raise: false, force_id: false, **attr)
    attr = account_params if attr.blank?
    attr.delete(:id) unless true?(force_id)
    new_account(attr).tap do |record|
      no_raise ? record.save : record.save!
    end
  end

  # Modify an existing (persisted) User account.
  #
  # @param [Boolean] no_raise  If *true*, use #update instead of #update!.
  # @param [Hash]    attr      New attributes (default: `#account_params`).
  #
  # @raise [ActiveRecord::RecordNotSaved]   If #update! failed.
  #
  # @return [User, nil]
  #
  def update_account(no_raise: false, **attr)
    attr = account_params if attr.blank?
    id   = attr.delete(:id) || attr[:email]
    get_account(id).tap do |record|
      no_raise ? record.update(attr) : record.update!(attr) if record
    end
  end

  # Remove an existing (persisted) User account.
  #
  # @param [Array<String,Integer,nil>] ids  Default: `#id_params`.
  # @param [Boolean] no_raise   If *true*, use #destroy instead of #destroy!.
  #
  # @raise [ActiveRecord::RecordNotFound]       If *ids* is blank.
  # @raise [ActiveRecord::RecordNotDestroyed]   If #destroy! failed.
  #
  # @return [Array<User>]
  #
  def destroy_accounts(*ids, no_raise: false, **)
    find_accounts(ids.presence).tap do |record|
      no_raise ? record.destroy : record.destroy!
    end
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
    message ||= message_for(action, :success)
    message &&= message % interpolation_terms(action)
    message ||= 'SUCCESS' # TODO: I18n
    opt[:notice] = message
    if redirect
      redirect_to(redirect, opt)
    else
      redirect_back(fallback_location: account_index_path, **opt)
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
    message ||= message_for(action, :failure)
    message &&= message % interpolation_terms(action)
    message ||= 'FAILED' # TODO: I18n
    if error
      error   = error.full_messages if error.is_a?(ActiveModel::Errors)
      message = message&.remove(/[[:punct:]]$/)&.concat(':') || 'ERRORS:'
      message = [message, *Array.wrap(error)]
      message = safe_join(message, HTML_BREAK)
    end
    # noinspection RubyCaseWithoutElseBlockInspection
    redirect ||=
      case action
        when :new,    :create  then { action: :new }
        when :edit,   :update  then { action: :edit }
        when :delete, :destroy then { action: :index }
      end
    redirect ||= account_index_path
    redirect_to(redirect, opt.merge!(alert: message))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Configured account record fields.
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def account_fields(...)
    Model.configuration_fields(:account)[:all] || {}
  end

  # Get the appropriate message to display.
  #
  # @param [Symbol]             action
  # @param [Symbol]             outcome
  # @param [Hash{Symbol=>Hash}] config
  #
  # @return [String, nil]
  #
  def message_for(action, outcome, config = account_fields)
    # noinspection RubyMismatchedReturnType
    [action, :generic, :messages].find do |k|
      (v = config.dig(k, outcome)) and break v
    end
  end

  # Get the appropriate terms for message interpolations.
  #
  # @param [Symbol]             action
  # @param [Hash{Symbol=>Hash}] config
  #
  # @return [Hash{Symbol=>Any}]
  #
  def interpolation_terms(action, config = account_fields)
    result = config.dig(action, :terms) || config.dig(action, :term) || {}
    action = result[:action] ||= action.to_s
    result[:actioned] ||= (action + (action.end_with?('e') ? 'd' : 'ed'))
    result
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
      # noinspection RailsParamDefResolve
      base.try(:helper, self)
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
