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
    method = method ? method.downcase.to_sym : :get
    @api ||= ApiService.instance
    data   = @api.send(:api, method, path, opt)&.body&.presence
    result = data ? { result: data } : { exception: @api.exception }
    result.reverse_merge(
      method: method.to_s.upcase,
      path:   path,
      opt:    opt.presence,
      url:    external_url(path, opt)
    )
  end

  # Generate HTML from the result of an API method invocation.
  #
  # @param [Faraday::Response, Api::Record::Base, Exception, Integer, String] value
  # @param [String, nil] separator    Default: "\n".
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def api_format_result(value, separator: "\n")
    record = value.is_a?(Api::Record::Base)
    value  = value.body if value.is_a?(Faraday::Response)
    elements =
      if record && value.exception.present?
        # === Exception or error response value ===
        mask_exception_value = false
        value.pretty_inspect
          .gsub(/(@exception=#<Faraday::ClientError)(.*?)(>,)/) { |substring|
            substring = "#{$1} ... #{$3}" if mask_exception_value
            mask_exception_value = true
            substring
          }
          .split(/\n/)
          .map { |line| content_tag(:div, line, class: 'exception') }

      elsif record || value.is_a?(Exception) || value.is_a?(String)
        # === Valid JSON response value ===
        link_opt = { rel: 'noreferrer' }
        link_opt[:target] = '_blank' unless params[:action] == 'v2'
        quot = '&quot;'
        pretty_json(value)
          .gsub(/"([^"]+)":/, '\1: ')
          .yield_self { |s| ERB::Util.h(s) }
          .gsub(/^( +)/) { |s| s.gsub(/ /, '&nbsp;&nbsp;') }
          .gsub(/^([^:]+:) /, '\1&nbsp;')
          .gsub(%r{&quot;https?://.+&quot;}) { |s|
            # Transform URLs into links, translating Bookshare API hrefs into
            # local paths.
            url = href = s.split(quot)[1].html_safe
            if href.start_with?(ApiService::BASE_URL)
              uri   = URI.parse(CGI.unescapeHTML(url)) rescue nil
              query = uri&.query&.sub(/api_key=[^&]*&?/, '')&.presence
              href  = uri && ERB::Util.h([uri.path, query].compact.join('?'))
            end
            url = make_link(url, href, link_opt) if href.present?
            "#{quot}#{url}#{quot}"
          }
          .split(/\n/)
          .map { |line| content_tag(:div, line.html_safe, class: 'data') }

      else
        # === Scalar response value ===
        value.pretty_inspect
          .split(/\n/)
          .map { |line| content_tag(:div, line, class: 'data') }

      end
    safe_join(elements, separator)
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
      when ApiService::HtmlResult
        value.response.body
      when Faraday::ClientError
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

end

__loading_end(__FILE__)
