# test/system/accounts_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class AccountsTest < ApplicationSystemTestCase

  MODEL = User
  CTRLR = :account
  PRM   = { controller: CTRLR }.freeze

  setup do
    @admin    = find_user(:test_adm)
    @manager  = find_user(:test_man_1)
    @member   = find_user(:test_dso_1)
    @generate = UserSampleGenerator.new(self)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'accounts - index - anonymous' do
    list_test(nil, meth: __method__)
  end

  test 'accounts - index - member' do
    list_test(@member, meth: __method__)
  end

  test 'accounts - index - admin' do
    list_test(@admin, meth: __method__)
  end

  test 'accounts - list_all - anonymous' do
    list_test(nil, meth: __method__, action: :list_all)
  end

  test 'accounts - list_all - member' do
    list_test(@member, meth: __method__, action: :list_all)
  end

  test 'accounts - list_all - admin' do
    list_test(@admin, meth: __method__, action: :list_all)
  end

  test 'accounts - list_org - anonymous' do
    list_test(nil, meth: __method__, action: :list_org)
  end

  test 'accounts - list_org - member' do
    list_test(@member, meth: __method__, action: :list_org)
  end

  test 'accounts - list_org - admin' do
    list_test(@admin, meth: __method__, action: :list_org)
  end

  test 'accounts - show - anonymous' do
    show_test(nil, meth: __method__, target: @manager)
  end

  test 'accounts - show - member' do
    show_test(@member, meth: __method__, target: @manager)
  end

  test 'accounts - show - admin' do
    show_test(@admin, meth: __method__, target: @manager)
  end

  test 'accounts - show_current - anonymous' do
    show_test(nil, meth: __method__)
  end

  test 'accounts - show_current - member' do
    show_test(@member, meth: __method__)
  end

  test 'accounts - show_current - admin' do
    show_test(@admin, meth: __method__)
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'accounts - new - anonymous' do
    new_test(nil, meth: __method__)
  end

  test 'accounts - new - member' do
    new_test(@member, meth: __method__)
  end

  test 'accounts - new - manager' do
    new_test(@manager, meth: __method__)
  end

  test 'accounts - new - admin' do
    new_test(@admin, meth: __method__)
  end

  test 'accounts - edit - anonymous' do
    edit_test(nil, meth: __method__)
  end

  test 'accounts - edit - member' do
    edit_test(@member, meth: __method__)
  end

  test 'accounts - edit - manager' do
    edit_test(@manager, meth: __method__)
  end

  test 'accounts - edit - admin' do
    edit_test(@admin, meth: __method__)
  end

  test 'accounts - delete - anonymous' do
    delete_test(nil, meth: __method__)
  end

  test 'accounts - delete - member' do
    delete_test(@member, meth: __method__)
  end

  test 'accounts - delete - manager' do
    delete_test(@manager, meth: __method__)
  end

  test 'accounts - delete - admin' do
    delete_test(@admin, meth: __method__)
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'accounts system test coverage' do
    skipped = []
    check_system_coverage AccountController, except: skipped
  end

  # ===========================================================================
  # :section: Methods - read tests
  # ===========================================================================

  protected

  # Perform a test to list accounts visible to *user*.
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

        total   ||= fixture_count(MODEL) if admin
        total   ||= fixture_count_for_org(MODEL, user)
        title   ||= page_title(**params, name: user&.org&.label)

        final_url = index ? index_redirect(user: user) : start_url

        # Successful sign-in should redirect back to the action page.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # The listing should be the first of one or more results pages with as
        # many entries as there are accounts visible to the user.
        show_url
        screenshot
        assert_current_url(final_url)
        assert_valid_page(heading: title)
        title_total_count(expected: total)
        data_record_total(expected: total)

        # Validate the table of accounts.
        check_item_table(section: true)

      elsif user

        show_item { "User '#{user}' blocked from listing user accounts." }
        assert_no_visit(start_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from listing user accounts.' }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

  # Perform a test to show a user account visible to *user*.
  #
  # If showing *user* itself, activity takes place on the :show_current page;
  # otherwise, activity takes place on the :show page.
  #
  # @param [User, nil]   user
  # @param [User, nil]   target       Default: *user* (i.e. :show_current).
  # @param [String, nil] title        Default based on *user* and opt[:action].
  # @param [Symbol]      meth         Calling test method.
  # @param [Hash]        opt          URL parameters.
  #
  # @return [void]
  #
  def show_test(user, target: nil, title: nil, meth: nil, **opt)
    target  ||= user || users(:example)
    params    = PRM.merge(action: :show, id: target.id, **opt)
    action    = params[:action]

    start_url = url_for(**params)

    run_test(meth || __method__) do

      if permitted?(action, user, target)

        title   ||= page_title(target, **params, name: target.label.inspect)

        final_url =
          if user&.id == target.id
            url_for(**params.except(:id).merge!(action: :show_current))
          else
            start_url
          end

        # Successful sign-in should redirect back to the action page.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # The page should show the details of the target user account.
        show_url
        screenshot
        assert_current_url(final_url)
        assert_valid_page(heading: title)

        # Validate the "Account Details" section.
        check_details_columns('.details-section .account-details')

        # Validate the "EMMA Submissions" section.
        check_details_section('.uploads-section')

        # Validate the "Bulk Upload Manifests" section.
        check_details_section('.manifests-section')

      elsif user

        show_item { "User '#{user}' blocked from viewing user account." }
        assert_no_visit(start_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from viewing user account.' }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

  # Perform a test to create a new account.
  #
  # @param [User, nil]   user
  # @param [Symbol, nil] meth         Calling test method.
  # @param [Hash]        opt          Added to URL parameters.
  #
  # @return [void]
  #
  def new_test(user, meth: nil, **opt)
    button   = 'Add User'
    action   = :new
    params   = PRM.merge(action: action, **opt)

    # Generate field data for the item to create.
    tag      = user&.role&.upcase || 'ANON'
    gen_opt  = { user: user, tag: tag, preserve: :org_id }
    fields   = @generate.fields_for(action, **gen_opt).except(:id)
    org_id   = fields[:org_id]

    form_url = form_page_url(**params)

    run_test(meth || __method__) do

      if permitted?(action, user)

        admin     = user&.administrator?
        records   = (fixture_count(MODEL) if admin)
        total     = (fixture_count_for_org(MODEL, user) unless records)

        index_url = url_for(controller: :org, action: :index)
        all_url   = url_for(controller: :org, action: :list_all)
        own_url   = url_for(controller: :org, action: :show_current)
        org_url   = url_for(controller: :org, action: :show, id: org_id)

        start_url = index_url
        final_url = [index_url, all_url, own_url, org_url]

        # Generate field data for the item to create.
        item_name = fields[:email]

        # Start on the index page showing the current number of items.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Go to the form page.
        select_action(button, wait_for: form_url)

        # On the form page:
        assert_selector '[data-field="id"]', visible: false #admin

        # Select/validate organization.
        org_name    = find_org(org_id).long_name.to_s
        org_menu_id = 'value-OrgId'
        if admin
          menu_select org_name, from: org_menu_id
        else
          assert_selector id: org_menu_id, text: org_name
        end

        # Add field data.
        fill_in 'value-Email',          with: fields[:email]
        fill_in 'value-FirstName',      with: fields[:first_name]
        fill_in 'value-LastName',       with: fields[:last_name]
        fill_in 'value-PreferredEmail', with: fields[:preferred_email]
        fill_in 'value-Phone',          with: fields[:phone]
        fill_in 'value-Address',        with: fields[:address]
        menu_select 'Standard',         from: 'value-Role'
        menu_select 'Active',           from: 'value-Status'

        # Create the item.
        show_item { "Creating user #{item_name.inspect}..." }
        form_submit

        # Verify successful submission.
        wait_for_page(final_url)
        assert_flash('Created EMMA user account')

        # There should be one more item than before on the index page.
        visit final_url.first unless final_url.include?(current_url)
        data_record_total(expected: total.succ)           if total
        assert_model_count(MODEL, expected: records.succ) if records

      elsif user

        show_item { "User '#{user}' blocked from creating user account." }
        assert_no_visit(form_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from creating user account.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

  # Perform a test to select then modify an account.
  #
  # @param [User, nil]   user
  # @param [Symbol, nil] meth         Calling test method.
  # @param [Hash]        opt          Added to URL parameters.
  #
  # @return [void]
  #
  def edit_test(user, meth: nil, **opt)
    button   = 'Edit User'
    action   = :edit
    params   = PRM.merge(action: action, **opt)

    # Find the item to be edited.
    record   = users(:edit_example)
    form_url = form_page_url(record.id, **params)

    run_test(meth || __method__) do

      if permitted?(action, user, record)

        admin     = user.administrator?
        records   = (fixture_count(MODEL) if admin)
        total     = (fixture_count_for_org(MODEL, user) unless records)

        index_url = url_for(controller: :org, action: :index)
        all_url   = url_for(controller: :org, action: :list_all)
        own_url   = url_for(controller: :org, action: :show_current)
        org_url   = url_for(controller: :org, action: :show, id: record.org_id)
        menu_url  = url_for(**params, action: menu_action(action))

        start_url = index_url
        final_url = [index_url, all_url, own_url, org_url]

        # Generate new field data for the item to edit.
        tag       = user&.role&.upcase || 'ANON'
        fields    = @generate.fields(record, tag: tag)
        item_name = record.email

        # Start on the index page showing the current number of items.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Go to the menu page and choose the item to edit.
        select_action(button, wait_for: menu_url)
        select_item(item_name, wait_for: form_url)

        # On the form page:
        assert_selector '[data-field="id"]', visible: false #admin

        # Modify field data.
        fill_in 'value-FirstName',      with: fields[:first_name]
        fill_in 'value-LastName',       with: fields[:last_name]
        fill_in 'value-PreferredEmail', with: fields[:preferred_email]
        fill_in 'value-Phone',          with: fields[:phone]
        fill_in 'value-Address',        with: fields[:address]

        # Update the item.
        show_item { "Updating user #{item_name.inspect}..." }
        form_submit

        # Verify that success was indicated back on the menu page.
        wait_for_page(menu_url)
        assert_flash('Updated EMMA user account')

        # There should be the same number of items as before on the index page.
        visit org_url unless final_url.include?(current_url)
        data_record_total(expected: total)           if total
        assert_model_count(MODEL, expected: records) if records

      elsif user

        show_item { "User '#{user}' blocked from modifying user account." }
        assert_no_visit(form_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from modifying user account.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

  # Perform a test to select then remove an account.
  #
  # @param [User, nil]   user
  # @param [Symbol, nil] meth         Calling test method.
  # @param [Hash]        opt          Added to URL parameters.
  #
  # @return [void]
  #
  def delete_test(user, meth: nil, **opt)
    button   = 'Remove User'
    action   = :delete
    params   = PRM.merge(action: action, **opt)

    # Generate a new item to be deleted.
    tag      = user&.role&.upcase || 'ANON'
    record   = @generate.new_record_for(action, user: user, tag: tag)
    form_url = form_page_url(record.id, **params)

    run_test(meth || __method__) do

      if permitted?(action, user, record)

        admin     = user.administrator?
        records   = (fixture_count(MODEL).succ if admin)
        total     = (fixture_count_for_org(MODEL, user).succ unless records)

        index_url = url_for(controller: :org, action: :index)
        all_url   = url_for(controller: :org, action: :list_all)
        own_url   = url_for(controller: :org, action: :show_current)
        org_url   = url_for(controller: :org, action: :show, id: record.org_id)
        menu_url  = url_for(**params, action: menu_action(action))

        start_url = index_url
        final_url = [index_url, all_url, own_url, org_url]

        # Identify the item to be deleted.
        item_name = record.email

        # Start on the index page showing the current number of items.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Go to the menu page and choose the item to remove.
        select_action(button, wait_for: menu_url)
        select_item(item_name, wait_for: form_url)

        # Delete the selected item.
        show_item { "Removing user #{item_name.inspect}..." }
        form_submit

        # Verify that success was indicated back on the menu page.
        wait_for_page(menu_url)
        assert_flash('Removed EMMA user account')

        # There should be one less item than before.
        visit org_url unless final_url.include?(current_url)
        data_record_total(expected: total.pred)           if total
        assert_model_count(MODEL, expected: records.pred) if records

      elsif user

        show_item { "User '#{user}' blocked from removing user account." }
        assert_no_visit(form_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from removing user account.' }
        assert_no_visit(form_url, :sign_in)

      end

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
  # @return [String]
  #
  def index_redirect(**opt)
    opt.reverse_merge!(PRM)
    opt[:user] = find_user(opt[:user] || current_user)
    opt[:dst]  = opt[:user]&.org ? :list_org : :list_all
    super
  end

end
