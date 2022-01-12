# app/helpers/head_helper/meta_tags.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for setting/getting <meta> tags.
#
module HeadHelper::MetaTags

  include HeadHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

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

  # Strings to prepend to the respective meta tags.
  #
  # @type [Hash{Symbol=>String}]
  #
  META_TAG_PREFIX = {
    description: HEAD_CONFIG.dig(:description, :prefix)
  }.freeze

  # Strings to append to the respective meta tags.
  #
  # @type [Hash{Symbol=>String}]
  #
  META_TAG_SUFFIX = {
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the meta tags for this page.
  #
  # If a block is given, this invocation is being used to accumulate "<meta>"
  # tags; otherwise this invocation is being used to emit the "<meta>" tags.
  #
  # @return [ActiveSupport::SafeBuffer]   If no block given.
  # @return [Hash]                        If block given.
  #
  # @yield To supply tag/value pairs to #set_page_meta_tags.
  # @yieldreturn [Hash]
  #
  def page_meta_tags
    if block_given?
      set_page_meta_tags(yield)
    else
      emit_page_meta_tags
    end
  end

  # Set the meta tags for this page, eliminating any previous value.
  #
  # @param [Hash, nil] pairs
  #
  # @return [Hash]                    The updated @page_meta_tags contents.
  #
  # @yield To supply additional tag/value pairs for @page_meta_tags.
  # @yieldreturn [Hash]
  #
  def set_page_meta_tags(pairs = nil)
    @page_meta_tags = {}
    merge_meta_tags!(pairs) if pairs.present?
    merge_meta_tags!(yield) if block_given?
    @page_meta_tags
  end

  # Add to the meta tags for this page.
  #
  # @param [Hash, nil] pairs
  #
  # @return [Hash]                    The updated @page_meta_tags contents.
  #
  # @yield To supply additional tag/value pairs for @page_meta_tags.
  # @yieldreturn [Hash]
  #
  def append_page_meta_tags(pairs = nil)
    @page_meta_tags ||= DEFAULT_PAGE_META_TAGS.dup
    merge_meta_tags!(pairs) if pairs.present?
    merge_meta_tags!(yield) if block_given?
    @page_meta_tags
  end

  # Replace existing (or add new) meta tags for this page.
  #
  # @param [Hash, nil] pairs
  #
  # @return [Hash]                    The updated @page_meta_tags contents.
  #
  # @yield To supply additional tag/value pairs for @page_meta_tags.
  # @yieldreturn [Hash]
  #
  def replace_page_meta_tags(pairs = nil)
    @page_meta_tags ||= DEFAULT_PAGE_META_TAGS.dup
    # noinspection RubyMismatchedArgumentType
    @page_meta_tags.merge!(pairs) if pairs.present?
    @page_meta_tags.merge!(yield) if block_given?
    @page_meta_tags
  end

  # Emit the "<meta>" tag(s) appropriate for the current page.
  #
  # @param [Hash] opt                 Passed to #emit_meta_tag except for:
  #
  # @option opt [String] :tag_separator   Default: #META_TAG_SEPARATOR
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def emit_page_meta_tags(opt = nil)
    opt, html_opt = partition_hash(opt, :tag_separator)
    tag_separator = opt[:tag_separator] || META_TAG_SEPARATOR
    @page_meta_tags ||= DEFAULT_PAGE_META_TAGS.dup
    # noinspection RubyMismatchedReturnType
    @page_meta_tags.map { |key, value|
      emit_meta_tag(key, value, html_opt)
    }.compact.join(tag_separator).html_safe
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Merge hashes, accumulating values as arrays for overlapping keys.
  #
  # @param [Hash, nil] src
  #
  # @return [Hash]                    The updated @page_meta_tags contents.
  #
  def merge_meta_tags!(src)
    @page_meta_tags.tap do |dst|
      src.presence&.each_pair do |k, v|
        k = k.to_sym
        v = Array.wrap(dst[k]) + Array.wrap(v) if dst[k].present?
        dst[k] = v
      end
    end
  end

  # @type [Array<Symbol>]
  EMIT_META_TAG_OPTIONS =
    %i[content_separator list_separator pair_separator sanitize quote].freeze

  # Generate a <meta> tag with special handling for :robots.
  #
  # @param [Symbol]                key
  # @param [String, Symbol, Array] value
  # @param [Hash]                  opt        Passed to #tag except for:
  #
  # @option opt [String]  :content_separator  Def.: #META_TAG_CONTENT_SEPARATOR
  # @option opt [String]  :list_separator     Passed to #normalized_list.
  # @option opt [String]  :pair_separator     Passed to #normalized_list.
  # @option opt [Boolean] :sanitize           Passed to #normalized_list.
  # @option opt [Boolean] :quote              Passed to #normalized_list.
  #
  # @return [ActiveSupport::SafeBuffer]       If valid.
  # @return [nil]                             If the tag would be a "no-op".
  #
  def emit_meta_tag(key, value, opt = nil)
    opt, html_opt = partition_hash(opt, *EMIT_META_TAG_OPTIONS)
    list_separator =
      opt.delete(:content_separator) || META_TAG_CONTENT_SEPARATOR

    # The tag name comes from the provided *key*.
    html_opt[:name] = key.to_s

    # If *value* is one or more Symbols, *key* is assumed to be :robots (or a
    # variant like :googlebot); if the tag is determined to be non-functional
    # then the result will be *nil*.
    value = value.is_a?(Array) ? value.dup : [value]
    if value.any? { |v| v.is_a?(Symbol) }
      value.map! { |v| v.to_s.downcase }.sort!.uniq!
      return if (value == %w(index)) || (value == %w(follow index))
      list_separator = ','
    end

    # The tag content is formed from the value(s) accumulated for this item.
    html_opt[:content] =
      normalized_list(value, **opt).join(list_separator).tap do |content|
        if (prefix = META_TAG_PREFIX[key]) && !content.start_with?(prefix)
          prefix = "#{prefix} - " unless prefix.end_with?(' ')
          content.prepend(prefix)
        end
        if (suffix = META_TAG_SUFFIX[key]) && !content.end_with?(suffix)
          suffix = " #{suffix}" unless suffix.start_with?(' ')
          content << suffix
        end
      end

    # Return with the <meta> tag element.
    tag(:meta, html_opt)
  end

  # ===========================================================================
  # :section: Meta description
  # ===========================================================================

  public

  # Set <meta name="description">, eliminating any previous value.
  #
  # @param [Array<String,Symbol,Hash>] values
  #
  # @return [Hash]                    The updated @page_meta_tags contents.
  #
  def set_page_description(*values)
    opt = { sanitize: false } # Sanitization occurs in #emit_meta_tag.
    replace_page_meta_tags(description: normalized_list(values, **opt))
  end

  # Add to <meta name="description">.
  #
  # @param [Array<String,Symbol,Hash>] values
  #
  # @return [Hash]                    The updated @page_meta_tags contents.
  #
  def append_page_description(*values)
    opt = { sanitize: false } # Sanitization occurs in #emit_meta_tag.
    append_page_meta_tags(description: normalized_list(values, **opt))
  end

  # ===========================================================================
  # :section: Meta robots
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
