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

  RUN_TEST_OPT = %i[test part frame].freeze

  # Run the test code provided via the block.
  #
  # When debugging, this frames the console output generated by the test.
  #
  # @param [String, Symbol, nil] test_name
  # @param [Hash]                opt        Passed to #show_test_start and
  #                                           #show_test_end except for:
  #
  # @option opt [Symbol] :format
  #
  # @return [void]
  #
  def run_test(test_name, **opt)
    error  = nil
    format = opt.delete(:format)
    format = nil if html?(format)
    opt[:part] = ["[#{format.to_s.upcase}]", opt[:part]].join(' - ') if format
    show_test_start(test_name, **opt)
    yield # Run test code provided in the block.
  rescue Exception => error
    show "[#{error.class}: #{error}]"
  ensure
    show_test_end(test_name, **opt)
    raise error if error
  end

  # Produce the top frame of debug output for a test.
  #
  # @param [String, Symbol] test_name
  # @param [Hash]           opt
  #
  # @option opt [Symbol] :test        Overrides *test_name* if given.
  # @option opt [String] :part
  # @option opt [String] :frame       Default: #TEST_DEBUG_FRAME.
  #
  # @return [void]
  #
  def show_test_start(test_name, **opt)
    part = opt[:part]
    name = opt[:test]  || test_name
    name = "#{name} - #{part} -"            if name && part
    line = opt[:frame] || TEST_DEBUG_FRAME
    line = "#{line} #{name} START #{line}"  if line && name
    $stderr.puts "\n#{line}\n"
  end

  # Produce the bottom frame of debug output for a test.
  #
  # @param [String, Symbol] test_name
  # @param [Hash]           opt
  #
  # @option opt [Symbol] :test        Overrides :name if given.
  # @option opt [String] :part
  # @option opt [String] :frame       Default: #TEST_DEBUG_FRAME.
  #
  # @return [void]
  #
  def show_test_end(test_name, **opt)
    part = opt[:part]
    name = opt[:test]  || test_name
    name = "#{name} - #{part}"              if name && part
    line = opt[:frame] || TEST_DEBUG_FRAME
    line = "#{line} END #{name} #{line}"    if line && name
    $stderr.puts "#{line}\n\n"
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
    opt, show_opt = partition_options(opt, *SHOW_MODEL_OPT)
    details = opt[:reflections] || !opt.key?(:reflections)
    indent  = opt[:indent]|| TEST_DEBUG_INDENT
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
    opt, show_opt = partition_options(opt, :indent)
    indent = opt[:indent] || TEST_DEBUG_INDENT
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
    url ||= "URL = #{current_url}"
    show(url.to_s, **opt)
  end

  # Display a user in output.
  #
  # @param [String, Symbol, User] user  Default: `#current_user`.
  # @param [Hash]                 opt   Passed to #show.
  #
  # @return [String]
  #
  def show_user(user: nil, **opt)
    user ||= current_user || 'anonymous'
    user = find_user(user) if user.is_a?(Symbol)
    show(user.to_s, **opt)
  end

  # Display item contents in output.
  #
  # @param [Array] items
  # @param [Hash]  opt                Passed to #show_model except for:
  #
  # @option opt [String] :output      If *false* the result is not displayed.
  #
  # @yield The caller generates line(s) to append to *items*.
  # @yieldreturn [Array, String, *]
  #
  # @return [String]                  The displayable result.
  #
  def show(*items, **opt)
    model_opt, opt = partition_options(opt, *SHOW_MODEL_OPT)
    model_opt[:output] = false
    items += Array.wrap(yield) if block_given?
    items.flatten.map { |item|
      case item
        when String             then item
        when ActiveRecord::Base then show_model(item, **model_opt)
        else                         item.pretty_inspect
      end
    }.join("\n\n").tap { |result|
      $stderr.puts result unless opt[:output] == false
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
  SHOW_TRACE_OPT     = %i[indent].freeze

  # Display conditions prior to invoking an HTTP method.
  #
  # @param [Symbol] verb              HTTP verb (:get, :put, :post, :delete)
  # @param [String] url               Target URL or relative path.
  # @param [Hash]   opt               Passed to #show_trace except for:
  #
  # @option opt [String] :user
  # @option opt [Symbol] :format      Result format (:html, :json, :xml).
  # @option opt [Symbol] :verb        Overrides *verb* argument if given.
  # @option opt [String] :url         Overrides *url* argument if given.
  #
  # @return [String]                  The displayable result.
  #
  def show_pre_send(verb, url, **opt)
    opt, show_opt = partition_options(opt, *SHOW_PRE_SEND_OPT)
    user = opt[:user] || current_user
    verb = opt[:verb] || verb
    url  = opt[:url]  || url
    show_trace(**show_opt) do
      TRACE_SEPARATOR.merge(
        user:   user.inspect,
        format: opt[:format]&.inspect || '-',
        method: verb.inspect,
        url:    url.inspect
      )
    end
  end

  # Display conditions after invoking an HTTP method.
  #
  # @param [Hash] opt                 Passed to #show_trace except for:
  #
  # @option opt [Symbol, String, Integer]      :expect
  # @option opt [Symbol, String, Integer]      :status
  # @option opt [ActionDispatch::TestResponse] :response
  #
  # @return [String]                  The displayable result.
  #
  def show_post_send(**opt)
    opt, show_opt = partition_options(opt, *SHOW_POST_SEND_OPT)
    resp   = opt[:response] || response
    redir  = resp&.redirection? && resp.redirect_url
    status = opt[:status] || resp&.response_code
    expect = opt[:expect]
    body   = resp&.body&.gsub(/\n/, TRACE_NL)&.truncate(TRACE_BODY)
    show_trace(**show_opt) do
      {}.tap { |lines|
        lines[:redir]  = redir.inspect if redir
        lines[:status] = status.inspect
        lines[:expect] = expect&.inspect || '-'
        lines[:body]   = body
      }.merge(TRACE_SEPARATOR)
    end
  end

  # show_trace
  #
  # @param [Hash] opt                 Passed to #show except for:
  #
  # @option opt [String, Integer] :indent
  #
  # @yield The caller generates pairs to be displayed.
  # @yieldreturn [Hash]
  #
  # @return [String]                  The displayable result.
  #
  def show_trace(**opt)
    opt, show_opt = partition_options(opt, *SHOW_TRACE_OPT)
    pairs  = block_given? && yield || {}
    indent = opt[:indent] || ''
    indent = ' ' * indent if indent.is_a?(Integer)
    width  = pairs.keys.map(&:to_s).sort_by(&:size).last.size
    format = "#{indent}*** %-#{width}s = %s"
    lines  = pairs.map { |k, v| sprintf(format, k, v) }
    show(**show_opt) do
      lines.join("\n") << "\n\n"
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # This module is included in ActionDispatch::IntegrationTest to support
  # tracing of HTTP method calls.
  module Trace

    if TestHelper::DEBUG_TESTS

      PRE_OPTIONS   = (SHOW_PRE_SEND_OPT  + SHOW_TRACE_OPT).freeze
      POST_OPTIONS  = (SHOW_POST_SEND_OPT + SHOW_TRACE_OPT).freeze
      TRACE_OPTIONS = (PRE_OPTIONS + POST_OPTIONS).uniq.freeze

      # Override HTTP methods defined in ActionDispatch::Integration::Runner
      # in order to surround the method calls with trace debugging information.
      #
      # No override methods are created if *base* is some other class/module
      # which doesn't define these methods.
      #
      # @param [Module] base
      #
      # @return [void]
      #
      def self.included(base)
        base.class_eval do
          %i[get put post patch delete head].each do |method|
            next unless method_defined?(method)
            define_method(method) do |*args|
              # Extract any options specific to the tracing methods.  Remaining
              # options are passed to the underlying HTTP method call.
              pre_opt = post_opt = {}
              if args.last.is_a?(Hash)
                trace_opt, opt = partition_options(args.last, *TRACE_OPTIONS)
                if trace_opt.present?
                  pre_opt  = trace_opt.slice(*PRE_OPTIONS)
                  post_opt = trace_opt.slice(*POST_OPTIONS)
                  args.pop
                  args.push(opt)
                end
              end
              # Call the underlying HTTP method between tracing output calls.
              show_pre_send(method, args.first, pre_opt)
              super(*args)
              show_post_send(post_opt)
            end
          end
        end
      end

    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Neutralize debugging methods when not debugging.
  unless TestHelper::DEBUG_TESTS
    instance_methods(false).each do |m|
      if m == :run_test
        module_eval "def #{m}(*); yield; end"
      else
        module_eval "def #{m}(*); end"
      end
    end
  end

end
