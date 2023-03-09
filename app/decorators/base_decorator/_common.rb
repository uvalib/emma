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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # HTML tags indicating construction of a <table>.
  #
  # For use with the :tag named option, any of these tags may be passed in to
  # indicate participation in a table; the method will replace it with the
  # appropriate tag as needed.
  #
  # @type [Array<Symbol>]
  #
  TABLE_TAGS = %i[table thead tbody th tr td].freeze

end

__loading_end(__FILE__)
