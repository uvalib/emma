# app/helpers/layout_helper/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LayoutHelper::Common
#
module LayoutHelper::Common

  include GenericHelper
  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Label for button to open a collapsible panel.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  PANEL_OPENER_LABEL =
    non_breaking(I18n.t('emma.panel.control.label')).html_safe.freeze

  # Tooltip for button to open a collapsible panel.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  PANEL_OPENER_TIP = I18n.t('emma.panel.control.tooltip').freeze

  # Label for button to close a collapsible panel.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  PANEL_CLOSER_LABEL =
    non_breaking(I18n.t('emma.panel.control.open.label')).html_safe.freeze

  # Tooltip for button to close a collapsible panel.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  PANEL_CLOSER_TIP = I18n.t('emma.panel.control.open.tooltip').freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # toggle_button
  #
  # @param [Hash] opt                 Passed to #button_tag except for:
  #
  # @option opt [String] :label       Default: #PANEL_OPENER_LABEL.
  # @option opt [String] :selector    Selector of the element(s) controlled by
  #                                     this button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def toggle_button(**opt)
    opt, html_opt = partition_options(opt, :label, :selector)
    label = opt[:label] ? non_breaking( opt[:label]) : PANEL_OPENER_LABEL
    prepend_css_classes!(html_opt, 'toggle')
    if (selector = opt[:selector])
      html_opt.deep_merge!(data: { selector: selector })
    elsif !html_opt[:'data-selector'] && !html_opt.dig(:data, :selector)
      raise 'no target selector given'
    end
    html_opt[:type]  ||= 'button'
    html_opt[:title] ||= PANEL_OPENER_TIP
    button_tag(label, html_opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The current type of search (as indicated by the current controller).
  #
  # @param [Symbol, String, nil] type   Default: `#params[:controller]`.
  #
  # @return [Symbol]                    The controller used for searching.
  # @return [nil]                       If searching should not be enabled.
  #
  def search_type(type = nil)
    (type || request_parameters[:controller])&.to_sym
  end

  # A form used to create/modify a search.
  #
  # If currently searching for the indicated *type*, then the current URL
  # parameters are included as hidden fields so that the current search is
  # repeated but augmented with the added parameter.  Otherwise a new search is
  # assumed.
  #
  # Hidden fields are sorted by name with those before *id* included before the
  # content provided via the block, and with those whose names sort later than
  # *id* included after the content provided by the block.  This ensures that
  # the resulting search URL will be generated with parameters in a consistent
  # order.
  #
  # @param [Symbol, String] id
  # @param [Symbol, String] type
  # @param [Hash]           opt       Passed to #form_tag.
  #
  # @yield Supplies additional field(s) for the <form>.
  # @yieldreturn [String, Array<String>]
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If search is not available for *type*.
  #
  def search_form(id, type, **opt)
    return if (path = search_target(type)).blank?
    opt[:method] ||= :get
    before, after =
      if path == request.path
        hidden_fields = url_parameters.except(id, :offset, :start).sort
        hidden_fields.partition { |k, _| k.to_s <= id.to_s }.each do |hidden|
          hidden.map! { |k, v| hidden_field_tag(k, v, id: "#{id}-#{k}") }
        end
      end
    form_tag(path, opt) do
      [*before, *yield, *after].join("\n").html_safe
    end
  end

  # The target path for searches from the search bar.
  #
  # @param [Symbol, String] type
  # @param [Hash]           opt       Passed to #url_for.
  #
  # @return [String]
  #
  def search_target(type, **opt)
    url_for(opt.merge(controller: "/#{type}", action: :index, only_path: true))
  rescue ActionController::UrlGenerationError
    search_target(:title, **opt)
  end

end

__loading_end(__FILE__)
