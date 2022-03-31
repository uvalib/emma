# config/initializers/draper.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Setup and initialization for the Draper gem.

module Draper

  class HelperProxy

    ROUTE_SET = ::Rails.application.routes

    include ROUTE_SET.url_helpers

    default_url_options[:host] = ROUTE_SET.default_url_options[:host]

  end

end
