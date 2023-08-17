# test/models/org_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class OrgTest < ActiveSupport::TestCase

  test 'model - valid org' do
    run_test(__method__) do
      item = orgs(:one)
      show item
      assert item.valid?
    end
  end

  test 'model - add users to org' do
    run_test(__method__) do
      item = orgs(:two)
      item.users += find_users(org: orgs(:one))
      show item
      assert item.valid?
    end
  end

end
