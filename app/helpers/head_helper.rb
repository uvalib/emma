# app/helpers/head_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting document "<head>" entries.
#
module HeadHelper

  def self.included(base)
    __included(base, '[HeadHelper]')
  end

  include GenericHelper

  # ===========================================================================
  # :section: Head - page title
  # ===========================================================================

  public

  # Text at the start of all page titles.
  #
  # @type [String]
  #
  PAGE_TITLE_PREFIX = I18n.t('emma.head.title.prefix').freeze

  # String prepended to all page titles.
  #
  # @type [String]
  #
  PAGE_TITLE_HEADER = PAGE_TITLE_PREFIX

  # Text at the end of all page titles.
  #
  # @type [String]
  #
  PAGE_TITLE_SUFFIX = I18n.t('emma.head.title.suffix').freeze

  # String appended to all page titles.
  #
  # @type [String]
  #
  PAGE_TITLE_TRAILER = " | #{PAGE_TITLE_SUFFIX}"

  # Access the page title.
  #
  # If a block is given, this invocation is being used to accumulate text into
  # the title; otherwise this invocation is being used to emit the "<title>"
  # element.
  #
  # @return [ActiveSupport::SafeBuffer]   If no block given.
  # @return [Array<String>]               If block given.
  #
  def page_title
    if block_given?
      set_page_title(*yield)
    else
      emit_page_title
    end
  end

  # Set the page title, eliminating any previous value.
  #
  # @param [Array] values
  #
  # @return [Array<String>]           The updated @page_title contents.
  #
  def set_page_title(*values)
    @page_title = []
    @page_title += values
    @page_title += Array.wrap(yield) if block_given?
    @page_title
  end

  # Add to the page title.
  #
  # @param [Array] values
  #
  # @return [Array<String>]           The updated @page_title contents.
  #
  def append_page_title(*values)
    @page_title ||= []
    @page_title += values
    @page_title += Array.wrap(yield) if block_given?
    @page_title
  end

  # Emit the "<title>" element (within "<head>").
  #
  # @param [Hash, nil] opt            Passed to #content_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Implementation Notes
  # Emit the <title> element with `data-turbolinks-eval="false"` so that it is
  # not included in Turbolinks' determination of whether the contents of <head>
  # have changed.
  #
  def emit_page_title(**opt)
    @page_title ||= []
    @page_title.flatten!
    text = @page_title.join(' ').squish
    text.prepend(PAGE_TITLE_HEADER) unless text.start_with?(PAGE_TITLE_PREFIX)
    text << PAGE_TITLE_TRAILER      unless text.end_with?(PAGE_TITLE_SUFFIX)
    content_tag(:title, opt.reverse_merge('data-turbolinks-eval': false)) do
      sanitized_string(text)
    end
  end

  # ===========================================================================
  # :section: Head - favicon
  # ===========================================================================

  public

  # @type [String]
  DEFAULT_PAGE_FAVICON = I18n.t('emma.head.favicon.asset').freeze

  # Access the favicon appropriate for the current page.
  #
  # If a block is given, this invocation is being used to set the favicon;
  # otherwise this invocation is being used to emit the favicon "<link>" tag.
  #
  # @return [ActiveSupport::SafeBuffer]   If no block given.
  # @return [String]                      If block given.
  #
  def page_favicon
    if block_given?
      set_page_favicon(yield)
    else
      emit_page_favicon
    end
  end

  # Set the favicon for this page, eliminating any previous value.
  #
  # @param [String] src
  #
  # @return [String]                  The updated @page_favicon.
  #
  def set_page_favicon(src)
    @page_favicon = block_given? && yield || src
  end

  # Emit the shortcut icon "<link>" tag appropriate for the current page.
  #
  # @param [Hash, nil] opt            Passed to #favicon_link_tag
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def emit_page_favicon(**opt)
    @page_favicon ||= DEFAULT_PAGE_FAVICON
    opt = link_options(opt)
    favicon_link_tag(@page_favicon, opt)
  end

  # ===========================================================================
  # :section: Head - stylesheets
  # ===========================================================================

  public

  # @type [Array<String>]
  DEFAULT_PAGE_STYLESHEETS = I18n.t('emma.head.stylesheets').deep_freeze

  # Access the stylesheets for this page.
  #
  # If a block is given, this invocation is being used to accumulate stylesheet
  # sources; otherwise this invocation is being used to emit the stylesheet
  # "<link>" element(s).
  #
  # @return [ActiveSupport::SafeBuffer]   If no block given.
  # @return [Array<String>]               If block given.
  #
  def page_stylesheets
    if block_given?
      set_page_stylesheets(*yield)
    else
      emit_page_stylesheets
    end
  end

  # Set the stylesheet(s) for this page, eliminating any previous value(s).
  #
  # @param [Array] sources
  #
  # @return [Array<String>]           The updated @page_stylesheets contents.
  #
  def set_page_stylesheets(*sources)
    @page_stylesheets = []
    @page_stylesheets += sources
    @page_stylesheets += Array.wrap(yield) if block_given?
    @page_stylesheets
  end

  # Add to the stylesheet(s) for this page.
  #
  # @param [Array] sources
  #
  # @return [Array<String>]           The updated @page_stylesheets contents.
  #
  def append_page_stylesheets(*sources)
    @page_stylesheets ||= DEFAULT_PAGE_STYLESHEETS.dup
    @page_stylesheets += sources
    @page_stylesheets += Array.wrap(yield) if block_given?
    @page_stylesheets
  end

  # Emit the stylesheet "<link>" tag(s) appropriate for the current page.
  #
  # @param [Hash, nil] opt            Passed to #stylesheet_link_tag
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def emit_page_stylesheets(**opt)
    @page_stylesheets ||= DEFAULT_PAGE_STYLESHEETS.dup
    @page_stylesheets.flatten!
    @page_stylesheets.reject!(&:blank?)
    @page_stylesheets.uniq!
    sources = @page_stylesheets.dup
    sources << link_options(opt)
    stylesheet_link_tag(*sources)
  end

  # ===========================================================================
  # :section: Head - scripts
  # ===========================================================================

  public

  # @type [Array<String>]
  DEFAULT_PAGE_JAVASCRIPTS = I18n.t('emma.head.javascripts').deep_freeze

  # Access the scripts for this page.
  #
  # If a block is given, this invocation is being used to accumulate script
  # sources; otherwise this invocation is being used to emit the JavaScript
  # "<script>" element(s).
  #
  # @return [ActiveSupport::SafeBuffer]   If no block given.
  # @return [Array<String>]               If block given.
  #
  def page_javascripts
    if block_given?
      set_page_javascripts(*yield)
    else
      emit_page_javascripts
    end
  end

  # Set the script(s) for this page, eliminating any previous value(s).
  #
  # @param [Array] sources
  #
  # @return [Array<String>]           The updated @page_javascript contents.
  #
  def set_page_javascripts(*sources)
    @page_javascript = []
    @page_javascript += sources
    @page_javascript += Array.wrap(yield) if block_given?
    @page_javascript
  end

  # Add to the script(s) for this page.
  #
  # @param [Array] sources
  #
  # @return [Array<String>]           The updated @page_javascript contents.
  #
  def append_page_javascripts(*sources)
    @page_javascript ||= DEFAULT_PAGE_JAVASCRIPTS.dup
    @page_javascript += sources
    @page_javascript += Array.wrap(yield) if block_given?
    @page_javascript
  end

  # Emit the "<script>" tag(s) appropriate for the current page.
  #
  # @param [Hash, nil] opt            Passed to #javascript_include_tag
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def emit_page_javascripts(**opt)
    @page_javascript ||= DEFAULT_PAGE_JAVASCRIPTS.dup
    @page_javascript.flatten!
    @page_javascript.reject!(&:blank?)
    @page_javascript.uniq!
    sources = @page_javascript.dup
    sources << link_options(opt)
    javascript_include_tag(*sources)
  end

  # ===========================================================================
  # :section: Head - meta tags
  # ===========================================================================

  public

  # @type [Hash]
  DEFAULT_PAGE_META_TAGS = {}.freeze

  # Default separator to join meta tag content values which are arrays.
  #
  # @type [String]
  #
  META_TAG_CONTENT_SEPARATOR = '; '

  # Default separator between meta tags.
  #
  # @type [String]
  #
  META_TAG_SEPARATOR = "\n"

  # Access the meta tags for this page.
  #
  # If a block is given, this invocation is being used to accumulate "<meta>"
  # tags; otherwise this invocation is being used to emit the "<meta>" tags.
  #
  # @return [ActiveSupport::SafeBuffer]   If no block given.
  # @return [Hash]                        If block given.
  #
  def page_meta_tags
    if block_given?
      set_page_meta_tags(*yield)
    else
      emit_page_meta_tags
    end
  end

  # Set the meta tags for this page, eliminating any previous value.
  #
  # @param [Hash] source
  #
  # @return [Hash]                    The updated @page_meta_tags contents.
  #
  def set_page_meta_tags(source)
    @page_meta_tags = {}
    merge_meta_tags!(source)
    merge_meta_tags!(block_given? && yield)
  end

  # Add to the meta tags for this page.
  #
  # @param [Hash] source
  #
  # @return [Hash]                    The updated @page_meta_tags contents.
  #
  def append_page_meta_tags(source)
    @page_meta_tags ||= DEFAULT_PAGE_META_TAGS.dup
    merge_meta_tags!(source)
    merge_meta_tags!(block_given? && yield)
  end

  # Replace existing (or add new) meta tags for this page.
  #
  # @param [Hash] source
  #
  # @return [Hash]                    The updated @page_meta_tags contents.
  #
  def replace_page_meta_tags(source)
    @page_meta_tags ||= DEFAULT_PAGE_META_TAGS.dup
    @page_meta_tags.merge!(source) if source.present?
    @page_meta_tags.merge!(yield)  if block_given?
    @page_meta_tags
  end

  # Emit the "<meta>" tag(s) appropriate for the current page.
  #
  # @param [Hash, nil] opt                Passed to #emit_meta_tag except for:
  #
  # @option opt [String] :tag_separator   Default: #META_TAG_SEPARATOR
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def emit_page_meta_tags(**opt)
    html_opt, opt = extract_options(opt, :tag_separator)
    tag_separator = opt[:tag_separator] || META_TAG_SEPARATOR
    @page_meta_tags ||= DEFAULT_PAGE_META_TAGS.dup
    @page_meta_tags.map { |key, value|
      emit_meta_tag(key, value, html_opt)
    }.compact.join(tag_separator).html_safe
  end

  # ===========================================================================
  # :section: Head - meta tags
  # ===========================================================================

  protected

  # Strings to prepend to the respective meta tags.
  #
  # @type [Hash{Symbol=>String}]
  #
  META_TAG_PREFIX = {
    description: I18n.t('emma.head.description.prefix').freeze
  }.freeze

  # Strings to append to the respective meta tags.
  #
  # @type [Hash{Symbol=>String}]
  #
  META_TAG_SUFFIX = {
  }.freeze

  # Include common options for "<link>" and "<script>" tags.
  #
  # @param [Hash, nil] opt
  #
  # @return [Hash]
  #
  # == Implementation Notes
  # Note that 'reload' is the documented value for 'data-turbolinks-track'
  # however (for some unknown reason) causes requests to be made twice.  By
  # experimentation the value that works best here is the empty string.
  #
  def link_options(**opt)
    opt.reverse_merge('data-turbolinks-track': '')
  end

  # Merge hashes, accumulating values as arrays for overlapping keys.
  #
  # @param [Hash] src
  #
  # @return [Hash]                    The updated @page_meta_tags contents.
  #
  def merge_meta_tags!(src)
    @page_meta_tags.tap do |dst|
      if src.present?
        src.each_pair do |k, v|
          k = k.to_sym
          v = Array.wrap(dst[k]) + Array.wrap(v) if dst[k].present?
          dst[k] = v
        end
      end
    end
  end

  # @type [Array<Symbol>]
  EMIT_META_TAG_OPTIONS =
    %i[content_separator list_separator pair_separator sanitize].freeze

  # Generate a <meta> tag with special handling for :robots.
  #
  # @param [Symbol]                key
  # @param [String, Symbol, Array] value
  # @param [Hash, nil]             opt        Passed to #tag except for:
  #
  # @option opt [String]  :content_separator  Def.: #META_TAG_CONTENT_SEPARATOR
  # @option opt [String]  :list_separator     Passed to #array_string.
  # @option opt [String]  :pair_separator     Passed to #array_string.
  # @option opt [Boolean] :sanitize           Passed to #array_string.
  #
  # @return [ActiveSupport::SafeBuffer]       If valid.
  # @return [nil]                             If the tag would be a "no-op".
  #
  def emit_meta_tag(key, value, opt)

    tag_opt, list_opt = extract_options(opt, EMIT_META_TAG_OPTIONS)
    sep   = list_opt.delete(:content_separator) || META_TAG_CONTENT_SEPARATOR
    value = value.is_a?(Array) ? value.dup : [value]

    # If *value* is one or more Symbols, *key* is assumed to be :robots (or a
    # variant like :googlebot); if the tag is determined to be non-functional
    # then the result will be *nil*.
    if value.any? { |v| v.is_a?(Symbol) }
      value.map! { |v| v.to_s.downcase }.sort!.uniq!
      return if (value == %w(index)) || (value == %w(follow index))
      sep = ','
    end

    # The tag content is formed from the value(s) accumulated for this item.
    content = normalized_list(value, **list_opt).join(sep)
    if (prefix = META_TAG_PREFIX[key]) && !content.start_with?(prefix)
      prefix = "#{prefix} - " unless prefix.end_with?(' ')
      # NOTE: The following silences a bug in RubyMine inspection:
      # noinspection RubyArgCount
      content.prepend(prefix)
    end
    if (suffix = META_TAG_SUFFIX[key]) && !content.end_with?(suffix)
      suffix = " #{suffix}" unless suffix.start_with?(' ')
      content << suffix
    end

    # Return with the <meta> tag element.
    tag(:meta, tag_opt.merge(name: key.to_s, content: content))
  end

  # ===========================================================================
  # :section: Head - meta description
  # ===========================================================================

  public

  # Set <meta name="description">, eliminating any previous value.
  #
  # @param [Array<String>] values
  #
  # @return [Hash]                    The updated @page_meta_tags contents.
  #
  def set_page_description(*values)
    opt = { sanitize: false } # Sanitization occurs in #emit_meta_tag.
    replace_page_meta_tags(description: normalized_list(values, opt))
  end

  # Add to <meta name="description">.
  #
  # @param [Array<String>] values
  #
  # @return [Hash]                    The updated @page_meta_tags contents.
  #
  def append_page_description(*values)
    opt = { sanitize: false } # Sanitization occurs in #emit_meta_tag.
    append_page_meta_tags(description: normalized_list(values, opt))
  end

  # ===========================================================================
  # :section: Head - meta robots
  # ===========================================================================

  public

  # Set <meta name="robots">.
  #
  # @param [Array<String,Symbol>] values
  #
  # @return [Hash]                    The updated @page_meta_tags contents.
  #
  def set_page_robots(*values)
    replace_page_meta_tags(robots: values.map(&:to_sym))
  end

  # Add to <meta name="robots">.
  #
  # @param [Array<String,Symbol>] values
  #
  # @return [Hash]                    The updated @page_meta_tags contents.
  #
  def append_page_robots(*values)
    append_page_meta_tags(robots: values.map(&:to_sym))
  end

end

__loading_end(__FILE__)
