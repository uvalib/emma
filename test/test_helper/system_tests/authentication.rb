# test/test_helper/system_tests/authentication.rb
#
# frozen_string_literal: true
# warn_indent:           true

require_relative './flash'
require_relative './keyboard'

# Support for sign-in.
#
module TestHelper::SystemTests::Authentication

  include TestHelper::Utility
  include TestHelper::SystemTests::Common
  include TestHelper::SystemTests::Flash
  include TestHelper::SystemTests::Keyboard

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Sign in as one of the pre-configured users if #AUTH_FAILURE is displayed.
  #
  # @param [String, Symbol, User, nil] arg
  #
  # @raise [Minitest::Assertion]
  #
  # @return [void]
  #
  # @note Currently unused.
  # :nocov:
  def if_needed_sign_in_as(arg)
    sign_in_as(arg) if flash?(alert: AUTH_FAILURE)
  end
  # :nocov:

  # Verify that #AUTH_FAILURE is displayed and sign in as a user.
  #
  # @param [String, Symbol, User, nil] arg
  #
  # @raise [Minitest::Assertion]
  #
  # @return [void]
  #
  # @note Currently unused.
  # :nocov:
  def required_sign_in_as(arg)
    assert_flash(alert: AUTH_FAILURE)
    sign_in_as(arg)
  end
  # :nocov:

  # Sign in as one of the pre-configured users.
  #
  # @param [String, Symbol, User, nil] arg
  # @param [Boolean]                   verify   If *true*, assert success.
  #
  # @raise [Minitest::Assertion]
  #
  # @return [Boolean]
  #
  def sign_in_as(arg, verify: true)
    return false if arg.blank?
    sign_in_out(verify: verify, expect: 'Signed in') do
      user = find_user(arg)
      assert user, -> { "no user for #{arg.inspect}" }
      visit new_user_session_url
      click_on "Sign in as #{user.email}"
    end
  end

  # Sign out as `#current_user`.
  #
  # @param [Boolean] verify           If *true*, assert success.
  #
  # @return [Boolean]
  #
  def sign_out(verify: true)
    return false if not_signed_in?
    sign_in_out(verify: verify, expect: 'signed out') do
      click_on class: 'session-logout'
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Perform sign-in/sign-out.
  #
  # @param [String]  expect   Expected flash message.
  # @param [Boolean] verify   If *true*, assert success.
  #
  # @return [Boolean]
  #
  # @yield  Sign-in/sign-out actions.
  # @yieldreturn [void]
  #
  def sign_in_out(expect:, verify: true)
    done, error = false, nil
    yield
    done = flash?(notice: expect, fatal: verify)
  rescue Minitest::Assertion => e
    error = e
    self.assertions -= 1 unless verify
  rescue => e
    error = e
  ensure
    screenshot   unless done
    raise(error) if error && verify
    close_flash  if done
    done
  end

end
