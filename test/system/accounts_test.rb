# test/system/accounts_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

# noinspection RubyJumpError
class AccountsTest < ApplicationSystemTestCase

  MODEL        = User
  CONTROLLER   = :account
  PARAMS       = { controller: CONTROLLER }.freeze
  INDEX_TITLE  = page_title(**PARAMS, action: :index).freeze
  LIST_ACTIONS = %i[list_all list_org].freeze

  TEST_USER    = :test_man_1

  setup do
    @user = find_user(TEST_USER)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'accounts - index' do
    action = :index
    params = PARAMS.merge(action: action, meth: __method__)
    redir  = index_redirect(**params)
    list_test(redir_url: redir, **params)
  end

  test 'accounts - list_all' do
    if @user.can?(:list_all, MODEL)
      action = :list_all
      params = PARAMS.merge(action: action, meth: __method__)
      list_test(**params)
    else
      # NOTE: There's an issue with looping in attempting to sign-in which
      #   causes this to fail inexplicably.  Since this test user can't
      #   perform this action this test needs to be skipped for now.
      not_applicable "#{TEST_USER} is not an administrator"
    end
  end

  test 'accounts - list_org' do
    action = :list_org
    params = PARAMS.merge(action: action, meth: __method__)
    list_test(**params)
  end

  test 'accounts - show' do
    action    = :show
    item      = @user
    params    = PARAMS.merge(action: action, id: item.id)
    title     = page_title(item, **params, name: item.label.inspect)

    start_url = url_for(**params)
    final_url = start_url

    run_test(__method__) do

      # Not available anonymously; successful sign-in should redirect back.
      visit start_url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user

      # The page should show the details of the org.
      show_url
      assert_current_url final_url
      assert_valid_page  heading: title
      screenshot

    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'accounts - new' do
    return if not_applicable 'test account/new' # TODO: AccountsTest#new_test
    new_test(direct: true, meth: __method__)
  end

  test 'accounts - new from index' do
    return if not_applicable 'test account/new' # TODO: AccountsTest#new_test
    new_test(direct: false, meth: __method__)
  end

  test 'accounts - edit (select)' do
    return if not_applicable 'test account/edit' # TODO: AccountsTest#edit_select_test
    edit_select_test(direct: true, meth: __method__)
  end

  test 'accounts - edit (select) from index' do
    return if not_applicable 'test account/edit' # TODO: AccountsTest#edit_select_test
    edit_select_test(direct: false, meth: __method__)
  end

  test 'accounts - delete (select)' do
    return if not_applicable 'test account/delete' # TODO: AccountsTest#delete_select_test
    delete_select_test(direct: true, meth: __method__)
  end

  test 'accounts - delete (select) from index' do
    return if not_applicable 'test account/delete' # TODO: AccountsTest#delete_select_test
    delete_select_test(direct: false, meth: __method__)
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  public

  # list_test
  #
  # @param [Symbol]      action
  # @param [String, nil] title        Default: #INDEX_TITLE.
  # @param [String, nil] redir_url
  # @param [Symbol]      meth         Calling test method.
  # @param [Hash]        params       URL parameters.
  #
  # @return [void]
  #
  def list_test(action:, title: nil, redir_url: nil, meth: nil, **params)
    params.merge!(action: action)
    title ||= page_title(**params, name: @user&.org&.label)

    start_url = url_for(**params)
    final_url = redir_url || start_url

    run_test(meth || __method__) do

      # Not available anonymously; successful sign-in should redirect back.
      visit start_url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user

      # The listing should be the first of one or more results pages with as
      # many entries as there are fixture records.
      show_url
      assert_current_url final_url
      assert_valid_page  heading: title
      screenshot

    end
  end

  # new_test
  #
  # @param [Boolean] direct
  # @param [Symbol]  meth             Calling test method.
  # @param [Hash]    opt              Added to URL parameters.
  #
  # @return [void]
  #
  def new_test(direct:, meth: nil, **opt)
    action    = :new
    params    = PARAMS.merge(action: action, **opt)

    form_url  = url_for(**params)
    index_url = url_for(**params, action: :index)
    list_urls = LIST_ACTIONS.map { |m| url_for(**params, action: m) }

    # noinspection RubyUnusedLocalVariable
    tag       = direct ? 'DIRECT' : 'INDIRECT'
    start_url = direct ? form_url : index_url
    final_url = [index_url, *list_urls]

    # noinspection RubyMismatchedArgumentType
    run_test(meth || __method__) do

      # Not available anonymously; successful sign-in should redirect back.
      visit start_url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user

      # Change to the form page if coming in from the index page.
      unless direct
        click_on 'Add User'
        wait_for_page form_url
      end

