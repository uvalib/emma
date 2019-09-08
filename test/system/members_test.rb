# test/system/members_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class MembersTest < ApplicationSystemTestCase

  test 'members - visit index' do
    run_test(__method__) do
      visit member_index_path
      assert_flash alert: 'You need to sign in'
    end
  end

end
