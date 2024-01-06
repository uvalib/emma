# app/helpers/html_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Shared view helper HTML support methods.
#
module HtmlHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.include(ActionView::Helpers::TagHelper)
    base.extend(ActionView::Helpers::TagHelper)
    base.extend(ActionView::Helpers::UrlHelper)
    include_and_extend_submodules(base)
  end

end

__loading_end(__FILE__)
