# app/helpers/layout_helper/logo.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# LayoutHelper::Logo
#
module LayoutHelper::Logo

  include LayoutHelper::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Text logo.
  #
  # @type [String]
  #
  #--
  # noinspection RailsI18nInspection
  #++
  LOGO_TEXT =
    I18n.t('emma.logo.text.label', default: ApplicationHelper::APP_NAME).freeze

  # Logo image relative asset path.
  #
  # @type [String]
  #
  LOGO_ASSET = I18n.t('emma.logo.image.asset').freeze

  # Logo image alt text.
  #
  # @type [String]
  #
  LOGO_ALT_TEXT = I18n.t('emma.logo.image.alt').freeze

  # Logo tagline.
  #
  # @type [String]
  #
  LOGO_TAGLINE = I18n.t('emma.application.tagline', default: '').freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The application tagline.
  #
  # @return [String]
  #
  def logo_tagline
    LOGO_TAGLINE
  end

  # The application logo.
  #
  # @param [Symbol] mode              Either :text or :image; default: :image.
  # @param [Hash]   opt               Passed to outer #html_div except for:
  #
  # @option opt [String] :alt         Passed to #image_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def logo_element(mode: :image, **opt)
    prepend_css_classes!(opt, 'logo')
    alt = opt.delete(:alt)
    opt[:'data-turbolinks-permanent'] = true
    html_div(opt) do
      link_to(root_path, title: logo_tagline) do
        if mode == :text
          LOGO_TEXT
        else
          image = asset_path(LOGO_ASSET)
          alt ||= LOGO_ALT_TEXT
          image_tag(image, alt: alt)
        end
      end
    end
  end

end

__loading_end(__FILE__)
