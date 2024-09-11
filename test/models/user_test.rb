# test/models/user_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test 'model - valid user' do
    run_test(__method__) do
      item = users(:example)
      show_item(item)
      assert item.valid?
    end
  end

  test 'model - user must have an email address' do
    run_test(__method__) do
      item = users(:example)
      data = item.attributes.except('email')
      item = User.new(data)
      show_item(item)
      refute item.valid?
    end
  end

  test 'model - user must have a valid email address' do
    run_test(__method__) do
      item = users(:example)
      data = item.attributes.tap { _1['email'].sub!(/@.*/, '') }
      item = User.new(data)
      show_item(item)
      refute item.valid?
    end
  end

end
