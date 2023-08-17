# test/test_helper/debugging.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for debugging tests.
#
module TestHelper::Debugging

  TEST_DEBUG_FRAME  = '-------'
  TEST_DEBUG_INDENT = '  '

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Produce the top frame of debug output for a test.
  #
  # @param [String, Symbol, nil] test_name
  # @param [Symbol]              test       Overrides *test_name* if given.
  # @param [String]              part
  # @param [String]              frame      Default: #TEST_DEBUG_FRAME.
  #
  # @return [void]
  #
  def show_test_start(test_name, test: nil, part: nil, frame: nil, **)
    line = frame || TEST_DEBUG_FRAME
    name = test  || test_name
    name = "#{name} - #{part} -"                            if name && part
    line = "#{line} START >> | #{name} | START >> #{line}"  if name
    $stderr.puts "\n#{line}"
    $stderr.puts
  end

  # Produce the bottom frame of debug output for a test.
  #
  # @param [String, Symbol, nil] test_name
  # @param [Symbol]              test       Overrides *test_name* if given.
  # @param [String]              part
  # @param [String]              frame      Default: #TEST_DEBUG_FRAME.
  #
  # @return [void]
  #
  def show_test_end(test_name, test: nil, part: nil, frame: nil, **)
    line = frame || TEST_DEBUG_FRAME
    name = test  || test_name
    name = "#{name} - #{part}"                              if name && part
    line = "#{line} END <<<< | #{name} | END <<<< #{line}"  if name
    $stderr.puts line
    $stderr.puts
    $stderr.puts
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  SHOW_MODEL_OPT = %i[indent reflections].freeze

  # Display item model in output.
  #
  # @param [ActiveRecord::Base] item
  # @param [Hash]               opt     Passed to #show except for:
  #
  # @option opt [String]  :indent       Default: #TEST_DEBUG_INDENT
  # @option opt [Boolean] :reflections  Default: *true*
  #
  # @return [String]
  #
  def show_model(item, **opt)
    show_opt = remainder_hash!(opt, *SHOW_MODEL_OPT)
    details  = opt[:reflections] || !opt.key?(:reflections)
    indent   = opt[:indent]|| TEST_DEBUG_INDENT
    not_indented = (indent == TEST_DEBUG_INDENT)
    show(**show_opt) do
      item.pretty_inspect.tap do |result|
        result.prepend("\n") if not_indented
        if details
          reflections = show_reflections(item, indent: indent, output: false)
          if reflections.present?
            result << "\n#{indent}REFLECTIONS\n\n"
            result << reflections.gsub(/^/, indent)
          end
        end
        result << "\n\n" if not_indented
      end
    end
  end

  # Display item model associations in output.
  #
  # @param [ActiveRecord::Base] item
  # @param [Hash]               opt   Passed to #show except for:
  #
  # @option opt [String] :indent      Default: #TEST_DEBUG_INDENT
  #
  # @return [String]
  #
  def show_reflections(item, **opt)
    show_opt = remainder_hash!(opt, :indent)
    indent   = opt[:indent] || TEST_DEBUG_INDENT
    show(**show_opt) do
      item._reflections.map do |key, entry|
        items = Array.wrap(item.send(key)) rescue nil
        count = items ? items.size : 'ERROR'
        items &&= items.map { |i| i.pretty_inspect.gsub(/^/, indent) }.presence
        items &&= items.join("\n").prepend("\n\n")
        "#{key} (#{count}) [#{entry.class}]#{items}"
      end
    end
  end

  # Display a URL in output.
  #
  # @param [URI, String, nil] url     Default: `#current_url`.
  # @param [Hash]             opt     Passed to #show.
  #
  # @return [String]
  #
  def show_url(url: nil, **opt)
    show("URL = #{url || current_url}", **opt)
  end

  # Display a user in output.
  #
  # @param [String, Symbol, User, nil] user   Default: `#current_user`.
  # @param [Hash]                      opt    Passed to #show.
  #
  # @return [String]
  #
  def show_user(user: nil, **opt)
    user ||= current_user
    user   = user && find_user(user) || :anonymous
    show(user.to_s, **opt)
  end

  # Display item contents in output.
  #
  # @param [Array<*>] items
  # @param [Hash]     opt             Passed to #show_model except for:
  #
  # @option opt [String] :output      If *false* the result is not displayed.
  #
  # @return [String]                  The displayable result.
  #
  # @yield To supply additional items.
  # @yieldreturn [Array, String, *]
  #
  def show(*items, **opt)
    model_opt = opt.extract!(*SHOW_MODEL_OPT)
    model_opt[:output] = false
    items += Array.wrap(yield) if block_given?
    items.flatten.map { |item|
      case item
        when String             then item
        when ActiveRecord::Base then show_model(item, **model_opt)
        else                         item.pretty_inspect
      end
    }.join("\n\n").tap { |result|
      $stderr.puts result unless opt[:output].is_a?(FalseClass)
    }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  TRACE_NL           = (' ' * 4).freeze
  TRACE_BODY         = 4 * 1024
  TRACE_SEPARATOR    = { ('*' * 7) => ('*' * 65) }.deep_freeze

  SHOW_PRE_SEND_OPT  = %i[user format verb url].freeze
  SHOW_POST_SEND_OPT = %i[expect status response].freeze
  SHOW_TRACE_OPT     = %i[indent trace].freeze

  # Display conditions prior to invoking an HTTP method.
  #
  # @param [Symbol] verb              HTTP verb (:get, :put, :post, :delete)
  # @param [String] url               Target URL or relative path.
  # @param [String] user              Default: `#current_user`.
  # @param [Symbol] format            Result format (:html, :json, :xml).
  # @param [Hash]   opt               Passed to #show_trace.
  #
  # @return [String, nil]             The displayable result.
  #
  def show_pre_send(verb, url, user: nil, format: nil, **opt)
    show_trace(**opt) do
      lines = {}
      lines[:user]   = (user || current_user)&.to_s.inspect
      lines[:format] = format&.inspect || '-'
      lines[:method] = verb.inspect
      lines[:url]    = url.inspect
      TRACE_SEPARATOR.merge(lines)
    end
  end

  # Display conditions after invoking an HTTP method.
  #
  # @param [Symbol, String, Integer]      expect
  # @param [Symbol, String, Integer]      status
  # @param [ActionDispatch::TestResponse] response
  # @param [Hash]                         opt       Passed to #show_trace.
  #
  # @return [String, nil]             The displayable result.
  #
  def show_post_send(expect: nil, status: nil, response: nil, **opt)
    show_trace(**opt) do
      redir = response&.redirection? && response.redirect_url
      body  = response&.body&.gsub(/\n/, TRACE_NL)&.truncate(TRACE_BODY)
      lines = {}
      lines[:redir]  = redir.inspect if redir
      lines[:status] = (status || response&.response_code).inspect
      lines[:expect] = expect&.inspect || '-'
      lines[:body]   = body
      lines.merge!(TRACE_SEPARATOR)
    end
  end

  # show_trace
  #
  # @param [String, Integer] indent
  # @param [Boolean, nil]    trace
  # @param [Hash] opt                 Passed to #show.
  #
  # @return [String, nil]             The displayable result.
  #
  # @yield To supply pairs to be displayed.
  # @yieldreturn [Hash]
  #
  def show_trace(indent: '', trace: nil, **opt)
    return if silence_tracing ? (trace != true) : (trace == false)
    # noinspection RubyMismatchedArgumentType
    indent = ' ' * indent if indent.is_a?(Integer)
    pairs  = block_given? && yield || {}
    width  = pairs.keys.map(&:to_s).sort_by(&:size).last&.size || ''
    format = "#{indent}*** %-#{width}s = %s"
    lines  = pairs.map { |k, v| sprintf(format, k, v) }
    show(**opt) do
      lines.join("\n") << "\n\n"
    end
  end

  # Execute the provided block with tracing turned off to allow for executions
  # which do not clutter the output.
  #
  def without_tracing
    self.silence_tracing = true
    yield
    self.silence_tracing = false
  end

  # Flag indicating that #show_trace should be silenced.
  #
  # @return [Boolean]
  #
  attr_accessor :silence_tracing

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Neutralize debugging methods when not debugging.
  instance_methods(false).each { |m| neutralize(m) } unless DEBUG_TESTS

