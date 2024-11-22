# test/system/data_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class DataTest < ApplicationSystemTestCase

  CTRLR = :data
  PRM   = { controller: CTRLR }.freeze

  setup do
    @admin  = find_user(:test_adm)
    @member = find_user(:test_dso_1)
  end

  # Important tables expected to be listed.
  #
  # @type [Array<String>]
  #
  KEY_TABLES = %w[
    good_jobs
    manifest_items
    manifests
    orgs
    search_calls
    sessions
    uploads
    users
  ].freeze

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'data - index - anonymous' do
    list_test(nil, meth: __method__)
  end

  test 'data - index - member' do
    list_test(@member, meth: __method__)
  end

  test 'data - index - all data tables' do
    list_test(@admin, meth: __method__)
  end

  test 'data - index - one data table' do
    list_test(@admin, meth: __method__, table: 'orgs')
  end

  test 'data - index - two data tables' do
    list_test(@admin, meth: __method__, table: 'orgs,users')
  end

  test 'data - show - anonymous' do
    show_test(nil, Org, meth: __method__)
  end

  test 'data - show - member' do
    show_test(@member, Org, meth: __method__)
  end

  test 'data - show - admin' do
    show_test(@admin, Org, meth: __method__)
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'data system test coverage' do
    # Endpoints covered by controller tests:
    skipped = %i[counts submissions]
    check_system_coverage DataController, prefix: 'data', except: skipped
  end

  # ===========================================================================
  # :section: Methods - read tests
  # ===========================================================================

  protected

  # Perform a test to list database tables.
  #
  # @param [User, nil] user
  # @param [Symbol]    meth           Calling test method.
  # @param [Hash]      opt            URL parameters.
  #
  # @return [void]
  #
  def list_test(user, meth: nil, **opt)
    params    = PRM.merge(action: :index, **opt)
    start_url = url_for(**params)

    run_test(meth || __method__) do

      if user&.administrator?

        # Successful sign-in should redirect back to the action page.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Validate the page.
        screenshot
        headings = all('main h2').map(&:text)
        assert_equal 'EMMA Submissions',     headings.shift
        assert_equal 'EMMA Database Tables', headings.shift

        # Validate listed table(s).
        tables  = all('main .database-table-links a').map(&:text)
        matches = opt[:table] || KEY_TABLES
        matches = matches.split(',') if matches.is_a?(String)
        matches.each do |t|
          assert tables.include?(t), "Missing table '#{t}'"
        end

      elsif user

        show_item { "User '#{user}' blocked from listing databases." }
        assert_no_visit(start_url, :admin_only, as: user)

      else

        show_item { 'Anonymous user blocked from listing databases.' }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

  # Perform a test to show a database table.
  #
  # @param [User, nil]     user
  # @param [Class, String] table
  # @param [Symbol]        meth       Calling test method.
  # @param [Hash]          opt        URL parameters.
  #
  # @return [void]
  #
  def show_test(user, table, meth: nil, **opt)
    expect    = opt.delete(:expect) || (table.count if table.is_a?(Class))
    name      = table.is_a?(Class) ? table.table_name : table
    params    = PRM.merge(action: :show, id: name, **opt)
    start_url = url_for(**params)

    run_test(meth || __method__) do

      if user&.administrator?

        # Successful sign-in should redirect back to the action page.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Validate the displayed table.
        screenshot
        heading = find('.heading')
        count   = heading.text.tr('^0-9', '').to_i
        table   = find('.database-table')
        rows    = table.all('.database-record')
        r_count = rows.size - 1 # Deduct heading row.
        assert_equal count,  r_count, 'Heading count invalid'
        assert_equal expect, r_count, 'Row count unexpected' if expect

      elsif user

        show_item { "User '#{user}' blocked from viewing database." }
        assert_no_visit(start_url, :admin_only, as: user)

      else

        show_item { 'Anonymous user blocked from viewing database.' }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

end
