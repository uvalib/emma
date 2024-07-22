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
  include LinkHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Footer elements.
  #
  # @type [Hash]
  #
  FOOT_CONFIG =
    config_page_section(:foot).select { |_, v|
      v.is_a?(Hash) && v.present?
    }.deep_freeze

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
    FOOT_CONFIG.map { |k, v|
      label = v[:label]&.to_s || k.to_s.capitalize
      if (url = v[:link])
        value = url.include?('@') ? mail_to(url) : external_link(url)
      elsif v[:content].to_s.casecmp?('BUILD_VERSION')
        value = BUILD_VERSION
      else
        value = v[:content]
      end
      [label, value]
    }.to_h.merge(opt)
  end

end

__loading_end(__FILE__)
