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
  def get_sign_in_as(user, follow_redirect: true, trace: true, **)
    user = find_user(user).presence or return
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
  def get_sign_out(follow_redirect: true, trace: true, **)
    url  = destroy_user_session_url(revoke: false)
    meth = trace ? :delete : :original_delete
    send(meth, url)
    follow_redirect!   if follow_redirect  && response.redirection?
    clear_current_user if !follow_redirect || response.successful?
  end

  # Run the provided block signed in as the specified user.
  #
  # @param [String, Symbol, User, nil] user
  # @param [Boolean]                   sign_in
  # @param [Boolean]                   sign_out
  #
  # @return [void]
  #
  # @yield Block to execute signed in as *user*.
  #
  def as_user(user, trace: false, sign_in: true, sign_out: true, **)
    sign_in = sign_out = false unless (user &&= find_user(user))
    get_sign_in_as(user, trace: trace) if sign_in && (user != current_user)
    yield
    get_sign_out(trace: trace) if sign_out
  end

  # Local options for #as_user.
  #
  # @type [Array<Symbol>]
  #
  AS_USER_OPT = method_key_params(:as_user).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Run the provided block for each test format.
  #
  # Because the block is expected to invoke #run_test_as (directly or
  # indirectly), *opt* is evaluated as it applies to that method:
  #
  # * If `opt[:sign_in]` is *false*, #run_test_as will expect the caller to
  #   have already caused a sign-in to happen; otherwise this method invokes
  #   #as_user with the expectation that the initial #run_test_as invocation
  #   will cause a sign-in to happen.
  #
  # * If `opt[:sign_out]` is *false*, #run_test_as will expect the caller to be
  #   responsible for causing a sign-out to happen; otherwise this method
  #   invokes #as_user with the expectation that the final #run_test_as
  #   invocation will cause a sign-out to happen.
  #
  # @param [String, Symbol, User, nil] user
  # @param [Array<Symbol>, Symbol]     formats
  # @param [Hash]                      opt
  #
  # @yield Block to execute for each format.
  # @yieldparam [Symbol] format
  #
  def foreach_format(user, formats: TEST_FORMATS, **opt, &blk)
    opt[:sign_in]  = user && opt[:sign_in].is_a?(FalseClass)
    opt[:sign_out] = user && opt[:sign_out].is_a?(FalseClass)
    as_user(user, **opt) do
      Array.wrap(formats).each(&blk)
    end
  end

  # Perform actions within the block signed-on as a test user.
  #
  # @param [String, Symbol, User, nil] user
  # @param [Hash]                      opt    To #run_test and/or #as_user.
  # @param [Proc]                      blk    Required test code to execute.
  #
  # @return [void]
  #
  # @yield Test code to run while signed-on as *user*.
  # @yieldreturn [void]
  #
  def run_test_as(user, **opt, &blk)
    user &&= find_user(user)
    unless opt.key?(:part)
      opt[:part] = 'USER %s' % show_user(user, indent: false, output: false)
    end
    run_test(**opt) do
      as_user(user, **opt, &blk)
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
  # @param [Hash]                 opt   Passed to #assert_result except for
  #                                       #RUN_TEST_OPT and #AS_USER_OPT passed
  #                                       to #run_test_as and local options:
  #
  # @option opt [String]       :redir   Expected redirection.
  # @option opt [Symbol]       :expect  Expected result regardless of the user.
  #                                       Default based on :format; if :nothing
  #                                       then no return status is assumed.
  #
  # @return [void]
  #
  # @yield The caller may provide added assertions or other post-send actions.
  # @yieldreturn [void]
  #
  def send_as(verb, user, url, **opt, &blk)
    format   = format_type(opt.delete(:format))
    run_opt  = opt.extract!(*RUN_TEST_OPT, *AS_USER_OPT)
    redir    = opt.delete(:redir)
    expect   = opt.delete(:expect)
    expect ||= (format == :html) ? :redirect : :unauthorized
    any_stat = %i[any nothing].include?(expect)
    no_body  = (expect == :no_content)

    case format
      when :any  then url = url.sub(%r{\.(html|xml|json)([/?]?|$)}, '\2')
      when :html then url = url.sub(%r{\.html([/?]?|$)}, '\1')
      else            opt[:format] = run_opt[:format] = format if format
    end

    run_test_as(user, **run_opt) do

      # Visit the provided URL.
      url_opt = {}
      if DEBUG_TESTS
        url_opt = run_opt.slice(:format)
        url_opt[:expect] = expect if expect && !any_stat
      end
      send(verb, url, **url_opt)

      # Follow the redirect if one was expected.
      if redir && response.redirection?
        follow_redirect!
        opt.merge!(request.path_parameters)
      end
      opt.merge!(format: format) if format == :any

      # Primary assertions based on initial conditions.
      case
        when any_stat         then assert_result(:any, **opt)
        when no_body          then assert_result(expect, **opt, format: :any)
        when expect           then assert_html_result(expect, **opt)
        when signed_in?       then assert_html_result(:success, **opt) 
        when run_opt[:format] then assert_response :unauthorized       
        else                       assert_response :redirect           
      end

      # Any additional assertions provided by the caller.
      blk&.call

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
    define_method(:"#{verb}_as") do |user, url, **opt, &blk|
      send_as(verb, user, url, **opt, &blk)
    end
  end

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  # noinspection RubyUnusedLocalVariable
  unless ONLY_FOR_DOCUMENTATION

    # HTTP GET *url* as *user*.
    #
    # @param [String] user
    # @param [String] url
    # @param [Hash]   opt
    #
    # @see #send_as
    #
    def get_as(user, url, **opt, &blk); end

    # HTTP PUT *url* as *user*.
    #
    # @param [String] user
    # @param [String] url
    # @param [Hash]   opt
    #
    # @see #send_as
    #
    def put_as(user, url, **opt, &blk); end

    # HTTP POST *url* as *user*.
    #
    # @param [String] user
    # @param [String] url
    # @param [Hash]   opt
    #
    # @see #send_as
    #
    def post_as(user, url, **opt, &blk); end

    # HTTP PUT *url* as *user*.
    #
    # @param [String] user
    # @param [String] url
    # @param [Hash]   opt
    #
    # @see #send_as
    #
    def patch_as(user, url, **opt, &blk); end

    # HTTP DELETE *url* as *user*.
    #
    # @param [String] user
    # @param [String] url
    # @param [Hash]   opt
    #
    # @see #send_as
    #
    def delete_as(user, url, **opt, &blk); end

  end
  # :nocov:

end
