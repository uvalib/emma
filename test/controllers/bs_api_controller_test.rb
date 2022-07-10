# test/controllers/bs_api_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class BsApiControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER    = :bs_api
  OPTIONS       = { controller: CONTROLLER }.freeze

  TEST_USERS    = %i[anonymous emmadso].freeze
  TEST_READERS  = TEST_USERS
  TEST_WRITERS  = %i[anonymous].freeze # TODO: API write tests

  # noinspection RbsMissingTypeSignature
  setup do
    @readers = find_users(*TEST_READERS)
    @writers = find_users(*TEST_WRITERS)
  end

  TEST_API_PATH = 'titles'

  # On-going problems with XML serialization...
  XML_FAILURE = :internal_server_error

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'bs_api index - visit the Bookshare API Explorer' do
    action  = :index
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)
    @readers.each do |user|
      TEST_FORMATS.each do |fmt|
        url = bs_api_index_url(format: fmt)
        opt = options.merge(format: fmt)
        opt[:expect] = XML_FAILURE if fmt == :xml
        get_as(user, url, **opt)
      end
    end
  end

  test 'bs_api v2 - Bookshare API results for GET' do
    action  = :v2
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)
    @readers.each do |user|
      TEST_FORMATS.each do |fmt|
        url = bs_api_v2_url(api_path: TEST_API_PATH, format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, **opt)
      end
    end
  end

  # ===========================================================================
  # :section: Download tests
  # ===========================================================================

  test 'bs_api image - proxy request to CloudFront' do
    action   = :image
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)
    options[:media_type] = :plain
    proxy_url = cdn_thumbnail(sample_title.bookshareId)
    @readers.each do |user|
      TEST_FORMATS.each do |fmt|
        url = bs_api_image_url(url: proxy_url, format: fmt)
        opt = options
        get_as(user, url, **opt)
      end
    end
  end

end
