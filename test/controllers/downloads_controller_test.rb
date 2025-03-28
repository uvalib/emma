# test/controllers/downloads_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_controller_test_case'

class DownloadsControllerTest < ApplicationControllerTestCase

  MODEL = Download
  CTRLR = :download
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
    @generate = DownloadSampleGenerator.new(self)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'download index - list download events' do
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

  test 'download show - details of an existing download event' do
    action  = :show
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        rec = downloads(:example)
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

  test 'download new - make a download event' do
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

  test 'download create - a new download event' do
    action  = :create
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
          opt[:expect] = able ? :no_content : :unauthorized
        end
        post_as(user, url, **opt)
      end
    end
  end

  test 'download edit - data for an existing download event' do
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
        end
        get_as(user, url, **opt)
      end
    end
  end

  test 'download update - replace an existing download event' do
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
          opt[:expect] = able ? :no_content : :unauthorized
        end
        put_as(user, url, **opt)
      end
    end
  end

  test 'download delete - select an existing download event for removal' do
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

  test 'download destroy - remove an existing download event' do
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

  test 'download controller test coverage' do
    # Endpoints covered by system tests:
    skipped = %i[
      delete_select
      edit_select
      list_all
      list_org
      list_own
      register
      show_select
    ]
    check_controller_coverage DownloadController, except: skipped
  end

end
