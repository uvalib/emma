# test/system/downloads_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class DownloadsTest < ApplicationSystemTestCase

  MODEL = Download
  CTRLR = :download
  PRM   = { controller: CTRLR }.freeze
  TITLE = page_title(**PRM, action: :index).freeze

  setup do
    @dev      = find_user(:test_dev)
    @admin    = find_user(:test_adm)
    @manager  = find_user(:test_man_1)
    @member   = find_user(:test_dso_1)
    @generate = DownloadSampleGenerator.new(self)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'downloads - index - anonymous' do
    list_test(nil, meth: __method__)
  end

  test 'downloads - index - member' do
    list_test(@member, meth: __method__)
  end

  test 'downloads - index - manager' do
    list_test(@manager, meth: __method__)
  end

  test 'downloads - index - admin' do
    list_test(@admin, meth: __method__)
  end

  test 'downloads - index - dev' do
    list_test(@dev, meth: __method__)
  end

  test 'downloads - list_all - anonymous' do
    list_test(nil, meth: __method__, action: :list_all)
  end

  test 'downloads - list_all - member' do
    list_test(@member, meth: __method__, action: :list_all)
  end

  test 'downloads - list_all - manager' do
    list_test(@manager, meth: __method__, action: :list_all)
  end

  test 'downloads - list_all - admin' do
    list_test(@admin, meth: __method__, action: :list_all)
  end

  test 'downloads - list_all - dev' do
    list_test(@dev, meth: __method__, action: :list_all)
  end

  test 'downloads - list_org - anonymous' do
    list_test(nil, meth: __method__, action: :list_org)
  end

  test 'downloads - list_org - member' do
    list_test(@member, meth: __method__, action: :list_org)
  end

  test 'downloads - list_org - manager' do
    list_test(@manager, meth: __method__, action: :list_org)
  end

  test 'downloads - list_org - admin' do
    list_test(@admin, meth: __method__, action: :list_org)
  end

  test 'downloads - list_org - dev' do
    list_test(@dev, meth: __method__, action: :list_org)
  end

  test 'downloads - list_own - anonymous' do
    list_test(nil, meth: __method__, action: :list_own)
  end

  test 'downloads - list_own - member' do
    list_test(@member, meth: __method__, action: :list_own)
  end

  test 'downloads - list_own - manager' do
    list_test(@manager, meth: __method__, action: :list_own)
  end

  test 'downloads - list_own - admin' do
    list_test(@admin, meth: __method__, action: :list_own)
  end

  test 'downloads - list_own - dev' do
    list_test(@dev, meth: __method__, action: :list_own)
  end

  test 'downloads - show - anonymous' do
    show_test(nil, meth: __method__)
  end

  test 'downloads - show - member' do
    show_test(@member, meth: __method__)
  end

  test 'downloads - show - manager' do
    show_test(@manager, meth: __method__)
  end

  test 'downloads - show - admin' do
    show_test(@admin, meth: __method__)
  end

  test 'downloads - show - dev' do
    show_test(@dev, meth: __method__)
  end

  test 'downloads - show_select - anonymous' do
    show_select_test(nil, meth: __method__)
  end

  test 'downloads - show_select - member' do
    show_select_test(@member, meth: __method__)
  end

  test 'downloads - show_select - manager' do
    show_select_test(@manager, meth: __method__)
  end

  test 'downloads - show_select - admin' do
    show_select_test(@admin, meth: __method__)
  end

  test 'downloads - show_select - dev' do
    show_select_test(@dev, meth: __method__)
  end

  test 'downloads - edit_select - anonymous' do
    edit_select_test(nil, meth: __method__)
  end

  test 'downloads - edit_select - member' do
    edit_select_test(@member, meth: __method__)
  end

  test 'downloads - edit_select - manager' do
    edit_select_test(@manager, meth: __method__)
  end

  test 'downloads - edit_select - admin' do
    edit_select_test(@admin, meth: __method__)
  end

  test 'downloads - edit_select - dev' do
    edit_select_test(@dev, meth: __method__)
  end

  test 'downloads - delete_select - anonymous' do
    delete_select_test(nil, meth: __method__)
  end

  test 'downloads - delete_select - member' do
    delete_select_test(@member, meth: __method__)
  end

  test 'downloads - delete_select - manager' do
    delete_select_test(@manager, meth: __method__)
  end

  test 'downloads - delete_select - admin' do
    delete_select_test(@admin, meth: __method__)
  end

  test 'downloads - delete_select - dev' do
    delete_select_test(@dev, meth: __method__)
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'downloads - register' do
    # TODO: download registration test
    # This will require setting up a search result entry that actually has a
    # file that the test system can deliver, then performing a search to
    # display the associated entry, clicking on the link to cause a download,
    # and then checking the expected entry in the 'downloads' table.
  end

  test 'downloads - new - anonymous' do
    new_test(nil, meth: __method__)
  end

  test 'downloads - new - member' do
    new_test(@member, meth: __method__)
  end

  test 'downloads - new - manager' do
    new_test(@manager, meth: __method__)
  end

  test 'downloads - new - admin' do
    new_test(@admin, meth: __method__)
  end

  test 'downloads - new - dev' do
    new_test(@dev, meth: __method__)
  end

  test 'downloads - edit - anonymous' do
    edit_test(nil, meth: __method__)
  end

  test 'downloads - edit - member' do
    edit_test(@member, meth: __method__)
  end

  test 'downloads - edit - manager' do
    edit_test(@manager, meth: __method__)
  end

  test 'downloads - edit - admin' do
    edit_test(@admin, meth: __method__)
  end

  test 'downloads - edit - dev' do
    edit_test(@dev, meth: __method__)
  end

  test 'downloads - delete - anonymous' do
    delete_test(nil, meth: __method__)
  end

  test 'downloads - delete - member' do
    delete_test(@member, meth: __method__)
  end

  test 'downloads - delete - manager' do
    delete_test(@manager, meth: __method__)
  end

  test 'downloads - delete - admin' do
    delete_test(@admin, meth: __method__)
  end

  test 'downloads - delete - dev' do
    delete_test(@dev, meth: __method__)
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'downloads system test coverage' do
    skipped = []
    check_system_coverage DownloadController, except: skipped
  end

  # ===========================================================================
  # :section: Methods - read tests
  # ===========================================================================

  protected

  # Perform a test to list download events visible to *user*.
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

        list_org  = (action == :list_org)
        list_own  = (action == :list_own)

        title   ||= page_title(**params, name: user&.org&.long_name)
        total   ||= fixture_count_for_user(MODEL, user) if list_own
        total   ||= fixture_count_for_org(MODEL, user)  if list_org
        total   ||= fixture_count(MODEL)

        final_url = start_url

        # Successful sign-in should redirect back to the action page.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # The listing should be the first of one or more results pages with as
        # many entries as there are download events visible to the user.
        show_url
        screenshot
        assert_current_url(final_url)
        assert_valid_page(heading: title)
        data_record_total(expected: total)

        # Validate the table of download events.
        check_item_table(section: true)

      elsif user

        show_item { "User '#{user}' blocked from listing download events." }
        assert_no_visit(start_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from listing download events.' }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

  # Perform a test to show a download event visible to *user*.
  #
  # @param [User, nil]     user
  # @param [Download, nil] target
  # @param [Symbol]        meth       Calling test method.
  # @param [Hash]          opt        URL parameters.
  #
  # @return [void]
  #
  def show_test(user, target: nil, meth: nil, **opt)
    target  ||= downloads(:example)
    params    = PRM.merge(action: :show, id: target.id, **opt)
    action    = params[:action]

    start_url = url_for(**params)

    run_test(meth || __method__) do

      if permitted?(action, user, target)

        final_url = start_url

        # Successful sign-in should redirect back to the action page.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # The page should show the details of the target download event.
        show_url
        screenshot
        assert_current_url(final_url)

        # Validate page contents.
        check_details_columns('.download-details')

      elsif user

        show_item { "User '#{user}' blocked from viewing download events." }
        assert_no_visit(start_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from viewing download events.' }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

  # Perform a test to invoke the menu for selecting a download to display.
  #
  # @param [User, nil] user
  # @param [Hash]      opt            Passed to #page_select_test.
  #
  # @return [void]
  #
  def show_select_test(user, **opt)
    page_select_test(user, action: :show, **opt)
  end

  # Perform a test to invoke the menu for selecting a download event to modify.
  #
  # @param [User, nil] user
  # @param [Hash]      opt            Passed to #page_select_test.
  #
  # @return [void]
  #
  def edit_select_test(user, **opt)
    page_select_test(user, action: :edit, **opt)
  end

  # Perform a test to invoke the menu for selecting a download event to remove.
  #
  # @param [User, nil] user
  # @param [Hash]      opt            Passed to #page_select_test.
  #
  # @return [void]
  #
  def delete_select_test(user, **opt)
    page_select_test(user, action: :delete, **opt)
  end

  # Perform a test to invoke the menu for selecting a download event.
  #
  # @param [User, nil]   user
  # @param [Symbol]      action
  # @param [String, nil] title
  # @param [Symbol]      meth         Calling test method.
  # @param [Hash]        opt          URL parameters.
  #
  # @return [void]
  #
  def page_select_test(user, action:, title: nil, meth: nil, **opt)
    form_url  = url_for(**PRM, action: action)
    action    = :"#{action}_select"
    params    = PRM.merge(action: action, **opt)

    start_url = url_for(**params)

    run_test(meth || __method__) do

      if permitted?(action, user)

        title   ||= page_title(**params, name: '')

        final_url = start_url

        # Successful sign-in should redirect back to the action page.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # The page should show a menu of download events.
        show_url
        screenshot
        assert_current_url(final_url)
        assert_valid_page(heading: title)

        # Check that the menu contains only download events visible to user.
        check_page_select_menu(count: fixture_count(MODEL), action: form_url)

      elsif user

        show_item { "User '#{user}' blocked from #{action} download event." }
        assert_no_visit(start_url, action, as: user)

      else

        show_item { "Anonymous user blocked from #{action} download event." }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

  # ===========================================================================
  # :section: Methods - write tests
  # ===========================================================================

  protected

  # Perform a test to create a new download event.
  #
  # Because :record and :link fields in "en.emma.page.download.display_fields"
  # are made developer-only, those fields do not appear in the form for
  # users with the Administrator role.
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

        dev       = user&.developer?
        records   = fixture_count(MODEL)

        index_url = url_for(**params, action: :index)
        all_url   = url_for(**params, action: :list_all)

        start_url = index_url
        final_url = [index_url, all_url]

        # Generate field data for the item to create.
        name   = 'New Download Event'
        tag    = user&.role&.upcase || 'ANON'
        fields = @generate.fields_for(action, tag: tag, base: name).except(:id)
        name   = fields[:id]

        # Start on the index page showing the current number of items.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Go to the form page.
        if dev
          select_action(button, wait_for: form_url)
        else
          visit url_for(**params)
        end

        # Add field data.
        fill_in 'value-User',       with: fields[:user]
        fill_in 'value-Source',     with: fields[:source]
        fill_in 'value-Record',     with: fields[:record] if dev
        fill_in 'value-Fmt',        with: fields[:fmt]
        fill_in 'value-Publisher',  with: fields[:publisher]
        fill_in 'value-Link',       with: fields[:link] if dev
        fill_in 'value-CreatedAt',  with: fields[:created_at] || DateTime.now

        # Create the item.
        show_item { "Creating download event #{name.inspect}..." }
        form_submit

        # Verify successful submission.
        wait_for_page(final_url)
        assert_valid_page(heading: TITLE)
        assert_flash('SUCCESS')

        # There should be one more item than before on the index page.
        visit final_url.first unless final_url.include?(current_url)
        assert_model_count(MODEL, expected: records.succ)

      elsif user

        show_item { "User '#{user}' blocked from creating download event." }
        assert_no_visit(form_url, :admin_only, as: user)

      else

        show_item { 'Anonymous user blocked from creating download event.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

  # Perform a test to select then modify a download event.
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
    record   = downloads(:edit_example)
    form_url = form_page_url(record.id, **params)

    run_test(meth || __method__) do

      if permitted?(action, user, record)

        dev       = user&.developer?
        records   = fixture_count(MODEL)

        index_url = url_for(**params, action: :index)
        all_url   = url_for(**params, action: :list_all)
        menu_url  = url_for(**params, action: menu_action(action))

        start_url = index_url
        final_url = [index_url, all_url]

        # Generate new field data for the item to edit.
        tag       = user&.role&.upcase || 'ANON'
        fields    = @generate.fields(record, tag: tag)
        item_name = record.id

        # Start on the index page showing the current number of items.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Go to the menu page and choose the item to edit.
        if dev
          select_action(button, wait_for: menu_url)
        else
          visit url_for(**params)
        end
        select_item(item_name, wait_for: form_url)
        result_page = menu_url
        final_title = TITLE

        # Modify field data.
        fill_in 'value-Publisher', with: fields[:publisher]

        # Update the item.
        show_item { "Updating download event #{item_name.inspect}..." }
        form_submit

        # Verify that success was indicated back on the menu page.
        wait_for_page(result_page)
        assert_flash('successfully updated')

        # There should be the same number of items as before on the index page.
        visit final_url.first unless final_url.include?(current_url)
        assert_valid_page(heading: final_title)
        assert_model_count(MODEL, expected: records)

      elsif user

        show_item { "User '#{user}' blocked from modifying download event." }
        assert_no_visit(form_url, :admin_only, as: user)

      else

        show_item { 'Anonymous user blocked from modifying download event.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

  # Perform a test to select then remove a download event.
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

        dev       = user&.developer?
        records   = fixture_count(MODEL).succ

        index_url = url_for(**params, action: :index)
        all_url   = url_for(**params, action: :list_all)
        menu_url  = url_for(**params, action: menu_action(action))

        start_url = index_url
        final_url = [index_url, all_url]

        # Identify the item to be deleted.
        item_name = record.id

        # Start on the index page showing the current number of items.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Go to the menu page and choose the item to remove.
        if dev
          select_action(button, wait_for: menu_url)
        else
          visit url_for(**params)
        end
        select_item(item_name, wait_for: form_url)

        # Delete the selected item.
        show_item { "Removing download event #{item_name.inspect}..." }
        form_submit

        # Verify that success was indicated back on the menu page.
        wait_for_page(menu_url)
        assert_flash('successfully removed')

        # On the index page, there should be one less record than before.
        visit final_url.first unless final_url.include?(current_url)
        assert_valid_page(heading: TITLE)
        assert_model_count(MODEL, expected: records.pred)

      elsif user

        show_item { "User '#{user}' blocked from removing download event." }
        assert_no_visit(form_url, :admin_only, as: user)

      else

        show_item { 'Anonymous user blocked from removing download event.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

end
