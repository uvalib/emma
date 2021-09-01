# lib/emma/common/url_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'cgi'

module Emma::Common::UrlMethods

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
  # @param [Array] args               URL path components, except for args[-1]
  #                                     which is passed as #url_query options.
  #
  # @return [String]
  #
  #--
  # noinspection RubyNilAnalysis, RubyMismatchedParameterType
  #++
  def make_path(*args)
    opt = args.extract_options!
    url = args.flatten.join('/').lstrip.sub(/[?&\s]+$/, '')
    url, query = url.split('?', 2)
    parts = query.to_s.split('&').compact_blank
    first = (parts.shift unless parts.blank? || parts.first.include?('='))
    query = url_query(parts, opt).presence
    url << '?'   if first || query
    url << first if first
    url << '&'   if first && query
    url << query if query
    url
  end

  # Combine URL query parameters into a URL query string.
  #
  # @param [Array<URI,String,Array,Hash>] args
  #
  # @option args.last [Boolean] :minimize   If *false*, do not reduce single-
  #                                           element array values to scalars
  #                                           (default: *true*).
  #
  # @option args.last [Boolean] :decorate   If *false*, do not modify keys for
  #                                           multi-element array values
  #                                           (default: *true*).
  #
  # @option args.last [Boolean] :replace    If *true*, subsequence key values
  #                                           replace previous ones; if *false*
  #                                           then values are accumulated as
  #                                           arrays (default: *false*).
  #
  # @return [String]
  #
  # @see #build_query_options
  #
  def url_query(*args)
    opt = { decorate: true, unescape: false }.merge!(args.extract_options!)
    build_query_options(*args, opt).flat_map { |k, v|
      v.is_a?(Array) ? v.map { |e| "#{k}=#{e}" } : "#{k}=#{v}"
    }.join('&')
  end

  # Transform URL query parameters into a hash.
  #
  # @param [Array<URI,String,Array,Hash>] args
  #
  # @option args.last [Boolean] :minimize   If *false*, do not reduce single-
  #                                           element array values to scalars
  #                                           (default: *true*).
  #
  # @option args.last [Boolean] :decorate   If *true*, modify keys for multi-
  #                                           element values (default: *false*)
  #
  # @option args.last [Boolean] :replace    If *true*, subsequence key values
  #                                           replace previous ones; if *false*
  #                                           then values are accumulated as
  #                                           arrays (default: *false*).
  #
  # @option args.last [Boolean] :unescape   If *false*, do not unescape values.
  #
  # @return [Hash{String=>String}]
  #
  def build_query_options(*args)
    opt = {
      minimize: true,
      decorate: false,
      replace:  false,
      unescape: true
    }.merge!(args.extract_options!)
    minimize = opt.delete(:minimize)
    decorate = opt.delete(:decorate)
    replace  = opt.delete(:replace)
    unescape = opt.delete(:unescape)
    opt      = reject_blanks(opt)
    args << opt if opt.present?
    result = {}
    args.each do |arg|
      arg = arg.query      if arg.is_a?(URI)
      arg = arg.split('&') if arg.is_a?(String)
      arg = arg.to_a       if arg.is_a?(Hash)
      next unless arg.is_a?(Array) && arg.present?
      res = {}
      arg.each do |pair|
        k, v = pair.is_a?(Array) ? pair : pair.to_s.split('=', 2)
        k = CGI.unescape(k.to_s).delete_suffix('[]')
        v = Array.wrap(v).compact_blank
        next if k.blank? || v.blank?
        v.map!(&:to_s)
        v.map! { |s| CGI.unescape(s) } if unescape
        if replace || !res[k]
          res[k] = v
        else
          res[k].rmerge!(v)
        end
      end
      if replace
        result.merge!(res)
      else
        result.rmerge!(res)
      end
    end
    result.map { |k, v|
      v = v.sort.uniq
      v = v.first  if minimize && (v.size <= 1)
      k = "#{k}[]" if decorate && v.is_a?(Array)
      [k, v]
    }.to_h
  end


end

__loading_end(__FILE__)
