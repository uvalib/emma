# app/helpers/head_helper/page_title.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# HeadHelper::PageTitle
#
module HeadHelper::PageTitle

  include GenericHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

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
  # @yield Supplies value(s) to #set_page_title.
  # @yieldreturn [String, Array<String>]
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
  # @yield Supplies additional values to @page_title.
  # @yieldreturn [String, Array<String>]
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
  # @yield Supplies additional values to @page_title.
  # @yieldreturn [String, Array<String>]
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
  # @param [Hash] opt                 Passed to #content_tag.
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

end

__loading_end(__FILE__)
