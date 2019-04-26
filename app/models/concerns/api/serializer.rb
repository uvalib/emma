# app/models/concerns/api/serializer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Api

  # Namespace for the serialization/de-serialization mechanisms associated with
  # objects derived from Api::Record::Base.
  #
  module Serializer
  end

end

require 'api/schema'
require_subdir(__FILE__)

__loading_end(__FILE__)
