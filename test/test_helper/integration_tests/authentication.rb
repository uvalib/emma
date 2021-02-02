# test/test_helper/integration_tests/authentication.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for sign-in.
#
module TestHelper::IntegrationTests::Authentication

  include TestHelper::Utility
  include TestHelper::Debugging

  # Text indicating an authentication failure.
  #
  # @type [String]
  #
  AUTH_FAILURE = I18n.t('devise.failure.unauthenticated').freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current user within a test.
  #
  # @return [User, nil]
  #
  def current_user
    @current_user
  end

  # Set the current test user.
  #
  # @param [String, Symbol, User, nil] user
  #
  # @return [User, nil]
  #
  def set_current_user(user)
    @current_user = find_user(user)
  end

  # Clear the current test user.
  #
  # @return [nil]
  #
  def clear_current_user
    set_current_user(nil)
  end

  # Indicate whether is an authenticated session.
  #
  def signed_in?
    current_user.present?
  end

  # Indicate whether is an anonymous session.
  #
  def not_signed_in?
    current_user.blank?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Sign in as a test user.
  #
  # If the request was not successful then `#current_user` will be unchanged.
  #
  # @param [String, Symbol, User, nil] user
  # @param [Boolean]              follow_redirect
  #
  # @return [void]
  #
  def get_sign_in_as(user, follow_redirect: true)
    user = find_user(user)
    return unless user.present?
    get sign_in_as_url(id: user.to_s)
    follow_redirect!       if follow_redirect  && response.redirection?
    set_current_user(user) if !follow_redirect || response.successful?
  end

  # Sign out of the local session.
  #
  # If the request was not successful then `#current_user` will be unchanged.
  #
  # @param [Boolean] follow_redirect
  #
  # @return [void]
  #
  def get_sign_out(follow_redirect: true)
    delete destroy_user_session_url(revoke: false)
    follow_redirect!   if follow_redirect  && response.redirection?
    clear_current_user if !follow_redirect || response.successful?
  end

  # Perform actions within the block signed-on as a test user.
  #
  # @param [String, Symbol, User, nil] user
  # @param [Hash]                      opt    Passed to #run_test.
  #
  # @return [void]
  #
  # @yield Test code to run while signed-on as *user*.
  # @yieldreturn [void]
  #
  def as_user(user, **opt)
    user = find_user(user)
    unless opt.key?(:part)
      name = show_user(user: user, output: false)
      opt[:part] = "USER #{name}"
    end
    run_test(opt[:test], **opt) do
      get_sign_in_as(user)
      yield # Run provided test code.
      get_sign_out
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Invoke an endpoint as the given user.
  #
  # @param [Symbol]               verb  HTTP verb (:get, :put, :post, :delete)
  # @param [String, Symbol, User] user  User identity to assume.
  # @param [String]               url   Target URL or relative path.
  # @param [Hash]                 opt   Passed to #assert_result except for the
  #                                       options for #as_user and local:
  #
  # @option opt [Symbol] :expect      Expected result regardless of the user.
  #
  # @return [void]
  #
  # @yield The caller may provide added assertions or other post-send actions.
  # @yieldreturn [void]
  #
  def send_as(verb, user, url, **opt)
    as_user_opt, assert_opt = partition_options(opt, *RUN_TEST_OPT)
    expect = assert_opt.delete(:expect)
    format = assert_opt[:format]
    if html?(format)
      url    = url.sub(/\.html(\??|$)/, '\1')
      format = nil
    end
    as_user_opt[:format] = format if format
    as_user(user, **as_user_opt) do
      method_opt = {}
      method_opt[:format] = format if format
      method_opt[:expect] = expect if TestHelper::DEBUG_TESTS
      send(verb, url, **method_opt)
      if expect
        assert_html_result expect, assert_opt
      elsif signed_in?
        assert_html_result :success, assert_opt
      elsif format
        assert_response :unauthorized
      else
        assert_response :redirect
      end
      yield if block_given?
    end
  end

  # Define HTTP method-specific shortcuts for #send_as.
  #
  # @!method get_as
  # @!method put_as
  # @!method post_as
  # @!method patch_as
  # @!method delete_as
  #
  %i[get put post patch delete].each do |verb|
    define_method(:"#{verb}_as") do |user, url, **opt, &block|
      send_as(verb, user, url, **opt, &block)
    end
  end

  # Non-functional hints for RubyMine type checking.
  # noinspection RubyUnusedLocalVariable
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION

    # HTTP GET *url* as *user*.
    #
    # @param [String] user
    # @param [String] url
    # @param [Hash]   opt
    #
    # @see #send_as
    #
    def get_as(user, url, **opt, &block); end

    # HTTP PUT *url* as *user*.
    #
    # @param [String] user
    # @param [String] url
    # @param [Hash]   opt
    #
    # @see #send_as
    #
    def put_as(user, url, **opt, &block); end

    # HTTP POST *url* as *user*.
    #
    # @param [String] user
    # @param [String] url
    # @param [Hash]   opt
    #
    # @see #send_as
    #
    def post_as(user, url, **opt, &block); end

    # HTTP PUT *url* as *user*.
    #
    # @param [String] user
    # @param [String] url
    # @param [Hash]   opt
    #
    # @see #send_as
    #
    def patch_as(user, url, **opt, &block); end

    # HTTP DELETE *url* as *user*.
    #
    # @param [String] user
    # @param [String] url
    # @param [Hash]   opt
    #
    # @see #send_as
    #
    def delete_as(user, url, **opt, &block); end

  end
  # :nocov:

end
