# app/controllers/concerns/run_state_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller callbacks for rejecting requests if the system is unavailable.
#
# @see RunState
#
# == Usage Notes
# This is not included in controllers which have endpoints which should be
# available regardless of the run state.
#
module RunStateConcern

  extend ActiveSupport::Concern

  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Controllers whose endpoints are exempt from redirection due to unavailable
  # run state.
  #
  # @type [Array<String,Hash>]
  #
  #--
  # noinspection RubyMismatchedConstantType
  #++
  NO_RUN_STATE_REDIRECT =
    I18n.t('emma.health.run_state.exempt', default: []).deep_freeze

  # Controllers whose endpoints are exempt from redirection due to unavailable
  # run state.
  #
  # @type [Array<String>]
  #
  #--
  # noinspection RubyArgCount
  #++
  RUN_STATE_EXEMPT_CONTROLLER =
    NO_RUN_STATE_REDIRECT.select { |item| item.is_a?(String) }.deep_freeze

  # Per-controller endpoints which are exempt from redirection due to
  # unavailable run state.
  #
  # @type [Hash{String=>Array<String>}]
  #
  RUN_STATE_EXEMPT_ACTION =
    NO_RUN_STATE_REDIRECT.map { |item|
      next unless item.is_a?(Hash)
      controller, action = item.flatten
      [controller.to_s, Array.wrap(action)]
    }.compact.to_h.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate whether the system is currently configured as unavailable.
  #
  def system_unavailable?
    RunState.unavailable?
  end

  # Indicate whether the controller is not exempt from redirection.
  #
  # @param [String, Symbol, nil] ctrlr    Default: `params[:controller]`
  # @param [String, Symbol, nil] action   Default: `params[:action]`
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def run_state_redirect?(ctrlr = nil, action = nil)
    ctrlr, action = ctrlr_action_to_names(ctrlr, action)
    exempt_ctrlr  = RUN_STATE_EXEMPT_CONTROLLER.include?(ctrlr)
    exempt_action = RUN_STATE_EXEMPT_ACTION[ctrlr]&.include?(action)
    !exempt_ctrlr && !exempt_action
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Unconditionally redirect to the page which indicates system unavailability.
  #
  def system_unavailable
    redirect_to system_unavailable_path
  end

  # Determine whether the system is unavailable.
  #
  def check_system_availability
    system_unavailable if system_unavailable? && run_state_redirect?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)

    extend ParamsHelper

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include AbstractController::Callbacks::ClassMethods
      include RunStateConcern
      # :nocov:
    end

    # =========================================================================
    # :section: Callbacks
    # =========================================================================

    # noinspection RubyMismatchedArgumentType
    if (this_controller = controller_to_name(base)).nil?
      # === Including class is not a controller ===

    elsif RUN_STATE_EXEMPT_CONTROLLER.include?(this_controller)
      # === Including class is an exempt controller ===

    elsif RunState::STATIC
      # === Only add callback if the system is unavailable at startup ===
      prepend_before_action :system_unavailable, if: :system_unavailable?

    else
      # === Check for system availability for every endpoint ===
      prepend_before_action :check_system_availability
    end

  end

end

__loading_end(__FILE__)
