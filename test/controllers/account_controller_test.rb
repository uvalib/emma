# test/controllers/account_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_controller_test_case'

class AccountControllerTest < ApplicationControllerTestCase

  MODEL = User
  CTRLR = :account
  PRM   = { controller: CTRLR }.freeze
  OPT   = { controller: CTRLR, sign_out: false }.freeze

  TEST_READERS  = ALL_TEST_USERS
  TEST_WRITERS  = ALL_TEST_USERS

  READ_FORMATS  = :all
  WRITE_FORMATS = :html

  NO_READ       = formats_other_than(*READ_FORMATS).freeze
  NO_WRITE      = formats_other_than(*WRITE_FORMATS).freeze

  setup do
    @readers  = find_users(*TEST_READERS)
    @writers  = find_users(*TEST_WRITERS)
    @generate = UserSampleGenerator.new(self)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'account index - list user accounts' do
    action  = :index
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        url = url_for(**u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_READ.include?(fmt)
          opt[:expect] = :not_found if able
        else
          opt[:redir]  = index_redirect(user: user, **opt) if able
        end
        get_as(user, url, **opt)
      end
    end
  end

  test 'account show - details of an existing user account' do
    action  = :show
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      other = other_member(user)
      able  = permitted?(action, user, other)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params.merge(id: other.id)

      foreach_format(user, **u_opt) do |fmt|
        url = url_for(**u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_READ.include?(fmt)
          opt[:expect] = :not_found if able
        end
        get_as(user, url, **opt)
      end
    end
  end

  test 'account show_current - details of the current user account' do
    action  = :show_current
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        url = url_for(**u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_READ.include?(fmt)
          opt[:expect] = :not_found if able
        end
        get_as(user, url, **opt)
      end
    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'account new - user account form' do
    action  = :new
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @writers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        url = url_for(**u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_WRITE.include?(fmt)
          opt[:expect] = :not_found if able
        end
        get_as(user, url, **opt)
      end
    end
  end

  test 'account create - a new user account' do
    action  = :create
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__, expect: :no_content)

    @writers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        rec = @generate.sample_for(action, user: user, mutate: true)
        url = url_for(**rec.fields, **u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        can = able && permitted?(action, user, rec)
        if NO_WRITE.include?(fmt)
          opt[:expect] = :unauthorized unless can
        else
          opt[:expect] = :redirect unless can
        end
        post_as(user, url, **opt)
      end
    end
  end

  test 'account edit_current - user account form' do
    action  = :edit_current
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @writers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        url = url_for(**u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_WRITE.include?(fmt)
          opt[:expect] = :not_found if able
        end
        get_as(user, url, **opt)
      end
    end
  end

  test 'account edit - user account edit form' do
    action  = :edit
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @writers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        rec = @generate.sample_for(action, user: user, mutate: true)
        url = url_for(id: rec.id, **u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_WRITE.include?(fmt)
          opt[:expect] = :not_found if able
        elsif !able || !permitted?(action, user, rec)
          opt[:expect] = :redirect
        end
        get_as(user, url, **opt)
      end
    end
  end

  test 'account update - modify an existing user account' do
    action  = :update
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__)

    @writers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        rec = @generate.sample_for(action, user: user, mutate: true)
        url = url_for(**rec.fields, **u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_WRITE.include?(fmt)
          can = able && permitted?(action, user, rec)
          opt[:expect] = can ? :no_content : :unauthorized
        end
        put_as(user, url, **opt)
      end
    end
  end

  test 'account delete - select an existing user account for removal' do
    action  = :delete
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @writers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        rec = @generate.sample_for(action, user: user, mutate: true)
        url = url_for(id: rec.id, **u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_WRITE.include?(fmt)
          opt[:expect] = :not_found if able
        end
        get_as(user, url, **opt)
      end
    end
  end

  test 'account destroy - remove an existing user account' do
    action  = :destroy
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__)

    @writers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        rec = @generate.sample_for(action, user: user, mutate: true)
        url = url_for(id: rec.id, **u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_WRITE.include?(fmt)
          opt[:expect] = :no_content if able
        end
        delete_as(user, url, **opt)
      end
    end
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'account controller test coverage' do
    # Endpoints covered by system tests:
    skipped = %i[
      delete_select
      edit_select
      list_all
      list_org
      show_select
    ]
    check_controller_coverage AccountController, except: skipped
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  protected

  # Return a user which is in the same member organization as the given user.
  #
  # @param [User, nil] this_user
  #
  # @return [User]
  #
  def other_member(this_user = nil)
    user =
      if (oid = this_user&.org_id)
        @readers.compact.excluding(this_user).find { _1.org_id == oid }
      elsif this_user
        @readers.compact.excluding(this_user).first
      end
    user || users(:example)
  end

  # ===========================================================================
  # :section: TestHelper::Utility overrides
  # ===========================================================================

  protected

  # The default :index action redirects to :list_org for an organization user.
  #
  # @param [Hash] opt
  #
  # @return [String]
  #
  def index_redirect(**opt)
    opt.reverse_merge!(PRM)
    opt[:user] = find_user(opt[:user] || current_user)
    opt[:dst]  = opt[:user]&.org ? :list_org : :list_all
    super
  end

end
