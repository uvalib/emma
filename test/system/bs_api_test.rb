# test/system/bs_api_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class BsApiTest < ApplicationSystemTestCase

  TRIAL_METHODS = BsApiConcern::ApiTesting::METHODS

  ANONYMOUS_METHODS =
    TRIAL_METHODS.select { |k|
      BookshareService.api_methods&.dig(k, :role) == :anonymous
    }.freeze

  AUTHORIZED_METHODS = (TRIAL_METHODS - ANONYMOUS_METHODS).freeze

  TEST_PATH = '/v2/titles'

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'bs_api - visit the Bookshare API Explorer' do

    title   = 'API Methods |'
    heading = 'Bookshare API Methods'
    url     = bs_api_index_url

    run_test(__method__) do

      # Visit the page.
      visit_index(url, title: title, heading: heading)
      success_screenshot

      # These API calls should succeed for any user:
      ANONYMOUS_METHODS.each do |api_method|
        assert_selector "#__#{api_method} + .value.success"
      end

      # These API calls should fail for an anonymous user:
      AUTHORIZED_METHODS.each do |api_method|
        assert_selector "#__#{api_method} + .value.error"
      end

    end

  end

  test 'bs_api - results for GET /v2/titles' do

    assert __method__.to_s.include?(TEST_PATH)
    title   = %Q(API Method Output "#{TEST_PATH}" |)
    heading = 'API Method Output'
    url     = File.join(bs_api_index_path, TEST_PATH)

    run_test(__method__) do
      visit url
      assert_valid_page title: title, heading: heading
      assert_selector '.trials .value *'
      success_screenshot
    end

  end

  # ===========================================================================
  # :section: Read tests for anonymous user
  # ===========================================================================

  test 'bs_api - visit the Bookshare API Explorer - unauthorized' do
    url = bs_api_index_url(no_test: true)
    run_test(__method__) do
      visit url
      assert_json(error: 'Unauthorized')
    end
  end

  test 'bs_api - results for GET /v2/titles - unauthorized' do
    url = File.join(bs_api_index_path, TEST_PATH) << '?no_test=true'
    run_test(__method__) do
      visit url
      assert_json(error: 'Unauthorized')
    end
  end

end
