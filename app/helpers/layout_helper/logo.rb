# app/helpers/layout_helper/logo.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for the '<header>' logo.
#
module LayoutHelper::Logo

  include LayoutHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Configuration for logo properties.
  #
  # @type [Hash{Symbol=>*}]
  #
  LOGO_CONFIG = I18n.t('emma.logo', default: {}).deep_freeze

  # Text logo.
  #
  # @type [String]
  #
  LOGO_TEXT = LOGO_CONFIG.dig(:text, :label)

  # Logo image relative asset path.
  #
  # @type [String]
  #
  LOGO_ASSET = LOGO_CONFIG.dig(:image, :asset)

  # Logo image alt text.
  #
  # @type [String]
  #
  LOGO_ALT_TEXT = LOGO_CONFIG.dig(:image, :alt)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The application tagline.
  #
  # @return [String]
  #
  def logo_tagline
    ApplicationHelper::APP_CONFIG[:tagline]
  end

  # The application logo.
  #
  # @param [Symbol] mode              Either :text or :image; default: :image.
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to outer #html_div except for:
  #
  # @option opt [String] :alt         Passed to #image_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def logo_element(mode: :image, css: '.logo', **opt)
    tip = opt.delete(:title) || LOGO_CONFIG.dig(:link, :label)
    alt = opt.delete(:alt)   || tip
    opt[:'data-turbolinks-permanent'] = true
    prepend_css!(opt, css)
    html_div(opt) do
      link_to(root_path, title: tip, 'aria-label': tip) do
        if mode == :text
          LOGO_TEXT
        else
          image_tag(asset_path(LOGO_ASSET), alt: alt)
        end
      end
    end
  end

end

__loading_end(__FILE__)
