# app/helpers/layout_helper/page_language.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LayoutHelper::PageLanguage
#
module LayoutHelper::PageLanguage

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The language code for the language of the current page for use with the
  # "<html>" element.
  #
  # @return [String]
  #
  def page_language
    @page_language ||= I18n.locale.to_s.downcase.sub(/-.*$/, '')
  end

  # Specify the language code for the current page.
  #
  # @param [String, Symbol] lang
  #
  # @return [String]
  #
  # == Usage Notes
  # Only use as an override if the page is in a language that has not been set
  # via I18n::Config#locale.
  #
  def set_page_language(lang)
    @page_language = lang.to_s.downcase.sub(/-.*$/, '')
  end

end

__loading_end(__FILE__)
