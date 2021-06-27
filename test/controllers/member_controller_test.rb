# test/controllers/member_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class MemberControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = 'member'
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = [ANONYMOUS, EMMA_DSO, EMMA_MEMBERSHIP].freeze
  TEST_READERS = TEST_USERS
  TEST_WRITERS = [ANONYMOUS].freeze # TODO: member write tests

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'member index - list all organization members' do
    options = OPTIONS.merge(test: __method__, action: 'index')
    TEST_READERS.each do |user|
      able  = can?(user, :index, Member)
      u_opt =
        if able
          options.merge(expect: :success)
        else
          options.except(:controller, :action)
        end
      TEST_FORMATS.each do |fmt|
        url = member_index_url(format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, opt)
      end
    end
  end

  test 'member show - details of an existing organization member' do
    member  = members(:organization).user_id
    options = OPTIONS.merge(test: __method__, action: 'show')
    TEST_READERS.each do |user|
      able  = can?(user, :show, Member)
      u_opt =
        if able
          options.merge(expect: :success)
        else
          options.except(:controller, :action)
        end
      TEST_FORMATS.each do |fmt|
        url = member_url(id: member, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, opt)
      end
    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  if TESTING_HTML

    test 'member new - add metadata for a new organization member' do
      url = new_member_url
      opt = OPTIONS.merge(test: __method__, action: 'new')
      TEST_WRITERS.each do |user|
        get_as(user, url, opt)
      end
    end

    test 'member create - a new organization member' do
      url = member_index_url
      opt = OPTIONS.merge(test: __method__, action: 'create')
      TEST_WRITERS.each do |user|
        post_as(user, url, opt)
      end
    end

    test 'member edit - metadata for an existing organization member' do
      member  = members(:organization).user_id
      url     = edit_member_url(id: member)
      opt     = OPTIONS.merge(test: __method__, action: 'edit')
      TEST_WRITERS.each do |user|
        get_as(user, url, opt)
      end
    end

    test 'member update - modify an existing organization member' do
      member  = members(:organization).user_id
      url     = member_url(id: member)
      opt     = OPTIONS.merge(test: __method__, action: 'update')
      TEST_WRITERS.each do |user|
        put_as(user, url, opt)
      end
    end

    test 'member destroy - remove an existing organization member' do
      member  = members(:organization).user_id
      url     = member_url(id: member)
      opt     = OPTIONS.merge(test: __method__, action: 'destroy')
      TEST_WRITERS.each do |user|
        delete_as(user, url, opt)
      end
    end

  end

end
