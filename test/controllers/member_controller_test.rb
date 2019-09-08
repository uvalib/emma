# test/controllers/member_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class MemberControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = 'member'
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = [ANONYMOUS, EMMA_DSO].freeze
  TEST_READERS = TEST_USERS
  TEST_WRITERS = [ANONYMOUS].freeze # TODO: member write tests

  # ===========================================================================
  # :section:
  # ===========================================================================

  test 'member index - list all organization members' do
    endpoint = member_index_path
    options  = OPTIONS.merge(test: __method__, action: 'index')
    TEST_READERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

  test 'member show - details of an existing organization member' do
    member   = members(:organization).user_id
    endpoint = member_path(id: member)
    options  = OPTIONS.merge(test: __method__, action: 'show')
    TEST_READERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

  test 'member new - add metadata for a new organization member' do
    endpoint = new_member_path
    options  = OPTIONS.merge(test: __method__, action: 'new')
    TEST_WRITERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

  test 'member create - a new organization member' do
    endpoint = member_index_path
    options  = OPTIONS.merge(test: __method__, action: 'create')
    TEST_WRITERS.each do |user|
      post_as(user, endpoint, options)
    end
  end

  test 'member edit - metadata for an existing organization member' do
    member   = members(:organization).user_id
    endpoint = edit_member_path(id: member)
    options  = OPTIONS.merge(test: __method__, action: 'edit')
    TEST_WRITERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

  test 'member update - modify an existing organization member' do
    member   = members(:organization).user_id
    endpoint = member_path(id: member)
    options  = OPTIONS.merge(test: __method__, action: 'update')
    TEST_WRITERS.each do |user|
      put_as(user, endpoint, options)
    end
  end

  test 'member destroy - remove an existing organization member' do
    member   = members(:organization).user_id
    endpoint = member_path(id: member)
    options  = OPTIONS.merge(test: __method__, action: 'destroy')
    TEST_WRITERS.each do |user|
      delete_as(user, endpoint, options)
    end
  end

end
