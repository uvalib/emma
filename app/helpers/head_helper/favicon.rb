# app/helpers/head_helper/favicon.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# HeadHelper::Favicon
#
module HeadHelper::Favicon

  include HeadHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # @type [String]
  DEFAULT_PAGE_FAVICON = I18n.t('emma.head.favicon.asset').freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the favicon appropriate for the current page.
  #
  # If a block is given, this invocation is being used to set the favicon;
  # otherwise this invocation is being used to emit the favicon "<link>" tag.
  #
  # @yield Supplies a value to #set_page_favicon.
  # @yieldreturn [String]
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
  # @yield Supplies a value to @page_favicon.
  # @yieldreturn [String]
  #
  # @param [String] src
  #
  # @return [String]                  The updated @page_favicon.
  #
  def set_page_favicon(src)
    # noinspection RubyYardReturnMatch
    @page_favicon = block_given? && yield || src
  end

  # Emit the shortcut icon "<link>" tag appropriate for the current page.
  #
  # @param [Hash] opt                 Passed to #favicon_link_tag
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def emit_page_favicon(**opt)
    @page_favicon ||= DEFAULT_PAGE_FAVICON
    opt = meta_options(opt)
    # noinspection RubyYardReturnMatch
    favicon_link_tag(@page_favicon, opt)
  end

end

__loading_end(__FILE__)
