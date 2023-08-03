# test/controllers/data_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

# noinspection RubyJumpError
class DataControllerTest < ActionDispatch::IntegrationTest

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'data index' do
    return if not_applicable 'data/index' # TODO: data/index
    get data_index_url
    assert_response :success
  end

end
