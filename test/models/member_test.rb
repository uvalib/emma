# test/models/member_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class MemberTest < ActiveSupport::TestCase

  test 'model - valid org member' do
    run_test(__method__) do
      item = members(:organization)
      show item
      assert item.valid?
    end
  end

=begin # TODO: org member must have a user_id ???
  test 'model - org member must have a user_id' do
    run_test(__method__) do
      data = members(:organization).attributes.except('user_id')
      item = Member.new(data)
      show item
      refute item.valid?
    end
  end
=end

  test 'model - valid institutional member' do
    run_test(__method__) do
      item = members(:institutional)
      show item
      assert item.valid?
    end
  end

  test 'model - institutional member must also be a User' do
    run_test(__method__) do
      data = members(:institutional).attributes.except('emailAddress')
      item = Member.new(data)
      show item
      refute item.valid?
    end
  end

end
