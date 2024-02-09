# test/system/uploads_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class UploadsTest < ApplicationSystemTestCase

  MODEL        = Upload
  CONTROLLER   = :upload
  PARAMS       = { controller: CONTROLLER }.freeze
  INDEX_TITLE  = page_title(**PARAMS, action: :index).freeze
  LIST_ACTIONS = %i[list_all list_org list_own].freeze

  TEST_USER    = :test_dso_1

  setup do
    @user = find_user(TEST_USER)
    @file = file_fixture(UPLOAD_FILE)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'uploads - index' do
    action = :index
    params = PARAMS.merge(action: action, meth: __method__)
    title  = page_title(**params)
    total  = nil # This will varying depending on the redirection destination.
    redir  = index_redirect(**params)
    list_test(title: title, total: total, redir_url: redir, **params)
  end

  test 'uploads - list_all' do
    if @user.can?(:list_all, MODEL)
      action = :list_all
      params = PARAMS.merge(action: action, meth: __method__)
      title  = page_title(**params)
      total  = fixture_count(MODEL)
      list_test(title: title, total: total, **params)
    else
      # NOTE: There's an issue with looping in attempting to sign-in which
      #   causes this to fail inexplicably.  Since this test user can't
      #   perform this action this test needs to be skipped for now.
      not_applicable "#{TEST_USER} is not an administrator"
    end
  end

  test 'uploads - list_org' do
    action = :list_org
    params = PARAMS.merge(action: action, meth: __method__)
    title  = page_title(**params, name: @user&.org&.label)
    total  = fixture_count_for_org(MODEL, @user)
    list_test(title: title, total: total, **params)
  end

  test 'uploads - list_own' do
    action = :list_own
    params = PARAMS.merge(action: action, meth: __method__)
    title  = page_title(**params, name: @user&.label.inspect)
    total  = fixture_count_for_user(MODEL, @user)
    list_test(title: title, total: total, **params)
  end

  test 'uploads - show' do
    action    = :show
    item      = uploads(:emma_completed)
    params    = PARAMS.merge(action: action, id: item.id)
    title     = "Uploaded file #{item.filename.inspect}"

    start_url = url_for(**params)
    final_url = start_url

    run_test(__method__) do

      # Details of a single upload submission are available anonymously.
      visit start_url

      # The page should show the details of the item.
      show_url
      assert_current_url final_url
      assert_valid_page  heading: title
      screenshot

    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'uploads - new' do
    new_test(meth: __method__, direct: true)
  end

  test 'uploads - new from index' do
    new_test(meth: __method__, direct: false)
  end

  test 'uploads - edit (select)' do
    edit_select_test(meth: __method__, direct: true)
  end

  test 'uploads - edit (select) from index' do
    edit_select_test(meth: __method__, direct: false)
  end

  test 'uploads - delete (select)' do
    delete_select_test(meth: __method__, direct: true)
  end

  test 'uploads - delete (select) from index' do
    delete_select_test(meth: __method__, direct: false)
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  public

  # Perform a test to list EMMA submissions visible to the test user.
  #
  # @param [Symbol]       action
  # @param [String]       title
  # @param [Integer, nil] total       Expected total number of items.
  # @param [String, nil]  redir_url
  # @param [Symbol]       meth        Calling test method.
  # @param [Hash]         opt         URL parameters.
  #
  # @return [void]
  #
  def list_test(action:, title:, total:, redir_url: nil, meth: nil, **opt)
    params    = opt.merge!(action: action)
    title   ||= INDEX_TITLE

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
      assert_search_count(CONTROLLER, total: total) if total
      screenshot

    end
  end

  # Perform a test to create a new EMMA submission.
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
    index_url = url_for(**params, action: :list_own)

    tag       = direct ? 'DIRECT' : 'INDIRECT'
    start_url = direct ? form_url : index_url
    final_url = index_url

    title     = 'New Upload'
    author    = "#{title} Author"
    prefix    = "#{TITLE_PREFIX} - "
    title     = "#{prefix} #{title}" unless title.start_with?(prefix)
    total     = fixture_count_for_user(MODEL, @user)

    # noinspection RubyMismatchedArgumentType
    run_test(meth || __method__) do

      # Not available anonymously; successful sign-in should redirect back.
      visit start_url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user

      # Change to the form page if coming in from the index page.
      unless direct
        click_on 'Create', match: :first
        wait_for_page form_url
      end

      # On the form page:
=begin # TODO: User selection field visible for Manager and Administrator
      assert_selector '[data-field="user_id"]', visible: false#, text: @user&.id # TODO: why is this not filled?
