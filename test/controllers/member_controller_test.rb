# test/controllers/member_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class MemberControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = :member
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = %i[anonymous emmadso].freeze
  TEST_READERS = TEST_USERS
  TEST_WRITERS = %i[anonymous].freeze # TODO: member write tests

  # noinspection RbsMissingTypeSignature
  setup do
    @readers = find_users(*TEST_READERS)
    @writers = find_users(*TEST_WRITERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'member index - list all organization members' do
    action  = :index
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      able  = can?(user, action, Member)
      u_opt =
        if able
          options.merge(expect: :success)
        else
          options.except(:controller, :action)
        end
      TEST_FORMATS.each do |fmt|
        next unless allowed_format(fmt, only: %i[html json])
        url = member_index_url(format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt)
      end
    end
  end

  test 'member show - details of an existing organization member' do
    action  = :show
    options = OPTIONS.merge(action: action, test: __method__)
    member  = members(:organization).user_id
    @readers.each do |user|
      able  = can?(user, action, Member)
      u_opt =
        if able
          options.merge(expect: :success)
        else
          options.except(:controller, :action)
        end
      TEST_FORMATS.each do |fmt|
        next unless allowed_format(fmt, only: %i[html json])
        url = member_url(id: member, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt)
      end
    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'member new - add metadata for a new organization member' do
    action  = :new
    options = OPTIONS.merge(action: action, test: __method__)
    url     = new_member_url
    @writers.each do |user|
      get_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'member create - a new organization member' do
    action  = :create
    options = OPTIONS.merge(action: action, test: __method__)
    url     = member_index_url
    @writers.each do |user|
      post_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'member edit - metadata for an existing organization member' do
    action  = :edit
    options = OPTIONS.merge(action: action, test: __method__)
    item    = members(:organization)
    url_opt = { id: item.user_id }
    url     = edit_member_url(**url_opt)
    @writers.each do |user|
      get_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'member update - modify an existing organization member' do
    action  = :update
    options = OPTIONS.merge(action: action, test: __method__)
    item    = members(:organization)
    url_opt = { id: item.user_id }
    url     = member_url(**url_opt)
    @writers.each do |user|
      put_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'member destroy - remove an existing organization member' do
    action  = :destroy
    options = OPTIONS.merge(action: action, test: __method__)
    item    = members(:organization)
    url_opt = { id: item.user_id }
    url     = member_url(**url_opt)
    @writers.each do |user|
      delete_as(user, url, **options)
    end if allowed_format(only: :html)
  end

end
