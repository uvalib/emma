# app/helpers/flash_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Flash message methods.
#
module FlashHelper

  def self.included(base)
    __included(base, '[FlashHelper]')
  end

  include HtmlHelper
  include Emma::Common

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
  # == Implementation Note
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
      columns =
        if @parts.size > 1
          n = 0
          @parts.map { |part| render_part(part, (n += 1), last: @parts.size) }
        else
          @parts.map { |part| first_part(part, html: true) }
        end
      opt = prepend_css_classes(opt, 'line')
      html_div(safe_join(columns, ' '), opt)
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
      opt = prepend_css_classes(opt, classes)
      html_div(part, opt)
    end

    # A hook for treating the first part of a entry as special.
    #
    # @param [String]  text
    # @param [Boolean] html           If *true*, allow for HTML formatting.
    #
    # @return [String, ActiveSupport::SafeBuffer]
    #
    def first_part(text, html: false)
      html ? ERB::Util.h(text) : text
    end

    # A hook for treating the first part of a entry as special.
    #
    # @param [String]  text
    # @param [Boolean] html           If *true*, allow for HTML formatting.
    #
    # @return [String, ActiveSupport::SafeBuffer]
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
  # @param [Array<Exception,String,Symbol,Entry>] args  Passed to #flash_notice
  #
  # @return [void]
  #
  def flash_success(*args)
    prepend_flash_source!(args)
    flash_notice(*args, topic: :success)
  end

  # Failure flash notice.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args  Passed to #flash_alert.
  #
  # @return [void]
  #
  def flash_failure(*args)
    prepend_flash_source!(args)
    flash_alert(*args, topic: :failure)
  end

  # Flash notice.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args  Passed to #set_flash.
  # @param [Symbol, nil]                          topic
  #
  # @return [void]
  #
  def flash_notice(*args, topic: nil)
    prepend_flash_source!(args)
    set_flash(*args, topic: topic, type: :notice)
  end

  # Flash alert.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args  Passed to #set_flash.
  # @param [Symbol, nil]                          topic
  #
  # @return [void]
  #
  def flash_alert(*args, topic: nil)
    prepend_flash_source!(args)
    set_flash(*args, topic: topic, type: :alert)
  end

  # Flash notification, which appears on the next page to be rendered.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args  Passed to #flash_format
  # @param [Symbol]                               type  :alert or :notice
  # @param [Symbol, nil]                          topic
  #
  # @return [void]
  #
  def set_flash(*args, type:, topic: nil)
    prepend_flash_source!(args)
    target  = flash_target(type)
    message = flash_format(*args, topic: topic)
    flash[target] = message
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Success flash now.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args  To #flash_now_notice.
  #
  # @return [void]
  #
  def flash_now_success(*args)
    prepend_flash_source!(args)
    flash_now_notice(*args, topic: :success)
  end

  # Failure flash now.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args  To #flash_now_alert.
  #
  # @return [void]
  #
  def flash_now_failure(*args)
    prepend_flash_source!(args)
    flash_now_alert(*args, topic: :failure)
  end

  # Flash now notice.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args  To #set_flash_now.
  # @param [Symbol, nil]                          topic
  #
  # @return [void]
  #
  def flash_now_notice(*args, topic: nil)
    prepend_flash_source!(args)
    set_flash_now(*args, topic: topic, type: :notice)
  end

  # Flash now alert.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args  To #set_flash_now.
  # @param [Symbol, nil]                          topic
  #
  # @return [void]
  #
  def flash_now_alert(*args, topic: nil)
    prepend_flash_source!(args)
    set_flash_now(*args, topic: topic, type: :alert)
  end

  # Flash now notification, which appears on the current page when it is
  # rendered.
  #
  # @param [Array<Exception,String,Symbol,Entry>] args  Passed to #flash_format
  # @param [Symbol]                               type  :alert or :notice
  # @param [Symbol, nil]                          topic
  #
  # @return [void]
  #
  def set_flash_now(*args, type:, topic: nil)
    prepend_flash_source!(args)
    target  = flash_target(type)
    message = flash_format(*args, topic: topic)
    flash.now[target] = message
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # @type [Array<Symbol>]
  FLASH_TARGETS = %i[notice alert].freeze

  # Return the method invoking flash.
  #
  # @param [Array] args
  #
  # @return [Array]                   The original *args*, possibly modified.
  #
  def prepend_flash_source!(args)
    args.unshift(calling_method(3).to_sym) unless args.first.is_a?(Symbol)
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
  # @return [ActiveSupport::SafeBuffer]   If *html*.
  # @return [String]                      If !*html*.
  #
  def flash_omission(count = nil, html: false, **)
    text = count ? "#{count} total" : 'more' # TODO: I18n
    text = "[#{text}]"
    html ? %Q(<div class="line">#{text}</div>).html_safe : "\n#{text}"
  end

  # Flash now notification, which appears on the current page when it is
  # rendered.
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
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def flash_format(*args, topic: nil)
    opt = (args.pop if args.last.is_a?(Hash))
    local, opt = partition_options(opt, :inspect)

    method  = args.shift
    error   = (args.shift if args.first.is_a?(Exception))
    msg     = nil
    msg   ||= (error.messages  if error.respond_to?(:messages))
    msg   ||= ([error.message] if error.respond_to?(:message))
    msg   ||= []
    html    = (msg + args).any? { |m| m.html_safe? || m.is_a?(Entry) }

    msg_sep = html ? "\n" : ' '
    sep_siz = flash_item_size(msg_sep, html: html)
    max     = flash_space_available - (sep_siz * (msg.size + 1))
    msg     = flash_item(msg,  max: max, html: html)

    arg_sep = html ? "\n" : ', '
    sep_siz = flash_item_size(arg_sep, html: html)
    max    -= flash_item_size(msg, html: html) + (sep_siz * (args.size + 1))
    args    = flash_item(args, max: max, html: html, inspect: local[:inspect])

    msg << nil unless html || msg.blank?
    msg << args.join(arg_sep)

    result = msg.join(msg_sep)
    result = flash_template(msg, method: method, topic: topic, **opt) if topic
    html ? result.html_safe : ERB::Util.h(result)
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

  # An item's actual impact toward the the total flash size.
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
  #
  # @return [String, ActiveSupport::SafeBuffer]
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
  # @param [Symbol, String]        method
  # @param [Symbol, String]        topic
  # @param [Boolean, nil]          html
  # @param [String, nil]           separator
  # @param [Hash]                  opt        Passed to I18n#t.
  #
  # @return [String]                          # Even if html is *true*.
  #
  def flash_template(msg, method:, topic:, html: nil, separator: nil, **opt)
    topic = topic.to_sym
    fail  = (topic != :success)
    scope = flash_i18n_scope
    path  = flash_i18n_path(scope, method, topic)
    if msg.is_a?(Array)
      separator ||= html ? "\n" : ', '
      msg = msg.reject(&:blank?).join(separator)
    end
    opt[fail ? :error : :file] = msg
    opt[:default] = Array.wrap(opt[:default]&.dup)
    opt[:default] << flash_i18n_path(scope, 'error', topic)
    opt[:default] << flash_i18n_path('error', topic)
    opt[:default] << DEFAULT_ERROR
    I18n.t(path, **opt)
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
  # @param [Array] parts
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
