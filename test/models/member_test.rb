# test/models/member_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class MemberTest < ActiveSupport::TestCase

  test 'valid org member' do
    run_test(__method__) do
      item = members(:organization)
      show item
      assert item.valid?
    end
  end

=begin
  test 'org member must have a user_id' do
    run_test(__method__) do
      data = members(:organization).attributes.except('user_id')
      item = Member.new(data)
      show item
      refute item.valid?
    end
  end
=end

  test 'valid institutional member' do
    run_test(__method__) do
      item = members(:institutional)
      show item
      assert item.valid?
    end
  end

  test 'institutional member must also be a User' do
    run_test(__method__) do
      data = members(:institutional).attributes.except('emailAddress')
      item = Member.new(data)
      show item
      refute item.valid?
    end
  end

end