end

# This module is included in ActionDispatch::IntegrationTest to support tracing
# of HTTP method calls.
#
# @!method original_get
#   The superclass :get method (without pre/post trace output).
#
# @!method original_put
#   The superclass :put method (without pre/post trace output).
#
# @!method original_post
#   The superclass :post method (without pre/post trace output).
#
# @!method original_patch
#   The superclass :patch method (without pre/post trace output).
#
# @!method original_delete
#   The superclass :delete method (without pre/post trace output).
#
# @!method original_head
#   The superclass :head method (without pre/post trace output).
#
module TestHelper::Debugging::Trace

  if DEBUG_TESTS

    include TestHelper::Debugging

    PRE_OPTIONS   = [*SHOW_TRACE_OPT, *SHOW_PRE_SEND_OPT].freeze
    POST_OPTIONS  = [*SHOW_TRACE_OPT, *SHOW_POST_SEND_OPT].freeze
    TRACE_OPTIONS = [*PRE_OPTIONS, *POST_OPTIONS].uniq.freeze

    # Override HTTP methods defined in ActionDispatch::Integration::Runner in
    # order to surround the method calls with trace debugging information.
    #
    # No override methods are created if *base* is some other class/module
    # which doesn't define these methods.
    #
    # @param [Module] base
    #
    def self.included(base)
      base.class_eval do
        %i[get put post patch delete head].each do |meth|
          next unless method_defined?(meth)
          alias_method :"original_#{meth}", meth
          define_method(meth) do |*args, **opt|
            # Extract any options specific to the tracing methods.  Remaining
            # options are passed to the underlying HTTP method call.
            trace_opt = opt.extract!(*TRACE_OPTIONS)
            post_opt  = trace_opt.slice(*POST_OPTIONS)
            pre_opt   = trace_opt.slice(*PRE_OPTIONS)
            # Call the underlying HTTP method between tracing output calls.
            show_pre_send(meth, args.first, **pre_opt)
            super(*args, **opt)
            show_post_send(**post_opt, response: response)
          end
        end
      end
    end

  end

end
