# test/controllers/org_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_controller_test_case'

class OrgControllerTest < ApplicationControllerTestCase

  MODEL = Org
  CTRLR = :org
  PRM   = { controller: CTRLR }.freeze
  OPT   = { controller: CTRLR, sign_out: false }.freeze

  TEST_READERS  = ALL_TEST_USERS
  TEST_WRITERS  = ALL_TEST_USERS

  READ_FORMATS  = :all
  WRITE_FORMATS = :html

  NO_READ       = formats_other_than(*READ_FORMATS).freeze
  NO_WRITE      = formats_other_than(*WRITE_FORMATS).freeze

  # The organization for users in #ALL_TEST_USERS.
  TEST_ORG = :one

  # An organization different from #TEST_ORG.
  OTHER_ORG = :two

  setup do
    @readers   = find_users(*TEST_READERS)
    @writers   = find_users(*TEST_WRITERS)
    @test_org  = orgs(TEST_ORG)
    @other_org = orgs(OTHER_ORG)
    @generate  = OrgSampleGenerator.new(self)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'org index - list orgs' do
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
        elsif able
          opt[:redir]  = index_redirect(user: user, **opt)
          opt[:expect] = :nothing
          opt[:format] = :any
        end
        get_as(user, url, **opt)
      end
    end
  end

  test 'org list_all - list all orgs' do
    action  = :list_all
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

  test 'org show - details of an existing org' do
    action  = :show
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params.merge(id: @other_org.id)

      foreach_format(user, **u_opt) do |fmt|
        url = url_for(**u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_READ.include?(fmt)
          opt[:expect] = :not_found if able
        elsif able && user.org && (user.org != @other_org)
          opt[:expect] = (fmt == :html) ? :redirect : :not_found
        end
        get_as(user, url, **opt)
      end
    end
  end

  test 'org show_current - details of the current org' do
    action  = :show_current
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        rec = @test_org
        url = url_for(id: rec.id, **u_prm, format: fmt)
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

  test 'org new - import data for a new org' do
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

  test 'org create - a new org' do
    action  = :create
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__)

    @writers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        rec = @generate.sample_for(action, unique: true)
        url = url_for(**rec.fields, **u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_WRITE.include?(fmt)
          opt[:expect] = able ? :not_found : :unauthorized
        end
        post_as(user, url, **opt)
      end
    end
  end

  test 'org edit - data for an existing org' do
    action  = :edit
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @writers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        rec = @generate.sample_for(action)
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

  test 'org update - replace an existing org' do
    action  = :update
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__)

    @writers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        rec = @generate.sample_for(action)
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

  test 'org delete - select an existing org for removal' do
    action  = :delete
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @writers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        rec = @generate.sample_for(action)
        url = url_for(id: rec.id, **u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        if NO_WRITE.include?(fmt)
          opt[:expect] = :not_found if able
        end
        get_as(user, url, **opt)
      end
    end
  end

  test 'org destroy - remove an existing org' do
    action  = :destroy
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__)

    @writers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        rec = @generate.sample_for(action)
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
  # :section: TestHelper::Utility overrides
  # ===========================================================================

  public

  # The default :index action redirects to :list_all for Administrator and
  # :show for everyone else.
  #
  # @param [Hash] opt
  #
  # @return [String]
  #
  def index_redirect(**opt)
    opt.reverse_merge!(PRM)
    opt[:user] = find_user(opt[:user] || current_user)
    opt[:dst]  = opt[:user]&.administrator? ? :list_all : :show
    super
  end

end
