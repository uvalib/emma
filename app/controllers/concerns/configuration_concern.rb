# app/controllers/concerns/configuration_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for configuration lookup.
#
module ConfigurationConcern

  extend ActiveSupport::Concern

  include ConfigurationHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The configuration key for the controller for use with "emma.#{config_key}".
  #
  # @return [Symbol]
  #
  def config_key
    self_class.name.underscore.split('_')[0...-1].join('_').to_sym
  end

  # Labels for item units operated on by this controller.
  #
  # - :item   Label for a single model instance.
  # - :items  Plural model instances label.
  # - :Item   Capitalized label for a single model instance.
  # - :Items  Capitalized plural model instances label.
  #
  # @param [Hash] opt                 Passed to #config_interpolations.
  #
  # @return [Hash]
  #
  def unit(**opt)
    opt[:ctrlr] ||= config_key
    config_interpolations(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
    base.extend(THIS_MODULE)
  end

end

__loading_end(__FILE__)
