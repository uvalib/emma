# app/records/bs/record/bisac_code.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::BisacCode
#
# @attr [String] code
# @attr [String] description
#
# @see https://apidocs.bookshare.org/reference/index.html#_bisac_code
#
class Bs::Record::BisacCode < Bs::Api::Record

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :code
    has_one :description
  end

end

__loading_end(__FILE__)
