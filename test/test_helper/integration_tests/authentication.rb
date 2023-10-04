# test/test_helper/integration_tests/authentication.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for sign-in.
#
module TestHelper::IntegrationTests::Authentication

  include TestHelper::Utility
  include TestHelper::Debugging

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
  # @param [Boolean]                   follow_redirect
  # @param [Boolean]                   trace
  #
  # @return [void]
  #
  def get_sign_in_as(user, follow_redirect: true, trace: true)
    user = find_user(user)
    return unless user.present?
    url  = sign_in_as_url(id: user.to_s)
    meth = trace ? :get : :original_get
    send(meth, url)
    follow_redirect!       if follow_redirect  && response.redirection?
    set_current_user(user) if !follow_redirect || response.successful?
  end

  # Sign out of the local session.
  #
  # If the request was not successful then `#current_user` will be unchanged.
  #
  # @param [Boolean] follow_redirect
  # @param [Boolean] trace
  #
  # @return [void]
  #
  def get_sign_out(follow_redirect: true, trace: true)
    url  = destroy_user_session_url(revoke: false)
    meth = trace ? :delete : :original_delete
    send(meth, url)
    follow_redirect!   if follow_redirect  && response.redirection?
    clear_current_user if !follow_redirect || response.successful?
  end

  # Perform actions within the block signed-on as a test user.
  #
  # @param [String, Symbol, User, nil] user
  # @param [Hash]                      opt    Passed to #run_test.
  # @param [Proc]                      block  Required test code to execute.
  #
  # @return [void]
  #
  # @yield Test code to run while signed-on as *user*.
  # @yieldreturn [void]
  #
  def as_user(user, **opt, &block)
    user &&= find_user(user)
    unless opt.key?(:part)
      opt[:part] = 'USER %s' % show_user(user, output: false, indent: false)
    end
    test_name = opt.delete(:test)
    if user.nil?
      run_test(test_name, **opt, &block)
    else
      run_test(test_name, **opt) do
        get_sign_in_as(user, trace: false)
        block.call
        get_sign_out(trace: false)
      end
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
  # @option opt [Symbol]       :expect  Expected result regardless of the user.
  # @option opt [Symbol,Array] :only    Allowed formats.
  # @option opt [String]       :redir   Expected redirection.
  #
  # @return [void]
  #
  # @yield The caller may provide added assertions or other post-send actions.
  # @yieldreturn [void]
  #
  def send_as(verb, user, url, **opt, &block)
    run_opt = opt.extract!(*RUN_TEST_OPT)
    redir   = opt.delete(:redir)
    expect  = opt.delete(:expect)
    format  = format_type(opt[:format])

    if format == :html
      url = url.sub(%r{\.html([/?]?|$)}, '\1')
    elsif format
      run_opt[:format] = format
    end

    as_user(user, **run_opt) do

      # Visit the provided URL.
      url_opt = run_opt.slice(:format)
      url_opt[:expect] = expect if DEBUG_TESTS
      send(verb, url, **url_opt)

      # Follow the redirect if one was expected.
      if redir && response.redirection?
        follow_redirect!
        opt.merge!(request.path_parameters)
      end

      # Primary assertions based on initial conditions.
      if expect
        assert_html_result expect, **opt
      elsif signed_in?
        assert_html_result :success, **opt
      elsif url_opt[:format]
        assert_response :unauthorized
      else
        assert_response :redirect
      end

      # Any additional assertions provided by the caller.
      block&.call

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
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:

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

    # :nocov:
  end

end
