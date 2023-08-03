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

  # Access the Options instance created for the current controller.
  #
  # @return [Options]
  #
  def model_options
    @model_options ||= get_model_options
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Create an Options instance from the current parameters.
  #
  # @return [Options]
  #
  def get_model_options
    not_implemented 'to be overridden by the model-specific Concern'
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
