# test/controllers/upload_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_controller_test_case'

class UploadControllerTest < ApplicationControllerTestCase

  MODEL = Upload
  CTRLR = :upload
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
    @generate = UploadSampleGenerator.new(self)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'upload index - list uploads' do
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

  test 'upload show - details of an existing upload' do
    action  = :show
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        rec = uploads(:example)
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

  test 'upload new - data for a new upload' do
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

  test 'upload create - a new upload' do
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
          opt[:expect] = able ? :no_content : :unauthorized
        end
        post_as(user, url, **opt)
      end
    end
  end

  test 'upload edit - data for an existing upload' do
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

  test 'upload update - replace an existing upload' do
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

  test 'upload delete - select an existing upload for removal' do
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

  test 'upload destroy - remove an existing upload' do
    action  = :destroy
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__)

    @writers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        rec = @generate.sample_for(action) and reindex(rec)
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
  # :section: Administrative tests
  # ===========================================================================

  test 'upload admin - view S3 buckets' do
    action  = :admin
    params  = PRM.merge(action: action)
    options = OPT.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = permitted?(action, user)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_prm = params

      foreach_format(user, **u_opt) do |fmt|
        url = make_path('/upload/admin', **u_prm, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'upload controller test coverage' do
    # Endpoints covered by system tests:
    skipped = %i[
      api_migrate
      bulk_create
      bulk_delete
      bulk_destroy
      bulk_edit
      bulk_index
      bulk_new
      bulk_reindex
      bulk_update
      cancel
      check
      delete_select
      download
      edit_select
      list_all
      list_org
      list_own
      probe_retrieval
      records
      reedit
      renew
      retrieval
      s3_object_table
      show_select
      upload
    ]
    check_controller_coverage UploadController, except: skipped
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  # NONE

  # ===========================================================================
  # :section: TestHelper::Utility overrides
  # ===========================================================================

  protected

  # The default :index action redirects to :list_own.
  #
  # @param [Hash] opt
  #
  # @return [String]
  #
  def index_redirect(**opt)
    opt.reverse_merge!(PRM)
    opt[:dst] ||= :list_own
    super
  end

end
