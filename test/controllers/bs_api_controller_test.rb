# test/controllers/bs_api_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class BsApiControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER    = 'bs_api'
  OPTIONS       = { controller: CONTROLLER }.freeze

  TEST_USERS    = [ANONYMOUS, EMMA_DSO].freeze
  TEST_READERS  = TEST_USERS
  TEST_WRITERS  = [ANONYMOUS].freeze # TODO: API write tests

  TEST_API_PATH = 'titles'

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'bs_api index - visit the Bookshare API Explorer' do
    options  = OPTIONS.merge(test: __method__, action: 'index')
    options[:expect] = :success
    TEST_READERS.each do |user|
      TEST_FORMATS.each do |fmt|
        url = bs_api_index_url(format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, opt)
      end
    end
  end

  test 'bs_api v2 - Bookshare API results for GET' do
    options = OPTIONS.merge(test: __method__, action: 'v2')
    options[:expect] = :success
    TEST_READERS.each do |user|
      TEST_FORMATS.each do |fmt|
        url = bs_api_v2_url(api_path: TEST_API_PATH, format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, opt)
      end
    end
  end

  # ===========================================================================
  # :section: Download tests
  # ===========================================================================

  test 'bs_api image - proxy request to CloudFront' do
    proxy_url = cdn_thumbnail(sample_title.bookshareId)
    options = OPTIONS.merge(test: __method__, action: 'image')
    options[:expect] = :success
    options[:media_type] = :plain
    TEST_READERS.each do |user|
      TEST_FORMATS.each do |fmt|
        url = bs_api_image_url(url: proxy_url, format: fmt)
        get_as(user, url, options)
      end
    end
  end

end