=begin
      # On the form page:
      assert_selector '[data-field="user_id"]', visible: false

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
=end

      # After submitting should be back on the index page with one more record
      # than before.
      form_submit
      wait_for_page final_url
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
    action    = :edit
    select    = menu_action(action)
    params    = PARAMS.merge(action: action, **opt)

    index_url = url_for(**params, action: :index)
    menu_url  = url_for(**params, action: select)
    list_urls = LIST_ACTIONS.map { |m| url_for(**params, action: m) }

    tag       = direct ? 'DIRECT' : 'INDIRECT'
    start_url = direct ? menu_url : index_url
    final_url = [index_url, *list_urls]

    item      = users(:edit_example)
    # noinspection RubyUnusedLocalVariable
    test_opt  = { action: action, tag: tag, item: item, unique: hex_rand }

    # noinspection RubyMismatchedArgumentType
    run_test(meth || __method__) do

      # Not available anonymously; successful sign-in should redirect back.
      visit start_url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user

      # Change to the select menu if coming in from the index page.
      unless direct
        click_on 'Edit User'
        wait_for_page menu_url
      end

=begin
      # Choose submission to edit.
      item_menu_select(item.id, name: 'id')

      # On the form page:
      assert_selector '[data-field="user_id"]', visible: false#, text: @user&.id # TODO: why is this not filled?

      # Replace field data.
      fill_in 'field-Title',   with: title
      fill_in 'field-Creator', with: author
=end


      # After submitting should be back on the index page with the same number
      # of records.
      form_submit
      assert_flash 'SUCCESS'
      if direct
        visit index_url
        screenshot
      else
        wait_for_page final_url
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
    action    = :delete
    select    = menu_action(action)
    params    = PARAMS.merge(action: action, **opt)

    index_url = url_for(**params, action: :index)
    menu_url  = url_for(**params, action: select)
    list_urls = LIST_ACTIONS.map { |m| url_for(**params, action: m) }

    tag       = direct ? 'DIRECT' : 'INDIRECT'
    start_url = direct ? menu_url : index_url
    final_url = [index_url, *list_urls]

    item      = users(:delete_example)
    # noinspection RubyUnusedLocalVariable
    test_opt  = { action: action, tag: tag, item: item, unique: hex_rand }

=begin
    # Add Upload copy to be deleted and ensure that it is in the EMMA Unified
    # Index.
    name = upload_title(**test_opt)
    attr = item.fields.except(:id).merge!(dc_title: name)
    item = Upload.create!(attr)
    reindex(item)

    item_delete = [
      url_for(**params, id: item.id),
      make_path(url_for(**params), id: item.id)
    ]
=end

    # noinspection RubyMismatchedArgumentType
    run_test(meth || __method__) do

      # Verify added copies on the index page.
      visit index_url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user

      # Change to the select menu if coming in from the index page.
      visit start_url
      unless direct
        click_on 'Remove User'
        wait_for_page menu_url
      end

=begin
      # Choose submission to remove, which leads to the delete page.
      item_menu_select(item.id, name: 'id')
      wait_for_page item_delete
      screenshot
      click_on 'Delete', match: :first, exact: true
=end

      # Should be back on the menu page.
      wait_for_page menu_url
      assert_flash 'SUCCESS'

      # The index page should still show one less record than before.
      visit index_url
      wait_for_page final_url
      assert_valid_page heading: INDEX_TITLE

    end
  end

  # ===========================================================================
  # :section: TestHelper::Utility overrides
  # ===========================================================================

  public

  # The default :index action redirects to :list_org for an organization user.
  #
  # @param [Hash] opt
  #
  # @return [String, nil]
  #
  def index_redirect(**opt, &blk)
    opt[:user] = find_user(opt[:user] || current_user || @user)
    opt[:dst]  = opt[:user]&.org ? :list_org : :list_all
    super(**opt, &blk)
  end

end
