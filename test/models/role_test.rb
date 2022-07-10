# test/models/role_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class RoleTest < ActiveSupport::TestCase

  test 'model - valid role' do
    run_test(__method__) do
      item = sample_role
      show item
      assert item.valid?
    end
  end

end
