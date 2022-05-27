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

  # The database column checked against the time of last reboot to determine
  # whether the record is defunct.
  #
  # @return [Symbol]
  #
  def activity_column
    :updated_at
  end

  # Select the records that have not been updated since the last reboot.
  #
  # @return [ActiveRecord::Relation]
  #
  def outdated
    record_class = is_a?(Class) ? self : self.class
    record_class.where(activity_column => ..BOOT_TIME)
  end

  # Indicate how many records have not been updated since the last reboot.
  #
  # @return [Integer]
  #
  def outdated_count
    outdated.count
  end

  # Select the records that have not been updated since the last reboot.
  #
  # @param [String,Symbol,Hash] sort_order
  #
  # @return [ActiveRecord::Relation]
  #
  def outdated_list(sort_order: { created_at: :desc})
    outdated.order(sort_order)
  end

  # Remove the records that have not been updated since the last reboot.
  #
  # @return [Integer]
  #
  def outdated_delete
    outdated.delete_all
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
