# app/records/ingest/shared/title_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to catalog titles.
#
module Ingest::Shared::TitleMethods
  include Api::Shared::TitleMethods
  include Ingest::Shared::CommonMethods
end

__loading_end(__FILE__)
