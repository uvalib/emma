# app/models/api/user_pod.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/record'

# Api::UserPod
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_pod
#
class Api::UserPod < Api::Record::Base

  schema do
    attribute :disabilityType, String
    attribute :proofSource,    String
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
