# app/models/action/_bulk_part.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Base class for phases that can be part of compound actions.
#
class Action::BulkPart < Action

  include Record::Bulk::Part

  # ===========================================================================
  # :section: ActiveRecord callbacks
  # ===========================================================================

  before_destroy do
    __debug_line("*** Action::BulkPart #{type} ***")
    # TODO: Kill the ActiveJob if it is associated with one.
  end

end

__loading_end(__FILE__)
