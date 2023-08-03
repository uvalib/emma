# test/system/uploads_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class UploadsTest < ApplicationSystemTestCase

  MODEL       = Upload
  CONTROLLER  = :upload
  PARAMS      = { controller: CONTROLLER }.freeze
  INDEX_TITLE = page_title(**PARAMS, action: :index).freeze

  TEST_USER   = :test_dso

  setup do
    @user  = find_user(TEST_USER)
    @total = fixture_count(MODEL)
    @file  = file_fixture(UPLOAD_FILE)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'uploads - visit index' do

    action = :index
    params = PARAMS.merge(action: action)
    url    = url_for(**params)

    run_test(__method__) do

      # Not available anonymously; successful sign-in should redirect back.
      visit url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user

      # The listing should be the first of one or more results pages with as
      # many entries as there are fixture records.
      show_url
      assert_current_url url
      assert_valid_page heading: INDEX_TITLE
      assert_search_count(CONTROLLER, total: @total)
      success_screenshot

    end

  end

  test 'uploads - show' do

    action = :show
    item   = uploads(:emma_completed)
    file   = item.filename
    params = PARAMS.merge(action: action, id: item.id)
    url    = url_for(**params)

    title  = "Uploaded file #{file.inspect}"

    run_test(__method__) do

      # Details of a single upload submission are available anonymously.
      visit url

      # The page should show the details of the submission.
      show_url
      assert_current_url url
      assert_valid_page heading: title
      success_screenshot

    end

  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'uploads - new' do
    new_test(direct: true, meth: __method__)
  end

  test 'uploads - new from index' do
    new_test(direct: false, meth: __method__)
  end

  test 'uploads - edit (select)' do
    edit_select_test(direct: true, meth: __method__)
  end

  test 'uploads - edit (select) from index' do
    edit_select_test(direct: false, meth: __method__)
  end

  test 'uploads - delete (select)' do
    delete_select_test(direct: true, meth: __method__)
  end

  test 'uploads - delete (select) from index' do
    delete_select_test(direct: false, meth: __method__)
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  public

  # new_test
  #
  # @param [Boolean] direct
  # @param [Symbol]  meth             Calling test method.
  # @param [Hash]    opt              Added to URL parameters.
  #
  # @return [void]
  #
  def new_test(direct:, meth: nil, **opt)
    meth    ||= __method__
    action    = :new
    params    = PARAMS.merge(action: action, **opt)
    prefix    = "#{TITLE_PREFIX} - "

    form_url  = url_for(**params)
    index_url = url_for(**params, action: :index)

    start_url, tag = direct ? [form_url, 'DIRECT'] : [index_url, 'INDIRECT']

    title     = 'New Upload'
    author    = "#{title} Author"
    title     = "#{prefix} #{title}" unless title.start_with?(prefix)

    # noinspection RubyMismatchedArgumentType
    run_test(meth) do

      # Not available anonymously; successful sign-in should redirect back.
      visit start_url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user

      # Change to the form page if coming in from the index page.
      unless direct
        click_on 'Create'
        wait_for_page form_url
      end

      # On the form page:
      assert_selector '[data-field="user_id"]', visible: false#, text: @user&.id # TODO: why is this not filled?

      # Provide file and wait for data extraction.
      attach_file(@file) { click_on 'Select file' }
      assert_selector '.uploaded-filename.complete', wait: 5

      # Add field data.
      select 'EMMA',            from: 'field-Repository'
      select 'Moving Image',    from: 'field-Type'
      select 'True',            from: 'field-Complete'
      select 'Born Accessible', from: 'field-Status'
      check  'Armenian'         # inside 'field-Language'
      fill_in 'field-Identifier', with: '' # remove bogus identifier
      fill_in 'field-Title',      with: "#{title } - #{tag}"
      fill_in 'field-Creator',    with: "#{author} - #{tag}"
      fill_in 'field-Comments',   with: 'FAKE - do not use'

      # If all required fields have been filled then submit will be visible.
      send_keys :tab # Bypass debounce delay by inducing a 'change' event.
      success_screenshot
      click_on 'Upload', match: :first, exact: true

      # Should be back on the index page with one more record than before.
      wait_for_page index_url
      assert_flash 'SUCCESS'
      assert_valid_page heading: INDEX_TITLE
      assert_search_count(CONTROLLER, total: (@total += 1))

    end
  end

  # edit_select_test
  #
  # @param [Boolean] direct
  # @param [Symbol]  meth             Calling test method.
  # @param [Hash]    opt              Added to URL parameters.
  #
  # @return [void]
  #
  def edit_select_test(direct:, meth: nil, **opt)
    meth    ||= __method__
    action    = :edit
    params    = PARAMS.merge(action: action, **opt)
    select    = menu_action(action)
    prefix    = "#{TITLE_PREFIX} - "

    index_url = url_for(**params, action: :index)
    menu_url  = url_for(**params, action: select)

    start_url, tag = direct ? [menu_url, 'DIRECT'] : [index_url, 'INDIRECT']

    item      = uploads(:edit_example)
    author    = item.emma_metadata[:dc_creator]
    title     = item.emma_metadata[:dc_title]
    title     = "#{title} (#{action})"
    title     = "#{prefix} #{title}" unless title.start_with?(prefix)
    unique    = hex_rand

    # noinspection RubyMismatchedArgumentType
    run_test(meth) do

      # Not available anonymously; successful sign-in should redirect back.
      visit start_url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user

      # Change to the select menu if coming in from the index page.
      unless direct
        click_on 'Change'
        wait_for_page menu_url
      end

      # Choose submission to edit.
      select item.id, from: 'selected'

      # On the form page:
      assert_selector '[data-field="user_id"]', visible: false#, text: @user&.id # TODO: why is this not filled?

      # Replace field data.
      fill_in 'field-Title',   with: "#{title } - #{unique} - #{tag}"
      fill_in 'field-Creator', with: "#{author} - #{unique} - #{tag}"

      # If all required fields have been filled then submit will be visible.
      send_keys :tab # Bypass debounce delay by inducing a 'change' event.
      success_screenshot
      click_on 'Update', match: :first, exact: true

      # The index page should still show the same number of records.
      assert_flash 'SUCCESS'
      if direct
        visit index_url
      else
        wait_for_page index_url
      end
      assert_valid_page heading: INDEX_TITLE
      assert_search_count(CONTROLLER, total: @total)

    end
  end

  # delete_select_test
  #
  # @param [Boolean] direct
  # @param [Symbol]  meth             Calling test method.
  # @param [Hash]    opt              Added to URL parameters.
  #
  # @return [void]
  #
  def delete_select_test(direct:, meth: nil, **opt)
    meth    ||= __method__
    action    = :delete
    select    = menu_action(action)
    params    = PARAMS.merge(action: action, **opt)

    index_url = url_for(**params, action: :index)
    menu_url  = url_for(**params, action: select)

    start_url, tag = direct ? [menu_url, 'DIRECT'] : [index_url, 'INDIRECT']

    # Add Upload copy to be deleted and ensure that it is in the EMMA Unified
    # Index.
    item = uploads(:delete_example)
    item =
      Upload.new(item.fields.except(:id)).tap do |rec|
        title = rec.emma_metadata[:dc_title]
        rec.update!(dc_title: "#{title} - #{tag}")
        reindex(rec)
      end

    item_delete = [
      url_for(**params, id: item.id),
      make_path(url_for(**params), id: item.id)
    ]

    # noinspection RubyMismatchedArgumentType
    run_test(meth) do

      # Verify added copies on the index page.
      visit index_url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user
      assert_search_count(CONTROLLER, total: (@total += 1))

      # Change to the select menu if coming in from the index page.
      visit start_url
      unless direct
        click_on 'Remove'
        wait_for_page menu_url
      end

      # Choose submission to remove, which leads to the delete page.
      select item.id, from: 'selected'
      wait_for_page item_delete
      success_screenshot
      click_on 'Delete', match: :first, exact: true

      # Should be back on the menu page.
      wait_for_page menu_url
      assert_flash 'SUCCESS'

      # The index page should still show one less record than before.
      visit index_url
      wait_for_page index_url
      assert_valid_page heading: INDEX_TITLE
      assert_search_count(CONTROLLER, total: (@total -= 1))

    end
  end

end
