# app/helpers/layout_helper/footer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for the page '<footer>'.
#
module LayoutHelper::Footer

  include LayoutHelper::Common

  include GridHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render a table of values from `#session`.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def footer_table(css: '.footer-table', **opt)
    opt[:wrap]    = true unless opt.key?(:wrap)
    opt[:col_max] = 2    unless opt.key?(:col_max)
    prepend_css!(opt, css)
    grid_table(footer_items, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Content for the footer.
  #
  # @param [Hash] opt
  #
  # @return [Hash]
  #
  def footer_items(**opt)
    opt.reverse_merge!(
      Website: link_to(nil, PROJECT_SITE),  # TODO: I18n
      Contact: mail_to(CONTACT_EMAIL)       # TODO: I18n
    )
  end

end

__loading_end(__FILE__)
