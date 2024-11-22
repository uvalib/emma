# test/system/manifests_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class ManifestsTest < ApplicationSystemTestCase

  MODEL = Manifest
  CTRLR = :manifest
  PRM   = { controller: CTRLR }.freeze
  TITLE = page_title(**PRM, action: :index).freeze

  setup do
    @csv      = csv_import_file
    @json     = json_import_file
    @admin    = find_user(:test_adm)
    @manager  = find_user(:test_man_1)
    @member   = find_user(:test_dso_1)
    @generate = ManifestSampleGenerator.new(self)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'manifests - index - anonymous' do
    list_test(nil, meth: __method__)
  end

  test 'manifests - index - member' do
    list_test(@member, meth: __method__)
  end

  test 'manifests - index - admin' do
    list_test(@admin, meth: __method__)
  end

  test 'manifests - list_all - anonymous' do
    list_test(nil, meth: __method__, action: :list_all)
  end

  test 'manifests - list_all - member' do
    list_test(@member, meth: __method__, action: :list_all)
  end

  test 'manifests - list_all - admin' do
    list_test(@admin, meth: __method__, action: :list_all)
  end

  test 'manifests - list_org - anonymous' do
    list_test(nil, meth: __method__, action: :list_org)
  end

  test 'manifests - list_org - member' do
    list_test(@member, meth: __method__, action: :list_org)
  end

  test 'manifests - list_org - admin' do
    list_test(@admin, meth: __method__, action: :list_org)
  end

  test 'manifests - list_own - anonymous' do
    list_test(nil, meth: __method__, action: :list_own)
  end

  test 'manifests - list_own - member' do
    list_test(@member, meth: __method__, action: :list_own)
  end

  test 'manifests - list_own - admin' do
    list_test(@admin, meth: __method__, action: :list_own)
  end

  test 'manifests - show - anonymous' do
    show_test(nil, meth: __method__)
  end

  test 'manifests - show - member' do
    show_test(@member, meth: __method__)
  end

  test 'manifests - show - admin' do
    show_test(@admin, meth: __method__)
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'manifests - new - anonymous' do
    new_test(nil, meth: __method__)
  end

  test 'manifests - new - member' do
    new_test(@member, meth: __method__)
  end

  test 'manifests - edit - anonymous' do
    edit_test(nil, meth: __method__)
  end

  test 'manifests - edit - member' do
    edit_test(@member, meth: __method__)
  end

  test 'manifests - delete - anonymous' do
    delete_test(nil, meth: __method__)
  end

  test 'manifests - delete - member' do
    delete_test(@member, meth: __method__)
  end

  test 'manifests - delete (select)' do
    delete_select_test(meth: __method__, direct: true)
  end

  test 'manifests - delete (select) from index' do
    delete_select_test(meth: __method__, direct: false)
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  public

  # Perform a test to list manifests visible to *user*.
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
        list_org  = (action == :list_org)
        list_own  = (action == :list_own)

        title   ||= page_title(**params, name: user&.org&.label) if list_org
        title   ||= page_title(**params)
        total   ||= fixture_count_for_user(MODEL, user) if index || list_own
        total   ||= fixture_count(MODEL) if admin
        total   ||= fixture_count_for_org(MODEL, user)

        final_url = index ? index_redirect(user: user) : start_url

        # Successful sign-in should redirect back to the action page.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # The listing should be the first of one or more results pages with as
        # many entries as there are manifests visible to the user.
        show_url
        screenshot
        assert_current_url(final_url)
        assert_valid_page(heading: title)
        assert_search_count(CTRLR, expected: total)

        # Verify that there are actually the indicated number of items.
        items   = all('.manifest-list .manifest-list-item')
        count   = all('.page-items', visible: :all).first&.text&.presence&.to_i
        count ||= total
        unless count == items.size
          flunk "#{count} items indicated but #{items.size} items found"
        end

        # Validate page contents.
        check_details_columns(items.first) if items.present?

      elsif user

        show_item { "User '#{user}' blocked from listing manifests." }
        assert_no_visit(start_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from listing manifests.' }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

  # Perform a test to show a manifest visible to *user*.
  #
  # @param [User, nil]     user
  # @param [Manifest, nil] target
  # @param [String, nil]   title
  # @param [Symbol]        meth       Calling test method.
  # @param [Hash]          opt        URL parameters.
  #
  # @return [void]
  #
  def show_test(user, target: nil, title: nil, meth: nil, **opt)
    target  ||= user&.manifests&.first || manifests(:example)
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

        # The page should show the details of the target manifest.
        show_url
        screenshot
        assert_current_url(final_url)
        assert_valid_page(heading: title)

        # Validate page contents.
        check_details_columns('.manifest-details')

      elsif user

        show_item { "User '#{user}' blocked from viewing manifest." }
        assert_no_visit(start_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from viewing manifest.' }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

  # Perform a test to create a new bulk operation manifest.
  #
  # @param [User, nil]             user
  # @param [String, Pathname, nil] file   Data import file.
  # @param [Symbol, nil]           meth   Calling test method.
  # @param [Hash]                  opt    Added to URL parameters.
  #
  # @return [void]
  #
  def new_test(user, file: nil, meth: nil, **opt)
    button   = 'Create'
    action   = :new
    params   = PRM.merge(action: action, **opt)

    form_url = url_for(**params)

    run_test(meth || __method__) do

      if permitted?(action, user)

        name      = "New Manifest #{hex_rand}"

        admin     = user&.administrator?
        records   = (fixture_count(MODEL) if admin)
        total     = (fixture_count_for_user(MODEL, user) unless records)

        index_url = url_for(**params, action: :index)
        all_url   = url_for(**params, action: :list_all)
        own_url   = url_for(**params, action: :list_own)
        org_url   = url_for(**params, action: :list_org)

        start_url = index_url
        final_url = [index_url, all_url, own_url, org_url]

        # Start on the index page showing the current number of items.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Go to the form page.
        select_action(button, wait_for: form_url)

        # Test functionality, either by acquiring field data from an import
        # file or by generating field data for the item to create.
        if file
          attach_file(file) { find('.import-button').click }
          data  = File.read(file)
          json  = file.to_s.end_with?('.json')
          rows  = json ? JSON.parse(data).size : (CSV.parse(data).size - 1)
          wait_for_condition(fatal: true) { all('tbody tr').size == rows }
        else
          tag   = user&.role&.upcase || 'ANON'
          flds  = @generate.fields_for(action, tag: tag, base: name)
          name  = flds[:name]
          t_opt = { item: flds.except(:id), action: action, tag: tag }
          manifest_title_test(**t_opt)
          manifest_grid_test(**t_opt)
        end

        # Create the item.
        show_item { "Creating manifest #{name.inspect}..." }
        screenshot
        click_on 'Save', match: :first, exact: true

        # There should be one more item than before on the index page.
        visit final_url.first unless final_url.include?(current_url)
        assert_valid_page(heading: TITLE)
        displayed_manifest_total(expected: total.succ)    if total
        assert_model_count(MODEL, expected: records.succ) if records

      elsif user

        show_item { "User '#{user}' blocked from creating manifest." }
        assert_no_visit(form_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from creating manifest.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

  # Perform a test to select then modify a bulk operation manifest.
  #
  # @param [User, nil]             user
  # @param [String, Pathname, nil] file   Data import file.
  # @param [Symbol, nil]           meth   Calling test method.
  # @param [Hash]                  opt    Added to URL parameters.
  #
  # @return [void]
  #
  def edit_test(user, file: nil, meth: nil, **opt)
    button   = 'Change'
    action   = :edit
    params   = PRM.merge(action: action, **opt)

    # Find the item to be edited.
    record   = user&.manifests&.first || manifests(:edit_example)
    form_url = form_page_url(record.id, **params)

    run_test(meth || __method__) do

      if permitted?(action, user, record)

        name      = record.name

        admin     = user.administrator?
        records   = (fixture_count(MODEL) if admin)
        total     = (fixture_count_for_user(MODEL, user) unless records)

        index_url = url_for(**params, action: :index)
        all_url   = url_for(**params, action: :list_all)
        own_url   = url_for(**params, action: :list_own)
        org_url   = url_for(**params, action: :list_org)
        menu_url  = url_for(**params, action: menu_action(action))

        start_url = index_url
        final_url = [index_url, all_url, own_url, org_url]

        # Start on the index page showing the current number of items.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Go to the menu page and choose the item to edit.
        select_action(button, wait_for: menu_url)
        select_item(name, wait_for: form_url)

        # Test functionality, either by acquiring field data from an import
        # file or by generating new field data for the item to edit.
        if file
          rows  = all('tbody tr').size
          attach_file(file) { find('.import-button').click }
          data  = File.read(file)
          json  = file.to_s.end_with?('.json')
          rows += json ? JSON.parse(data).size : (CSV.parse(data).size - 1)
          wait_for_condition(fatal: true) { all('tbody tr').size == rows }
        else
          tag   = user&.role&.upcase || 'ANON'
          flds  = @generate.fields(record, tag: tag)
          t_opt = { item: flds, action: action, tag: tag }
          manifest_title_test(**t_opt)
          manifest_grid_test(**t_opt)
        end

        # Update the item.
        show_item { "Updating manifest #{name.inspect}..." }
        screenshot
        click_on 'Save', match: :first, exact: true

        # There should be the same number of items as before on the index page.
        visit final_url.first unless final_url.include?(current_url)
        assert_valid_page(heading: TITLE)
        displayed_manifest_total(expected: total)    if total
        assert_model_count(MODEL, expected: records) if records

      elsif user

        show_item { "User '#{user}' blocked from modifying manifest." }
        assert_no_visit(form_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from modifying manifest.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

  # Perform a test to select then remove a bulk operation manifest.
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

        admin     = user.administrator?
        records   = (fixture_count(MODEL).succ if admin)
        total     = (fixture_count_for_user(MODEL, user).succ unless records)

        index_url = url_for(**params, action: :index)
        all_url   = url_for(**params, action: :list_all)
        own_url   = url_for(**params, action: :list_own)
        org_url   = url_for(**params, action: :list_org)
        menu_url  = url_for(**params, action: menu_action(action))

        start_url = index_url
        final_url = [index_url, all_url, own_url, org_url]

        # Identify the item to be deleted.
        item_name = record.name

        # Start on the index page showing the current number of items.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Go to the menu page and choose the item to remove.
        select_action(button, wait_for: menu_url)
        select_item(item_name, wait_for: form_url)

        # Delete the selected item.
        show_item { "Removing manifest #{item_name.inspect}..." }
        form_submit

        # After deletion, we should be back on the menu page.
        wait_for_page(menu_url)
        assert_flash('Removed manifest')

        # On the index page, there should be one less record than before.
        visit final_url.first unless final_url.include?(current_url)
        assert_model_count_for_user(MODEL, user, expected: total.pred) if total
        assert_model_count(MODEL, expected: records.pred) if records

      elsif user

        show_item { "User '#{user}' blocked from removing manifest." }
        assert_no_visit(form_url, action, as: user)

      else

        show_item { 'Anonymous user blocked from removing manifest.' }
        assert_no_visit(form_url, :sign_in)

      end

    end
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  protected

  # Get the number of manifests from a manifest listing page.
  #
  # @param [Integer, nil] expected    Assert that the expected count is found.
  #
  # @return [Integer]
  #
  def displayed_manifest_total(expected: nil)
    total = find('.manifest-list .total-items').text.to_i
    unless expected.nil? || (total == expected)
      flunk "count is #{total} instead of #{expected}"
    end
    total
  end

  # Check operation of Manifest information display/edit by setting the title
  # to the provided value.
  #
  # @param [Hash] opt                 Test options
  #
  # @return [void]
  #
  def manifest_title_test(**opt)
    show_item { 'Modify manifest name...' }
    title = opt.dig(:item, :name)
    curr  = find('.heading .name').text
    title = "#{title} - MODIFIED #{hex_rand}" if title == curr

    # Click on "Edit" button to make the line editor visible.
    click_on class: 'title-edit', match: :first

    # Change the title value and commit by clicking the "Change" button.
    line = find('.line-editor')
    line.find('.input.value').set(title)
    line.find('.update').click

    # Verify that the displayed title has changed.
    current = find('.heading .name').text
    return if current == title
    flunk "title = #{title.inspect} but current = #{current.inspect}"
  end

  # Check operation of ManifestItem grid.
  #
  # @param [Hash, nil] fields         Default: `#generate_item_fields`.
  # @param [Boolean]   shuffle        If *false*, do not randomize order.
  # @param [Hash]      opt            Test options
  #
  # @option opt [Symbol] :fixture     Passed to #generate_item_fields
  #
  # @return [void]
  #
  def manifest_grid_test(fields: nil, shuffle: true, **opt)
    show_item { 'Modify manifest content...' }
    fields &&= fields.except(*NON_DATA_ITEM_FIELDS)
    fields ||= generate_item_fields(**opt)
    fields   = fields.to_a.shuffle.to_h if shuffle
    fields.each_pair do |field, value|
      fill_cell(field, value)
    end
  end

  # ManifestItem fields which do not relate directly to manifest grid inputs.
  #
  # @type [Array<Symbol>]
  #
  NON_DATA_ITEM_FIELDS = %i[
    dcterms_dateAccepted
    id manifest_id row delta
    editing deleting
    last_saved last_lookup last_submit
    created_at updated_at
    data_status file_status ready_status
    backup last_indexed submission_id field_error
  ].freeze

  # Generate fields for a ManifestItem.
  #
  # @param [Symbol] fixture
  #
  # @return [Hash{Symbol=>any}]
  #
  def generate_item_fields(fixture: :manifest_grid_new_example, **)
    manifest_items(fixture).fields.compact.except(*NON_DATA_ITEM_FIELDS)
  end

  # Click on the cell to activate the input control before filling it.
  #
  # @param [Symbol, String] key
  # @param [any]            value
  # @param [Integer]        row
  #
  # @return [void]
  #
  def fill_cell(key, value, row: 1)
    key = key.to_s.sub(/^[^_]+_/, '') if key.is_a?(Symbol)
    key = key.camelize

    # Click the cell to make its edit element visible.
    find_by_id("cell-#{key}-#{row}").scroll_to(:center).click

    # Update the edit element based on its type.
    edit = find_by_id("edit-#{key}-#{row}").scroll_to(:center)
    css  = edit[:class].split(' ')
    if css.include?('menu')
      items = Array.wrap(value).map { %Q([value="#{_1}"]) }.join(',')
      if css.include?('multi')
        edit.all(items).each { _1.set(true) }
      else
        edit.all(items).each { _1.scroll_to(:center).select_option }
      end
    elsif css.include?('input')
      value = value.join("\n") if value.is_a?(Array)
      edit.set(value)
    else
      flunk "unexpected class combination: #{css.inspect}"
    end
  rescue Selenium::WebDriver::Error::ElementClickInterceptedError => e
    $stderr.puts "KEY #{key.inspect} EXCEPTION: #{e.inspect}" # TODO: remove
    take_screenshot # TODO: remove?
  end

  # Return the path to the CSV import file fixture.
  #
  # @param [String, Pathname] name
  #
  # @return [Pathname]
  #
  def csv_import_file(name: 'import.csv')
    file_fixture(name)
  end

  # Return the path to the JSON import file fixture.
  #
  # If it does not exist, it will be generated from the CSV import fixture.
  #
  # @param [String, Pathname] name
  #
  # @return [Pathname]
  #
  def json_import_file(name: 'import.json')
    json = Pathname.new(File.join(file_fixture_path, name))
    unless json.exist?
      base = File.basename(name, '.*')
      csv  = file_fixture("#{base}.csv")
      data = csv_to_json(csv)
      File.write(json, data)
    end
    json
  end

  # Convert CSV content into JSON.
  #
  # @param [String, Pathname] file
  #
  # @return [String]
  #
  def csv_to_json(file)
    file = file_fixture(file) unless file.is_a?(Pathname)
    data = CSV.read(file)
    flds = data.shift
    data.map { flds.zip(_1).to_h }.to_json
  end

  # ===========================================================================
  # :section: TestHelper::Utility overrides
  # ===========================================================================

  public

  # The default :index action redirects to :list_own.
  #
  # @param [Hash] opt
  #
  # @return [String]
  #
  def index_redirect(**opt)
    opt.reverse_merge!(PRM)
    opt[:dst]  ||= :list_own
    super
  end

end
