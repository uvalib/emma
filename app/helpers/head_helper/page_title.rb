# app/helpers/head_helper/page_title.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for setting/getting the <title> meta-tag.
#
module HeadHelper::PageTitle

  include HeadHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Text at the start of all page titles.
  #
  # @type [String]
  #
  PAGE_TITLE_PREFIX = HEAD_CONFIG.dig(:title, :prefix)

  # String prepended to all page titles.
  #
  # @type [String]
  #
  PAGE_TITLE_HEADER = PAGE_TITLE_PREFIX

  # Text at the end of all page titles.
  #
  # @type [String]
  #
  PAGE_TITLE_SUFFIX = HEAD_CONFIG.dig(:title, :suffix)

  # String appended to all page titles.
  #
  # @type [String]
  #
  PAGE_TITLE_TRAILER = " | #{PAGE_TITLE_SUFFIX}"

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the page title.
  #
  # If a block is given, this invocation is being used to accumulate text into
  # the title; otherwise this invocation is being used to emit the "<title>"
  # element.
  #
  # @return [ActiveSupport::SafeBuffer]   If no block given.
  # @return [Array<String>]               If block given.
  #
  # @yield To supply value(s) to #set_page_title.
  # @yieldreturn [String, Array<String>]
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
  # @yield To supply additional values to @page_title.
  # @yieldreturn [String, Array<String>]
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
  # @yield To supply additional values to @page_title.
  # @yieldreturn [String, Array<String>]
  #
  def append_page_title(*values)
    @page_title ||= []
    @page_title += values
    @page_title += Array.wrap(yield) if block_given?
    @page_title
  end

  # Emit the "<title>" element (within "<head>").
  #
  # @param [Hash] opt                 Passed to #html_tag.
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
    html_tag(:title, opt.reverse_merge('data-turbolinks-eval': false)) do
      sanitized_string(text)
    end
  end

end

__loading_end(__FILE__)
