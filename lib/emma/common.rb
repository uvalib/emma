# lib/emma/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# General support methods.
#
module Emma::Common

  # @private
  def self.included(base)
    base.extend(self)
  end

  require_submodules(__FILE__)

  include Emma::Common::BooleanMethods
  include Emma::Common::ExceptionMethods
  include Emma::Common::FormatMethods
  include Emma::Common::HashMethods
  include Emma::Common::HtmlMethods
  include Emma::Common::MethodMethods
  include Emma::Common::NumericMethods
  include Emma::Common::ObjectMethods
  include Emma::Common::StringMethods
  include Emma::Common::UrlMethods

end

__loading_end(__FILE__)
