# app/models/concerns/job_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# This is a mixin for record classes related to jobs.
#
module JobMethods

  extend ActiveSupport::Concern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Select the records that have not been updated since the last reboot.
  #
  # @param [String,Symbol,Hash] sort_order
  #
  # @return [ActiveRecord::Relation]
  #
  def outdated(sort_order: { created_at: :desc})
    record_class = is_a?(Class) ? self : self.class
    record_class.where(updated_at: ..BOOT_TIME).order(sort_order)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
    extend THIS_MODULE
  end

end

__loading_end(__FILE__)
