# app/controllers/concerns/account_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/account" controller.
#
module AccountConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'AccountConcern')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # noinspection RailsI18nInspection
  UA_MESSAGES     = I18n.t('emma.account.messages', default: {}).deep_freeze
  UA_SUCCESSFULLY = UA_MESSAGES[:success]
  UA_FAILED_TO    = UA_MESSAGES[:failure]

  UA_MATCH_FIELDS = %i[email last_name first_name].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Only allow a list of trusted parameters through. # TODO: strong params
  #
  # @return [Hash]
  #
  def user_params
=begin
    params.require(:user).permit!
    # noinspection RubyYardReturnMatch
    params.fetch(:user, {})
=end
    url_parameters.slice(*User.field_names)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Matching User account records.
  #
  # @param [Array<String,Hash,Array>] terms
  # @param [Array, nil]               fields
  #
  # @return [ActiveRecord::Relation]
  #
  def match_accounts(*terms, fields: UA_MATCH_FIELDS)
    User.matching(*terms, fields: fields)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # redirect_success
  #
  # @param [Symbol]            action
  # @param [String, nil]       message
  # @param [User, String, nil] to
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  #--
  # noinspection RubyCaseWithoutElseBlockInspection
  #++
  def redirect_success(action, message = nil, to: nil)
    target = to || account_index_path
    message ||=
      case action
        when :new,    :create  then UA_SUCCESSFULLY % 'created'
        when :edit,   :update  then UA_SUCCESSFULLY % 'updated'
        when :delete, :destroy then UA_SUCCESSFULLY % 'destroyed'
      end
    opt = message ? { notice: message } : {}
    redirect_to(target, opt)
  end

  # redirect_failure
  #
  # @param [Symbol]            action
  # @param [String, nil]       message
  # @param [User, String, nil] to
  # @param [String, Array]     error
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  #--
  # noinspection RubyCaseWithoutElseBlockInspection
  #++
  def redirect_failure(action, message = nil, to: nil, error: nil)
    target    = to
    target  ||=
      case action
        when :new,    :create  then { action: :new }
        when :edit,   :update  then { action: :edit }
        when :delete, :destroy then { action: :index }
      end
    target  ||= account_index_path
    message ||=
      case action
        when :new,    :create  then UA_FAILED_TO % 'create'
        when :edit,   :update  then UA_FAILED_TO % 'update'
        when :delete, :destroy then UA_FAILED_TO % 'destroy'
      end
    if error
      error   = error.full_messages if error.respond_to?(:full_messages)
      message = message&.remove(/[[:punct:]]$/)&.concat(':') || 'ERRORS:'
      message = [message, *Array.wrap(error)]
      message = safe_join(message, "<br/>\n".html_safe)
    end
    opt = message ? { alert: message } : {}
    redirect_to(target, opt)
  end

end

__loading_end(__FILE__)
