# app/helpers/head_helper/page_title.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for setting/getting the '<title>' meta-tag.
#
module HeadHelper::PageTitle

  include HeadHelper::Common

  include HtmlHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # @private
  META_TITLE_CONFIG = HEAD_CONFIG[:title] || {}

  # Text at the start of all page titles.
  #
  # @type [String]
  #
  META_TITLE_PREFIX = META_TITLE_CONFIG[:prefix] || ''

  # String prepended to all page titles.
  #
  # @type [String]
  #
  META_TITLE_LEADER = META_TITLE_PREFIX

  # Text at the end of all page titles.
  #
  # @type [String]
  #
  META_TITLE_SUFFIX = META_TITLE_CONFIG[:suffix] || ''

  # String appended to all page titles.
  #
  # @type [String]
  #
  META_TITLE_TRAILER = "| #{META_TITLE_SUFFIX}"

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the page title.
  #
  # If a block is given, this invocation is being used to accumulate text into
  # the title; otherwise this invocation is being used to emit the '<title>'
  # element.
  #
  # @return [ActiveSupport::SafeBuffer]   If no block given.
  # @return [Array<String>]               If block given.
  #
  # @yield To supply value(s) to #set_page_meta_title.
  # @yieldreturn [String, Array<String>]
  #
  def page_meta_title
    if block_given?
      set_page_meta_title(*yield)
    else
      emit_page_meta_title
    end
  end

  # Set the page title, eliminating any previous value.
  #
  # @param [Array] values
  #
  # @return [Array<String>]           The new @page_meta_title contents.
  #
  # @yield To supply additional values to @page_meta_title.
  # @yieldreturn [String, Array<String>]
  #
  def set_page_meta_title(*values)
    @page_meta_title = values
    @page_meta_title.concat(Array.wrap(yield)) if block_given?
    @page_meta_title
  end

  # Add to the page title.
  #
  # @param [Array] values
  #
  # @return [Array<String>]           The updated @page_meta_title contents.
  #
  # @yield To supply additional values to @page_meta_title.
  # @yieldreturn [String, Array<String>]
  #
  def append_page_meta_title(*values)
    @page_meta_title ||= []
    @page_meta_title.concat(values)
    @page_meta_title.concat(Array.wrap(yield)) if block_given?
    @page_meta_title
  end

  # Emit the '<title>' element (within '<head>').
  #
  # @param [Hash] opt                 Passed to #html_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # === Implementation Notes
  # Emit the '<title>' element with 'data-turbolinks-eval="false"' so that it
  # is not included in Turbolinks' determination of whether the contents of
  # '<head>' have changed.
  #
  def emit_page_meta_title(**opt)
    @page_meta_title &&= @page_meta_title.flatten.compact_blank.uniq
    @page_meta_title ||= []
    title  = @page_meta_title.join(' ').squish
    parts  = []
    parts << META_TITLE_LEADER  unless title.start_with?(META_TITLE_PREFIX)
    parts << title
    parts << META_TITLE_TRAILER unless title.end_with?(META_TITLE_SUFFIX)
    title  = parts.join(' ').strip
    html_tag(:title, 'data-turbolinks-eval': false, **opt) do
      sanitized_string(title).squish
    end
  end

end

__loading_end(__FILE__)
