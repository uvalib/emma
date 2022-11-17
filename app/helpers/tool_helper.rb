# app/helpers/tool_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting standalone "tools".
#
module ToolHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The table of standalone tool labels and paths.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  #--
  # noinspection RailsI18nInspection, RubyNilAnalysis
  #++
  TOOL_ITEMS =
    I18n.t('emma.tool').map { |k, v|
      next unless v.is_a?(Hash) && v[:_endpoint] && (k != :index)
      v = v.slice(:label, :path)
      v[:path] = v[:path]&.to_sym
      [k, v]
    }.compact.to_h.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Standalone tool list entry.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to outer :ul tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/search.js
  #
  def tool_list(css: '.tool-list', **opt)
    prepend_css!(opt, css)
    html_tag(:ul, opt) do
      TOOL_ITEMS.map { |k, v| tool_list_item(k, v) }
    end
  end

  # Standalone tool list entry.
  #
  # @param [Symbol] action
  # @param [Hash]   config
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #link_to.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/search.js
  #
  def tool_list_item(action, config, css: '.tool-item', **opt)
    label  = config[:label]&.to_s || '???'
    path   = config[:path]
    path   = try(path) if path.is_a?(Symbol)
    path ||= url_for(controller: :tool, action: action, only_path: true)
    prepend_css!(opt, css)
    html_tag(:li, opt) do
      link_to(label, path)
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
