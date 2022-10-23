# app/decorators/base_decorator/_common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common definitions for modules supporting BaseDecorator.
#
# @!attribute [r] object
#   Set in Draper::Decorator#initialize
#   @return [Model]
#
# @!attribute [r] context
#   Set in Draper::Decorator#initialize
#   @return [Hash{Symbol=>*}]
#
module BaseDecorator::Common

  include Emma::Common
  include Emma::Unicode
  include Emma::Json

end

__loading_end(__FILE__)
