# app/helpers/layout_helper/nav_bar.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for the '<header>' nav bar.
#
module LayoutHelper::NavBar

  include LayoutHelper::Common

  include ParamsHelper
  include RouteHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Configuration for nav bar properties.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  NAV_BAR_CONFIG = config_section('emma.nav_bar').transform_values { |cfg|
    Array.wrap(cfg).compact.map!(&:to_sym)
  }.deep_freeze

  # The controllers included on the nav bar.
  #
  # @type [Array<Symbol>]
  #
  # === Implementation Notes
  # Should contain some or all of superset ApplicationHelper#APP_CONTROLLERS.
  #
  NAV_BAR_CONTROLLERS = NAV_BAR_CONFIG[:controllers]

  # The important nav bar entries.
  #
  # @type [Array<Symbol>]
  #
  PRIMARY_CONTROLLERS = NAV_BAR_CONFIG[:primary]

  # Nav bar primary entries that are not displayed in the production
  # deployment.
  #
  # @type [Array<Symbol>]
  #
  UNRELEASED_CONTROLLERS = NAV_BAR_CONFIG[:unreleased]

  if sanity_check?
    if (invalid = PRIMARY_CONTROLLERS - NAV_BAR_CONTROLLERS).present?
      raise "Invalid PRIMARY_CONTROLLERS: #{invalid.inspect}"
    end
    if (invalid = UNRELEASED_CONTROLLERS - PRIMARY_CONTROLLERS).present?
      raise "Invalid UNRELEASED_CONTROLLERS: #{invalid.inspect}"
    end
  end

  # Configuration for dashboard page properties.
  #
  # @type [Hash]
  #
  DASHBOARD_CONFIG = config_section('emma.home.dashboard').deep_freeze

  # Controller link labels.
  #
  # @type [Hash{Symbol=>String}]
  #
  CONTROLLER_LABEL =
    NAV_BAR_CONTROLLERS.map { |c|
      [c, config_item("emma.#{c}.label", fallback: c.to_s.camelize)]
    }.to_h.deep_freeze

  # Controller link tooltips.
  #
  # @type [Hash{Symbol=>String}]
  #
  CONTROLLER_TOOLTIP =
    NAV_BAR_CONTROLLERS.map { |c|
      [c, config_item("emma.#{c}.tooltip", fallback: '')]
    }.to_h.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether it is appropriate to show the nav bar.
  #
  def show_nav_bar?(...)
    true
  end

  # Generate an element containing links for the main page of each controller.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def nav_bar_links
    curr_path  = request.path
    base_path  = curr_path.sub(%r{^(/[^/]*)/.*$}, '\1')
    curr_prm   = url_parameters.except(:limit)
    curr_path += '?' + url_query(curr_prm) if curr_prm.present?
    html_div(class: 'links') do
      init = true
      NAV_BAR_CONTROLLERS.map do |controller|
        if controller == :home
          # Special entry for the dashboard/welcome screen.
          path   = dashboard_path
          base   = (base_path == '/account')
          label  = DASHBOARD_CONFIG[:label]
          tip    = DASHBOARD_CONFIG[:tooltip]
          hidden = !current_user
        else
          # Entry for the main page of the given controller.
          path   = get_path_for(controller)
          base   = (base_path == path)
          label  = CONTROLLER_LABEL[controller]
          tip    = CONTROLLER_TOOLTIP[controller]
          hidden =
            case controller
              when :org        then !current_user
              when :sys        then !current_user&.developer?
              when :enrollment then !current_user&.administrator?
            end
        end

        primary  = PRIMARY_CONTROLLERS
        primary -= UNRELEASED_CONTROLLERS if production_deployment?
        primary  = primary.include?(controller)

        current  = (path == curr_path)
        active   = current || base
        disabled = current

        classes = []
        classes << 'secondary' unless primary
        classes << 'active'    if active
        classes << 'disabled'  if disabled
        classes << 'hidden'    if hidden

        # The separator preceding the link.
        sep_css = %w[separator]
        sep_css << 'hidden'    if init
        separator = html_span('|', class: css_classes(*classes, *sep_css))

        # The link (inactive if already on the associated page).
        page = (config_text(:layout, :nav_bar, :current_page) if disabled)
        tip  = [*tip, "(#{page})"].compact.join("\n") if page.present?
        opt  = { class: css_classes(*classes), title: tip }
        link = disabled ? html_span(label, **opt) : link_to(label, path, opt)
        init = false unless hidden

        separator << link
      end
    end
  end

end

__loading_end(__FILE__)
