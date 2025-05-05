# app/helpers/image_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting the display of images.
#
module ImageHelper

  include Emma::Common

  include HtmlHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # If this value is true, a placeholder image will be displayed initially and
  # client-side JavaScript will be responsible for replacing fetching the image
  # asynchronously via "/search/image".
  #
  # @type [Boolean]
  #
  ASYNCHRONOUS_IMAGES = !Rails.env.test?

  # Asynchronous image placeholder image relative asset path.
  #
  # @type [String]
  #
  IMAGE_PLACEHOLDER_ASSET =
    config_page(:image, :placeholder, :image, :asset).freeze

  # Asynchronous image placeholder image CSS class.
  #
  # @type [String]
  #
  IMAGE_PLACEHOLDER_CLASS = 'placeholder'

  # Asynchronous image placeholder image alt text.
  #
  # @type [String]
  #
  # === Implementation Notes
  # This is defined as an empty string because display of the alt text by the
  # (for the brief time that the placeholder image might be unavailable) is
  # disruptive to the entire display layout.
  #
  IMAGE_PLACEHOLDER_ALT = ''

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create an HTML image element.
  #
  # @param [String]       url
  # @param [String, nil]  link        If present, the URL to which the image
  #                                     is a link.
  # @param [String, nil]  alt         Passed to #image_tag.
  # @param [Integer, nil] row         Grid row of the element.
  # @param [Hash]         opt         Passed to #html_div except for options
  #                                     passed to #make_link if *link* given.
  #
  # @return [ActiveSupport::SafeBuffer]   HTML image or placeholder.
  # @return [nil]                         If *url* is invalid.
  #
  def image_element(url, link: nil, alt: nil, row: nil, **opt)
    return if url.blank?
    i_opt = { alt: alt || config_term(:image, :alt) }
    image =
      if ASYNCHRONOUS_IMAGES
        image_placeholder(url, **i_opt)
      else
        image_tag(url, i_opt)
      end
    if link.present?
      opt[:'aria-hidden'] = true
      l_opt = opt.slice!(:class, :style)
      image = make_link(link, image, tabindex: -1, **l_opt)
    end
    row = positive(row)
    append_css!(opt, "row-#{row}") if row
    html_div(image, **opt)
  end

  # Placeholder image.
  #
  # If :alt text is provided in *opt* it is preserved as 'data-alt', along with
  # *url* in 'data-path'.
  #
  # @param [String]      url
  # @param [String, nil] image        Default: #image_placeholder_asset.
  # @param [String]      css          Characteristic CSS class/selector.
  # @param [Hash]        opt          Passed to #image_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def image_placeholder(url, image: nil, css: IMAGE_PLACEHOLDER_CLASS, **opt)
    image    ||= image_placeholder_asset
    data       = opt.slice(:alt).merge!(path: url)
    opt[:data] = opt[:data]&.merge(data) || data
    opt[:alt]  = IMAGE_PLACEHOLDER_ALT
    prepend_css!(opt, css)
    image_tag(image, opt)
  end

  # Current path to the #IMAGE_PLACEHOLDER_ASSET.
  #
  # @return [String]
  #
  def image_placeholder_asset
    asset_path(IMAGE_PLACEHOLDER_ASSET)
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
