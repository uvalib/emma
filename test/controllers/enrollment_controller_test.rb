# test/controllers/enrollment_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_controller_test_case'

class EnrollmentControllerTest < ApplicationControllerTestCase

  MODEL = Enrollment
  CTRLR = :enrollment
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
    @generate  = OrgSampleGenerator.new(self)
    @test_org  = enrollments(TEST_ORG)
    @other_org = enrollments(OTHER_ORG)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'enrollment index - list enrollment requests' do
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
        end
        get_as(user, url, **opt)
      end
    end
  end

  test 'enrollment show - details of an existing enrollment request' do
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

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'enrollment new - import data for a new enrollment request' do
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

  test 'enrollment create - a new enrollment request' do
    action  = :create
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
          opt[:expect] = able ? :not_found : :unauthorized
        elsif !able || !permitted?(action, user, rec)
          opt[:expect] = :redirect
        end
        post_as(user, url, **opt)
      end
    end
  end

  test 'enrollment edit - data for an existing enrollment request' do
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

  test 'enrollment update - replace an existing enrollment request' do
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

  test 'enrollment delete - select an existing enrollment request for removal' do
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

  test 'enrollment destroy - remove an existing enrollment request' do
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
  # :section: Meta tests
  # ===========================================================================

  test 'enrollment controller test coverage' do
    # Endpoints covered by system tests:
    skipped = %i[
      delete_select
      edit_select
      finalize
      show_select
    ]
    check_controller_coverage EnrollmentController, except: skipped
  end

end
