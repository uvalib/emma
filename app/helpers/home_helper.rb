# app/helpers/home_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for /home pages.
#
module HomeHelper

  include CssHelper
  include HtmlHelper
  include AboutHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a display of the number of active EMMA member organizations.
  #
  # @param [String] css               Characteristic CSS class/selector
  # @param [Hash]   opt               Passed to #html_span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def orgs_count(css: '.orgs-count', **opt)
    prepend_css!(opt, css)
    html_span(**opt) do
      Org.active.count
    end
  end

  # Generate a display list of active EMMA member organizations.
  #
  # @param [String] css               Characteristic CSS class/selector
  # @param [Hash]   opt               Passed to #html_ul.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def orgs_list(css: '.orgs-list', **opt)
    prepend_css!(opt, css)
    html_ul(**opt) do
      org_names.map { |org| html_li(org) }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
