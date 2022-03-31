# app/controllers/concerns/options_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for managing model/controller options.
#
module OptionsConcern

  extend ActiveSupport::Concern

  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the @model_options instance created for the current controller.
  #
  # @return [Options]
  #
  def model_options
    @model_options ||= set_model_options
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # Create a @model_options instance from the current parameters.
  #
  # @return [Options]
  #
  def set_model_options
    # noinspection RubyMismatchedArgumentType
    @model_options = Options.new(self, request_parameters)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)

    include ParamsHelper

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include AbstractController::Callbacks::ClassMethods
      include OptionsConcern
      # :nocov:
    end

    # =========================================================================
    # :section: Callbacks
    # =========================================================================

    before_action :set_model_options, if: :request_get?

  end

end

__loading_end(__FILE__)
