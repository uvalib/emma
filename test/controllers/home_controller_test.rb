# test/controllers/home_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class HomeControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = 'home'
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = [ANONYMOUS, EMMA_DSO].freeze
  TEST_READERS = TEST_USERS

  TEST_USER    = TEST_USERS.last

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'home main as anonymous' do
    # options = OPTIONS.merge(action: 'main')
    TEST_FORMATS.each do |fmt|
      next unless html?(fmt) # NOTE: TESTING_HTML only
      url = home_url(format: fmt)
      run_test(__method__, format: fmt) do
        get url
        assert_redirected_to welcome_url
      end
    end
  end if TESTING_HTML

  test 'home main as emmadso' do
    # options = OPTIONS.merge(action: 'main')
    TEST_FORMATS.each do |fmt|
      next unless html?(fmt) # NOTE: TESTING_HTML only
      url = home_url(format: fmt)
      run_test(__method__, format: fmt) do
        get_sign_in_as(TEST_USER, follow_redirect: false)
        get url
        assert_redirected_to dashboard_url
      end
    end
  end if TESTING_HTML

  test 'home welcome' do
    options = OPTIONS.merge(action: 'welcome')
    TEST_FORMATS.each do |fmt|
      next unless html?(fmt) # NOTE: TESTING_HTML only
      url = welcome_url(format: fmt)
      opt = options.merge(format: fmt)
      run_test(__method__, format: fmt) do
        get url
        assert_result :success, opt
      end
    end
  end if TESTING_HTML

  test 'home dashboard' do
    options = OPTIONS.merge(test: __method__, action: 'dashboard')
    TEST_READERS.each do |user|
      able   = user.present?
      expect = able ? :success : :unauthorized
      opt    = options.merge(expect: expect)
      TEST_FORMATS.each do |fmt|
        url = dashboard_url(format: fmt)
        opt[:format] = fmt
        get_as(user, url, opt)
      end
    end
  end

end
