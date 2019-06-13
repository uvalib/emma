# app/helpers/layout_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LayoutHelper.
#
module LayoutHelper

  def self.included(base)
    __included(base, '[LayoutHelper]')
  end

  # The controllers included on the nav bar.
  #
  # @type [Array<Symbol>]
  #
  NAV_BAR_CONTROLLERS = I18n.t('emma.nav_bar.controllers').map(&:to_sym).freeze

  # Default dashboard link label.
  #
  # @type [String]
  #
  DASHBOARD_LABEL = I18n.t('emma.home.dashboard.label').freeze

  # Default dashboard link tooltip.
  #
  # @type [String]
  #
  DASHBOARD_TOOLTIP = I18n.t('emma.home.dashboard.tooltip', default: '').freeze

  # Controller link labels.
  #
  # @type [Hash{Symbol=>String}]
  #
  CONTROLLER_LABEL =
    NAV_BAR_CONTROLLERS.map { |c|
      [c, I18n.t("emma.#{c}.label", default: c.to_s.capitalize).freeze]
    }.to_h.freeze

  # Controller link tooltips.
  #
  # @type [Hash{Symbol=>String}]
  #
  CONTROLLER_TOOLTIP =
    NAV_BAR_CONTROLLERS.map { |c|
      [c, I18n.t("emma.#{c}.tooltip", default: '').freeze]
    }.to_h.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate an element containing links for the main page of each controller.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def controller_links

    current_params = url_parameters.except(:limit)
    current_path   = current_base_path = request.path
    current_path  += '?' + current_params.to_param if current_params.present?

    links = []

    # Special entry for the dashboard/welcome screen.
    label = DASHBOARD_LABEL
    path  = dashboard_path
    opt   = { title: DASHBOARD_TOOLTIP }
    links <<
      if path == current_path
        content_tag(:span, label, opt.merge(class: 'active disabled'))
      elsif !current_user
        content_tag(:span, label, opt.merge(class: 'disabled'))
      elsif path == current_base_path
        link_to(label, path, opt.merge(class: 'active'))
      else
        link_to(label, path, opt)
      end

    # Entries for the main page of each controller.
    links +=
      NAV_BAR_CONTROLLERS.map do |controller|
        label = CONTROLLER_LABEL[controller]
        path  = send("#{controller}_index_path")
        opt   = { title: CONTROLLER_TOOLTIP[controller] }
        if path == current_path
          content_tag(:span, label, opt.merge(class: 'active disabled'))
        elsif path == current_base_path
          link_to(label, path, opt.merge(class: 'active'))
        else
          link_to(label, path, opt)
        end
      end

    # Element containing links.
    content_tag(:div, class: 'links') do
      separator = content_tag(:span, '|', class: 'separator')
      safe_join(links, separator).html_safe
    end

  end

end

__loading_end(__FILE__)
