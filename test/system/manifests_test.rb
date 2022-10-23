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

  TEST_USER   = :emmadso

  # noinspection RbsMissingTypeSignature
  setup do
    @user  = find_user(TEST_USER)
    @total = fixture_count(MODEL)
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

    start_url, tag = direct ? [form_url, 'DIRECT'] : [index_url, 'INDIRECT']

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
        click_on 'Create'
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
    params    = PARAMS.merge(action: action, **opt)

    index_url = url_for(**params, action: :index)
    menu_url  = url_for(**params, id: 'SELECT')
    alt_url   = File.join(index_url, "#{action}_select")
    menu      = [menu_url, alt_url]

    start_url, tag = direct ? [menu_url, 'DIRECT'] : [index_url, 'INDIRECT']

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
        wait_for_page menu
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
    params    = PARAMS.merge(action: action, **opt)

    index_url = url_for(**params, action: :index)
    menu_url  = url_for(**params, id: 'SELECT')
    alt_url   = File.join(index_url, "#{action}_select")
    menu      = [menu_url, alt_url]

    start_url, tag = direct ? [menu_url, 'DIRECT'] : [index_url, 'INDIRECT']

    # Add Manifest copy to be deleted.
    item = manifests(:delete_example)
    item =
      Manifest.new(item.fields.except(:id)).tap do |rec|
        rec.update!(name: "#{item.name} - #{tag}")
      end

    item_delete = [
      url_for(**params, id: item.id),
      make_path(alt_url, selected: item.id)
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
        wait_for_page menu
      end

      # Choose submission to remove, which leads to the delete page.
      select item.name, from: 'selected'
      wait_for_page item_delete
      success_screenshot

      # After deletion we should be back on the previous page.
      click_on 'Delete', match: :first, exact: true
      wait_for_page menu
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

  # Check operation of Manifest information display/edit.
  #
  # @param [Hash] opt                 Test options
  #
  # @return [void]
  #
  def manifest_title_test(**opt)
    # TODO: manifest_title_test
    action, item, name, tag, unique = extract_options!(opt)
    name ||= item.name
    name  += " (#{action})" if action
    title  = [name, unique, tag].compact.join(' - ')
=begin
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
    # TODO: manifest_grid_test
    _action, _item, _name, _tag, _unique = extract_options!(opt)
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

  # Extract named value entries from *opt*.
  #
  # @param [Hash]          opt        Source hash to modify.
  # @param [Array<Symbol>] names      Value entry keys.
  #
  # @return [Array]
  #
  def extract_options!(opt, *names)
    names = %i[action item name tag unique] if names.empty?
    extract_hash!(opt, *names).values_at(*names)
  end

end
