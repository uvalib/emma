# test/test_helper/debugging.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for debugging tests.
#
module TestHelper::Debugging

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  TEST_START   = 'START >>'
  TEST_END     = 'END <<<<'
  TEST_DEFAULT = '(UNNAMED)'

  # Produce the top frame of debug output for a test.
  #
  # @param [String, Symbol, nil] test
  # @param [String, nil]         part
  # @param [Hash]                opt  Passed to #emit_lines.
  #
  # @return [void]
  #
  def show_test_start(test: nil, part: nil, **opt)
    test = show_test_part(TEST_START, test: test, part: part)
    emit_lines(nil, test, **opt)
  end
    .tap { neutralize(_1) unless DEBUG_TESTS }

  # Produce the bottom frame of debug output for a test.
  #
  # @param [String, Symbol, nil] test
  # @param [String, nil]         part
  # @param [Hash]                opt  Passed to #emit_lines.
  #
  # @return [void]
  #
  def show_test_end(test: nil, part: nil, **opt)
    test = show_test_part(TEST_END, test: test, part: part)
    emit_lines(test, nil, **opt)
  end
    .tap { neutralize(_1) unless DEBUG_TESTS }

  # Produce a framing line for debug test output.
  #
  # @param [String]              tag
  # @param [String, Symbol, nil] test
  # @param [String, nil]         part
  #
  # @return [String]
  #
  def show_test_part(tag, test: nil, part: nil, **)
    test = TEST_DEFAULT unless test
    test = "#{test} - #{part}" if part
    "#{tag} | #{test} | #{tag}"
  end
    .tap { neutralize(_1) unless DEBUG_TESTS }

  # Local options for #show_test_start and #show_test_end.
  #
  # @type [Array<Symbol>]
  #
  SHOW_TEST_OPT = method_key_params(:show_test_part).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Display item model in output.
  #
  # @param [ActiveRecord::Base] item
  # @param [Boolean]            reflections
  # @param [Hash]               opt           Passed to #show_item.
  #
  # @return [String]
  #
  def show_model(item, reflections: true, **opt)
    reflections &&= show_reflections(item, indent: false, output: false)
    parts = reflections ? ["\nREFLECTIONS", reflections] : []
    show_item(item.pretty_inspect, *parts, **opt)
  end
    .tap { neutralize(_1) unless DEBUG_TESTS }

  # Display item model associations in output.
  #
  # @param [ActiveRecord::Base] item
  # @param [Hash]               opt   Passed to #show_item.
  #
  # @return [String, nil]
  #
  def show_reflections(item, **opt)
    item.try(:_reflections)&.map { |key, entry|
      items = (Array.wrap(item.send(key)) if item.respond_to?(key))
      count = items&.size || 'ERROR'
      items = items&.map!(&:pretty_inspect)&.prepend("\n")&.join("\n")
      "\n#{key} (#{count}) [#{entry.class}]#{items}"
    }.then { |parts| show_item(*parts, **opt) if parts.present? }
  end
    .tap { neutralize(_1) unless DEBUG_TESTS }

  # Display a URL in output.
  #
  # @param [URI, String, nil] url     Default: `#current_url`.
  # @param [Array]            note    Additional text on the line.
  # @param [Hash]             opt     Passed to #show_item.
  #
  # @return [String]
  #
  def show_url(url = nil, *note, **opt)
    url = opt.delete(:url) || url || current_url
    show_item("URL = #{url}", join: ' ', **opt) { note.compact }
  end
    .tap { neutralize(_1) unless DEBUG_TESTS }

  # Display a user in output.
  #
  # @param [String, Symbol, User, nil] user   Default: `#current_user`.
  # @param [Hash]                      opt    Passed to #show_item.
  #
  # @return [String]
  #
  def show_user(user = nil, **opt)
    user = opt.delete(:user) || user || current_user
    user = user && find_user(user) || :anonymous
    show_item(user.to_s, **opt)
  end
    .tap { neutralize(_1) unless DEBUG_TESTS }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  TEST_INDENT = (' ' * 8).freeze

  # Display item contents in output.
  #
  # If *join* results a multi-line value then *indent* is applied to each line.
  # If *join* is overridden to be *nil* or a string without a newline then
  # *indent* is applied only to the resulting line itself.
  #
  # @param [Array<*>]                   items
  # @param [String,nil]                 join
  # @param [String,Integer,Boolean,nil] indent  Default: #TEST_INDENT
  # @param [Boolean]                    output  If *false* just return result.
  # @param [Hash]                       opt     Passed to #show_model except
  #                                               #EMIT_LINES_OPT to
  #                                               #emit_lines.
  #
  # @return [String]                            The displayable result.
  #
  # @yield To supply additional items.
  # @yieldreturn [Array, String, any, nil]
  #
  def show_item(*items, join: "\n", indent: true, output: true, **opt)
    indent = TEST_INDENT                   if indent.is_a?(TrueClass)
    indent = ' ' * (positive(indent) || 0) unless indent.is_a?(String)
    inner  = (indent if join&.include?("\n"))
    e_opt  = opt.extract!(*EMIT_LINES_OPT)

    items.concat(Array.wrap(yield)) if block_given?
    items.flatten.map { |item|
      # == Transform *item* to a String.
      next item if item.is_a?(String)
      next item.pretty_inspect unless item.is_a?(ActiveRecord::Base)
      e_opt[:start]  ||= "\n"
      e_opt[:finish] ||= "\n"
      show_model(item, **opt, indent: false, output: false)

    }.flat_map { |item|
      # == Split *item* into newline-delimited parts.
      next item if item == "\n"
      item.chomp.split("\n").tap { |part| part[-1] = "\n" if part[-1] == '' }

    }.map.with_index { |item, idx|
      # == Prepend a prefix if appropriate.
      next item if item.match?(/^ *\*{3, } /)
      idx.zero? ? "#{indent}#{item}" : "#{inner}#{item}"

    }.join(join).tap { |result|
      # == Output the result as a side effect if requested.
      emit_lines(result, **e_opt) if output
    }
  end
    .tap { neutralize(_1) unless DEBUG_TESTS }

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Send one or more lines to $stderr.
  #
  # @param [Array, nil]  lines        Nil elements are interpreted as newlines.
  # @param [String, nil] prefix       Prepended to each line.
  # @param [String, nil] suffix       Appended to each line.
  # @param [String, nil] start        Prepended to the first line.
  # @param [String, nil] finish       Appended to the last line.
  #
  # @return [void]
  #
  def emit_lines(*lines, prefix: nil, suffix: nil, start: nil, finish: nil, **)
    $stdout.flush
    $stderr.flush
    if prefix || suffix || start || finish
      prefix = "#{prefix} " if prefix && !prefix.end_with?(' ', "\t", "\n")
      finish = "\n\n"       if finish == "\n"
      lines.flatten!
      lines.map! { "#{prefix}#{_1}" }     if prefix
      lines.map! { "#{_1}#{suffix}" }     if suffix
      lines[0]  = "#{start}#{lines[0]}"   if start
      lines[-1] = "#{lines[-1]}#{finish}" if finish
    end
    lines.each { $stderr.puts _1 }
    $stderr.flush
  end

  # Local options for #emit_lines.
  #
  # @type [Array<Symbol>]
  #
  EMIT_LINES_OPT = method_key_params(:emit_lines).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  TRACE_NL           = ' \n '.freeze # Not " \n ".
  TRACE_BODY         = 2 * 1024
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
    show_trace(**opt, finish: "\n") do
      if (user ||= current_user)
        org  = user.org&.then { "org = #{_1.long_name.inspect} (#{_1.id})" }
        name = "#{user.to_s.inspect} (#{user.id})"
        user = [name, org].compact.join('; ')
      end
      lines = {}
      lines[:user]   = user
      lines[:format] = format&.inspect
      lines[:method] = verb&.inspect
      lines[:url]    = url
      lines.transform_values! { _1 || '-' }.reverse_merge!(TRACE_SEPARATOR)
    end
  end
    .tap { neutralize(_1) unless DEBUG_TESTS }

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
      stat  = status || response&.response_code
      body  = response&.body&.presence&.gsub(/( *\n *)+/, TRACE_NL)
      body  = body&.sub(/(<head[^>]*>).*(<\/head>)/, '\1...\2')
      body  = body&.sub(/(<header[^>]*>).*(<\/header>)/, '\1...\2')
      lines = {}
      lines[:redir]  = response.redirect_url if response&.redirection?
      lines[:status] = stat&.inspect
      lines[:expect] = expect&.inspect
      lines[:body]   = body&.truncate(TRACE_BODY)
      lines.transform_values! { _1 || '-' }.merge!(TRACE_SEPARATOR)
    end
  end
    .tap { neutralize(_1) unless DEBUG_TESTS }

  # Display output before or after invoking an HTTP method.
  #
  # @param [Boolean, nil] trace
  # @param [Hash]         opt         Passed to #show_item.
  #
  # @return [String, nil]             The displayable result.
  #
  # @yield To supply pairs to be displayed.
  # @yieldreturn [Hash]
  #
  def show_trace(trace: nil, **opt)
    return if silence_tracing ? (trace != true) : (trace == false)
    pairs  = block_given? && yield || {}
    width  = pairs.keys.map(&:to_s).sort_by(&:size).last&.size
    format = "*** %-#{width}s = %s"
    show_item(**opt) { pairs.map { sprintf(format, _1, _2) } }
  end
    .tap { neutralize(_1) unless DEBUG_TESTS }

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

