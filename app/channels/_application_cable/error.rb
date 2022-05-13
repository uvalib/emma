# app/channels/_application_cable/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Stub base class for ActionCable-related exceptions.
#
class ApplicationCable::Error < Exception
end

# Raised to indicate that a payload would fail to be acceptable to Postgres
# NOTIFY (raising a PG::InvalidParameterValue exception).
#
class ApplicationCable::PayloadTooLarge < ApplicationCable::Error
end

__loading_end(__FILE__)
