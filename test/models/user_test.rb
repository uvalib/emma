# test/models/user_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test 'valid user' do
    run_test(__method__) do
      item = sample_user
      show item
      assert item.valid?
    end
  end

  test 'user must have an email address' do
    run_test(__method__) do
      data = sample_user.attributes.except('email')
      item = User.new(data)
      show item
      refute item.valid?
    end
  end

  test 'user must have a valid email address' do
    run_test(__method__) do
      data = sample_user.attributes.tap { |u| u['email'].sub!(/@.*/, '') }
      item = User.new(data)
      show item
      refute item.valid?
    end
  end

end
