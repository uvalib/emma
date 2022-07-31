# app/helpers/flash_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods for creating and displaying flash messages.
#
module FlashHelper

  include Emma::Common

  include EncodingHelper
  include HtmlHelper
  include XmlHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Maximum length of any one flash message.
  #
  # @type [Integer]
  #
  # == Implementation Notes
  # This has been sized very conservatively so that it also works in the
  # desktop setting where the instance shares the 4096-byte cookie space with
  # other local applications.
  #
  # This shouldn't be a big problem; if it is then it might be time to consider
  # investing in setting up infrastructure for an alternative cookie mechanism.
  #
  FLASH_MAX_ITEM_SIZE = application_deployed? ? 384 : 256

  # Maximum size of all combined flash messages.
  #
  # @type [Integer]
  #
  FLASH_MAX_TOTAL_SIZE = 2 * FLASH_MAX_ITEM_SIZE

  # ===========================================================================
  # :section: Classes
  # ===========================================================================

  public

  # Each instance translates to a distinct line in the flash message.
  #
  class FlashPart < ExecReport::FlashPart

    include HtmlHelper

    # =========================================================================
    # :section: ExecReport::FlashPart overrides
    # =========================================================================

    public

    # Create a new instance.
    #
    def initialize(topic, details = nil)
      super
      @render_html = true
    end

    # =========================================================================
    # :section: ExecReport::FlashPart overrides
    # =========================================================================

    public

    # Generate HTML elements for the parts of the entry.
    #
    # @param [Integer, nil] first     Index of first column (def: 1).
    # @param [Integer, nil] last      Index of last column (def: `parts.size`).
    # @param [Hash]         part      Options passed to inner #html_div.
    # @param [Hash]         opt       Passed to outer #html_div
    #
    # @option opt [String, nil]  :separator   Default: #HTML_BREAK.
    # @option opt [Boolean, nil] :html
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @see #render_part
    #
    def render(first: nil, last: nil, part: nil, **opt)
      css = '.line'
      prepend_css!(opt, css)
      opt[:separator] ||= HTML_BREAK
      html_div(opt) do
        part = opt.slice(:html, :separator).reverse_merge(part || {})
        super(first: first, last: last, **part)
      end
    end

    # =========================================================================
    # :section: ExecReport::FlashPart::BaseMethods overrides
    # =========================================================================

    protected

    # Generate an HTML element for a single part of the entry.
    #
    # @param [String, nil]  part
    # @param [Integer, nil] pos       Position of part (starting from 1).
    # @param [Integer, nil] first     Index of the first column.
    # @param [Integer, nil] last      Index of the last column.
    # @param [Hash]         opt       Passed to #html_div.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def render_part(part, pos: nil, first: 1, last: -1, **opt)
      css      = '.part'
      html_opt = opt.except(:xhr, :html, :separator, :separators)
      prepend_css!(html_opt, css)
      append_css!(html_opt, "col-#{pos}") if pos
      append_css!(html_opt, 'first')      if pos == first
      append_css!(html_opt, 'last')       if pos == last
      html_div(html_opt) do
        super(part, **opt)
      end
    end

    # =========================================================================
    # :section: Class methods
    # =========================================================================

    public

    # A short-cut for creating a FlashHelper::FlashPart only if required.
    #
    # @param [FlashPart, Any] other
    #
    # @return [FlashPart]
    #
    def self.[](other)
      other.is_a?(self) ? other : new(other)
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Success flash notice.
  #
  # @param [Array<Symbol,ExecReport,Exception,FlashPart,String>] args
  # @param [Hash]                                                opt
  #
  # @return [void]
  #
  # @see #flash_notice
  # @see #flash_format
  #
  def flash_success(*args, **opt)
    prepend_flash_source!(args, **opt)
    flash_notice(*args, topic: :success, **opt)
  end

  # Failure flash notice.
  #
  # @param [Array<Symbol,ExecReport,Exception,FlashPart,String>] args
  # @param [Hash]                                                opt
  #
  # @return [void]
  #
  # @see #flash_alert
  # @see #flash_format
  #
  def flash_failure(*args, **opt)
    prepend_flash_source!(args, **opt)
    flash_alert(*args, topic: :failure, **opt)
  end

  # Flash notice.
  #
  # @param [Array<Symbol,ExecReport,Exception,FlashPart,String>] args
  # @param [Symbol, nil]                                         topic
  # @param [Hash]                                                opt
  #
  # @return [void]
  #
  # @see #set_flash
  # @see #flash_format
  #
  def flash_notice(*args, topic: nil, **opt)
    prepend_flash_source!(args, **opt)
    set_flash(*args, topic: topic, type: :notice, **opt)
  end

  # Flash alert.
  #
  # @param [Array<Symbol,ExecReport,Exception,FlashPart,String>] args
  # @param [Symbol, nil]                                         topic
  # @param [Hash]                                                opt
  #
  # @return [void]
  #
  # @see #set_flash
  # @see #flash_format
  #
  def flash_alert(*args, topic: nil, **opt)
    prepend_flash_source!(args, **opt)
    set_flash(*args, topic: topic, type: :alert, **opt)
  end

  # Flash notification, which appears on the next page to be rendered.
  #
  # @param [Array<Symbol,ExecReport,Exception,FlashPart,String>] args
  # @param [Symbol]      type         :alert or :notice
  # @param [Symbol, nil] topic
  # @param [Boolean]     clear        If *true* clear flash first.
  # @param [Hash]        opt          Passed to #flash_format.
  #
  # @return [void]
  #
  # @see #flash_format
  #
  def set_flash(*args, type:, topic: nil, clear: nil, **opt)
    prepend_flash_source!(args, **opt)
    message = flash_format(*args, topic: topic, **opt)
    target  = flash_target(type)
    clear ||= flash[target].blank?
    flash[target] = clear ? message : [*flash[target], *message]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Success flash now.
  #
  # @param [Array<Symbol,ExecReport,Exception,FlashPart,String>] args
  # @param [Hash]                                                opt
  #
  # @return [void]
  #
  # @note Currently unused.
  #
  # @see #flash_now_notice
  # @see #flash_format
  #
  def flash_now_success(*args, **opt)
    prepend_flash_source!(args, **opt)
    flash_now_notice(*args, topic: :success, **opt)
  end

  # Failure flash now.
  #
  # @param [Array<Symbol,ExecReport,Exception,FlashPart,String>] args
  # @param [Hash]                                                opt
  #
  # @return [void]
  #
  # @see #flash_now_alert
  # @see #flash_format
  #
  def flash_now_failure(*args, **opt)
    prepend_flash_source!(args, **opt)
    flash_now_alert(*args, topic: :failure, **opt)
  end

  # Flash now notice.
  #
  # @param [Array<Symbol,ExecReport,Exception,FlashPart,String>] args
  # @param [Symbol, nil]                                         topic
  # @param [Hash]                                                opt
  #
  # @return [void]
  #
  # @see #set_flash_now
  # @see #flash_format
  #
  def flash_now_notice(*args, topic: nil, **opt)
    prepend_flash_source!(args, **opt)
    set_flash_now(*args, topic: topic, type: :notice, **opt)
  end

  # Flash now alert.
  #
  # @param [Array<Symbol,ExecReport,Exception,FlashPart,String>] args
  # @param [Symbol, nil]                                         topic
  # @param [Hash]                                                opt
  #
  # @return [void]
  #
  # @see #set_flash_now
  # @see #flash_format
  #
  def flash_now_alert(*args, topic: nil, **opt)
    prepend_flash_source!(args, **opt)
    set_flash_now(*args, topic: topic, type: :alert, **opt)
  end

  # Flash now notification, which appears on the current page when it is
  # rendered.
  #
  # @param [Array<Symbol,ExecReport,Exception,FlashPart,String>] args
  # @param [Symbol]      type         :alert or :notice
  # @param [Symbol, nil] topic
  # @param [Hash]        opt
  #
  # @return [void]
  #
  # @see #flash_format
  #
  def set_flash_now(*args, type:, topic: nil, **opt)
    prepend_flash_source!(args, **opt)
    target  = flash_target(type)
    message = flash_format(*args, topic: topic, **opt)
    flash.now[target] = [*flash.now[target], *message]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create items(s) to be included in the 'X-Flash-Message' header to support
  # the ability of the client to update the flash display.
  #
  # @param [Array<Symbol,ExecReport,Exception,FlashPart,String>] args
  # @param [Hash]                                                opt
  #
  # @return [String]
  #
  # @see #flash_format
  #
  def flash_xhr(*args, **opt)
    opt[:xhr] = true
    prepend_flash_source!(args, **opt)
    flash_format(*args, topic: nil, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # @type [Array<Symbol>]
  FLASH_TARGETS = %i[notice alert].freeze

  # Prepend the method invoking flash if there is not already one at the start
  # of *args*.
  #
  # @param [Array]          args
  # @param [Symbol, String] meth      Calling method (if not at args[0]).
  #
  # @return [Array]                   The original *args*, possibly modified.
  #
  def prepend_flash_source!(args, meth: nil, **)
    unless args.first.is_a?(Symbol)
      meth ||= calling_method(3)
      args.unshift(meth.to_sym) if meth
    end
    args
  end

  # Return the effective flash type.
  #
  # @param [Symbol, String, nil] type
  #
  # @return [Symbol]
  #
  def flash_target(type)
    type = type&.to_sym
    # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
    FLASH_TARGETS.include?(type) ? type : FLASH_TARGETS.first
  end

  # Theoretical space available for flash messages.
  #
  # @return [Integer]
  #
  # @see ActionDispatch::Flash::RequestMethods#commit_flash
  # @see ActionDispatch::Flash::FlashHash#to_session_value
  #
  def flash_space_available
    flashes = session['flash']   || {}
    flashes = flashes['flashes'] || {}
    in_use  = flashes.values.flatten.sum(&:bytesize)
    # noinspection RubyMismatchedArgumentType
    FLASH_MAX_TOTAL_SIZE - in_use
  end

  # String to display if item(s) were omitted.
  #
  # @param [Integer, nil] count   Total number of items.
  # @param [Boolean]      html
  #
  # @return [String]                    If *html* is *false*.
  # @return [ActiveSupport::SafeBuffer] If *html* is *true*.
  #
  def flash_omission(count = nil, html: false, **)
    text = count ? "#{count} total" : 'more' # TODO: I18n
    text = "[#{text}]"
    html ? %Q(<div class="line">#{text}</div>).html_safe : "\n#{text}"
  end

  # Create item(s) to be included in the flash display.
  #
  # By default, when displaying an Exception, this method also logs the
  # exception and its stack trace (to avoid "eating" the exception when this
  # method is called from an exception handler block).
  #
  # @param [Array<Symbol,ExecReport,Exception,FlashPart,String>] args
  # @param [Symbol, nil] topic
  # @param [Hash]        opt          To #flash_template except for:
  #
  # @option opt [Boolean] :inspect    If *true* apply #inspect to messages.
  # @option opt [Any]     :status     Override reported exception status.
  # @option opt [Boolean] :log        If *false* do not log exceptions.
  # @option opt [Boolean] :trace      If *true* always log exception trace.
  # @option opt [Symbol]  :meth       Calling method.
  # @option opt [Boolean] :xhr        Format for 'X-Flash-Message'.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [String]                      For :xhr.
  #
  #--
  # == Variations
  #++
  #
  # @overload flash_format(meth, error, *args, topic: nil, **opt)
  #   @param [Symbol]                  meth   Calling method.
  #   @param [ExecReport, Exception]   error  Error (message) if :alert.
  #   @param [Array<String,FlashPart>] args   Additional message part(s).
  #   @param [Symbol, nil]             topic
  #   @param [Hash]                    opt
  #
  # @overload flash_format(error, *args, topic: nil, **opt)
  #   @param [ExecReport, Exception]   error  Error (message) if :alert.
  #   @param [Array<String,FlashPart>] args   Additional message part(s).
  #   @param [Symbol, nil]             topic
  #   @param [Hash]                    opt
  #
  # @overload flash_format(meth, *args, topic: nil, **opt)
  #   @param [Symbol]                  meth   Calling method.
  #   @param [Array<String,FlashPart>] args   Additional message part(s).
  #   @param [Symbol, nil]             topic
  #   @param [Hash]                    opt
  #
  # @overload flash_format(*args, topic: nil, **opt)
  #   @param [Array<String,FlashPart>] args   Additional message part(s).
  #   @param [Symbol, nil]             topic
  #   @param [Hash]                    opt
  #
  #--
  # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
  #++
  def flash_format(*args, topic: nil, **opt)
    prop = extract_hash!(opt, :meth, :status, :inspect, :log, :trace)
    meth = args.first.is_a?(Symbol) && args.shift || prop[:meth] || __method__
    item = args.shift
    rpt  = ExecReport[item]
    args = args.flat_map { |arg| arg.is_a?(ExecReport) ? arg.parts : arg }
    args.map! { |arg| ExecReport::Part[arg] }

    if (xhr = opt[:xhr])
      opt[:html] = false
    elsif opt[:html].nil?
      opt[:html] = respond_to?(:params) || [rpt, *args].any?(&:html_safe?)
    end
    html    = opt[:html]
    msg_sep = ' '
    arg_sep = ', '

    # Lead with the message derived from an Exception.
    # noinspection RubyNilAnalysis
    msg = rpt.render(html: html)

    # Log exceptions or messages.
    unless false?(prop[:log])
      status = prop[:status] || rpt.http_status || '???'
      if (excp = rpt.exception)
        trace    = true?(prop[:trace])
        trace  ||=
          !excp.is_a?(UploadWorkflow::SubmitError) && # TODO: remove after upload -> entry
          !excp.is_a?(Record::Error) &&
          !excp.is_a?(Timeout::Error) &&
          !excp.is_a?(Net::ProtocolError)
        trace &&= excp.full_message(order: :top).prepend("\n")
        trace ||= msg.join(msg_sep)
        Log.warn { "#{meth}: #{status}: #{excp.class}: #{trace}" }
      else
        topics  = msg.join(msg_sep).presence
        details = args.join(arg_sep).presence
        Log.info { [meth, status, topics, details].compact.join(': ') }
      end
    end

    msg_sep = arg_sep = "\n" if xhr || html
    brackets = nil

    # Assemble the message.
    if msg.present? || args.present?
      inspect = prop[:inspect]
      fi_opt  = { xhr: xhr, html: html }
      max     = flash_space_available

      # Adjustments for 'X-Flash-Message'.
      if xhr && msg.many?
        inspect  = true
        brackets = %w( [ ] )
        max -= brackets.sum(&:bytesize)
      end

      if msg.present?
        max -= (msg.size + 1) * flash_item_size(msg_sep, **fi_opt)
        msg  = flash_item(msg, max: max, **fi_opt)
      end

      if args.present?
        max -= msg.sum(&:bytesize)
        max -= (args.size + 1) * flash_item_size(arg_sep, **fi_opt)
        args.each { |arg| arg.render_html = true } if html
        args = flash_item(args, max: max, inspect: inspect, **fi_opt)
        msg << nil if (xhr || html) && msg.present?
        msg << (html ? html_join(args, arg_sep) : args.join(arg_sep))
      end
    end

    # Complete the message and adjust the return type as needed.
    result =
      if topic
        flash_template(msg, meth: meth, topic: topic, **opt)
      elsif msg.present?
        msg.join(msg_sep)
      end
    result &&= [brackets.first, result, brackets.last].join if brackets
    result ||= ''
    if xhr
      result
    elsif html
      result.html_safe
    else
      ERB::Util.h(result)
    end
  end

  # Create item(s) to be included in the flash display.
  #
  # @param [String, Array, FlashPart] item
  # @param [Hash]                     opt
  #
  # @option opt [Boolean] :inspect  If *true* show inspection of *item*.
  # @option opt [Boolean] :html     If *true* force ActiveSupport::SafeBuffer.
  # @option opt [Integer] :max      See below.
  #
  # @return [ActiveSupport::SafeBuffer]   If *item* is HTML or *html* is true.
  # @return [String]                      If *item* is not HTML.
  # @return [Array]                       If *item* is an array.
  #
  #--
  # == Variations
  #++
  #
  # @overload flash_item(string, max: FLASH_MAX_ITEM_SIZE, **opt)
  #   Create a single flash item which conforms to the maximum per-item size.
  #   @param [ActiveSupport::SafeBuffer, String] string
  #   @return [ActiveSupport::SafeBuffer, String]
  #   @return [ActiveSupport::SafeBuffer]               If :html is *true*.
  #
  # @overload flash_item(array, max: FLASH_MAX_TOTAL_SIZE, **opt)
  #   Create a set of flash items which conforms to the overall maximum size.
  #   @param [Array<ActiveSupport::SafeBuffer,String>] array
  #   @return [Array<ActiveSupport::SafeBuffer,String>]
  #   @return [Array<ActiveSupport::SafeBuffer>]        If :html is *true*.
  #
  #--
  # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
  #++
  def flash_item(item, **opt)
    if item.is_a?(Array)
      return [] if item.blank?
      opt[:max] ||= FLASH_MAX_TOTAL_SIZE
      opt[:max]   = [opt[:max], flash_space_available].min
      total       = item.size
      omitted     = flash_omission(total, **opt)
      omitted_len = flash_item_size(omitted, **opt)
      result      = []
      item.each_with_index do |str, index|
        break unless opt[:max] > omitted_len
        str_max  = opt[:max]
        str_max -= omitted_len unless (index + 1) < total
        str = flash_item_render(str, **opt.merge(max: str_max))
        next if str.blank?
        opt[:max] -= flash_item_size(str, **opt)
        result << str unless opt[:max].negative?
        break if str == HTML_TRUNCATE_OMISSION
      end
      result << omitted if (result.size < total) && (opt[:max] >= omitted_len)
      result
    else
      opt[:max] ||= FLASH_MAX_ITEM_SIZE
      opt[:max]   = [opt[:max], flash_space_available].min
      flash_item_render(item, **opt)
    end
  end

  # An item's actual impact toward the total flash size.
  #
  # @param [String, Array<String>] item
  # @param [Boolean]               html
  #
  # @return [Integer]
  #
  # == Usage Notes
  # This does not account for any separators that would be added when
  # displaying multiple items.
  #
  def flash_item_size(item, html: false, **)
    items   = Array.wrap(item)
    result  = items.sum(&:bytesize)
    result += items.sum { |v| v.count("\n") + v.count('"') } if html
    result
  end

  # Render an item in the intended form for addition to the flash.
  #
  # @param [String, FlashPart] item
  # @param [Boolean, nil]      html     Force ActiveSupport::SafeBuffer.
  # @param [Boolean, nil]      xhr
  # @param [Boolean, nil]      inspect  Show inspection of *item*.
  # @param [Integer, nil]      max      Max length of result.
  #
  # @return [String]                    If *html* is *false*.
  # @return [ActiveSupport::SafeBuffer] If *html* is *true*.
  #
  def flash_item_render(item, html: nil, xhr: nil, inspect: nil, max: nil, **)
    item = FlashPart[item] if html
    # noinspection RailsParamDefResolve
    res  = item.try(:render) || item.to_s
    res  = res.inspect if inspect && !res.html_safe? && !res.start_with?('"')
    res  = max ? html_truncate(res, max, xhr: xhr) : to_utf(res, xhr: xhr)
    html ? ERB::Util.h(res) : res
  end

  # If a :topic was specified, it is used as part of a set of I18n paths used
  # to locate a template to which the flash message is applied.
  #
  # @param [String, Array<String>] msg
  # @param [Symbol, String]        topic
  # @param [Symbol, String, nil]   meth
  # @param [Boolean, nil]          html
  # @param [String, nil]           separator
  # @param [Hash]                  opt        Passed to I18n#t.
  #
  # @return [String]                          # Even if html is *true*.
  #
  def flash_template(msg, topic:, meth: nil, html: nil, separator: nil, **opt)
    scope = flash_i18n_scope
    topic = topic.to_sym
    # noinspection RubyMismatchedArgumentType
    i18n_path = flash_i18n_path(scope, meth, topic)
    if msg.is_a?(Array)
      separator ||= html ? "\n" : ', '
      msg = msg.compact_blank.join(separator)
    end
    i18n_key = (topic == :success) ? :file : :error
    opt[i18n_key] = msg
    opt[:default] = Array.wrap(opt[:default]&.dup)
    opt[:default] << flash_i18n_path(scope, 'error', topic)
    opt[:default] << flash_i18n_path(scope, topic)
    opt[:default] << flash_i18n_path('error', topic)
    opt[:default] << ExecError::DEFAULT_ERROR
    I18n.t(i18n_path, **opt)
  end

  # I18n scope based on the current class context.
  #
  # @return [String]
  #
  def flash_i18n_scope
    parts = self.class.name&.split('_') || []
    parts.reject { |p| %w(controller concern helper).include?(p) }.join('_')
  end

  # Build an I18n path.
  #
  # @param [Array<String,Symbol,Array,nil>] parts
  #
  # @return [Symbol]
  #
  def flash_i18n_path(*parts)
    result = parts.flatten.compact_blank.join('.')
    result = "emma.#{result}" unless result.start_with?('emma.')
    result.to_sym
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
