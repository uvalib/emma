# app/helpers/layout_helper/footer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for the page '<footer>'.
#
module LayoutHelper::Footer

  include LayoutHelper::Common

  include HtmlHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Content for the footer. # TODO: I18n
  #
  # @type [Hash]
  #
  FOOTER_TABLE = {
    Website: link_to(nil, PROJECT_SITE),
    Contact: mail_to(CONTACT_EMAIL)
  }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render a table of values from `#session`.
  #
  # @param [Hash] opt                 Passed to outer #html_div.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def footer_table(**opt)
    css_selector  = '.footer-table'
    opt[:wrap]    = true unless opt.key?(:wrap)
    opt[:col_max] = 2    unless opt.key?(:col_max)
    grid_table(FOOTER_TABLE, **prepend_classes!(opt, css_selector))
  end

end

__loading_end(__FILE__)
