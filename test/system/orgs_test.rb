# test/system/orgs_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class OrgsTest < ApplicationSystemTestCase

  MODEL = Org
  CTRLR = :org
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

  test 'orgs - index - anonymous' do
    list_test(nil, meth: __method__)
  end

  test 'orgs - index - member' do
    # NOTE: redirects to the show page for the user's organization.
    user  = @member
    title = page_title(action: :show, name: user.org.label.inspect)
    total = fixture_count_for_org(User, user)
    list_test(user, meth: __method__, title: title, total: total)
  end

  test 'orgs - index - admin' do
    list_test(@admin, meth: __method__)
  end

  test 'orgs - list_all - anonymous' do
    list_test(nil, meth: __method__, action: :list_all)
  end

  test 'orgs - list_all - member' do
    list_test(@member, meth: __method__, action: :list_all)
  end

  test 'orgs - list_all - admin' do
    list_test(@admin, meth: __method__, action: :list_all)
  end

  test 'orgs - show - anonymous' do
    show_test(nil, meth: __method__)
  end

  test 'orgs - show - member' do
    show_test(@member, meth: __method__)
  end

  test 'orgs - show - admin' do
    show_test(@admin, meth: __method__)
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'orgs - new - anonymous' do
    new_test(nil, meth: __method__)
  end

  test 'orgs - new - member' do
    new_test(@member, meth: __method__)
  end

  test 'orgs - new - manager' do
    new_test(@manager, meth: __method__)
  end

  test 'orgs - new - admin' do
    new_test(@admin, meth: __method__)
  end

  test 'orgs - edit - anonymous' do
    edit_test(nil, meth: __method__)
  end

  test 'orgs - edit - member' do
    edit_test(@member, meth: __method__)
  end

  test 'orgs - edit - manager' do
    edit_test(@manager, meth: __method__)
  end

  test 'orgs - edit - admin' do
    edit_test(@admin, meth: __method__)
  end

  test 'orgs - delete - anonymous' do
    delete_test(nil, meth: __method__)
  end

  test 'orgs - delete - member' do
    delete_test(@member, meth: __method__)
  end

  test 'orgs - delete - manager' do
    delete_test(@manager, meth: __method__)
  end

  test 'orgs - delete - admin' do
    delete_test(@admin, meth: __method__)
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'orgs system test coverage' do
    skipped = []
    check_system_coverage OrgController, except: skipped
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  protected

  # Perform a test to list organizations visible to *user*.
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

        total   ||= admin ? fixture_count(MODEL) : 1
        title   ||= page_title(**params, name: user&.org&.long_name)

        final_url = index ? index_redirect(user: user) : start_url

        # Successful sign-in should redirect back to the action page.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # The listing should be the first of one or more results pages with as
        # many entries as there are organizations visible to the user.
        show_url
        screenshot
        assert_current_url(final_url)
        assert_valid_page(heading: title)
        data_record_total(expected: total)

        # Validate the table of organizations.
        check_item_table(section: true)

      elsif user

        show_item { "User '#{user}' blocked from listing organizations." }
        assert_no_visit(start_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from listing organizations.' }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

  # Perform a test to show an organization visible to *user*.
  #
  # If showing the user's own organization, activity takes place on the
  # :show_current page; otherwise, activity takes place on the :show page;
  # otherwise if *target* is not given it is assigned an example organization.
  #
  # @param [User, nil]   user
  # @param [Org, nil]    target       Default: `user.org` (i.e. :show_current).
  # @param [String, nil] title        Default based on *user* and opt[:action].
  # @param [Symbol]      meth         Calling test method.
  # @param [Hash]        opt          URL parameters.
  #
  # @return [void]
  #
  def show_test(user, target: nil, title: nil, meth: nil, **opt)
    target  ||= user&.org || orgs(:example)
    params    = PRM.merge(action: :show, id: target.id, **opt)
    action    = params[:action]

    start_url = url_for(**params)

    run_test(meth || __method__) do

      if permitted?(action, user, target)

        accounts  = fixture_count_for_org(User, target)

        title   ||= page_title(target, **params, name: target.label.inspect)

        final_url =
          if user&.org&.id == target.id
            url_for(**params.except(:id).merge!(action: :show_current))
          else
            start_url
          end

        # Successful sign-in should redirect back to the action page.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # The page should show the details of the target organization.
        show_url
        screenshot
        assert_current_url(final_url)
        assert_valid_page(heading: title)
        data_record_total(selector: '.account', expected: accounts)

        # Validate the "Users" section.
        check_item_table('.account.model-table')

        # Validate the "EMMA Submissions" section.
        check_details_section('.uploads-section')

        # Validate the "Bulk Upload Manifests" section.
        check_details_section('.manifests-section')

      elsif user

        show_item { "User '#{user}' blocked from viewing organization." }
        assert_no_visit(start_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from viewing organization.' }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

  # Perform a test to create a new organization.
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

        records   = fixture_count(MODEL)

        index_url = url_for(**params, action: :index)
        all_url   = url_for(**params, action: :list_all)
        own_url   = url_for(**params, action: :show_current)

        start_url = index_url
        final_url = [index_url, all_url, own_url]

        # Generate field data for the item to create.
        name   = 'New Organization'
        tag    = user&.role&.upcase || 'ANON'
        fields = @generate.fields_for(action, tag: tag, base: name).except(:id)
        name   = fields[:long_name]

        # Start on the index page showing the current number of items.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Go to the form page.
        select_action(button, wait_for: form_url)

        # Add field data.
        fill_in 'value-ShortName', with: fields[:short_name]
        fill_in 'value-LongName',  with: fields[:long_name]
        fill_in 'value-IpDomain',  with: fields[:ip_domain]&.join("\n")
        menu_select user.email, from: 'value-Contact'
        menu_select 'Active',   from: 'value-Status'

        # Create the item.
        show_item { "Creating organization #{name.inspect}..." }
        form_submit

        # Verify successful submission.
        wait_for_page(final_url)
        assert_valid_page(heading: TITLE)
        assert_flash('SUCCESS')

        # There should be one more item than before on the index page.
        visit final_url.first unless final_url.include?(current_url)
        assert_model_count(MODEL, expected: records.succ)

      elsif user

        show_item { "User '#{user}' blocked from creating organization." }
        assert_no_visit(form_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from creating organizations.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

  # Perform a test to select then modify an organization.
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
    admin    = user&.administrator?
    record   = !admin && find_org(user) || orgs(:edit_example)
    form_url = form_page_url(record.id, **params)
    if form_url.is_a?(Array)
      form_url << url_for(**params, action: :edit_current)
    end

    run_test(meth || __method__) do

      if permitted?(action, user, record)

        records   = fixture_count(MODEL)

        index_url = url_for(**params, action: :index)
        all_url   = url_for(**params, action: :list_all)
        own_url   = url_for(**params, action: :show_current)
        menu_url  = url_for(**params, action: menu_action(action))

        start_url = index_url
        final_url = [index_url, all_url, own_url]

        # Generate new field data for the item to edit.
        tag       = user&.role&.upcase || 'ANON'
        fields    = @generate.fields(record, tag: tag)
        item_name = record.long_name

        # Start on the index page showing the current number of items.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # If administrator, go to the menu page and choose the item to edit.
        if admin
          select_action(button, wait_for: menu_url)
          select_item(item_name, wait_for: form_url)
          result_page = menu_url
          final_title = TITLE
        else
          select_action('Modify', wait_for: form_url)
          result_page = url_for(**params, action: :show_current)
          final_title = TITLE.singularize
        end

        # Modify field data.
        fill_in 'value-LongName', with: fields[:long_name]

        # Update the item.
        show_item { "Updating organization #{item_name.inspect}..." }
        form_submit

        # Verify that success was indicated back on the menu page.
        wait_for_page(result_page)
        assert_flash('SUCCESS')

        # There should be the same number of items as before on the index page.
        visit final_url.first unless final_url.include?(current_url)
        assert_valid_page(heading: final_title)
        assert_model_count(MODEL, expected: records)

      elsif user

        show_item { "User '#{user}' blocked from modifying organization." }
        assert_no_visit(form_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from modifying organization.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

  # Perform a test to select then remove an organization.
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

        records   = fixture_count(MODEL).succ

        index_url = url_for(**params, action: :index)
        all_url   = url_for(**params, action: :list_all)
        own_url   = url_for(**params, action: :show_current)
        menu_url  = url_for(**params, action: menu_action(action))

        start_url = index_url
        final_url = [index_url, all_url, own_url]

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
        show_item { "Removing organization #{item_name.inspect}..." }
        form_submit

        # Verify that success was indicated back on the menu page.
        wait_for_page(menu_url)
        assert_flash('SUCCESS')

        # On the index page, there should be one less record than before.
        visit final_url.first unless final_url.include?(current_url)
        assert_valid_page(heading: TITLE)
        assert_model_count(MODEL, expected: records.pred)

      elsif user

        show_item { "User '#{user}' blocked from removing organization." }
        assert_no_visit(form_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from removing organization.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

  # ===========================================================================
  # :section: TestHelper::Utility overrides
  # ===========================================================================

  protected

  # The default :index action redirects to :list_all for Administrator and
  # :show_current for everyone else.
  #
  # @param [Hash] opt
  #
  # @return [String]
  #
  def index_redirect(**opt)
    opt.reverse_merge!(PRM)
    opt[:user] = find_user(opt[:user] || current_user)
    opt[:dst]  = opt[:user]&.administrator? ? :list_all : :show_current
    super
  end

end
