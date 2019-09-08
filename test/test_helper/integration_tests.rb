# test/test_helper/integration_tests.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Extensions for controller and system tests.
#
module TestHelper::IntegrationTests

  include TestHelper::Debugging

  MEDIA_TYPE = {
    html: 'text/html',
    json: 'application/json',
    text: 'text/plain',
    xml:  'application/xml',
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current user within a test.
  #
  # @return [String]
  # @return [nil]
  #
  def current_user
    @current_user
  end

  # Set the current test user.
  #
  # @param [String] user
  #
  # @return [String]
  #
  def set_current_user(user)
    @current_user = user
  end

  # Clear the current test user.
  #
  # @return [nil]
  #
  def clear_current_user
    set_current_user(nil)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate that this is an authenticated session.
  #
  def signed_in?
    current_user.present?
  end

  # Indicate that this is an anonymous session.
  #
  def not_signed_in?
    !signed_in?
  end

  # Indicate that this is a session authenticated as the given user.
  #
  # @param [String] user
  #
  def signed_in_as?(user)
    user.present? && (user == current_user)
  end

  # Indicate that this is not a session authenticated as the given user.
  #
  # @param [String] user
  #
  def not_signed_in_as?(user)
    user.present? && (user != current_user)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  AS_USER_OPT = RUN_TEST_OPT

  # Perform actions within the block signed-on as a test user.
  #
  # @param [String] user
  # @param [Hash]   opt               Passed to #run_test.
  #
  # @yield Test code to run while signed-on as *user*.
  # @yieldreturn [void]
  #
  # @return [void]
  #
  def as_user(user, **opt, &block)
    unless opt.key?(:part)
      part = show_user(user, output: false)
      part = "USER #{part}"
      opt  = opt.merge(part: part)
    end
    run_test(**opt) do
      get_sign_in_as(user)
      reset!
      block.call
      get_sign_out
    end
  end

  # Sign in as a test user.
  #
  # @param [String] user
  #
  # @return [void]
  #
  def get_sign_in_as(user)
    clear_current_user
    if user
      get sign_in_as_path(id: user)
      set_current_user(user) if @response.successful?
    end
  end

  # Sign out.
  #
  # @return [void]
  #
  def get_sign_out
    clear_current_user
    delete destroy_user_session_path
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Invoke an endpoint as the given user.
  #
  # @param [Symbol] verb              HTTP verb (:get, :put, :post, :delete)
  # @param [String] user              User identity to assume.
  # @param [String] endpoint          Target URL or relative path.
  # @param [Hash]   opt               Passed to #assert_result except for the
  #                                     options for #as_user and local option:
  #
  # @option opt [Symbol] :expect      Expected result regardless of the user.
  #
  # @return [void]
  #
  def send_as(verb, user, endpoint, **opt)
    as_user_opt, assert_opt = partition_options(opt, *AS_USER_OPT)
    expected = assert_opt.delete(:expect)
    as_user(user, **as_user_opt) do
      send(verb, endpoint)
      if expected
        assert_html_result expected, assert_opt
      elsif signed_in?
        assert_html_result :success, assert_opt
      else
        assert_response :redirect
      end
    end
  end

  # GET endpoint as the given user.
  #
  # @param [String] user              User identity to assume.
  # @param [String] endpoint          Target URL or relative path.
  # @param [Hash]   opt               Passed to #send_as.
  #
  # @return [void]
  #
  def get_as(user, endpoint, **opt)
    send_as(:get, user, endpoint, **opt)
  end

  # POST endpoint as the given user.
  #
  # @param [String] user              User identity to assume.
  # @param [String] endpoint          Target URL or relative path.
  # @param [Hash]   opt               Passed to #send_as.
  #
  # @return [void]
  #
  def post_as(user, endpoint, **opt)
    send_as(:post, user, endpoint, **opt)
  end

  # PUT endpoint as the given user.
  #
  # @param [String] user              User identity to assume.
  # @param [String] endpoint          Target URL or relative path.
  # @param [Hash]   opt               Passed to #send_as.
  #
  # @return [void]
  #
  def put_as(user, endpoint, **opt)
    send_as(:put, user, endpoint, **opt)
  end

  # DELETE endpoint as the given user.
  #
  # @param [String] user              User identity to assume.
  # @param [String] endpoint          Target URL or relative path.
  # @param [Hash]   opt               Passed to #send_as.
  #
  # @return [void]
  #
  def delete_as(user, endpoint, **opt)
    send_as(:delete, user, endpoint, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Assert that the response is 'text/html'.
  #
  # @param [Symbol] status
  # @param [Hash]   opt               Passed to #assert_result.
  #
  # @see #assert_result
  #
  def assert_html_result(status, **opt)
    opt = opt.merge(media_type: :html) unless opt.key?(:media_type)
    assert_result(status, **opt)
  end

  # Assert that the response is 'application/json'.
  #
  # @param [Symbol] status
  # @param [Hash]   opt               Passed to #assert_result.
  #
  # @see #assert_result
  #
  def assert_json_result(status, **opt)
    opt = opt.merge(media_type: :json) unless opt.key?(:media_type)
    assert_result(status, **opt)
  end

  # Assert that the response is 'application/xml'.
  #
  # @param [Symbol] status
  # @param [Hash]   opt               Passed to #assert_result.
  #
  # @see #assert_result
  #
  def assert_xml_result(status, **opt)
    opt = opt.merge(media_type: :xml) unless opt.key?(:media_type)
    assert_result(status, **opt)
  end

  # Assert that the response is 'text/plain'.
  #
  # @param [Symbol] status
  # @param [Hash]   opt               Passed to #assert_result.
  #
  # @see #assert_result
  #
  def assert_text_result(status, **opt)
    opt = opt.merge(media_type: :text) unless opt.key?(:media_type)
    assert_result(status, **opt)
  end

  # Assert that the response matches the given criteria.
  #
  # @param [Symbol] status
  # @param [Hash]   opt
  #
  # @options opt [String]        :from
  # @options opt [String,Symbol] :controller
  # @options opt [String,Symbol] :action
  # @options opt [String,Symbol] :media_type
  #
  # @raise [Minitest::Assertion]      If one or more criteria don't match.
  #
  # @return [void]                    If all criteria match.
  #
  def assert_result(status, **opt)

    assert_response status

    action, controller = (opt[:from].split('#').reverse if opt[:from])
    controller = opt[:controller]&.to_s || controller
    action     = opt[:action]&.to_s     || action
    media_type = opt[:media_type]
    media_type = MEDIA_TYPE[media_type] if media_type.is_a?(Symbol)

    assert_equal controller, @controller.controller_path if controller.present?
    assert_equal action,     @controller.action_name     if action.present?
    assert_equal media_type, @response.media_type        if media_type.present?

  end

end
