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
  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Invoke an API method.
  #
  # @param [Symbol]    method         One of ApiService#HTTP_METHODS.
  # @param [String]    path
  # @param [Hash, nil] opt
  #
  # @return [Hash]
  #
  def api_method(method, path, **opt)
    url = make_path(path, opt)
    url = "/v2/#{url}".squeeze('/') unless url.start_with?('/v2/')
    result = {
      method: method.to_s.upcase,
      path:   path,
      opt:    opt.presence,
      url:    url
    }
    method = "api_#{method}".downcase.to_sym
    @api ||= ApiService.instance
    data   = @api.send(method, path, opt)
    if data.is_a?(Hash) && data[:invalid]
      result.merge(exception: data[:exception])
    else
      result.merge(result: data)
    end
  end

  # Generate HTML from the result of an API method invocation.
  #
  # @param [Api::Record::Base, String, Integer] value
  # @param [String, nil]                        separator   Default: "\n".
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def api_format_result(value, separator: "\n")
    elements =
      if value.is_a?(Api::Record::Base) && value.exception.present?
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

      elsif value.is_a?(Api::Record::Base) || value.is_a?(String)
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
            url = link_to(url, href, link_opt) if href.present?
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

  # pretty_json
  #
  # @param [Api::Record::Base, String] value
  #
  # @return [String]
  #
  def pretty_json(value)
    if value.is_a?(Api::Record::Base)
      value.to_json(pretty: true)
    else
      MultiJson.dump(MultiJson.load(value), pretty: true)
    end
  end

end

__loading_end(__FILE__)
