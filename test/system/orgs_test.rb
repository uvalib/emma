# test/system/orgs_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class OrgsTest < ApplicationSystemTestCase

  MODEL        = Org
  CONTROLLER   = :org
  PARAMS       = { controller: CONTROLLER }.freeze
  INDEX_TITLE  = page_title(**PARAMS, action: :index).freeze
  LIST_ACTIONS = %i[list_all].freeze

  TEST_USER    = :test_adm

  setup do
    @user = find_user(TEST_USER)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'orgs - index' do
    action = :index
    params = PARAMS.merge(action: action, meth: __method__)
    redir  = index_redirect(**params)
    list_test(redir_url: redir, **params)
  end

  test 'orgs - list_all' do
    action = :list_all
    params = PARAMS.merge(action: action, meth: __method__)
    list_test(**params)
  end

  test 'orgs - show' do
    action    = :show
    item      = orgs(:example)
    params    = PARAMS.merge(action: action, id: item.id)
    title     = page_title(item, **params, name: item.label.inspect)

    start_url = url_for(**params)
    final_url = start_url

    run_test(__method__) do

      # Not available anonymously; successful sign-in should redirect back.
      visit start_url
      assert_flash alert: AUTH_FAILURE
      sign_in_as @user

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
    title ||= page_title(**params)

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

    tag       = direct ? 'DIRECT' : 'INDIRECT'
    start_url = direct ? form_url : index_url
    final_url = [index_url, *list_urls]

    item      = orgs(:one)
    test_opt  = { action: action, tag: tag, item: item, unique: hex_rand }

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

    item      = orgs(:edit_example)
    test_opt  = { action: action, tag: tag, item: item, unique: hex_rand }

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

      # Choose org to edit.
      item_menu_select(item.long_name, name: 'id')

      # Replace field data.
      fill_in 'field-LongName', with: org_name(**test_opt)

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

    tag       = direct ? 'DIRECT' : 'INDIRECT'
    start_url = direct ? menu_url : index_url

    item      = orgs(:delete_example)
    test_opt  = { action: action, tag: tag, item: item, unique: hex_rand }

    # Add item copy to be deleted.
    name = org_name(**test_opt)
    attr = item.fields.except(:id).merge!(long_name: name)
    item = Org.create!(attr)

    item_delete = [
      url_for(**params, id: item.id),
      make_path(url_for(**params, action: action), id: item.id)
    ]

    # noinspection RubyMismatchedArgumentType
    run_test(meth || __method__) do

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
      item_menu_select(item.long_name, name: 'id')
      wait_for_page item_delete
      screenshot

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

  # ===========================================================================
  # :section: TestHelper::Utility overrides
  # ===========================================================================

  public

  # The default :index action redirects to :list_all for Administrator and
  # :show for everyone else.
  #
  # @param [Hash] opt
  #
  # @return [String, nil]
  #
  def index_redirect(**opt, &blk)
    opt[:user] = find_user(opt[:user] || current_user || @user)
    opt[:dst]  = opt[:user]&.administrator? ? :list_all : :show
    super(**opt, &blk)
  end

end
