# test/system/manifests_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class ManifestsTest < ApplicationSystemTestCase

  MODEL       = Manifest
  CONTROLLER  = :manifest
  PARAMS      = { controller: CONTROLLER }.freeze
  INDEX_TITLE = page_title(**PARAMS, action: :index).freeze

  TEST_USER   = :test_dso_1

  setup do
    @user  = find_user(TEST_USER)
=begin # TODO: this is what we want:
    @total = fixture_count_for_org(MODEL, @user)
=end # NOTE: this is what's actually implemented right now:
    @total = fixture_count_for_user(MODEL, @user)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'manifests - visit index' do

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

  test 'manifests - show' do

    action = :show
    item   = manifests(:example)
    params = PARAMS.merge(action: action, id: item.id)
    url    = url_for(**params)

    title  = page_title(item, **params)

    run_test(__method__) do

      # Not available anonymously; successful sign-in should redirect back.
      visit url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user

      # The page should show the details of the manifest.
      show_url
      assert_current_url url
      assert_valid_page heading: title
      success_screenshot

    end

  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'manifests - new' do
    new_test(direct: true, meth: __method__)
  end

  test 'manifests - new from index' do
    new_test(direct: false, meth: __method__)
  end

  test 'manifests - edit (select)' do
    edit_select_test(direct: true, meth: __method__)
  end

  test 'manifests - edit (select) from index' do
    edit_select_test(direct: false, meth: __method__)
  end

  test 'manifests - delete (select)' do
    delete_select_test(direct: true, meth: __method__)
  end

  test 'manifests - delete (select) from index' do
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

    form_url  = url_for(**params)
    index_url = url_for(**params, action: :index)

    start_url = direct ? form_url : index_url
    tag       = direct ? 'DIRECT' : 'INDIRECT'

    item      = manifests(:example)
    test_opt  = { action: action, tag: tag, item: item, name: 'New manifest' }

    # noinspection RubyMismatchedArgumentType
    run_test(meth) do

      # Start at the default page.
      visit root_url

      # Not available anonymously; successful sign-in should redirect back.
      visit start_url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user

      # Change to the form page if coming in from the index page.
      unless direct
        click_on 'Create', match: :first
        wait_for_page form_url
      end

      # Test functionality.
      manifest_title_test(**test_opt)
      manifest_grid_test(**test_opt)

=begin
      # If all required fields have been filled then submit will be visible.
      send_keys :tab # Bypass debounce delay by inducing a 'change' event.
      success_screenshot
      click_on 'Save', match: :first, exact: true

      # Should be back on the index page with one more record than before.
      wait_for_page index_url
      assert_flash 'SUCCESS'
      assert_valid_page heading: INDEX_TITLE
      assert_search_count(CONTROLLER, total: (@total += 1))
=end

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
    select    = menu_action(action)
    params    = PARAMS.merge(action: action, **opt)

    index_url = url_for(**params, action: :index)
    menu_url  = url_for(**params, action: select)

    start_url = direct ? menu_url : index_url
    tag       = direct ? 'DIRECT' : 'INDIRECT'

    item      = manifests(:edit_example)
    test_opt  = { action: action, tag: tag, item: item, unique: hex_rand }

    # noinspection RubyMismatchedArgumentType
    run_test(meth) do

      # Start at the default page.
      visit root_url

      # Not available anonymously; successful sign-in should redirect back.
      visit start_url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user

      # Change to the select menu if coming in from the index page.
      unless direct
        click_on 'Change'
        wait_for_page menu_url
      end

      # Choose manifest to edit.
      select item.name, from: 'selected'

      # Test functionality.
      manifest_title_test(**test_opt)
      manifest_grid_test(**test_opt)

=begin
      # If all required fields have been filled then submit will be visible.
      send_keys :tab # Bypass debounce delay by inducing a 'change' event.
      success_screenshot
      click_on 'Save', match: :first, exact: true

      # Should be back on the index page with the same number of records.
      wait_for_page index_url
      assert_flash 'SUCCESS'
      assert_valid_page heading: INDEX_TITLE
      assert_search_count(CONTROLLER, total: @total)
=end

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

    start_url = direct ? menu_url : index_url
    tag       = direct ? 'DIRECT' : 'INDIRECT'

    item      = manifests(:delete_example)
    test_opt  = { action: action, tag: tag, item: item, unique: hex_rand }

    # Add Manifest copy to be deleted.
    name = manifest_name(**test_opt)
    attr = item.fields.except(:id).merge!(name: name)
    item = Manifest.create!(attr)

    item_delete = [
      url_for(**params, id: item.id),
      make_path(url_for(**params), id: item.id)
    ]

    # noinspection RubyMismatchedArgumentType
    run_test(meth) do

      # Start at the default page.
      visit root_url

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
      select item.name, from: 'selected'
      wait_for_page item_delete
      success_screenshot

      # After deletion we should be back on the previous page.
      click_on 'Delete', match: :first, exact: true
      wait_for_page menu_url
      assert_flash 'SUCCESS'

      # On the index page, there should be one less record than before.
      visit index_url
      assert_valid_page heading: INDEX_TITLE
      assert_search_count(CONTROLLER, total: (@total -= 1))

    end
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  protected

  # Generate a Manifest :name.
  #
  # @param [Hash] opt                 Test options
  #
  # @return [String]
  #
  def manifest_name(**opt)
    opt[:name] ||= opt[:item].name      if opt[:item]
    opt[:name]  += " (#{opt[:action]})" if opt[:action]
    opt.slice(:name, :unique, :tag).compact.values.join(' - ')
  end

  # Check operation of Manifest information display/edit.
  #
  # @param [Hash] opt                 Test options
  #
  # @return [void]
  #
  def manifest_title_test(**opt)
    _title = manifest_name(**opt)
=begin # TODO: manifest_title_test

    # On the form page:
    assert_selector '[data-field="user_id"]', visible: false#, text: @user&.id

    # Replace field data.
    fill_in 'Title', with: title
=end
  end

  # Check operation of ManifestItem grid.
  #
  # @param [Hash] opt                 Test options
  #
  # @return [void]
  #
  def manifest_grid_test(**opt)
    _title = manifest_name(**opt)
=begin # TODO: manifest_grid_test

    # If all required fields have been filled then submit will be visible.
    send_keys :tab # Bypass debounce delay by inducing a 'change' event.
    success_screenshot
    click_on 'Save', match: :first, exact: true

    # Should be back on the index page with the same number of records.
    wait_for_page index_url
    assert_flash 'SUCCESS'
    assert_valid_page heading: INDEX_TITLE
    assert_search_count(CONTROLLER, total: @total)
=end
  end

end
