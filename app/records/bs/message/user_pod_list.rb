# app/records/bs/message/user_pod_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Message::UserPodList
#
# @attr [Array<BsAllowsType>]        allows
# @attr [Array<Bs::Record::UserPod>] disabilities
# @attr [Array<Bs::Record::Link>]    links
#
# @see https://apidocs.bookshare.org/membership/index.html#_user_pod_list
#
class Bs::Message::UserPodList < Bs::Api::Message

  include Bs::Shared::LinkMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_many :allows,       BsAllowsType
    has_many :disabilities, Bs::Record::UserPod
    has_many :links,        Bs::Record::Link
  end

end

__loading_end(__FILE__)
