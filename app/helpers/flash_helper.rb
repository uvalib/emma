# app/helpers/flash_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'net/http'

# Methods for creating and displaying flash messages.
#
# The .flash-messages container starts hidden and only displayed when the
# client side can determine that this is an original page load and not one due
# to page history or page reload.
#
# @see app/assets/javascripts/shared/flash.js *flashInitialize*
#
#--
# noinspection RubyTooManyMethodsInspection
#++
module FlashHelper

  include Emma::Common
  include Emma::Config

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
  # === Implementation Notes
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
  # :section:
  # ===========================================================================

  public

  # If *true*, the flash container should be displayed inline on the page.
  #
  # @type [Boolean, nil]
  #
  attr_reader :flash_inline

  # If *true*, the flash container should float above the page.
  #
  # @type [Boolean, nil]
  #
  attr_reader :flash_floating

  # Specify that flash messages are displayed inline on the page.
  #
  # @param [Boolean] on
  #
  # @return [Boolean]
  #
  def set_flash_inline(on = true)
    @flash_inline = on
  end

  # Specify that flash messages should float above the page.
  #
  # @param [Boolean] on
  #
  # @return [Boolean]
  #
  def set_flash_floating(on = true)
    @flash_floating = on
  end

  # Specify that the flash container should be cleared on page refresh.
  #
  # @param [Boolean] on
  #
  # @return [Boolean]
  #
  def set_flash_reset(on = true)
    @flash_reset = on
  end

  # Indicate whether the flash container should be cleared on page refresh.
  #
  # @return [Boolean]
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def flash_reset
    @flash_reset = true if @flash_reset.nil?
    @flash_reset
  end

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
    # @param [String]       css       Characteristic CSS class/selector.
    # @param [Hash]         opt       Passed to outer #html_div
    #
    # @option opt [String, nil]  :separator   Default: #HTML_BREAK.
    # @option opt [Boolean, nil] :html
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @see #render_part
    #
    def render(first: nil, last: nil, part: nil, css: '.line', **opt)
      prepend_css!(opt, css)
      opt[:separator] ||= HTML_BREAK
      html_div(**opt) do
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
    # @param [String]       css       Characteristic CSS class/selector.
    # @param [Hash]         opt       Passed to #html_div.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def render_part(part, pos: nil, first: 1, last: -1, css: '.part', **opt)
      html_opt = opt.except(:xhr, :html, :separator, :separators)
      prepend_css!(html_opt, css)
      append_css!(html_opt, "col-#{pos}") if pos
      append_css!(html_opt, 'first')      if pos == first
      append_css!(html_opt, 'last')       if pos == last
      html_div(**html_opt) do
        super(part, **opt)
      end
    end

    # =========================================================================
    # :section: Class methods
    # =========================================================================

    public

    # A short-cut for creating a FlashHelper::FlashPart only if required.
    #
    # @param [any, nil] other         FlashPart or arg to initializer.
    #
    # @return [FlashPart]
    #
    def self.[](other)
      # noinspection RubyMismatchedReturnType
      other.is_a?(self) ? other : new(other)
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Success flash notice.
  #
  # @param [Array] args         String, Model, Exception, ExecReport, FlashPart
  # @param [Hash]  opt          Passed to #flash_notice.
  #
  # @return [Array<String>]     Current flash notice messages.
  #
  def flash_success(*args, **opt)
    prepend_flash_caller!(args, opt)
    flash_notice(*args, topic: :success, **opt)
  end

  # Failure flash alert.
  #
  # @param [Array] args         String, Model, Exception, ExecReport, FlashPart
  # @param [Hash]  opt          Passed to #flash_alert.
  #
  # @return [Array<String>]     Current flash alert messages.
  #
  def flash_failure(*args, **opt)
    prepend_flash_caller!(args, opt)
    flash_alert(*args, topic: :failure, **opt)
  end

  # Flash notice.
  #
  # @param [Array]      args    String, Model, Exception, ExecReport, FlashPart
  # @param [Symbol,nil] topic
  # @param [Hash]       opt     Passed to #set_flash.
  #
  # @return [Array<String>]     Current flash notice messages.
  #
  def flash_notice(*args, topic: nil, **opt)
    prepend_flash_caller!(args, opt)
    set_flash(*args, topic: topic, type: :notice, **opt)
  end

  # Flash alert.
  #
  # @param [Array]      args    String, Model, Exception, ExecReport, FlashPart
  # @param [Symbol,nil] topic
  # @param [Hash]       opt     Passed to #set_flash.
  #
  # @return [Array<String>]     Current flash alert messages.
  #
  def flash_alert(*args, topic: nil, **opt)
    prepend_flash_caller!(args, opt)
    set_flash(*args, topic: topic, type: :alert, **opt)
  end

  # Flash notification, which appears on the next page to be rendered.
  #
  # @param [Array]       args   String, Model, Exception, ExecReport, FlashPart
  # @param [Symbol]      type   :alert or :notice
  # @param [Symbol, nil] topic
  # @param [Boolean]     clear  If *true* clear flash first.
  # @param [Hash]        opt    Passed to #flash_format.
  #
  # @return [Array<String>]     Current *type* flash messages.
  #
  def set_flash(*args, type:, topic: nil, clear: nil, **opt)
    prepend_flash_caller!(args, opt)
    message = flash_format(*args, topic: topic, **opt)
    target  = flash_target(type)
    clear ||= flash[target].blank?
    flash[target] = clear ? [message] : [*flash[target], *message]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Success flash now.
  #
  # @param [Array] args         String, Model, Exception, ExecReport, FlashPart
  # @param [Hash]  opt          Passed to #flash_now_notice.
  #
  # @return [Array<String>]     Current flash.now notice messages.
  #
  # @note Currently unused.
  #
  def flash_now_success(*args, **opt)
    prepend_flash_caller!(args, opt)
    flash_now_notice(*args, topic: :success, **opt)
  end

  # Failure flash now.
  #
  # @param [Array] args         String, Model, Exception, ExecReport, FlashPart
  # @param [Hash]  opt          Passed to #flash_now_alert.
  #
  # @return [Array<String>]     Current flash.now alert messages.
  #
  def flash_now_failure(*args, **opt)
    prepend_flash_caller!(args, opt)
    flash_now_alert(*args, topic: :failure, **opt)
  end

  # Flash now notice.
  #
  # @param [Array]      args    String, Model, Exception, ExecReport, FlashPart
  # @param [Symbol,nil] topic
  # @param [Hash]       opt     Passed to #set_flash_now.
  #
  # @return [Array<String>]     Current flash.now notice messages.
  #
  def flash_now_notice(*args, topic: nil, **opt)
    prepend_flash_caller!(args, opt)
    set_flash_now(*args, topic: topic, type: :notice, **opt)
  end

  # Flash now alert.
  #
  # @param [Array]      args    String, Model, Exception, ExecReport, FlashPart
  # @param [Symbol,nil] topic
  # @param [Hash]       opt     Passed to #set_flash_now.
  #
  # @return [Array<String>]     Current flash.now alert messages.
  #
  def flash_now_alert(*args, topic: nil, **opt)
    prepend_flash_caller!(args, opt)
    set_flash_now(*args, topic: topic, type: :alert, **opt)
  end

  # Flash now notification, which appears on the current page when it is
  # rendered.
  #
  # @param [Array]      args    String, Model, Exception, ExecReport, FlashPart
  # @param [Symbol]     type    :alert or :notice
  # @param [Symbol,nil] topic
  # @param [Hash]       opt     Passed to #flash_format.
  #
  # @return [Array<String>]     Current *type* flash.now messages.
  #
  def set_flash_now(*args, type:, topic: nil, **opt)
    prepend_flash_caller!(args, opt)
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
  # @param [Array] args         String, Model, Exception, ExecReport, FlashPart
  # @param [Hash]  opt
  #
  # @return [String]
  #
  def flash_xhr(*args, **opt)
    prepend_flash_caller!(args, opt)
    flash_format(*args, topic: nil, **opt, xhr: true)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # @type [Array<Symbol>]
  FLASH_TARGETS = %i[notice alert].freeze

  # Prepend the method invoking flash if there is not already one at the start
  # of *args* and ensure that `opt[:meth]` is removed (whether used or or).
  #
  # @param [Array] args
  # @param [Hash]  opt
  #
  # @option opt [Symbol, String] meth   Calling method (if not at args[0]).
  #
  # @return [void]
  #
  def prepend_flash_caller!(args, opt)
    meth = opt.delete(:meth)&.to_sym
    if (arg = args.first).is_a?(Symbol)
      return if !meth || (meth == arg)
      Log.error("#{__method__}: args[0] == :#{arg}; opt[:meth] == :#{meth}")
    elsif (meth ||= calling_method(3)).nil?
      Log.error("#{__method__}: could not determine caller")
    else
      args.unshift(meth)
    end
  end

  # Return the effective flash type.
  #
  # @param [Symbol, String, nil] type
  #
  # @return [Symbol]
  #
  def flash_target(type)
    type = type&.to_sym
    # noinspection RubyMismatchedReturnType
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
    if count
      text = config_term(:flash, :total, count: count)
    else
      text = config_term(:flash, :more)
    end
    text = "[#{text}]"
    html ? %Q(<div class="line">#{text}</div>).html_safe : "\n#{text}"
  end

  # Create item(s) to be included in the flash display.
  #
  # By default, when displaying an Exception, this method also logs the
  # exception and its stack trace (to avoid "eating" the exception when this
  # method is called from an exception handler block).
  #
  # @param [Array]      args    String, Model, Exception, ExecReport, FlashPart
  # @param [Symbol,nil] topic
  # @param [Hash]       opt     To #flash_template except for:
  #
  # @option opt [Boolean] :inspect    If *true* apply #inspect to messages.
  # @option opt [any]     :status     Override reported exception status.
  # @option opt [Boolean] :log        If *false* do not log exceptions.
  # @option opt [Boolean] :trace      If *true* always log exception trace.
  # @option opt [Symbol]  :meth       Calling method.
  # @option opt [Boolean] :xhr        Format for 'X-Flash-Message'.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [String]                  For :xhr.
  #
  #--
  # === Variations
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
  def flash_format(*args, topic: nil, **opt)
    args.compact!
    prop = opt.extract!(:meth, :status, :inspect, :log, :trace)
    meth = args.first.is_a?(Symbol) && args.shift || prop[:meth] || __method__
    item = args.shift
    rpt  = ExecReport[item]
    args = args.flat_map { _1.is_a?(ExecReport) ? _1.parts : _1 }
    args.map! { ExecReport::Part[_1] }

    if (xhr = opt[:xhr])
      opt[:html] = false
    elsif opt[:html].nil?
      opt[:html] = respond_to?(:params) || [rpt, *args].any?(&:html_safe?)
    end
    html    = opt[:html]
    msg_sep = ' '
    arg_sep = ', '

    # Lead with the message derived from an Exception.
    msg = rpt.render(html: html)

    # Log exceptions or messages.
    unless false?(prop[:log])
      status = prop[:status] || rpt.http_status
      if (excp = rpt.exception)
        Log.warn do
          trace =
            if prop.key?(:trace)
              true?(prop[:trace])
            else
              !excp.is_a?(CanCan::AccessDenied) &&
              !excp.is_a?(Net::ProtocolError) &&
              !excp.is_a?(Record::Error) &&
              !excp.is_a?(Timeout::Error) &&
              !excp.is_a?(UploadWorkflow::SubmitError)
            end
          topics  = excp.class
          details = trace ? excp.full_message(order: :top) : msg.join(msg_sep)
          ['flash', meth, status, topics, details].compact_blank.join(': ')
        end
      else
        Log.info do
          topics  = msg.join(msg_sep)
          details = args.join(arg_sep)
          ['flash', meth, status, topics, details].compact_blank.join(': ')
        end
      end
    end

    msg_sep  = arg_sep = "\n" if xhr || html
    brackets = []

    # Assemble the message.
    if msg.present? || args.present?
      inspect = prop[:inspect]
      parts   = msg.size + args.size
      fi_opt  = { xhr: xhr, html: html, single: (parts == 1) }
      max     = flash_space_available

      # Adjustments for 'X-Flash-Message'.
      if xhr && msg.many?
        inspect  = true
        brackets = %w[ [ ] ]
        max -= brackets.sum(&:bytesize)
      end

      if msg.present?
        max -= (msg.size + 1) * flash_item_size(msg_sep, **fi_opt)
        msg  = flash_item(msg, max: max, **fi_opt)
      end

      if args.present?
        max -= msg.sum(&:bytesize)
        max -= (args.size + 1) * flash_item_size(arg_sep, **fi_opt)
        args.each { _1.render_html = true } if html
        args = flash_item(args, max: max, inspect: inspect, **fi_opt)
        msg << nil if (xhr || html) && msg.present?
        msg << (html ? html_join(args, arg_sep) : args.join(arg_sep))
      end
    end

    # Complete the message and adjust the return type as needed.
    msg = flash_template(msg, meth: meth, topic: topic, **opt) if topic
    msg = msg.presence&.join(msg_sep) if msg.is_a?(Array)
    msg = [brackets.first, msg, brackets.last].compact.join
    case
      when xhr  then msg
      when html then msg.html_safe
      else           ERB::Util.h(msg)
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
  # === Variations
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
        next if (str = flash_item_render(str, **opt, max: str_max)).blank?
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
  # === Usage Notes
  # This does not account for any separators that would be added when
  # displaying multiple items.
  #
  def flash_item_size(item, html: false, **)
    items   = Array.wrap(item)
    result  = items.sum(&:bytesize)
    result += items.sum { _1.count("\n") + _1.count('"') } if html
    result
  end

  # Render an item in the intended form for addition to the flash.
  #
  # @param [String, FlashPart] item
  # @param [Boolean]           single   If *true* only one item in the message.
  # @param [Boolean, nil]      html     Force ActiveSupport::SafeBuffer.
  # @param [Boolean, nil]      xhr
  # @param [Boolean, nil]      inspect  Show inspection of *item*.
  # @param [Integer, nil]      max      Max length of result.
  # @param [Hash]              opt      Passed to FlashPart#render.
  #
  # @return [String]                    If *html* is *false*.
  # @return [ActiveSupport::SafeBuffer] If *html* is *true*.
  #
  def flash_item_render(
    item,
    single:   false,
    html:     nil,
    xhr:      nil,
    inspect:  nil,
    max:      nil,
    **opt
  )
    append_css!(opt, 'single') if single
    res  = html ? FlashPart[item].render(**opt) : item.to_s
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
  # @param [Hash]                  opt        Passed to #config_entry.
  #
  # @return [String]                          # Even if html is *true*.
  #
  def flash_template(msg, topic:, meth: nil, html: nil, separator: nil, **opt)
    if msg.is_a?(Array)
      msg = msg.compact_blank.join(separator || (html ? "\n" : ', '))
    end
    i_key = (topic.to_sym == :success) ? :name : :error
    scope = flash_i18n_scope.presence
    keys  = []
    keys << :"emma.page.#{scope}.action.#{meth}.#{topic}" if scope && meth
    keys << :"emma.page.#{scope}.#{meth}.#{topic}"        if scope && meth
    keys << :"emma.page.#{scope}.error.#{topic}"          if scope
    keys << :"emma.page.#{scope}.#{topic}"                if scope
    keys << :"emma.error.#{scope}.#{meth}.#{topic}"       if scope && meth
    keys << :"emma.error.#{meth}.#{topic}"                if meth
    keys << :"emma.error.#{scope}.#{topic}"               if scope
    keys << :"emma.error.#{topic}"
    # noinspection RubyMismatchedReturnType
    config_entry(keys, i_key => msg, fallback: ExecError::DEFAULT_ERROR, **opt)
  end

  # I18n scope based on the current class context.
  #
  # @return [String]
  #
  def flash_i18n_scope
    parts = self.class.name&.underscore&.split('_') || []
    parts.excluding('controller', 'concern', 'helper').join('_')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

__loading_end(__FILE__)
