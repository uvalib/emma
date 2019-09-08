# test/controllers/api_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class ApiControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER    = 'api'
  OPTIONS       = { controller: CONTROLLER }.freeze

  TEST_USERS    = [ANONYMOUS, EMMA_DSO].freeze
  TEST_READERS  = TEST_USERS
  TEST_WRITERS  = [ANONYMOUS].freeze # TODO: API write tests

  TEST_API_PATH = 'titles'

  # ===========================================================================
  # :section:
  # ===========================================================================

  test 'api index - visit the API Explorer' do
    endpoint = api_index_path
    options  = OPTIONS.merge(test: __method__, action: 'index')
    options[:expect] = :success
    TEST_READERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

  test 'api v2 - Bookshare API results for GET' do
    endpoint = v2_api_path(api_path: TEST_API_PATH)
    options  = OPTIONS.merge(test: __method__, action: 'v2')
    options[:expect] = :success
    TEST_READERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

  test 'api image - proxy request to CloudFront' do
    proxy_url = cdn_thumbnail(sample_title.bookshareId)
    endpoint  = image_api_path(url: proxy_url)
    options = OPTIONS.merge(test: __method__, action: 'image', media_type: nil)
    options[:expect] = :success
    TEST_READERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

end
