# test/system/api_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class ApiTest < ApplicationSystemTestCase

  test 'api - visit Bookshare API Explorer' do
    run_test(__method__) do

      # Visit the page.
      visit api_index_path
      assert_title 'API Methods |'
      assert_selector 'h1', text: 'Bookshare API Methods'

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
    run_test(__method__) do
      visit v2_api_path(api_path: 'titles')
      assert_title 'API Method Output "/v2/titles"'
      assert_selector 'h1', text: 'API Method Output'
      assert_selector '.trials .value *'
    end
  end

end
