# app/helpers/head_helper/stylesheets.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# HeadHelper::Stylesheets
#
module HeadHelper::Stylesheets

  include HeadHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # @type [Array<String>]
  DEFAULT_PAGE_STYLESHEETS = I18n.t('emma.head.stylesheets').deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the stylesheets for this page.
  #
  # If a block is given, this invocation is being used to accumulate stylesheet
  # sources; otherwise this invocation is being used to emit the stylesheet
  # "<link>" element(s).
  #
  # @yield Supplies sources(s) to #set_page_stylesheets.
  # @yieldreturn [String, Array<String>]
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
  # @yield Supplies additional source(s) to @page_stylesheets.
  # @yieldreturn [String, Array<String>]
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
  # @yield Supplies additional source(s) to @page_stylesheets.
  # @yieldreturn [String, Array<String>]
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
  # @param [Hash] opt                 Passed to #stylesheet_link_tag
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def emit_page_stylesheets(**opt)
    @page_stylesheets ||= DEFAULT_PAGE_STYLESHEETS.dup
    @page_stylesheets.flatten!
    @page_stylesheets.reject!(&:blank?)
    @page_stylesheets.uniq!
    sources = @page_stylesheets.dup
    sources << meta_options(opt)
    stylesheet_link_tag(*sources)
  end

end

__loading_end(__FILE__)