end

# This module is included in ApplicationControllerTestCase to support tracing
# of HTTP method calls.
#
# @!method original_get
#   The superclass :get method (without pre-/post-trace output).
#
# @!method original_put
#   The superclass :put method (without pre-/post-trace output).
#
# @!method original_post
#   The superclass :post method (without pre-/post-trace output).
#
# @!method original_patch
#   The superclass :patch method (without pre-/post-trace output).
#
# @!method original_delete
#   The superclass :delete method (without pre-/post-trace output).
#
# @!method original_head
#   The superclass :head method (without pre-/post-trace output).
#
module TestHelper::Debugging::Trace

  include TestHelper::Debugging

  PRE_OPT   = (SHOW_TRACE_OPT + SHOW_PRE_SEND_OPT).freeze
  POST_OPT  = (SHOW_TRACE_OPT + SHOW_POST_SEND_OPT).freeze
  TRACE_OPT = (PRE_OPT + POST_OPT).uniq.freeze

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
        if DEBUG_TESTS
          define_method(meth) do |*args, **opt|
            # Extract any options specific to the tracing methods.  Remaining
            # options are passed to the underlying HTTP method call.
            trace_opt = opt.extract!(*TRACE_OPT)
            post_opt  = trace_opt.slice(*POST_OPT)
            pre_opt   = trace_opt.slice(*PRE_OPT)
            # Call the underlying HTTP method between tracing output calls.
            show_pre_send(meth, args.first, **pre_opt)
            super(*args, **opt)
            show_post_send(**post_opt, response: response)
          end
        else
          define_method(meth) do |*args, **opt|
            # Clean up tracing method options for the underlying HTTP method.
            super(*args, **opt.except(*TRACE_OPT))
          end
        end
      end
    end
  end

end
