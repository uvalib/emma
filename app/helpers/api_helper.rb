# app/helpers/api_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for rendering API responses.
#
module ApiHelper

  include Emma::Common
  include Emma::Json

  include HtmlHelper
  include LinkHelper

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate HTML from the result of an API method invocation.
  #
  # @param [Api::Record, Faraday::Response, Exception, Integer, String, nil] value
  # @param [Integer, String] indent     Space count or literal indent string.
  # @param [String]          separator  Default: "\n".
  # @param [Boolean]         html       If *false* then URLs will not be turned
  #                                       into *a* links and no HTML formatting
  #                                       will be applied.
  #
  # @return [ActiveSupport::SafeBuffer] If *html* is *true*.
  # @return [String]                    If *html* is *false*.
  #
  def format_api_result(value, indent: nil, separator: "\n", html: true)
    record = value.is_a?(Api::Record)
    value  = value.body if value.is_a?(Faraday::Response)
    space  = html ? '&nbsp;' : ' '
    indent = indent.gsub(/[ \t]/, space) if indent.is_a?(String)
    indent = space * indent              if indent.is_a?(Integer)
    lines =
      if record && value.exception.present?
        # === Exception or error response value ===
        value = value.pretty_inspect
        value = mask_later_exceptions(value)
        value.split(/\n/).map do |line|
          line = "#{indent}#{line}" if indent
          line = html_div(line, class: 'exception') if html
          line
        end

      elsif record || value.is_a?(Exception) || value.is_a?(String)
        # === Valid JSON response value ===
        value = pretty_format(value)
        value.gsub!(/\\"([^"\\]+?)\\":/, '\1: ')
        value = ERB::Util.h(value) if html
        value.gsub!(/,([^ ])/, (',' + space + '\1'))
        value.gsub!(/^( +)/) { _1.gsub(/ /, (space * 2)) } if html
        value.gsub!(/^([^:]+:) /, ('\1' + space))
        value = make_links(value) if html
        value.split(/\n/).map do |line|
          line = "#{indent}#{line}" if indent
          line = html_div(line.html_safe, class: 'data') if html
          line
        end

      else
        # === Scalar response value ===
        value = value.pretty_inspect
        value.split(/\n/).map do |line|
          line = "#{indent}#{line}" if indent
          line = html_div(line, class: 'data') if html
          line
        end

      end
    html ? safe_join(lines, separator) : lines.join(separator)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Abbreviate all but the first instance of the rendering of an exception.
  #
  # @param [String, nil] html         An HTML-ready string.
  #
  # @return [String]                  The modified string.
  #
  def mask_later_exceptions(html)
    mask = false
    html.to_s.gsub(/(@exception=#<[A-Z0-9_:]+Error)(.*?)(>,)/i) do |substring|
      if mask
        "#{$1} ... #{$3}"
      else
        mask = true
        substring
      end
    end
  end

  # Transform URLs into links.
  #
  # @param [String, nil] html         An HTML-ready string.
  # @param [Hash]   opt               Passed to #make_link.
  #
  # @return [String]                  The modified string.
  #
  def make_links(html, **opt)
    opt[:rel]    ||= 'noreferrer'
    opt[:target] ||= '_blank' unless params[:action] == 'v2'
    html.to_s.gsub(%r{&quot;https?://.+&quot;}) do |s|
      url = href = s.split('&quot;')[1].html_safe
      url = make_link(href, url, **opt) if href.present?
      "&quot;#{url}&quot;"
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  PF_INDENT      = ' '
  PF_NEWLINE     = "\n#{PF_INDENT}"
  PF_OPEN_BRACE  = "{\n#{PF_INDENT}#{PF_INDENT}"
  PF_CLOSE_BRACE = "\n#{PF_INDENT}}"

  # Format data objects for Explorer display.
  #
  # @param [any, nil] value           Api::Record, Exception, Numeric, String
  #
  # @return [String]
  #
  def pretty_format(value)
    case value
      when nil, Numeric
        value.inspect
      when Api::Record
        value.to_json(pretty: true)
      when ApiService::HtmlResultError
        value.response.body
      when Faraday::Error
        response =
          value.response.pretty_inspect
            .gsub(/\n/,    PF_NEWLINE)
            .sub(/\A{/,    PF_OPEN_BRACE)
            .sub(/}\s*\z/, PF_CLOSE_BRACE)
        [
          "#<#{value.class}",
          "#{PF_INDENT}message  = #{value.message.inspect}",
          "#{PF_INDENT}response = #{response}",
          '>'
        ].join("\n")
      when Exception
        value.pretty_inspect.gsub(/@[^=]+=/, (PF_NEWLINE + '\0'))
      else
        pretty_json(value)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Attempt to interpret *arg* as an exception or a record with an exception.
  #
  # @param [any, nil] arg             Api::Record, Exception
  # @param [any, nil] default         On parse failure, return this if provided
  #                                     (or return *arg* otherwise).
  #
  # @return [Hash, String, any, nil]
  #
  def safe_exception_parse(arg, default: :original)
    case (ex = arg.try(:exception))
      when Faraday::Error
        {
          message:   ex.message,
          response:  ex.response,
          exception: ex.wrapped_exception
        }.compact_blank
      when Exception
        ex.message
      else
        (default == :original) ? arg : default
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
