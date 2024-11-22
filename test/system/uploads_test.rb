# test/system/uploads_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class UploadsTest < ApplicationSystemTestCase

  MODEL = Upload
  CTRLR = :upload
  PRM   = { controller: CTRLR }.freeze
  TITLE = page_title(**PRM, action: :index).freeze

  setup do
    @file     = file_fixture(UPLOAD_FILE)
    @admin    = find_user(:test_adm)
    @manager  = find_user(:test_man_1)
    @member   = find_user(:test_dso_1)
    @generate = UploadSampleGenerator.new(self)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'uploads - index - anonymous' do
    list_test(nil, meth: __method__)
  end

  test 'uploads - index - member' do
    list_test(@member, meth: __method__)
  end

  test 'uploads - index - admin' do
    list_test(@admin, meth: __method__)
  end

  test 'uploads - list_all - anonymous' do
    list_test(nil, meth: __method__, action: :list_all)
  end

  test 'uploads - list_all - member' do
    list_test(@member, meth: __method__, action: :list_all)
  end

  test 'uploads - list_all - admin' do
    list_test(@admin, meth: __method__, action: :list_all)
  end

  test 'uploads - list_org - anonymous' do
    list_test(nil, meth: __method__, action: :list_org)
  end

  test 'uploads - list_org - member' do
    user   = @member
    action = :list_org
    title  = page_title(action: action, name: user.org&.label)
    list_test(user, meth: __method__, action: action, title: title)
  end

  test 'uploads - list_org - admin' do
    list_test(@admin, meth: __method__, action: :list_org)
  end

  test 'uploads - list_own - anonymous' do
    list_test(nil, meth: __method__, action: :list_own)
  end

  test 'uploads - list_own - member' do
    list_test(@member, meth: __method__, action: :list_own)
  end

  test 'uploads - list_own - admin' do
    list_test(@admin, meth: __method__, action: :list_own)
  end

  test 'uploads - show - anonymous' do
    show_test(nil, meth: __method__)
  end

  test 'uploads - show - member' do
    show_test(@member, meth: __method__)
  end

  test 'uploads - show - admin' do
    show_test(@admin, meth: __method__)
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'uploads - new - anonymous' do
    new_test(nil, meth: __method__)
  end

  test 'uploads - new - member' do
    new_test(@member, meth: __method__)
  end

  test 'uploads - new - manager' do
    new_test(@manager, meth: __method__)
  end

  test 'uploads - new - admin' do
    new_test(@admin, meth: __method__)
  end

  test 'uploads - edit - anonymous' do
    edit_test(nil, meth: __method__)
  end

  test 'uploads - edit - member' do
    edit_test(@member, meth: __method__)
  end

  test 'uploads - edit - manager' do
    edit_test(@manager, meth: __method__)
  end

  test 'uploads - edit - admin' do
    edit_test(@admin, meth: __method__)
  end

  test 'uploads - delete - anonymous' do
    delete_test(nil, meth: __method__)
  end

  test 'uploads - delete - member' do
    delete_test(@member, meth: __method__)
  end

  test 'uploads - delete - manager' do
    delete_test(@manager, meth: __method__)
  end

  test 'uploads - delete - admin' do
    delete_test(@admin, meth: __method__)
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'uploads system test coverage' do
    skipped = [
      :download,        # @see 'search - download - EMMA native item'
      :retrieval,       # @see 'search - download - BiblioVault item'
      :probe_retrieval, # @see 'search - download - InternetArchive item'
    ]
    skipped += %i[
      admin
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
      reedit
      renew
      s3_object_table
      upload
    ] # TODO: still needed for UploadsTest
    check_system_coverage UploadController, except: skipped
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  protected

  # Perform a test to list EMMA submissions visible to *user*.
  #
  # @param [User, nil]    user
  # @param [Integer, nil] total       Expected total number of items.
  # @param [String, nil]  title       Default based on *user* and opt[:action].
  # @param [Symbol]       meth        Calling test method.
  # @param [Hash]         opt         URL parameters.
  #
  # @return [void]
  #
  def list_test(user, total: nil, title: nil, meth: nil, **opt)
    params    = PRM.merge(action: :index, **opt)
    action    = params[:action]

    start_url = url_for(**params)

    run_test(meth || __method__) do

      if permitted?(action, user)

        admin     = user&.administrator?
        index     = (action == :index)
        list_org  = (action == :list_org)
        list_own  = (action == :list_own)

        title   ||= page_title(**params, name: user&.org&.label) if list_org
        title   ||= page_title(**params)
        total   ||= fixture_count_for_user(MODEL, user) if index || list_own
        total   ||= fixture_count(MODEL) if admin
        total   ||= fixture_count_for_org(MODEL, user)

        final_url = index ? index_redirect(user: user) : start_url

        # Successful sign-in should redirect back to the action page.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # The listing should be the first of one or more results pages with as
        # many entries as there are submissions visible to the user.
        show_url
        screenshot
        assert_current_url(final_url)
        assert_valid_page(heading: title)
        assert_search_count(CTRLR, expected: total)

        # Verify that there are actually the indicated number of items.
        items   = all('.upload-list .upload-list-item')
        count   = all('.page-items', visible: :all).first&.text&.presence&.to_i
        count ||= total
        unless count == items.size
          flunk "#{count} items indicated but #{items.size} items found"
        end

        # Validate page contents.
        check_details_columns(items.first, prune: '.hierarchy') if items.present?

      elsif user

        show_item { "User '#{user}' blocked from listing submissions." }
        assert_no_visit(start_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from listing submissions.' }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

  # Perform a test to show an EMMA submission visible to *user*.
  #
  # @param [User, nil]   user
  # @param [Upload, nil] target
  # @param [String, nil] title
  # @param [Symbol]      meth         Calling test method.
  # @param [Hash]        opt          URL parameters.
  #
  # @return [void]
  #
  def show_test(user, target: nil, title: nil, meth: nil, **opt)
    target  ||= user&.uploads&.first || uploads(:emma_completed)
    params    = PRM.merge(action: :show, id: target.id, **opt)
    action    = params[:action]

    start_url = url_for(**params)

    run_test(meth || __method__) do

      if permitted?(action, user, target)

        title   ||= "Uploaded file #{target.filename.inspect}"

        final_url = start_url

        # Details of a single upload submission are available anonymously.
        sign_in_as(user) if user
        visit start_url

        # The page should show the details of the target submission.
        show_url
        screenshot
        assert_current_url(final_url)
        assert_valid_page(heading: title)

        # Validate page contents.
        check_details_columns('.upload-details', prune: '.hierarchy')

      elsif user

        show_item { "User '#{user}' blocked from viewing submission." }
        assert_no_visit(start_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from viewing submission.' }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

  # Perform a test to create a new EMMA submission.
  #
  # @param [User, nil]   user
  # @param [Symbol, nil] meth         Calling test method.
  # @param [Hash]        opt          Added to URL parameters.
  #
  # @return [void]
  #
  def new_test(user, meth: nil, **opt)
    button   = 'Create'
    action   = :new
    params   = PRM.merge(action: action, **opt)

    form_url = url_for(**params)

    run_test(meth || __method__) do

      if permitted?(action, user)

        admin     = user&.administrator?
        records   = (fixture_count(MODEL) if admin)
        total     = (fixture_count_for_user(MODEL, user) unless records)

        index_url = url_for(**params, action: :index)
        all_url   = url_for(**params, action: :list_all)
        own_url   = url_for(**params, action: :list_own)
        org_url   = url_for(**params, action: :list_org)

        start_url = index_url
        final_url = [index_url, all_url, own_url, org_url]

        # Generate field data for the item to create.
        name   = 'New Upload'
        tag    = user&.role&.upcase || 'ANON'
        fields = @generate.fields_for(action, tag: tag, base: name).except(:id)

        # Start on the index page showing the current number of items.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Go to the form page.
        select_action(button, wait_for: form_url)

        # On the form page a Manager or Administrator should see the
        # "Submitter" menu with their account pre-selected.
        if admin || user.manager?
          assert_selector '[data-field="user_id"]', text: user.email
        end

        # Provide file and wait for data extraction.
        attach_file(@file) { click_on 'Select file' }
        assert_selector '.uploaded-filename.complete', wait: 5

        # Add field data.
        menu_select 'Moving Image',    from: 'value-Type'
        menu_select 'RTF',             from: 'value-Format'
        menu_select 'True',            from: 'value-Complete'
        menu_select 'Born Accessible', from: 'value-Status'
        check       'Armenian'         # inside 'value-Language'
        fill_in 'value-Identifier', with: '' # remove bogus identifier
        fill_in 'value-Title',      with: fields[:dc_title]
        fill_in 'value-Creator',    with: fields[:dc_creator]
        fill_in 'value-Comments',   with: fields[:rem_comments]

        # Create the item.
        show_item { 'Creating EMMA submission...' }
        form_submit

        # Verify successful submission.
        wait_for_page(final_url)
        assert_valid_page(heading: TITLE)
        assert_flash('Created EMMA entry')

        # There should be one more item than before on the index page.
        visit final_url.first unless final_url.include?(current_url)
        assert_search_count(CTRLR, expected: total.succ)   if total
        assert_model_count( MODEL, expected: records.succ) if records

      elsif user

        show_item { "User '#{user}' blocked from creating submission." }
        assert_no_visit(form_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from creating submission.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

  # Perform a test to select then modify an EMMA submission.
  #
  # @param [User, nil]   user
  # @param [Symbol, nil] meth         Calling test method.
  # @param [Hash]        opt          Added to URL parameters.
  #
  # @return [void]
  #
  def edit_test(user, meth: nil, **opt)
    button   = 'Change'
    action   = :edit
    params   = PRM.merge(action: action, **opt)

    # Find the item to be edited.
    record   = user&.uploads&.find(&:completed?) || uploads(:edit_example)
    form_url = form_page_url(record.id, **params)

    run_test(meth || __method__) do

      if permitted?(action, user, record)

        admin     = user.administrator?
        records   = (fixture_count(MODEL) if admin)
        total     = (fixture_count_for_user(MODEL, user) unless records)

        index_url = url_for(**params, action: :index)
        all_url   = url_for(**params, action: :list_all)
        own_url   = url_for(**params, action: :list_own)
        org_url   = url_for(**params, action: :list_org)
        menu_url  = url_for(**params, action: menu_action(action))

        start_url = index_url
        final_url = [index_url, all_url, own_url, org_url]

        # Generate new field data for the item to edit.
        tag       = user&.role&.upcase || 'ANON'
        fields    = @generate.fields(record, tag: tag)
        item_name = Upload.make_label(record)

        # Start on the index page showing the current number of items.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Go to the menu page and choose the item to edit.
        select_action(button, wait_for: menu_url)
        select_item(item_name, wait_for: form_url)

        # On the form page a Manager or Administrator should see the
        # "Submitter" menu with their account pre-selected.
        if admin || user.manager?
          assert_selector '[data-field="user_id"]', text: user.email
        end

        # Modify field data.
        fill_in 'value-Title',   with: fields[:dc_title]
        fill_in 'value-Creator', with: fields[:dc_creator]

        # Update the item.
        show_item { "Updating #{item_name.inspect}..." }
        form_submit

        # Verify that success was indicated back on the menu page.
        wait_for_page(menu_url)
        assert_flash('Updated EMMA entry')

        # There should be the same number of items as before on the index page.
        visit final_url.first unless final_url.include?(current_url)
        assert_valid_page(heading: TITLE)
        assert_search_count(CTRLR, expected: total)   if total
        assert_model_count( MODEL, expected: records) if records

      elsif user

        show_item { "User '#{user}' blocked from modifying submission." }
        assert_no_visit(form_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from modifying submission.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

  # Perform a test to select then remove an EMMA submission.
  #
  # @param [User, nil]   user
  # @param [Symbol, nil] meth         Calling test method.
  # @param [Hash]        opt          Added to URL parameters.
  #
  # @return [void]
  #
  def delete_test(user, meth: nil, **opt)
    button   = 'Remove'
    action   = :delete
    params   = PRM.merge(action: action, **opt)

    # Generate a new item to be deleted.
    tag      = user&.role&.upcase || 'ANON'
    record   = @generate.new_record_for(action, tag: tag)
    form_url = form_page_url(record.id, **params)

    run_test(meth || __method__) do

      if permitted?(action, user, record)

        admin     = user.administrator?
        records   = (fixture_count(MODEL).succ if admin)
        total     = (fixture_count_for_user(MODEL, user).succ unless records)

        index_url = url_for(**params, action: :index)
        all_url   = url_for(**params, action: :list_all)
        own_url   = url_for(**params, action: :list_own)
        org_url   = url_for(**params, action: :list_org)
        menu_url  = url_for(**params, action: menu_action(action))

        start_url = index_url
        final_url = [index_url, all_url, own_url, org_url]

        # Identify the item to be deleted.
        item_name = record.menu_label
        reindex(record)

        # Start on the index page showing the current number of items.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Go to the menu page and choose the item to remove.
        select_action(button, wait_for: menu_url)
        select_item(item_name, wait_for: form_url)

        # Delete the selected item.
        show_item { "Removing EMMA submission #{item_name.inspect}..." }
        form_submit

        # Verify that success was indicated back on the menu page.
        wait_for_page(menu_url)
        assert_flash('Removed EMMA entry')

        # On the index page, there should be one less record than before.
        visit final_url.first unless final_url.include?(current_url)
        assert_search_count(CTRLR, expected: total.pred)   if total
        assert_model_count( MODEL, expected: records.pred) if records

      elsif user

        show_item { "User '#{user}' blocked from removing submission." }
        assert_no_visit(form_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from removing submission.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

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
