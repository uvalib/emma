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
  # @return [Hash{Symbol=>*}]
  #
  def account_params
    prm = params[:user] ? params.require(:user) : params
    prm = prm.permit(*ACCT_PARAMETERS, *ACCT_PARAMETERS.map(&:to_s))
    prm.to_h.symbolize_keys
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
  # @param [Symbol]            action
  # @param [String, nil]       message
  # @param [String, Array]     error
  # @param [User, String, nil] redirect
  # @param [Hash]              opt        Passed to redirect.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def redirect_failure(action, message = nil, error: nil, redirect: nil, **opt)
    message ||= message_for(action, :failure)
    message &&= message % interpolation_terms(action)
    message ||= 'FAILED' # TODO: I18n
    if error
      error   = error.full_messages if error.respond_to?(:full_messages)
      message = message&.remove(/[[:punct:]]$/)&.concat(':') || 'ERRORS:'
      message = [message, *Array.wrap(error)]
      message = safe_join(message, "<br/>\n".html_safe)
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

  # Get the appropriate message to display.
  #
  # @param [Symbol] action
  # @param [Symbol] outcome
  # @param [Hash]   config
  #
  # @return [String, nil]
  #
  def message_for(action, outcome, config = AccountHelper::ACCOUNT_FIELDS)
    # noinspection RubyYardReturnMatch
    [action, :generic, :messages].find do |k|
      (v = config.dig(k, outcome)) and break v
    end
  end

  # Get the appropriate terms for message interpolations.
  #
  # @param [Symbol] action
  # @param [Hash]   config
  #
  # @return [Hash]
  #
  def interpolation_terms(action, config = AccountHelper::ACCOUNT_FIELDS)
    terms = config.dig(action, :terms) || config.dig(action, :term) || {}
    terms[:action]   ||= action.to_s
    terms[:actioned] ||=
      (suffix = terms[:action].end_with?('e') ? 'd' : 'ed') &&
        (terms[:action] + suffix)
    terms
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
