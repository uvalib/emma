# test/models/enrollment_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_model_test_case'

class EnrollmentTest < ApplicationModelTestCase

  test 'model - valid enrollment' do
    run_test(__method__) do
      item = enrollments(:one)
      show_item(item)
      assert item.valid?
    end
  end

  test 'model - add users to enrollment' do
    break # TODO: enrollment tests
    run_test(__method__) do
      item = enrollments(:two)
      item.users += find_users(org: orgs(:one))
      show_item(item)
      assert item.valid?
    end
  end

end
