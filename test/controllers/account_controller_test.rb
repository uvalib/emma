# test/controllers/account_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class AccountControllerTest < ActionDispatch::IntegrationTest

  MODEL         = User
  CONTROLLER    = :account
  PARAMS        = { controller: CONTROLLER }.freeze
  OPTIONS       = { controller: CONTROLLER }.freeze

  TEST_USERS    = ALL_TEST_USERS
  TEST_READERS  = TEST_USERS
  TEST_WRITERS  = TEST_USERS

  READ_FORMATS  = :all
  WRITE_FORMATS = :html

  setup do
    @readers = find_users(*TEST_READERS)
    @writers = find_users(*TEST_WRITERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'account index - list all user accounts' do
    action  = :index
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        case opt[:expect]
          when :success then opt[:redir] = index_redirect(user: user, **opt)
        end
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'account show - details of an existing user account' do
    action  = :show
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      other = other_member(user) || users(:example)

      TEST_FORMATS.each do |fmt|
        url = url_for(id: other.id, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'account show_current - details of the current user account' do
    action  = :show_current
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'account new - user account form' do
    action  = :new
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'account create - a new user account' do
    action  = :create
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @writers.each do |user|
      org   = user&.oid
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        rec = new_record.tap { |r| r.org_id = org }
        url = url_for(**rec.fields, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        post_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'account edit - user account edit form' do
    action  = :edit
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    @writers.each do |user|
      org   = user&.oid
      able  = user&.manager? && can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        rec = sample_for_edit.tap { |r| r.update!(org_id: org) if org }
        url = url_for(id: rec.id, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'account update - modify an existing user account' do
    action  = :update
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @writers.each do |user|
      org   = user&.oid
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        rec = sample_for_edit.tap { |r| r.update!(org_id: org) if org }
        url = url_for(**rec.fields, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        put_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'account delete - select an existing user account for removal' do
    action  = :delete
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    @writers.each do |user|
      org   = user&.oid
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        rec = sample_for_delete.tap { |r| r.update!(org_id: org) if org }
        url = url_for(id: rec.id, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'account destroy - remove an existing user account' do
    action  = :destroy
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @writers.each do |user|
      org   = user&.oid
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        rec = sample_for_delete.tap { |r| r.update!(org_id: org) if org }
        url = url_for(id: rec.id, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        delete_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  public

  # @private
  # @type [String,nil]
  attr_accessor :edit_id

  # @private
  # @type [String,nil]
  attr_accessor :delete_id

  # Return a user which is in the same member organization as the given user.
  #
  # @param [User, nil] user
  #
  # @return [User, nil]
  #
  def other_member(user)
    @readers.compact.excluding(user).first if user
  end

  # Push a dummy item into the database for editing.
  #
  # @param [Symbol, String, Hash] src
  #
  # @return [User]
  #
  def sample_for_edit(src = :edit_example)
    current = edit_id && User.find_by(id: edit_id)
    current&.delete
    new_record(src).tap do |record|
      self.edit_id = record.id if record.save!
    end
  end

  # Push a dummy item into the database for deletion.
  #
  # @param [Symbol, String, Hash] src
  #
  # @return [User]
  #
  def sample_for_delete(src = :delete_example)
    current = delete_id && User.find_by(id: delete_id)
    return current if current && (src == :delete_example)
    current&.delete
    new_record(src).tap do |record|
      self.delete_id = record.id if record.save!
    end
  end

  # Generate a new non-persisted item to support new item creation.
  #
  # @param [Symbol, String, Hash] src
  #
  # @return [User]
  #
  def new_record(src = :example)
    src = src.to_sym if src.is_a?(String)
    # noinspection RubyMismatchedArgumentType
    src = users(src) if src.is_a?(Symbol)
    if src.is_a?(User)
      src = src.fields.except(:id)
      src[:email] = unique_email(src[:email])
    end
    User.new(src) if src.is_a?(Hash)
  end

  # ===========================================================================
  # :section: TestHelper::Utility overrides
  # ===========================================================================

  public

  # The default :index action redirects to :list_org for an organization user.
  #
  # @param [Hash] opt
  #
  # @return [String, nil]
  #
  def index_redirect(**opt)
    opt[:user] = find_user(opt[:user] || current_user)
    opt[:dst]  = opt[:user]&.org ? :list_org : :list_all
    super
  end

end
