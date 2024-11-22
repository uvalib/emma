# test/system/tool_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'application_system_test_case'

class ToolTest < ApplicationSystemTestCase

  CTRLR = :tool
  PRM   = { controller: CTRLR }.freeze

  setup do
    @file   = file_fixture('math1.png')
    @member = find_user(:test_dso_1)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'tool - md - anonymous' do
    md_test(nil, meth: __method__)
  end

  test 'tool - md - member' do
    md_test(@member, meth: __method__)
  end

  test 'tool - lookup - anonymous' do
    lookup_test(nil, meth: __method__)
  end

  test 'tool - lookup - member' do
    lookup_test(@member, meth: __method__)
  end

  # ===========================================================================
  # :section: Meta tests
  # ===========================================================================

  test 'tool system test coverage' do
    # Endpoints covered by controller tests:
    skipped = %i[index]
    skipped += %i[get_job_result md_proxy] # Client-only endpoints.
    check_system_coverage ToolController, prefix: 'tool', except: skipped
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  protected

  # Perform a test to use Math Detective to interpret the image of an equation.
  #
  # @param [User, nil]   user
  # @param [Symbol, nil] meth         Calling test method.
  # @param [Hash]        opt          Added to URL parameters.
  #
  # @return [void]
  #
  def md_test(user, meth: nil, **opt)
    action    = :md
    params    = PRM.merge(action: action, **opt)

    start_url = url_for(**params)

    run_test(meth || __method__) do

      if user

        # Successful sign-in should redirect back to the action page.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Provide the image file.
        find('.file-input').attach_file(@file)
        assert_selector '.status-container', wait: 5
        screenshot

        # Wait for completion.
        wait_for_condition(fatal: true) do
          all('.api-container').present?
        end

      else

        show_item { 'Anonymous user blocked from Math Detective.' }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

  # Perform a test to use bibliographic lookup.
  #
  # @param [User, nil]   user
  # @param [Symbol, nil] meth         Calling test method.
  # @param [Hash]        opt          Added to URL parameters.
  #
  # @return [void]
  #
  def lookup_test(user, meth: nil, **opt)
    action    = :lookup
    params    = PRM.merge(action: action, **opt)

    start_url = url_for(**params)

    run_test(meth || __method__) do

      if user

        # Successful sign-in should redirect back to the action page.
        visit start_url
        assert_flash(alert: AUTH_FAILURE)
        sign_in_as(user)

        # Perform lookups.
        check_lookup('author:King title:Carrie')
        check_lookup('title:Carries AND author:"Stephen King"')

      else

        show_item { 'Anonymous user blocked from bibliographic lookup.' }
        assert_no_visit(start_url, :sign_in)

      end

    end
  end

  # Perform a lookup on the bibliographic lookup page.
  #
  # @param [String] query
  #
  # @return [String]
  #
  def check_lookup(query)
    show_item { "Lookup #{query.inspect}" }

    # Perform lookup.
    fill_in 'Query', with: query
    screenshot
    click_on 'Lookup'

    # Wait for completion.
    result = services = nil
    wait_for_condition(fatal: true) do
      errors = all('.item-errors.value').first.text
      result = all('.item-results.value').first.text
      unless services
        result.match(/service: *\[(.*?)\]/)
        services = $1&.split(/, */)&.map { _1.sub(/^"(.*)"$/, '\1') }
      end
      services&.delete_if do |service|
        result.match?(/service: *"#{service}"/).tap do |found|
          show_item { "- results from #{service.inspect}" } if found
        end
      end
      $stderr.puts "Reported errors: #{errors.inspect}" if errors.present?
      services&.blank? || result.match?(/status: *"COMPLETE"/)
    end
    result.to_s
  end

end
