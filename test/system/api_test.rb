# test/system/api_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class ApiTest < ApplicationSystemTestCase

  TRIAL_METHODS = ApiConcern::ApiTesting::TRIAL_METHODS.freeze

  ANONYMOUS_METHODS =
    TRIAL_METHODS.select { |k|
      ApiService.api_methods.dig(k, :role) == :anonymous
    }.freeze

  AUTHORIZED_METHODS = (TRIAL_METHODS - ANONYMOUS_METHODS).freeze

  TEST_PATH = '/v2/titles'

  # ===========================================================================
  # :section:
  # ===========================================================================

  test 'api - visit Bookshare API Explorer' do
    run_test(__method__) do

      # Visit the page.
      title   = 'API Methods |'
      heading = 'Bookshare API Methods'
      visit_index api_index_url, title: title, heading: heading

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

  test 'api - results for GET /v2/titles' do
    assert __method__.to_s.include?(TEST_PATH)
    title   = %Q(API Method Output "#{TEST_PATH}" |)
    heading = 'API Method Output'
    run_test(__method__) do
      visit v2_api_url(api_path: 'titles')
      assert_valid_page title: title, heading: heading
      assert_selector '.trials .value *'
    end
  end

end
