# app/helpers/html_helper/options.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Shared view helper HTML support methods.
#
module HtmlHelper::Options

  include HtmlHelper::Attributes
  include CssHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Make a copy which has only valid HTML attributes with coalesced "data-*"
  # and `data: { }` options.
  #
  # @param [Hash, nil] html_opt       The target options hash.
  #
  # @return [Hash]
  #
  # @note Currently unused.
  #
  def html_options(html_opt)
    html_options!(dup_options(html_opt))
  end

  # Retain only entries which are valid HTML attributes with coalesced "data-*"
  # and `data: { }` options.
  #
  # @param [Hash] html_opt            The target options hash.
  #
  # @return [Hash]                    The modified *html_opt* hash.
  #
  def html_options!(html_opt)
    meth = html_opt.delete(:method).presence
    data = html_opt.delete(:data).presence
    html_opt.reverse_merge!(data.transform_keys { :"data-#{_1}" }) if data
    html_opt[:'data-method'] ||= meth if meth
    remove_non_attributes!(html_opt)
  end

  # Merge values from one or more options hashes.
  #
  # @param [Hash, nil]       html_opt   The target options hash.
  # @param [Array<Hash,nil>] args       Options hash(es) to merge into *opt*.
  #
  # @return [Hash]                      A new hash.
  #
  def merge_html_options(html_opt, *args)
    html_opt = html_opt&.dup || {}
    # noinspection RubyMismatchedArgumentType
    merge_html_options!(html_opt, *args)
  end

  # Merge values from one or more hashes into an options hash.
  #
  # @param [Hash]            html_opt   The target options hash.
  # @param [Array<Hash,nil>] args       Options hash(es) to merge into *opt*.
  #
  # @return [Hash]                      The modified *opt* hash.
  #
  def merge_html_options!(html_opt, *args)
    args    = args.map { _1[:class] ? _1.dup : _1 if _1.is_a?(Hash) }.compact
    classes = args.map { _1.delete(:class) }.compact
    append_css!(html_opt, *classes).merge!(*args)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Append additional line(s) options[:title].
  #
  # @param [Hash]          options
  # @param [Array<String>] lines
  #
  # @return [Hash]                    The modified *options*.
  #
  def append_tooltip!(options, *lines)
    tooltip = tooltip_text(options[:title], *lines)
    options.merge!(title: tooltip)
  end

  # Generate multi-line tooltip text, avoiding parts of *lines* that duplicate
  # the final part of *title*.
  #
  # @param [String, nil]   title
  # @param [Array<String>] lines
  #
  # @return [String]
  #
  def tooltip_text(title, *lines)
    split = ->(v) { v.to_s.split("\n").compact_blank }
    text  = split.(title)
    rest  = lines.flat_map(&split)
    if text.present? && rest.present?
      norm = ->(v) { v.gsub(/[[:punct:]]/, ' ').squish.downcase }
      last = norm.(text.last)
      rest.delete_if { norm.(_1) == last }
    end
    text.concat(rest).join("\n")
  end

end

__loading_end(__FILE__)
