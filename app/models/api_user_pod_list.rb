# app/models/api_user_pod_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/message'
require 'api/user_pod'
require 'api/link'

# ApiUserPodList
#
# @see https://apidocs-qa.bookshare.org/reference/index.html#_user_pod_list
#
class ApiUserPodList < Api::Message

  schema do
    has_many :allows,       String
    has_many :disabilities, UserPod
    has_many :links,        Link
  end

end

__loading_end(__FILE__)
