# app/helpers/head_helper/stylesheets.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for setting/getting '<link rel="stylesheet">' meta-tags.
#
# @see "en.emma.head.stylesheets"
#
module HeadHelper::Stylesheets

  include HeadHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # @type [Array<String>]
  DEFAULT_PAGE_STYLESHEETS = HEAD_CONFIG[:stylesheets] || []

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the stylesheets for this page.
  #
  # If a block is given, this invocation is being used to accumulate stylesheet
  # sources; otherwise this invocation is being used to emit the stylesheet
  # '<link>' element(s).
  #
  # @return [ActiveSupport::SafeBuffer]   If no block given.
  # @return [Array<String>]               If block given.
  #
  # @yield To supply sources(s) to #set_page_stylesheets.
  # @yieldreturn [String, Array<String>]
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
  # @return [Array<String>]           The new @page_stylesheets contents.
  #
  # @yield To supply additional source(s) to @page_stylesheets.
  # @yieldreturn [String, Array<String>]
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
  # @yield To supply additional source(s) to @page_stylesheets.
  # @yieldreturn [String, Array<String>]
  #
  def append_page_stylesheets(*sources)
    @page_stylesheets ||= DEFAULT_PAGE_STYLESHEETS.dup
    @page_stylesheets += sources
    @page_stylesheets += Array.wrap(yield) if block_given?
    @page_stylesheets
  end

  # Emit the stylesheet '<link>' tag(s) appropriate for the current page.
  #
  # @param [Hash] opt                 Passed to #stylesheet_link_tag
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def emit_page_stylesheets(**opt)
    @page_stylesheets ||= DEFAULT_PAGE_STYLESHEETS.dup
    @page_stylesheets.flatten!
    @page_stylesheets.compact_blank!
    stylesheet_link_tag(*@page_stylesheets, opt) << app_stylesheet(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Main stylesheet for the application.
  #
  # @param [Hash] opt                 Passed to #stylesheet_link_tag
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def app_stylesheet(**opt)
    opt['media']                 ||= 'all'
    opt['data-turbolinks-track'] ||= 'reload'
    stylesheet_link_tag('application', opt).prepend("\n")
  end

end

__loading_end(__FILE__)