=end

      # Provide file and wait for data extraction.
      attach_file(@file) { click_on 'Select file' }
      assert_selector '.uploaded-filename.complete', wait: 5

      # Add field data.
      select 'EMMA',            from: 'value-Repository'
      select 'Moving Image',    from: 'value-Type'
      select 'RTF',             from: 'value-Format'
      select 'True',            from: 'value-Complete'
      select 'Born Accessible', from: 'value-Status'
      check  'Armenian'         # inside 'value-Language'
      fill_in 'value-Identifier', with: '' # remove bogus identifier
      fill_in 'value-Title',      with: "#{title } - #{tag}"
      fill_in 'value-Creator',    with: "#{author} - #{tag}"
      fill_in 'value-Comments',   with: 'FAKE - do not use'

      # After submitting should be back on the index page with one more record
      # than before.
      form_submit
      wait_for_page final_url
      assert_flash 'SUCCESS'
      assert_valid_page heading: INDEX_TITLE
      assert_search_count(CONTROLLER, total: (total += 1))

    end
  end

  # Perform a test to select then modify an EMMA submission.
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
    prefix    = "#{TITLE_PREFIX} - "

    index_url = url_for(**params, action: :list_own)
    menu_url  = url_for(**params, action: select)

    tag       = direct ? 'DIRECT' : 'INDIRECT'
    start_url = direct ? menu_url : index_url
    final_url = index_url

    total     = fixture_count_for_user(MODEL, @user)
    item      = uploads(:edit_example)
    test_opt  = { action: action, tag: tag, item: item, unique: hex_rand }

    author    = item.emma_metadata[:dc_creator]
    author    = [author, *test_opt.slice(:unique, :tag)].join(' - ')
    title     = upload_title(**test_opt)
    title     = "#{prefix} #{title}" unless title.start_with?(prefix)

    # noinspection RubyMismatchedArgumentType
    run_test(meth || __method__) do

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
      item_menu_select(item.id, name: 'id')

      # On the form page:
=begin # TODO: User selection field visible for Manager and Administrator
      assert_selector '[data-field="user_id"]', visible: false#, text: @user&.id # TODO: why is this not filled?
=end

      # Replace field data.
      fill_in 'value-Title',   with: title
      fill_in 'value-Creator', with: author

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
      assert_search_count(CONTROLLER, total: total)

    end
  end

  # Perform a test to select then remove an EMMA submission.
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

    index_url = url_for(**params, action: :list_own)
    menu_url  = url_for(**params, action: select)

    tag       = direct ? 'DIRECT' : 'INDIRECT'
    start_url = direct ? menu_url : index_url
    final_url = index_url

    total     = fixture_count_for_user(MODEL, @user)
    item      = uploads(:delete_example)
    test_opt  = { action: action, tag: tag, item: item, unique: hex_rand }

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

    # noinspection RubyMismatchedArgumentType
    run_test(meth || __method__) do

      # Verify added copies on the index page.
      visit index_url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user
      assert_search_count(CONTROLLER, total: (total += 1))

      # Change to the select menu if coming in from the index page.
      visit start_url
      unless direct
        click_on 'Remove'
        wait_for_page menu_url
      end

      # Choose submission to remove, which leads to the delete page.
      item_menu_select(item.id, name: 'id')
      wait_for_page item_delete
      screenshot
      click_on 'Delete', match: :first, exact: true

      # Should be back on the menu page.
      wait_for_page menu_url
      assert_flash 'SUCCESS'

      # On the index page, there should be one less record than before.
      visit index_url
      wait_for_page final_url
      assert_valid_page heading: INDEX_TITLE
      assert_search_count(CONTROLLER, total: (total -= 1))

    end
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  protected

  # Generate a distinct submission title.
  #
  # @param [Hash] opt                 Test options
  #
  # @return [String]
  #
  def upload_title(**opt)
    opt[:name] ||= opt[:item].emma_metadata[:dc_title] if opt[:item]
    opt[:name]  += " (#{opt[:action]})"                if opt[:action]
    opt.slice(:name, :unique, :tag).compact.values.join(' - ')
  end

  # ===========================================================================
  # :section: TestHelper::Utility overrides
  # ===========================================================================

  public

  # The default :index action redirects to :list_own.
  #
  # @param [Hash] opt
  #
  # @return [String, nil]
  #
  def index_redirect(**opt)
    opt[:user] ||= current_user || @user
    opt[:dst]  ||= :list_own
    super
  end

end
