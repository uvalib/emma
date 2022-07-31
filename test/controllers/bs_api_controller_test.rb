# test/controllers/bs_api_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class BsApiControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER    = :bs_api
  PARAMS        = { controller: CONTROLLER }.freeze
  OPTIONS       = { controller: CONTROLLER, expect: :success }.freeze

  TEST_USERS    = %i[anonymous emmadso].freeze
  TEST_READERS  = TEST_USERS

  READ_FORMATS  = :all

  TEST_API_PATH = 'titles'

  # noinspection RbsMissingTypeSignature
  setup do
    @readers = find_users(*TEST_READERS)
  end

  # On-going problems with XML serialization...
  XML_FAILURE = :internal_server_error

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'bs_api index - visit the Bookshare API Explorer' do
    action  = :index
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      u_opt = options
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] = XML_FAILURE if fmt == :xml
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'bs_api v2 - Bookshare API results for GET' do
    action  = :v2
    params  = PARAMS.merge(action: action, api_path: TEST_API_PATH)
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      u_opt = options
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  # ===========================================================================
  # :section: Download tests
  # ===========================================================================

  test 'bs_api image - proxy request to CloudFront' do
    action  = :image
    item    = sample_title
    proxy   = cdn_thumbnail(item.bookshareId)
    params  = PARAMS.merge(action: action, url: proxy)
    options =
      OPTIONS.merge(action: action, test: __method__, media_type: :plain)
    @readers.each do |user|
      u_opt = options
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

end
