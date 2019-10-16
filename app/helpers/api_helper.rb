# app/helpers/api_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ApiHelper
#
# @see ApiController
# @see app/views/api
#
module ApiHelper

  def self.included(base)
    __included(base, '[ApiHelper]')
  end

  include GenericHelper
  include HtmlHelper
  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the API service.
  #
  # @return [ApiService]
  #
  def api
    @api ||= api_update
  end

  # Update the API service.
  #
  # @param [Hash] opt
  #
  # @return [ApiService]
  #
  def api_update(**opt)
    default_opt = {}
    default_opt[:user]     = current_user if current_user.present?
    default_opt[:no_raise] = true         if Rails.env.test?
    @api = ApiService.update(**opt.reverse_merge(default_opt))
  end

  # Remove the API service.
  #
  # @return [nil]
  #
  def api_clear
    @api = ApiService.clear
  end

  # Indicate whether the latest API request generated an exception.
  #
  def api_error?
    defined?(@api) && @api.present? && @api.error?
  end

  # Get the current API exception message if the service has been started.
  #
  # @return [String]
  # @return [nil]
  #
  def api_error_message
    @api.error_message if defined?(:@api) && @api.present?
  end

  # Get the current API exception if the service has been started.
  #
  # @return [Exception]
  # @return [nil]
  #
  def api_exception
    @api.exception if defined?(:@api) && @api.present?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a URL to an external (Bookshare-related) site, but refactor API
  # URL's so that they are passed through the application's "API explorer".
  #
  # @param [String] path
  # @param [Hash]   opt               Passed to #make_path.
  #
  # @return [String]
  #
  def external_url(path, **opt)
    api_version = "/#{ApiService::API_VERSION}/"
    make_path(path, opt).tap do |result|
      result.delete_prefix!(ApiService::BASE_URL)
      unless result.start_with?('http', api_version)
        result.prepend(api_version).squeeze!('/')
      end
    end
  end

  # Invoke an API method.
  #
  # @param [Symbol] method            One of ApiService#HTTP_METHODS.
  # @param [String] path
  # @param [Hash]   opt               Passed to #api_get, etc.
  #
  # @return [Hash]
  #
  def api_method(method, path, **opt)
    method = method&.downcase&.to_sym || :get
    path   = URI.escape(path.to_s)
    data   = api.send(:api, method, path, **opt.merge(no_raise: true))
    data &&= data.body.presence
    {
      method:    method.to_s.upcase,
      path:      path,
      opt:       opt.presence || '',
      url:       external_url(path, opt),
      result:    data&.force_encoding('UTF-8'),
      exception: api_exception,
    }.reject { |_, v| v.nil? }
  end

  # Generate HTML from the result of an API method invocation.
  #
  # @param [Api::Record::Base, Faraday::Response, Exception, Integer, String] value
  # @param [Integer, String] indent     Space count or literal indent string.
  # @param [String]          separator  Default: "\n".
  # @param [Boolean]         html       If *false* then URLs will not be turned
  #                                       into <a> links and no HTML formatting
  #                                       will be applied.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [String]
  #
  def api_format_result(value, indent: nil, separator: "\n", html: true)
    record = value.is_a?(Api::Record::Base)
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
          line = content_tag(:div, line, class: 'exception') if html
          line
        end

      elsif record || value.is_a?(Exception) || value.is_a?(String)
        # === Valid JSON response value ===
        value = pretty_json(value)
        value.gsub!(/\\"([^"\\]+?)\\":/, '\1: ')
        value = ERB::Util.h(value) if html
        value.gsub!(/,([^ ])/, (',' + space + '\1'))
        value.gsub!(/^( +)/) { |s| s.gsub(/ /, (space * 2)) } if html
        value.gsub!(/^([^:]+:) /, ('\1' + space))
        value = make_links(value) if html
        value.split(/\n/).map do |line|
          line = "#{indent}#{line}" if indent
          line = content_tag(:div, line.html_safe, class: 'data') if html
          line
        end

      else
        # === Scalar response value ===
        value = value.pretty_inspect
        value.split(/\n/).map do |line|
          line = "#{indent}#{line}" if indent
          line = content_tag(:div, line, class: 'data') if html
          line
        end

      end
    html ? safe_join(lines, separator) : lines.join(separator)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  PJ_INDENT      = ' '
  PJ_NEWLINE     = "\n#{PJ_INDENT}"
  PJ_OPEN_BRACE  = "{\n#{PJ_INDENT}#{PJ_INDENT}"
  PJ_CLOSE_BRACE = "\n#{PJ_INDENT}}"

  # pretty_json
  #
  # @param [Api::Record::Base, Exception, Numeric, String] value
  #
  # @return [String]
  #
  def pretty_json(value)
    case value
      when ApiService::HtmlResultError
        value.response.body
      when Faraday::Error
        response =
          value.response.pretty_inspect
            .gsub(/\n/,    PJ_NEWLINE)
            .sub(/\A{/,    PJ_OPEN_BRACE)
            .sub(/}\s*\z/, PJ_CLOSE_BRACE)
        [
          "#<#{value.class}",
          "#{PJ_INDENT}message  = #{value.message.inspect}",
          "#{PJ_INDENT}response = #{response}",
          '>'
        ].join("\n")
      when Exception
        value.pretty_inspect.gsub(/@[^=]+=/, (PJ_NEWLINE + '\0'))
      when Api::Record::Base
        value.to_json(pretty: true)
      when Numeric
        value.inspect
      else
        MultiJson.dump(MultiJson.load(value), pretty: true)
    end
  rescue
    value.pretty_inspect
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Abbreviate all but the first instance of the rendering of an exception.
  #
  # @param [String] html              An HTML-ready string.
  #
  # @return [String]                  The modified string.
  #
  def mask_later_exceptions(html)
    mask = false
    html.gsub(/(@exception=#<[A-Z0-9_:]+Error)(.*?)(>,)/i) do |substring|
      if mask
        "#{$1} ... #{$3}"
      else
        mask = true
        substring
      end
    end
  end

  # Transform URLs into links by translating Bookshare API hrefs into local
  # paths.
  #
  # @param [String] html              An HTML-ready string.
  # @param [Hash]   opt               Passed to #make_link.
  #
  # @return [String]                  The modified string.
  #
  def make_links(html, **opt)
    opt[:rel]    ||= 'noreferrer'
    opt[:target] ||= '_blank' unless params[:action] == 'v2'
    html.gsub(%r{&quot;https?://.+&quot;}) do |s|
      url = href = s.split('&quot;')[1].html_safe
      if href.start_with?(ApiService::BASE_URL)
        uri   = URI.parse(CGI.unescapeHTML(url)) rescue nil
        query = uri&.query&.sub(/api_key=[^&]*&?/, '')&.presence
        href  = uri && ERB::Util.h([uri.path, query].compact.join('?'))
      end
      url = make_link(url, href, opt) if href.present?
      "&quot;#{url}&quot;"
    end
  end

end

__loading_end(__FILE__)
