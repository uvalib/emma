# test/controllers/help_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_controller_test_case'

class HelpControllerTest < ApplicationControllerTestCase

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'help index' do
    get(help_index_url)
    assert_response :success
  end

end
