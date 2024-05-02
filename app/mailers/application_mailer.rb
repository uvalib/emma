# app/mailers/application_mailer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class ApplicationMailer < ActionMailer::Base

  include Emma::Common
  include HtmlHelper

  # ===========================================================================
  # :section: Mailer layout
  # ===========================================================================

  helper EmmaHelper
  helper LayoutHelper::PageLanguage

  layout 'mailer'

  # ===========================================================================
  # :section: Mailer settings
  # ===========================================================================

  default from: MAILER_SENDER

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Options for ActionMailer::Base#mail.
  #
  # @type [Array<Symbol>]
  #
  MAIL_OPT = %i[to from subject cc bcc].freeze

  # The pattern indicating a `<meta>` tag from an HTML content document which
  # specifies a mail option.
  #
  # E.g. `<meta name="emma-mail-subject" content="MAIL SUBJECT LINE">`
  #
  # @type [Regexp]
  #
  META_PREFIX = /^emma-mail-/.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Acquire the message body from a source other than the view template.
  #
  # @param [String, Hash] src
  # @param [Hash]         opt
  #
  # @return [String]                  The acquired message body
  # @return [nil]                     If no body could be acquired.
  #
  def fetch_message(src, **opt)
    src = src[:body] if src.is_a?(Hash)
    src = src.strip  if src.is_a?(String)
    # noinspection RubyMismatchedReturnType, RubyMismatchedArgumentType
    case (src = src.presence)
      when nil                        then return
      when /\A *(https?:[^\n]+) *\z/  then fetch_remote_message($1, **opt)
      when /\A *(\/[^\n]+) *\z/       then fetch_local_message($1, **opt)
      when /\A *db:([^\s]+) *\z/      then fetch_db_message($1, **opt)
      when                                 process_content(src, **opt)
    end
  end

  # Acquire the message body from a web site.
  #
  # @param [String] src               Full URL to the file.
  # @param [Hash]   opt               Passed to #process_content.
  #
  # @return [Hash, nil]
  #
  def fetch_remote_message(src, **opt)
    return unless src.is_a?(String) && src.present?
    resp = Faraday.get(src)
    stat = resp&.status || '-'
    body = resp&.body&.strip
    process_content(body, **opt).tap do |result|
      if result[:body].blank?
        err = (stat == 200) ? 'no content' : "status #{stat}"
        err = result[:body] = "#{__method__}: failed: #{src.inspect} (#{err})"
        Log.error(err)
      end
    end
  end

  # Acquire the message body from a local file.
  #
  # @param [String] src               Project-relative path to the file.
  # @param [Hash]   opt               Passed to #process_content.
  #
  # @return [Hash, nil]
  #
  def fetch_local_message(src, **opt)
    not_implemented 'TODO: fetch message body from local file'
    return unless src.is_a?(String) && src.present?
    body = src # TODO: get local file
    process_content(body, **opt).tap do |result|
      if result[:body].blank?
        err = result[:body] = "#{__method__}: failed: #{src.inspect}"
        Log.error(err)
      end
    end
  end

  # Acquire the message body from the "messages" database table.
  #
  # @param [String] src               Project-relative path to the file.
  # @param [String] table             Database table name.
  # @param [Hash]   opt               Passed to #process_content.
  #
  # @return [Hash, nil]
  #
  def fetch_db_message(src, table: 'messages', **opt)
    not_implemented 'TODO: fetch message body from database table'
    return unless src.is_a?(String) && src.present?
    body = table && src # TODO: get table field value
    process_content(body, **opt).tap do |result|
      if result[:body].blank?
        err = result[:body] = "#{__method__}: failed: #{src.inspect}"
        Log.error(err)
      end
    end
  end

  # Process fetched content according to its original format.
  #
  # @param [String, nil] msg
  # @param [Hash]        opt
  #
  # @return [Hash]
  #
  def process_content(msg, **opt)
    # noinspection RubyMismatchedArgumentType
    case
      when msg&.include?('</') then process_html(msg, **opt)
      when msg.present?        then process_text(msg, **opt)
      else                          {}
    end
  end

  # Process HTML content by interpreting `<head>` `<meta>` tags matching
  # #META_PREFIX as mail option overrides and returning the contents of
  # `<body>`.
  #
  # @param [String]      msg
  # @param [Symbol, nil] format
  #
  # @return [Hash]
  #
  def process_html(msg, format: nil, **)
    result = {}
    html   = (format == :html)
    msg    = "<body>#{msg}</body>" unless msg.include?('<body')
    doc    = Nokogiri.parse(msg)

    # Look for `<meta>` overrides of mail options.
    doc.search('//head/meta[@name]').each do |node|
      attrs = node.attributes.map { |k, v| [k.to_s.to_sym, v.to_s] }.to_h
      name, value = attrs.values_at(:name, :content)
      next unless name.match?(META_PREFIX) && value.present?
      name = name.sub(META_PREFIX, '').to_sym
      result[name] = value
    end

    # If the first element is `<h1>`, `<h2>`, etc. then assume the document
    # defines the heading and ensure that the configured value is not used.
    body = doc.at('//body')
    result[:heading] = '' if body.elements.first.name.match?(/^h\d$/)

    # Prepare message content for the current format.
    body = body.children.map { |v| v.to_html.strip }.join("\n").html_safe
    body = format_body(body, format: format).join("\n")
    body = body.html_safe if html
    result.merge!(body: body)
  end

  # Process text content by interpreting the initial lines as mail headers and
  # returning with a hash where [:body] contains the remaining lines.
  #
  # @param [Array, String] msg
  # @param [Symbol, nil]   format
  #
  # @return [Hash]
  #
  def process_text(msg, format: nil, **)
    result = {}
    html   = (format == :html)
    lines  = msg.is_a?(Array) ? msg.dup : msg.split("\n")

    # Look for overrides of mail options (e.g. "Subject: MAIL SUBJECT LINE").
    while lines.first&.match(/^([a-z_-]+):\s*([^\n]*)$/i) do
      break unless (header = $1) && (value = $2)
      result[header.underscore.to_sym] = value
      lines.shift
    end

    # Prepare message content for the current format.
    body = lines.join("\n").strip
    body = body.html_safe if msg.is_a?(ActiveSupport::SafeBuffer)
    body = format_body(body, format: format).join("\n")
    body = body.html_safe if msg.is_a?(ActiveSupport::SafeBuffer) || html
    result.merge!(body: body)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Separator which indicates a division between paragraphs for text format.
  # 
  # @type [String]
  # 
  PARAGRAPH = "\n\n"

  # The width of text format lines.
  # 
  # @type [Integer]
  # 
  WIDTH = 80

  # Transform source content into an array of paragraphs.
  #
  # @param [Array, String, nil] src
  # @param [Symbol, nil]        format
  # @param [Integer, nil]       width
  # @param [String]             paragraph
  #
  # @return [Array<ActiveSupport::SafeBuffer>]    If *format* == :html
  # @return [Array<String>]                       Otherwise
  #
  def format_body(src, format: nil, width: WIDTH, paragraph: PARAGRAPH, **)
    src = (src.is_a?(Array) ? src.flatten : Array.wrap(src)).map!(&:to_s)
    if format == :html
      src.flat_map do |v|
        if v.is_a?(ActiveSupport::SafeBuffer)
          v.split(paragraph).map!(&:html_safe)
        else
          v.split(paragraph).map! { |p| html_paragraph(p) }
        end
      end
    else
      width = positive(width)
      src.flat_map { |v|
        v = sanitize(v) if v.is_a?(ActiveSupport::SafeBuffer)
        v.split(paragraph)
      }.tap { |parts| parts.map! { |v| wrap_lines(v, width: width) } if width }
    end
  end

  # Transform HTML into plain text with paragraphs separated by two newlines.
  #
  # @param [ActiveSupport::SafeBuffer] text
  #
  # @return [String]
  #
  def sanitize(text)
    elems = Sanitize::Config::DEFAULT[:whitespace_elements]
    elems = elems.transform_values { { after: PARAGRAPH } }
    sanitized_string(text, whitespace_elements: elems)
  end

  # Replace white space in *text* to yield a result containing one or more
  # newline-delimited lines.
  #
  # @param [String]  text
  # @param [Integer] width
  #
  # @return [String]
  #
  def wrap_lines(text, width: WIDTH)
    lines = [[]]
    chars = 0
    text.to_s.scan(/([^\s]+)(\s+|$)/) do |word, _space_after|
      if (chars + word.size) > width
        lines << []
        chars = 0
      end
      lines.last << word
      chars += word.size + 1
    end
    lines.map! { |line| line.join(' ').rstrip }.join("\n")
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Combine email addresses.
  #
  # @param [Array<String>, String] values
  #
  # @return [String]
  #
  def join_addresses(*values)
    values = values.flatten.compact_blank!
    if values.many?
      values.uniq { |v| v.to_s.downcase }.join('; ')
    else
      values.first
    end
  end

  # Generate mailer message content for an AccountMailer email.
  #
  # If this is not the production deployment, the heading and body will be
  # annotated to indicate that this is not a real enrollment request.
  #
  # @param [Symbol] key               Entry under "en.emma.mail".
  # @param [Hash]   opt
  #
  # @option opt [Symbol]  :format
  # @option opt [Boolean] :test
  #
  # @return [Hash]
  #
  def email_elements(key, **opt)
    cfg = config_section("emma.mail.#{key}").deep_dup
    opt = { test: !production_deployment? }.merge!(params, opt)
    msg = fetch_message(cfg, **opt)
    msg = msg ? cfg.merge(msg) : cfg
    interpolate_message!(msg, **opt)
  end

  # Process message properties, including filling interpolation values.
  #
  # @param [Hash] msg                 Message configuration values.
  # @param [Hash] opt
  #
  # @option opt [Hash] :vals          Interpolation values from caller.
  #
  # @return [Hash]
  #
  def interpolate_message!(msg, **opt)
    html = (opt[:format] == :html)
    test = opt[:test] && msg[:testing].presence || {}

    test_heading, test_body = test.values_at(:heading, :body).map!(&:presence)
    if test_body
      test_body = format_body(test_body, **opt)
      test_body.map! { |v| content_tag(:strong, v) } if html
      test_body = [nil, test_body].join(PARAGRAPH)
      test_body = test_body.html_safe if html
      msg[:testing][:body] = test_body
    end

    if (heading = msg[:heading]).present?
      heading = test_heading % heading if test_heading
      msg[:heading] = html ? heading : "#{heading}\n%s" % ('=' * heading.size)
    end

    if (body = msg[:body]).present?
      vals = interpolation_values(**opt)
      safe = body.is_a?(ActiveSupport::SafeBuffer)
      body = body.is_a?(Array) ? body.dup : body.split(PARAGRAPH)
      body.map! { |paragraph| interpolate(paragraph, **vals) } if vals.present?
      if !html
        body.prepend(msg[:heading])
      elsif !safe
        body.map! { |paragraph| html_paragraph(paragraph) }
      else
        body.map!(&:html_safe)
      end
      body << test_body.lstrip.then { |s| html ? s.html_safe : s } if test_body
      msg[:body] = html ? safe_join(body, PARAGRAPH) : body.join(PARAGRAPH)
    end

    msg
  end

  # Supply interpolation values for the current email.
  #
  # @param [Hash, nil] vals
  # @param [Hash]      opt
  #
  # @option opt [Hash] :vals
  #
  # @return [Hash]
  #
  def interpolation_values(vals = nil, **opt)
    vals&.dup || opt[:vals]&.dup || {}
  end

  helper_method :email_elements, :interpolation_values

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Takes the same arguments as RenderingHelper#render but converts the
  # provided partial into text.
  #
  # @param [String, Hash] options
  # @param [Hash]         locals
  #
  # @return [String]
  #
  def render_as_text(options, locals = {}, &block)
    options = { partial: options } unless options.is_a?(Hash)
    options = options.merge(formats: %i[html])
    body    = capture { render(options, locals, &block) }.strip
    sanitize(body).split(PARAGRAPH).flat_map { |v|
      # Special handling for the heading and its underline.
      if v.match?(/\s=+$/)
        parts = v.strip.split(/\s+/)
        under = parts.pop
        head  = parts.join(' ')
        "#{head}\n#{under}"
      else
        format_body(v)
      end
    }.join(PARAGRAPH)
  end

  helper_method :render_as_text

end

__loading_end(__FILE__)
