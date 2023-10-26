# test/controllers/tool_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class ToolControllerTest < ActionDispatch::IntegrationTest

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'tool index' do
    get tool_index_url
    assert_response :success
  end

end
