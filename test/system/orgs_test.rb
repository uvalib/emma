# test/system/orgs_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class OrgsTest < ApplicationSystemTestCase

  MODEL       = Org
  CONTROLLER  = :org
  PARAMS      = { controller: CONTROLLER }.freeze
  INDEX_TITLE = page_title(**PARAMS, action: :index).freeze

  TEST_USER   = :test_adm

  setup do
    @user = find_user(TEST_USER)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'orgs - visit index' do

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
      success_screenshot

    end

  end

  test 'orgs - show' do

    action = :show
    item   = orgs(:example)
    params = PARAMS.merge(action: action, id: item.id)
    url    = url_for(**params)

    title  = page_title(item, **params)

    run_test(__method__) do

      # Not available anonymously; successful sign-in should redirect back.
      visit url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user

      # The page should show the details of the org.
      show_url
      assert_current_url url
      assert_valid_page heading: title
      success_screenshot

    end

  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'orgs - new' do
    new_test(direct: true, meth: __method__)
  end

  test 'orgs - new from index' do
    new_test(direct: false, meth: __method__)
  end

  test 'orgs - edit (select)' do
    edit_select_test(direct: true, meth: __method__)
  end

  test 'orgs - edit (select) from index' do
    edit_select_test(direct: false, meth: __method__)
  end

  test 'orgs - delete (select)' do
    delete_select_test(direct: true, meth: __method__)
  end

  test 'orgs - delete (select) from index' do
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

    item      = orgs(:one)
    test_opt  = { action: action, tag: tag, item: item, unique: hex_rand }

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

      # Add field data.
      fill_in 'field-ShortName', with: 'NU'
      fill_in 'field-LongName',  with: org_name(**test_opt)
      fill_in 'field-IpDomain',  with: 'new_university.edu'
      fill_in 'field-Contact',   with: 'test_adm@new_university.edu'
=begin # TODO: fix evaluation of field role
      # noinspection RubyMismatchedArgumentType
      select 'Incomplete', from: 'field-Status'   if @user.administrator?
=end
      select 'Shibboleth', from: 'field-Provider'

      # If all required fields have been filled then submit will be visible.
      send_keys :tab # Bypass debounce delay by inducing a 'change' event.
      success_screenshot
      click_on class: 'submit-button', match: :first

      # Should be back on the index page with one more record than before.
      wait_for_page index_url
      assert_flash 'SUCCESS'
      assert_valid_page heading: INDEX_TITLE

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

    item      = orgs(:edit_example)
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

      # Choose org to edit.
      select item.long_name, from: 'selected'

      # Replace field data.
      fill_in 'field-LongName', with: org_name(**test_opt)

      # If all required fields have been filled then submit will be visible.
      send_keys :tab # Bypass debounce delay by inducing a 'change' event.
      success_screenshot
      click_on class: 'submit-button', match: :first

      # The index page should still show the same number of records.
      assert_flash 'SUCCESS'
      if direct
        visit index_url
      else
        wait_for_page index_url
      end
      assert_valid_page heading: INDEX_TITLE

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

    item      = orgs(:delete_example)
    test_opt  = { action: action, tag: tag, item: item, unique: hex_rand }

    # Add Org copy to be deleted.
    name = org_name(**test_opt)
    attr = item.fields.except(:id).merge!(long_name: name)
    item = Org.create!(attr)

    item_delete = [
      url_for(**params, id: item.id),
      make_path(url_for(**params, action: action), id: item.id)
    ]

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
        click_on 'Remove'
        wait_for_page menu_url
      end

      # Choose submission to remove, which leads to the delete page.
      select item.long_name, from: 'selected'
      wait_for_page item_delete
      success_screenshot

      # After deletion we should be back on the previous page.
      click_on class: 'submit-button', match: :first
      wait_for_page menu_url
      assert_flash 'SUCCESS'

      # On the index page, there should be one less record than before.
      visit index_url
      assert_valid_page heading: INDEX_TITLE

    end
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  protected

  # Generate an Org :long_name.
  #
  # @param [Hash] opt                 Test options
  #
  # @return [String]
  #
  def org_name(**opt)
    opt[:name] ||= opt[:item].long_name if opt[:item]
    opt[:name]  += " (#{opt[:action]})" if opt[:action]
    opt.slice(:name, :unique, :tag).compact.values.join(' - ')
  end

end
