# test/controllers/data_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class DataControllerTest < ActionDispatch::IntegrationTest

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'data index' do
    # noinspection RubyJumpError
    return if not_applicable 'TODO: data/index'
    get data_index_url
    assert_response :success
  end

end
