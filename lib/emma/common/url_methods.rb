# lib/emma/common/url_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'cgi'

module Emma::Common::UrlMethods

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Fully URL-encode (including transforming '.' to '%2E') without escaping a
  # string which is already escaped.
  #
  # @param [String] s
  #
  # @return [String]
  #
  def url_escape(s)
    s = s.to_s
    s = s.match?(/%[0-9a-fA-F]{2}/) ? s.tr(' ', '+') : CGI.escape(s)
    s.gsub('.', '%2E')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a URL or partial path.
  #
  # The result will have query parameters in sorted order.  Query parameters
  # are assumed to have the form "key=value" with the exception of the first
  # parameter after the '?' -- this is a concession to Bookshare URLs like
  # "myReadingLists/(id)?delete".
  #
  # @param [Array<*>] args            URL path components.
  # @param [Hash]     opt             Passed as #url_query options.
  #
  # @return [String]
  #
  def make_path(*args, **opt)
    opt.reverse_merge!(args.extract_options!) if args.last.is_a?(Hash)
    url = args.flatten.compact.join('/').lstrip.sub(/[?&\s]+$/, '')
    url, query = url.split('?', 2)
    parts = query.to_s.split('&').compact_blank!
    first = (parts.shift unless parts.blank? || parts.first.include?('='))
    query = url_query(*parts, **opt).presence
    url << '?'   if first || query
    url << first if first
    url << '&'   if first && query
    url << query if query
    url
  end

  # Combine URL query parameters into a URL query string.
  #
  # @param [Array<URI,String,Array,Hash>] args
  # @param [Hash]                         opt   Passed to #extract_url_query.
  #
  # @option opt [Boolean] :decorate   If *false*, do not modify keys for multi-
  #                                     element array values (default: *true*).
  #
  # @option opt [Boolean] :unescape   If *true*, unescape values
  #                                     (default: *false*).
  #
  # @return [String]
  #
  def url_query(*args, **opt)
    opt.reverse_merge!(args.extract_options!) if args.last.is_a?(Hash)
    opt.reverse_merge!(decorate: true, unescape: false)
    extract_url_query(*args, **opt).flat_map { |key, value|
      Array.wrap(value).map { "#{key}=#{_1}" }
    }.join('&')
  end

  # Transform URL query parameters into a hash.
  #
  # @param [Array<URI,String,Array,Hash>] args
  # @param [Boolean] minimize         If *false*, do not reduce single-element
  #                                     array values to scalars (def: *true*).
  # @param [Boolean] decorate         If *true*, modify keys for multi-element
  #                                     array values (default: *false*).
  # @param [Boolean] replace          If *true*, subsequence key values replace
  #                                     previous ones; if *false* then values
  #                                     accumulated as arrays (def: *false*).
  # @param [Boolean] unescape         If *false*, do not unescape values.
  # @param [Hash]    opt              Included in *args* if present.
  #
  # @return [Hash{String=>String}]
  #
  def extract_url_query(
    *args,
    minimize: true,
    decorate: false,
    replace:  false,
    unescape: true,
    **opt
  )
    opt = reject_blanks(args.extract_options!.merge(opt))
    args << opt if opt.present?
    normal = ->(v) { CGI.unescape(v.to_s) }
    rmerge = !replace
    result = {}
    args.each do |arg|
      arg = arg.query                        if arg.is_a?(URI)
      arg = arg.sub(/^.*?\?/, '').split('&') if arg.is_a?(String)
      arg = arg.to_a                         if arg.is_a?(Hash)
      next unless arg.present? && arg.is_a?(Array)
      res = {}
      arg.each do |pair|
        k, v = pair.is_a?(Array) ? pair : pair.to_s.split('=', 2)
        next if (k = normal.(k).delete_suffix('[]')).blank?
        next if (v = Array.wrap(v).compact_blank.map!(&:to_s)).blank?
        v.map!(&normal) if unescape
        rmerge && res[k]&.rmerge!(v) || res.merge!(k => v)
      end
      rmerge ? result.rmerge!(res) : result.merge!(res)
    end
    result.map { |k, v|
      v = v.sort.uniq
      v = v.first  if minimize && !v.many?
      k = "#{k}[]" if decorate && v.is_a?(Array)
      [k, v]
    }.to_h
  end

end

__loading_end(__FILE__)
