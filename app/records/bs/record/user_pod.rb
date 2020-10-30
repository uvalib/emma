# app/records/bs/record/user_pod.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::UserPod
#
# @attr [DisabilityType] disabilityType
# @attr [String]         proofSource
#
# @see https://apidocs.bookshare.org/reference/index.html#_user_pod
#
class Bs::Record::UserPod < Bs::Api::Record

  schema do
    has_one   :disabilityType, DisabilityType
    has_one   :proofSource
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A label for the item.
  #
  # @return [String]
  #
  def label
    disabilityType.to_s
  end


end

__loading_end(__FILE__)
