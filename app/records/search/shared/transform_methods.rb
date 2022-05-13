# app/records/search/shared/transform_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting transformations of data fields.
#
module Search::Shared::TransformMethods
  include Api::Shared::TransformMethods
  include Search::Shared::CommonMethods
end

__loading_end(__FILE__)
