# app/channels/_application_cable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ApplicationCable
  include ApplicationCable::Common
  include ApplicationCable::Logging
  include ApplicationCable::Payload
end

__loading_end(__FILE__)
