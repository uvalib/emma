# test/controllers/member_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class MemberControllerTest < ActionDispatch::IntegrationTest

  MODEL         = Member
  CONTROLLER    = :member
  PARAMS        = { controller: CONTROLLER }.freeze
  OPTIONS       = { controller: CONTROLLER, expect: :success }.freeze

  TEST_USERS    = %i[anonymous emmadso].freeze
  TEST_READERS  = TEST_USERS
  TEST_WRITERS  = %i[anonymous].freeze # TODO: member write tests

  READ_FORMATS  = :all
  WRITE_FORMATS = :all

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
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'member show - details of an existing organization member' do
    action  = :show
    member  = members(:organization).user_id
    params  = PARAMS.merge(action: action, id: member)
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'member new - add metadata for a new organization member' do
    action  = :new
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)
    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'member create - a new organization member' do
    action  = :create
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)
    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        post_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'member edit - metadata for an existing organization member' do
    action  = :edit
    item    = members(:organization)
    params  = PARAMS.merge(action: action, id: item.user_id)
    options = OPTIONS.merge(action: action, test: __method__)
    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'member update - modify an existing organization member' do
    action  = :update
    item    = members(:organization)
    params  = PARAMS.merge(action: action, id: item.user_id)
    options = OPTIONS.merge(action: action, test: __method__)
    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        put_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'member destroy - remove an existing organization member' do
    action  = :destroy
    item    = members(:organization)
    params  = PARAMS.merge(action: action, id: item.user_id)
    options = OPTIONS.merge(action: action, test: __method__)
    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        delete_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

end
