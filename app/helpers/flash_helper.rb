# app/helpers/flash_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods for creating and displaying flash messages.
#
module FlashHelper

  # @private
  def self.included(base)
    __included(base, '[FlashHelper]')
  end

  include Emma::Common
  include HtmlHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Fall-back error message.
  #
  # @type [String]
  #
  DEFAULT_ERROR = I18n.t('emma.error.default', default: 'unknown').freeze

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
  class Entry

    include HtmlHelper

    # Distinct portions of the entry.
    #
    # @type [Array<Upload, Hash, String, Integer>]
    #
    attr_reader :parts

    alias_method :to_a, :parts

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Create a new instance.
    #
    # @param [Array<Entry, Hash, String, Array, *>] parts
    #
    # == Variations
    #
    # @overload initialize(other)
    #   @param [Entry] other
    #
    # @overload initialize(first, *parts)
    #   @param [String, Array]               first
    #   @param [Array<String, Entry, Array>] parts
    #
    def initialize(*parts)
      @parts = parts.flat_map { |part| make_parts(part) }.compact
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Process an object to extract parts.
    #
    # @param [Entry, Hash, String, Array, *] part
    #
    def make_parts(part)
      case part
        when nil    then part
        when Entry  then part.parts
        when Array  then part.map { |v| send(__method__, v) }
        when Hash   then part.to_a.flatten(1).map { |v| send(__method__, v) }
        else             transform(part)
      end
    end

    # Process a single object to make it a part.
    #
    # @param [*] part
    #
    # @return [String]
    #
    def transform(part)
      part.to_s
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Generate a string representation of the parts of the entry.
    #
    # @return [String]
    #
    #--
    # noinspection RubyYardParamTypeMatch
    #++
    def to_s
      count  = @parts&.size || 0
      result = +''
      result << first_part(@parts.first)          if count > 0
      result << ': '                              if count > 1
      result << @parts[1..-2].join(', ') << ', '  if count > 2
      result << last_part(@parts.last)            if count > 1
      result
    end

    # Generate HTML elements for the parts of the entry.
    #
    # @param [Hash] opt               Passed to outer #html_div.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @see #render_part
    #
    def render(**opt)
      prepend_classes!(opt, 'line').merge!(separator: ' ')
      html_div(opt) do
        if @parts.size > 1
          n = 0
          @parts.map { |part| render_part(part, (n += 1), last: @parts.size) }
        else
          @parts.map { |part| first_part(part, html: true) }
        end
      end
    end

    # render_part
    #
    # @param [String]       part
    # @param [Integer, nil] position  Position of part (starting from 1).
    # @param [Hash]         opt       Passed to #html_div except for:
    #
    # @option [Integer] :first        Index of the first column (default: 1).
    # @option [Integer] :last         Index of the last column.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @see #first_part
    # @see #last_part
    #
    def render_part(part, position = nil, **opt)
      first   = opt.delete(:first) || 1
      last    = opt.delete(:last) || -1
      classes = %w(part)
      classes << "col-#{position}" if position
      classes << 'first'           if position == first
      classes << 'last'            if position == last
      if position == first
        part = first_part(part, html: true)
      elsif position == last
        part = last_part(part, html: true)
      end
      prepend_classes!(opt, *classes)
      html_div(part, opt)
    end

    # A hook for treating the first part of a entry as special.
    #
    # @param [String]  text
    # @param [Boolean] html           If *true*, allow for HTML formatting.
    #
    # @return [String]                    If *html* is *false*.
    # @return [ActiveSupport::SafeBuffer] If *html* is *true*.
    #
    def first_part(text, html: false)
      html ? ERB::Util.h(text) : text
    end

    # A hook for treating the first part of a entry as special.
    #
    # @param [String]  text
    # @param [Boolean] html           If *true*, allow for HTML formatting.
    #
    # @return [String]                    If *html* is *false*.
    # @return [ActiveSupport::SafeBuffer] If *html* is *true*.
    #
    def last_part(text, html: false)
      html ? ERB::Util.h(text) : text
    end

    # =========================================================================
    # :section: Class methods
    # =========================================================================

    public

    # A short-cut for creating an Entry only if required.
    #
    # @param [Entry, *] other
    #
    # @return [Entry]
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
  # @param [Array<Exception,String,Symbol,Entry>] args
  # @param [Hash]                                 opt
  #
  # @return [void]
  #
  # @see #flash_notice
  #
  def flash_success(*args, **opt)
    prepend_flash_source!(args)
    flash_notice(*args, topic: :success, **opt)
  end

  # Failure flash notice.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args
  # @param [Hash]                                 opt
  #
  # @return [void]
  #
  # @see #flash_alert
  #
  def flash_failure(*args, **opt)
    prepend_flash_source!(args)
    flash_alert(*args, topic: :failure, **opt)
  end

  # Flash notice.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args
  # @param [Symbol, nil]                          topic
  # @param [Hash]                                 opt
  #
  # @return [void]
  #
  # @see #set_flash
  #
  def flash_notice(*args, topic: nil, **opt)
    prepend_flash_source!(args)
    set_flash(*args, topic: topic, type: :notice, **opt)
  end

  # Flash alert.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args
  # @param [Symbol, nil]                          topic
  # @param [Hash]                                 opt
  #
  # @return [void]
  #
  # @see #set_flash
  #
  def flash_alert(*args, topic: nil, **opt)
    prepend_flash_source!(args)
    set_flash(*args, topic: topic, type: :alert, **opt)
  end

  # Flash notification, which appears on the next page to be rendered.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args
  # @param [Symbol]                               type  :alert or :notice
  # @param [Symbol, nil]                          topic
  # @param [Hash]                                 opt
  #
  # @return [void]
  #
  # @see #flash_format
  #
  def set_flash(*args, type:, topic: nil, **opt)
    prepend_flash_source!(args)
    target  = flash_target(type)
    message = flash_format(*args, topic: topic, **opt)
    flash[target] = message
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Success flash now.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args
  # @param [Hash]                                 opt
  #
  # @return [void]
  #
  # @see #flash_now_notice
  #
  def flash_now_success(*args, **opt)
    prepend_flash_source!(args)
    flash_now_notice(*args, topic: :success, **opt)
  end

  # Failure flash now.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args
  # @param [Hash]                                 opt
  #
  # @return [void]
  #
  # @see #flash_now_alert
  #
  def flash_now_failure(*args, **opt)
    prepend_flash_source!(args)
    flash_now_alert(*args, topic: :failure, **opt)
  end

  # Flash now notice.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args
  # @param [Symbol, nil]                          topic
  # @param [Hash]                                 opt
  #
  # @return [void]
  #
  # @see #set_flash_now
  #
  def flash_now_notice(*args, topic: nil, **opt)
    prepend_flash_source!(args)
    set_flash_now(*args, topic: topic, type: :notice, **opt)
  end

  # Flash now alert.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args
  # @param [Symbol, nil]                          topic
  # @param [Hash]                                 opt
  #
  # @return [void]
  #
  # @see #set_flash_now
  #
  def flash_now_alert(*args, topic: nil, **opt)
    prepend_flash_source!(args)
    set_flash_now(*args, topic: topic, type: :alert, **opt)
  end

  # Flash now notification, which appears on the current page when it is
  # rendered.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args
  # @param [Symbol]                               type  :alert or :notice
  # @param [Symbol, nil]                          topic
  # @param [Hash]                                 opt
  #
  # @return [void]
  #
  # @see #flash_format
  #
  def set_flash_now(*args, type:, topic: nil, **opt)
    prepend_flash_source!(args)
    target  = flash_target(type)
    message = flash_format(*args, topic: topic, **opt)
    flash.now[target] = message
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create items(s) to be included in the 'X-Flash-Message' header to support
  # the ability of the client to update the flash display.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args
  #
  # @see #flash_format
  #
  def flash_xhr(*args, **opt)
    opt[:xhr] = true
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
  # @param [Array] args
  #
  # @return [Array]                   The original *args*, possibly modified.
  #
  def prepend_flash_source!(args)
    caller_name = (calling_method(3)&.to_sym unless args.first.is_a?(Symbol))
    args.unshift(caller_name) if caller_name
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
    # noinspection RubyYardReturnMatch
    FLASH_TARGETS.include?(type) ? type : FLASH_TARGETS.first
  end

  # Theoretical space available for flash messages.
  #
  # @return [Integer]
  #
  def flash_space_available
    flashes = session['flash']   || {}
    flashes = flashes['flashes'] || {}
    in_use  = flashes.values.sum(&:size)
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
  # @param [Array<Exception,String,Symbol,Entry>] args
  # @param [Symbol, nil]                          topic
  #
  # args[0] [Symbol]            method  Calling method
  # args[1] [Exception, String] error   Error (message) if :alert
  # args[..-2]                          Message part(s).
  # args[-1] [Hash]                     Passed to #flash_template except for:
  #
  # @option args[-1] [Boolean] :inspect   If *true* apply #inspect to messages.
  # @option args[-1] [*]       :status    Override reported exception status.
  # @option args[-1] [Boolean] :log       If *false* do not log exceptions.
  # @option args[-1] [Boolean] :trace     If *true* always log exception trace.
  # @option args[-1] [Symbol]  :meth      Calling method.
  # @option args[-1] [Boolean] :xhr       Format for 'X-Flash-Message'.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [String]                      For :xhr.
  #
  def flash_format(*args, topic: nil, **opt)
    meth = (args.shift if args.first.is_a?(Symbol))
    excp = (args.shift if args.first.is_a?(Exception))
    local, opt = partition_options(opt, :inspect, :status, :log, :trace, :meth)

    meth ||= local[:meth]
    status = local[:status]
    opt[:html] = false if opt[:xhr]

    # Lead with the message derived from an Exception.
    msg = []
    msg += excp.respond_to?(:messages) ? excp.messages : [excp.message] if excp

    # Log exceptions or messages.
    unless false?(local[:log])
      if excp
        status ||= (excp.code             if excp.respond_to?(:code))
        status ||= (excp.response&.status if excp.respond_to?(:response))
        trace    = true?(local[:trace])
        trace  ||=
          !excp.is_a?(UploadWorkflow::SubmitError) &&
          !excp.is_a?(Net::ProtocolError)
        Log.warn do
          err_msg = +"#{meth}: "
          err_msg << "#{status}: " if status.present?
          err_msg << "#{excp.class}: "
          if trace
            err_msg << "\n" << excp.full_message(order: :top)
          else
            err_msg << ' '  << msg.join(', ')
          end
        end
      else
        Log.info { [meth, status, args.join(', ')].join(': ') }
      end
    end

    unless opt.key?(:html)
      opt[:html] = (msg + args).any? { |m| m.html_safe? || m.is_a?(Entry) }
    end
    f_opt = opt.slice(:html)

    msg_sep = opt[:html] ? "\n" : ' '
    sep_siz = flash_item_size(msg_sep, **f_opt)
    max     = flash_space_available - (sep_siz * (msg.size + 1))
    msg     = flash_item(msg,  max: max, **f_opt)

    arg_sep = opt[:html] ? "\n" : ', '
    sep_siz = flash_item_size(arg_sep, **f_opt)
    max    -= flash_item_size(msg, **f_opt) + (sep_siz * (args.size + 1))
    args    = flash_item(args, max: max, inspect: local[:inspect], **f_opt)

    msg << nil unless opt[:html] || msg.blank?
    msg << args.join(arg_sep)

    result =
      if topic
        # noinspection RubyYardParamTypeMatch
        flash_template(msg, meth: meth, topic: topic, **opt)
      else
        msg.join(msg_sep)
      end
    if opt[:xhr]
      result
    elsif opt[:html]
      result.html_safe
    else
      ERB::Util.h(result)
    end
  end

  # Create item(s) to be included in the flash display.
  #
  # @param [String, Entry, Array] item
  # @param [Hash]                 opt
  #
  # @option opt [Boolean] :inspect  If *true* show inspection of *item*.
  # @option opt [Boolean] :html     If *true* force ActiveSupport::SafeBuffer.
  # @option opt [Integer] :max      See below.
  #
  # @return [ActiveSupport::SafeBuffer]   If *item* is HTML or *html* is true.
  # @return [String]                      If *item* is not HTML.
  # @return [Array]                       If *item* is an array.
  #
  # == Variations
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
  # noinspection RubyYardReturnMatch
  #++
  def flash_item(item, **opt)
    if item.is_a?(Array)
      return [] if item.blank?
      opt[:max]   ||= FLASH_MAX_TOTAL_SIZE
      opt[:max]     = [opt[:max], flash_space_available].min
      item_count    = item.size
      omission      = flash_omission(item_count, **opt)
      omission_size = flash_item_size(omission, **opt)
      count  = 0
      result = []
      item.each do |str|
        count += 1
        break unless opt[:max] > omission_size
        str_max  = opt[:max]
        str_max -= omission_size if count < item_count
        # noinspection RubyYardParamTypeMatch
        str = flash_item_render(str, **opt.merge(max: str_max))
        next if str.blank?
        opt[:max] -= flash_item_size(str, **opt)
        result << str unless opt[:max].negative?
        break if str == HTML_TRUNCATE_OMISSION
      end
      result << omission if opt[:max].positive? && (count < item_count)
      result
    else
      opt[:max] ||= FLASH_MAX_ITEM_SIZE
      opt[:max]   = [opt[:max], flash_space_available].min
      # noinspection RubyYardParamTypeMatch
      flash_item_render(item, **opt)
    end
  end

  # An item's actual impact toward the total flash size.
  #
  # @param [String, Entry, Array<String,Entry>] item
  # @param [Hash]                               opt   To #flash_item_render.
  #
  # @return [Integer]
  #
  # == Usage Note
  # This does not account for any separators that would be added when
  # displaying multiple items.
  #
  def flash_item_size(item, **opt)
    opt[:max] = nil
    items   = Array.wrap(item).map { |v| flash_item_render(v, **opt) }
    result  = items.sum(&:size)
    result += items.sum { |v| v.count("\n") + v.count('"') } if opt[:html]
    result
  end

  # Render an item in the intended form for addition to the flash.
  #
  # @param [String, Entry] item
  # @param [Boolean, nil]  html     If *true* force ActiveSupport::SafeBuffer.
  # @param [Boolean, nil]  inspect  If *true* show inspection of *item*.
  # @param [Integer, nil]  max      Max length of result.
  #
  # @return [String]                    If *html* is *false*.
  # @return [ActiveSupport::SafeBuffer] If *html* is *true*.
  #
  def flash_item_render(item, html: false, inspect: false, max: nil, **)
    res = (item.is_a?(Entry) && html) ? item.render : item.to_s
    res = res.inspect if inspect && !res.html_safe? && !res.start_with?('"')
    res = safe_truncate(res, max) if max
    res = ERB::Util.h(res)        if html && !res.html_safe?
    res
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
    # noinspection RubyYardParamTypeMatch
    i18n_path = flash_i18n_path(scope, meth, topic)
    if msg.is_a?(Array)
      separator ||= html ? "\n" : ', '
      msg = msg.reject(&:blank?).join(separator)
    end
    i18n_key = (topic == :success) ? :file : :error
    opt[i18n_key] = msg
    opt[:default] = Array.wrap(opt[:default]&.dup)
    opt[:default] << flash_i18n_path(scope, 'error', topic)
    opt[:default] << flash_i18n_path('error', topic)
    opt[:default] << DEFAULT_ERROR
    I18n.t(i18n_path, **opt)
  end

  # I18n scope based on the current class context.
  #
  # @return [String]
  #
  def flash_i18n_scope
    self.class.name.underscore.split('_').reject { |part|
      %w(controller concern helper).include?(part)
    }.join('_')
  end

  # Build an I18n path.
  #
  # @param [Array<String,Symbol,Array,nil>] parts
  #
  # @return [Symbol]
  #
  def flash_i18n_path(*parts)
    result = parts.flatten.reject(&:blank?).join('.')
    result = "emma.#{result}" unless result.start_with?('emma.')
    result.to_sym
  end

end

__loading_end(__FILE__)
