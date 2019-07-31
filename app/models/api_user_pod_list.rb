# app/models/api_user_pod_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'

require_relative 'api/common/link_methods'
require_relative 'api/user_pod'

# ApiUserPodList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_pod_list
#
class ApiUserPodList < Api::Message

  include Api::Common::LinkMethods

  schema do
    has_many :allows,       AllowsType
    has_many :disabilities, Api::UserPod
    has_many :links,        Api::Link
  end

end

__loading_end(__FILE__)
