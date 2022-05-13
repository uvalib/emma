# app/records/search/shared/date_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to dates.
#
module Search::Shared::DateMethods
  include Api::Shared::DateMethods
  include Search::Shared::CommonMethods
end

__loading_end(__FILE__)
