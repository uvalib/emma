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
  FLASH_MAX_ITEM_SIZE = 1024

  # Maximum size of all combined flash messages.
  #
  # @type [Integer]
  #
  FLASH_MAX_TOTAL_SIZE = 2 * FLASH_MAX_ITEM_SIZE

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Success flash notice.
  #
  # @param [Array<Exception,String,Symbol>] args  Passed to #flash_notice.
  #
  # @return [void]
  #
  def flash_success(*args)
    prepend_flash_source!(args)
    flash_notice(*args, topic: :success)
  end

  # Failure flash notice.
  #
  # @param [Array<Exception,String,Symbol>] args  Passed to #flash_alert.
  #
  # @return [void]
  #
  def flash_failure(*args)
    prepend_flash_source!(args)
    flash_alert(*args, topic: :failure)
  end

  # Flash notice.
  #
  # @param [Array<Exception,String,Symbol>] args  Passed to #set_flash.
  # @param [Symbol]                         topic
  #
  # @return [void]
  #
  def flash_notice(*args, topic:)
    prepend_flash_source!(args)
    set_flash(*args, topic: topic, type: :notice)
  end

  # Flash alert.
  #
  # @param [Array<Exception,String,Symbol>] args  Passed to #set_flash.
  # @param [Symbol]                         topic
  #
  # @return [void]
  #
  def flash_alert(*args, topic:)
    prepend_flash_source!(args)
    set_flash(*args, topic: topic, type: :alert)
  end

  # Flash notification, which appears on the next page to be rendered.
  #
  # @param [Array<Exception,String,Symbol>] args  Passed to #flash_format.
  # @param [Symbol]                         topic
  # @param [Symbol]                         type  Either :alert or :notice.
  #
  # @return [void]
  #
  def set_flash(*args, topic:, type:)
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
  # @param [Array<Exception,String,Symbol>] args  Passed to #flash_now_notice.
  #
  # @return [void]
  #
  def flash_now_success(*args)
    prepend_flash_source!(args)
    flash_now_notice(*args, topic: :success)
  end

  # Failure flash now.
  #
  # @param [Array<Exception,String,Symbol>] args  Passed to #flash_now_alert.
  #
  # @return [void]
  #
  def flash_now_failure(*args)
    prepend_flash_source!(args)
    flash_now_alert(*args, topic: :failure)
  end

  # Flash now notice.
  #
  # @param [Array<Exception,String,Symbol>] args  Passed to #set_flash_now.
  # @param [Symbol]                         topic
  #
  # @return [void]
  #
  def flash_now_notice(*args, topic:)
    prepend_flash_source!(args)
    set_flash_now(*args, topic: topic, type: :notice)
  end

  # Flash now alert.
  #
  # @param [Array<Exception,String,Symbol>] args  Passed to #set_flash_now.
  # @param [Symbol]                         topic
  #
  # @return [void]
  #
  def flash_now_alert(*args, topic:)
    prepend_flash_source!(args)
    set_flash_now(*args, topic: topic, type: :alert)
  end

  # Flash now notification, which appears on the current page when it is
  # rendered.
  #
  # @param [Array<Exception,String,Symbol>] args  Passed to #flash_format.
  # @param [Symbol]                         topic
  # @param [Symbol]                         type  Either :alert or :notice.
  #
  # @return [void]
  #
  def set_flash_now(*args, topic:, type:)
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
  # @param [Array<Exception,String,Symbol>] args
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

  # Flash now notification, which appears on the current page when it is
  # rendered.
  #
  # @param [Array<Exception,String,Symbol>] args
  # @param [Symbol]                         topic
  #
  # args[0] [Symbol]            method  Calling method
  # args[1] [Exception, String] error   Error (message) if :alert
  # args[*]                             Anything else passed to I18n#t.
  #
  # @return [String]
  #
  def flash_format(*args, topic:)
    opt    = args.last.is_a?(Hash) ? args.pop.dup : {}
    scope  = flash_i18n_scope
    method = args.shift
    error  = (args.shift if args.first.is_a?(Exception))
    topic  = topic&.to_sym || (error ? :failure : :success)
    fail   = (topic != :success)
    msg    = fail ? Array.wrap(error&.message || DEFAULT_ERROR).dup : []
    html   = args.any?(&:html_safe?)
    sep    = html ? '<br/>' : ', '
    max    = FLASH_MAX_ITEM_SIZE - (sep.size * (args.size + 1))
    args   = flash_item(args, max: max, html: html, inspect: true)
    msg    = flash_item(msg,  max: max, html: html)
    msg << nil unless html || msg.blank?
    msg << sep if html && (args.size > 1)
    msg << args.join(sep)
    opt[fail ? :error : :file] = msg.join(' ')
    opt[:default] = Array.wrap(opt[:default]&.dup)
    opt[:default] << flash_i18n_path(scope, 'error', topic)
    opt[:default] << flash_i18n_path('error', topic)
    opt[:default] << DEFAULT_ERROR
    path   = flash_i18n_path(scope, method, topic)
    result = I18n.t(path, **opt)
    html ? result.html_safe : result
  end

  # Create item(s) to be included in the flash display.
  #
  # @param [String, Array] item
  # @param [Hash]          opt
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
      opt[:max] ||= FLASH_MAX_TOTAL_SIZE
      result = []
      item.each do |str|
        break unless opt[:max].positive?
        str = flash_item(str, **opt)
        opt[:max] -= str.size
        result << str unless str.blank? || opt[:max].negative?
      end
    else
      opt[:max] ||= FLASH_MAX_ITEM_SIZE
      string  = item.to_s
      inspect = opt[:inspect] && !string.html_safe? && !string.start_with?('"')
      string  = string.inspect if inspect
      result  = safe_truncate(string, opt[:max])
      result  = ERB::Util.h(result) if opt[:html] && !result.html_safe?
    end
    result
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
