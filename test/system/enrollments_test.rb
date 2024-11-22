# test/system/enrollments_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class EnrollmentsTest < ApplicationSystemTestCase

  MODEL = Enrollment
  CTRLR = :enrollment
  PRM   = { controller: CTRLR }.freeze
  TITLE = page_title(**PRM, action: :index).freeze

  setup do
    @admin    = find_user(:test_adm)
    @manager  = find_user(:test_man_1)
    @member   = find_user(:test_dso_1)
    @generate = OrgSampleGenerator.new(self)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'enrollments - index - anonymous' do
    list_test(nil, meth: __method__)
  end

  test 'enrollments - index - member' do
    list_test(@member, meth: __method__)
  end

  test 'enrollments - index - admin' do
    list_test(@admin, meth: __method__)
  end

  test 'enrollments - show - anonymous' do
    show_test(nil, meth: __method__)
  end

  test 'enrollments - show - member' do
    show_test(@member, meth: __method__)
  end

  test 'enrollments - show - admin' do
    show_test(@admin, meth: __method__)
  end

  test 'enrollments - show_select - anonymous' do
    show_select_test(nil, meth: __method__)
  end

  test 'enrollments - show_select - member' do
    show_select_test(@member, meth: __method__)
  end

  test 'enrollments - show_select - admin' do
    show_select_test(@admin, meth: __method__)
  end

  test 'enrollments - edit_select - anonymous' do
    edit_select_test(nil, meth: __method__)
  end

  test 'enrollments - edit_select - member' do
    edit_select_test(@member, meth: __method__)
  end

  test 'enrollments - edit_select - admin' do
    edit_select_test(@admin, meth: __method__)
  end

  test 'enrollments - delete_select - anonymous' do
    delete_select_test(nil, meth: __method__)
  end

  test 'enrollments - delete_select - member' do
    delete_select_test(@member, meth: __method__)
  end

  test 'enrollments - delete_select - admin' do
    delete_select_test(@admin, meth: __method__)
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'enrollments - new - anonymous' do
    new_test(nil, meth: __method__)
  end

  test 'enrollments - new - member' do
    new_test(@member, meth: __method__)
  end

  test 'enrollments - new - admin' do
    new_test(@admin, meth: __method__)
  end

  test 'enrollments - edit - anonymous' do
    edit_test(nil, meth: __method__)
  end

  test 'enrollments - edit - member' do
    edit_test(@member, meth: __method__)
  end

  test 'enrollments - edit - admin' do
    edit_test(@admin, meth: __method__)
  end

  test 'enrollments - delete - anonymous' do
    delete_test(nil, meth: __method__)
  end

  test 'enrollments - delete - member' do
    delete_test(@member, meth: __method__)
  end

  test 'enrollments - delete - admin' do
    delete_test(@admin, meth: __method__)
  end

  test 'enrollments - finalize - anonymous' do
    finalize_test(nil, meth: __method__)
  end

  test 'enrollments - finalize - member' do
    finalize_test(@member, meth: __method__)
  end

  test 'enrollments - finalize - admin' do
    finalize_test(@admin, meth: __method__)
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'enrollments system test coverage' do
    skipped = []
    check_system_coverage EnrollmentController, except: skipped
  end

  # ===========================================================================
  # :section: Methods - read tests
  # ===========================================================================

  protected

  # Perform a test to list enrollments visible to *user*.
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

        total   ||= fixture_count(MODEL)
        title   ||= page_title(**params)

        final_url = start_url

        # Successful sign-in should redirect back to the action page.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # The listing should be a single page with as many entries as there are
        # enrollment records.
        show_url
        screenshot
        assert_current_url(final_url)
        assert_valid_page(heading: title)
        title_total_count(expected: total)
        data_record_total(expected: total)

        # Validate the table of enrollments.
        check_item_table(section: true)

      elsif user

        show_item { "User '#{user}' blocked from listing enrollments." }
        assert_no_visit(start_url, :admin_only, as: user)

      else

        show_item { 'Anonymous user blocked from listing enrollments.' }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

  # Perform a test to show an enrollment visible to *user*.
  #
  # @param [User, nil]       user
  # @param [Enrollment, nil] target
  # @param [String, nil]     title
  # @param [Symbol]          meth     Calling test method.
  # @param [Hash]            opt      URL parameters.
  #
  # @return [void]
  #
  def show_test(user, target: nil, title: nil, meth: nil, **opt)
    target  ||= enrollments(:example)
    params    = PRM.merge(action: :show, id: target.id, **opt)
    action    = params[:action]

    start_url = url_for(**params)

    run_test(meth || __method__) do

      if permitted?(action, user, target)

        title   ||= page_title(target, **params, name: target.label.inspect)

        final_url = start_url

        # Successful sign-in should redirect back to the action page.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # The page should show the details of the target enrollment.
        show_url
        screenshot
        assert_current_url(final_url)
        assert_valid_page(heading: title)

        # Validate page contents.
        check_details_columns('.enrollment-details')

      elsif user

        show_item { "User '#{user}' blocked from viewing enrollment." }
        assert_no_visit(start_url, :admin_only, as: user)

      else

        show_item { 'Anonymous user blocked from viewing enrollment.' }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

  # Perform a test to invoke the menu for selecting an enrollment to display.
  #
  # @param [User, nil] user
  # @param [Hash]      opt            Passed to #page_select_test.
  #
  # @return [void]
  #
  def show_select_test(user, **opt)
    page_select_test(user, action: :show, **opt)
  end

  # Perform a test to invoke the menu for selecting an enrollment to modify.
  #
  # @param [User, nil] user
  # @param [Hash]      opt            Passed to #page_select_test.
  #
  # @return [void]
  #
  def edit_select_test(user, **opt)
    page_select_test(user, action: :edit, **opt)
  end

  # Perform a test to invoke the menu for selecting an enrollment to remove.
  #
  # @param [User, nil] user
  # @param [Hash]      opt            Passed to #page_select_test.
  #
  # @return [void]
  #
  def delete_select_test(user, **opt)
    page_select_test(user, action: :delete, **opt)
  end

  # Perform a test to invoke the menu for selecting an enrollment.
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

        # The page should show a menu of enrollments.
        show_url
        screenshot
        assert_current_url(final_url)
        assert_valid_page(heading: title)

        # Check that the menu contains only enrollments visible to the user.
        check_page_select_menu(count: fixture_count(MODEL), action: form_url)

      elsif user

        show_item { "User '#{user}' blocked from #{action} enrollment." }
        assert_no_visit(start_url, :admin_only, as: user)

      else

        show_item { "Anonymous user blocked from #{action} enrollment." }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

  # ===========================================================================
  # :section: Methods - write tests
  # ===========================================================================

  protected

  # Perform a test to create a new enrollment.
  #
  # @param [User, nil]   user
  # @param [Symbol, nil] meth         Calling test method.
  # @param [Hash]        opt          Added to URL parameters.
  #
  # @return [void]
  #
  def new_test(user, meth: nil, **opt)
    action   = :new
    params   = PRM.merge(action: action, **opt)

    form_url = url_for(**params)

    run_test(meth || __method__) do

      if permitted?(action, user)

        records   = fixture_count(MODEL)

        start_url = welcome_url
        final_url = start_url

        # Generate field data for the item to create.
        name      = 'New Organization'
        tag       = user&.role&.upcase || 'ANON'
        gen_opt   = { tag: tag, base: name }
        fields    = @generate.fields_for(action, **gen_opt).except(:id)
        org_user  = Array.wrap(fields[:org_users]).first
        org_user  = org_user.symbolize_keys.transform_values { "new_#{_1}" }
        item_name = fields[:long_name]

        # Start on a page available to any user then go to the form page.
        visit start_url
        visit form_url

        # Add field data.
        fill_in 'value-ShortName',           with: fields[:short_name]
        fill_in 'value-LongName',            with: fields[:long_name]
        fill_in 'value-IpDomain',            with: fields[:ip_domain]&.join("\n")
        fill_in 'value-RequestNotes',        with: fields[:request_notes]
        fill_in 'value-OrgUsers-email',      with: org_user[:email]
        fill_in 'value-OrgUsers-first_name', with: org_user[:first_name]
        fill_in 'value-OrgUsers-last_name',  with: org_user[:last_name]

        # Create the item.
        show_item { "Creating enrollment for #{item_name.inspect}..." }
        form_submit

        # Verify successful submission.
        wait_for_page(final_url)
        assert_flash('has been sent')

        # There should be one more item than before.
        assert_model_count(MODEL, expected: records.succ)

      elsif user

        show_item { "User '#{user}' blocked from creating enrollment." }
        assert_no_visit(form_url, :admin_only, as: user)

      else

        show_item { 'Anonymous user blocked from creating enrollment.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

  # Perform a test to select then modify an enrollment.
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
    record   = enrollments(:edit_example)
    form_url = form_page_url(record.id, **params)

    run_test(meth || __method__) do

      if permitted?(action, user, record)

        records   = fixture_count(MODEL)

        index_url = url_for(**params, action: :index)
        menu_url  = url_for(**params, action: menu_action(action))

        start_url = index_url
        final_url = start_url

        # Generate new field data for the item to edit.
        tag       = user&.role&.upcase || 'ANON'
        fields    = @generate.fields(record, tag: tag)
        org_user  = Array.wrap(fields[:org_users]).first
        org_user  = org_user.symbolize_keys.transform_values { "edit_#{_1}" }
        item_name = record.long_name

        # Start on the index page showing the current number of items.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Go to the menu page and choose the item to edit.
        select_action(button, wait_for: menu_url)
        select_item(item_name, wait_for: form_url)

        # Modify field data.
        fill_in 'value-LongName',            with: fields[:long_name]
        fill_in 'value-RequestNotes',        with: fields[:request_notes]
        fill_in 'value-OrgUsers-email',      with: org_user[:email]
        fill_in 'value-OrgUsers-first_name', with: org_user[:first_name]
        fill_in 'value-OrgUsers-last_name',  with: org_user[:last_name]

        # Update the item.
        show_item { "Updating enrollment for #{item_name.inspect}..." }
        form_submit

        # Verify that success was indicated back on the menu page.
        wait_for_page(menu_url)
        assert_flash('updated')

        # There should be the same number of items as before on the index page.
        visit final_url unless current_url == final_url
        assert_valid_page(heading: TITLE)
        assert_model_count(MODEL, expected: records)

      elsif user

        show_item { "User '#{user}' blocked from modifying enrollment." }
        assert_no_visit(form_url, :admin_only, as: user)

      else

        show_item { 'Anonymous user blocked from modifying enrollment.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

  # Perform a test to select then remove an enrollment.
  #
  # @param [User, nil]   user
  # @param [Symbol, nil] meth         Calling test method.
  # @param [Hash]        opt          Added to URL parameters.
  #
  # @return [void]
  #
  def delete_test(user, meth: nil, **opt)
    button    = 'Remove'
    action    = :delete
    params    = PRM.merge(action: action, **opt)

    # Generate a new item to be deleted.
    tag       = user&.role&.upcase || 'ANON'
    record    = @generate.new_record_for(action, tag: tag)
    form_url  = form_page_url(record.id, **params)

    run_test(meth || __method__) do

      if permitted?(action, user, record)

        records   = fixture_count(MODEL).succ

        index_url = url_for(**params, action: :index)
        menu_url  = url_for(**params, action: menu_action(action))

        start_url = index_url
        final_url = start_url

        # Identify the item to be deleted.
        item_name = record.long_name

        # Start on the index page showing the current number of items.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Go to the menu page and choose the item to remove.
        select_action(button, wait_for: menu_url)
        select_item(item_name, wait_for: form_url)

        # Delete the selected item.
        show_item { "Removing enrollment for #{item_name.inspect}..." }
        form_submit

        # After deletion, we should be back on the previous page.
        wait_for_page(menu_url)
        assert_flash('deleted')

        # There should be one less item than before.
        visit final_url unless current_url == final_url
        assert_valid_page(heading: TITLE)
        assert_model_count(MODEL, expected: records.pred)

      elsif user

        show_item { "User '#{user}' blocked from removing enrollment." }
        assert_no_visit(form_url, :admin_only, as: user)

      else

        show_item { 'Anonymous user blocked from removing enrollment.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

  # Perform a test to finalize an enrollment to create an organization.
  #
  # @param [User, nil]   user
  # @param [Symbol, nil] meth         Calling test method.
  # @param [Hash]        opt          Added to URL parameters.
  #
  # @return [void]
  #
  def finalize_test(user, meth: nil, **opt)
    button   = I18n.t('emma.page.enrollment.action.finalize.label')
    action   = :finalize
    params   = PRM.merge(action: action, **opt)

    # Find the item to be edited.
    record   = enrollments(:edit_example)
    form_url = url_for(**params, action: :show) << "?id=#{record.id}"

    run_test(meth || __method__) do

      if permitted?(action, user, record)

        records   = fixture_count(MODEL)
        orgs      = fixture_count(Org)

        index_url = url_for(**params, action: :index)
        menu_url  = url_for(**params, action: :show_select)

        start_url = index_url
        final_url = start_url

        # Identify the item to finalize.
        item_name = record.long_name

        # Start on the index page showing the current number of items.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Go to the menu page and choose the item to finalize.
        select_action('Select', wait_for: menu_url)
        select_item(item_name, wait_for: form_url)

        # Finalize the item.
        show_item { "Finalizing enrollment for #{item_name.inspect}..." }
        click_on button, match: :first, exact: true

        # Verify that success was indicated back on the menu page.
        wait_for_page(final_url)
        assert_flash('organization created')
        assert_valid_page(heading: TITLE)

        # There should be one less enrollment and one additional organization.
        assert_model_count(MODEL, expected: records.pred)
        assert_model_count(Org, expected: orgs.succ)

      elsif user

        show_item { "User '#{user}' blocked from finalizing enrollment." }
        assert_no_visit(form_url, :admin_only, as: user)

      else

        show_item { 'Anonymous user blocked from finalizing enrollment.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

end
