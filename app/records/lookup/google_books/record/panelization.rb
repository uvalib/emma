# app/records/lookup/google_books/record/panelization.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Undocumented.
#
# @attr [Boolean] containsEpubBubbles
# @attr [Boolean] containsImageBubbles
#
# @see https://developers.google.com/books/docs/v1/reference/volumes
#
#--
# noinspection LongLine
#++
class Lookup::GoogleBooks::Record::Panelization < Lookup::GoogleBooks::Api::Record

  include Lookup::GoogleBooks::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :containsEpubBubbles,  Boolean
    has_one :containsImageBubbles, Boolean
  end

end

__loading_end(__FILE__)
