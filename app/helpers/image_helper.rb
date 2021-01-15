# app/helpers/image_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# ImageHelper
#
module ImageHelper

  def self.included(base)
    __included(base, '[ImageHelper]')
  end

  include Emma::Common
  include HtmlHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # If this value is true, a placeholder image will be displayed initially and
  # client-side JavaScript will be responsible for replacing fetching the image
  # asynchronously via "/api/image".
  #
  # @type [Boolean]
  #
  ASYNCHRONOUS_IMAGES = !Rails.env.test?

  # Asynchronous image placeholder image relative asset path.
  #
  # @type [String]
  #
  PLACEHOLDER_IMAGE_ASSET = I18n.t('emma.placeholder.image.asset').freeze

  # Asynchronous image placeholder image CSS class.
  #
  # @type [String]
  #
  PLACEHOLDER_IMAGE_CLASS = 'placeholder'

  # Asynchronous image placeholder image alt text.
  #
  # @type [String]
  #
  # == Implementation Notes
  # This is defined as an empty string because display of the alt text by the
  # (for the brief time that the placeholder image might be unavailable) is
  # disruptive to the entire display layout.
  #
  PLACEHOLDER_IMAGE_ALT = ''

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
  # @param [Hash]         opt         Passed to #html_div except for:
  #
  # @option opt [String] :link        If *true* make the image a link to
  #                                     the given path.
  # @option opt [String] :alt         Passed to #image_tag.
  #
  # @return [ActiveSupport::SafeBuffer]   HTML image or placeholder.
  # @return [nil]                         If *url* is invalid.
  #
  def image_element(url, link: nil, alt: nil, row: nil, **opt)
    return if url.blank?
    alt ||= 'Illustration' # TODO: I18n
    image =
      if ASYNCHRONOUS_IMAGES
        image_placeholder(url, alt: alt)
      else
        image_tag(url, alt: alt)
      end
    row = positive(row)
    append_css_classes!(opt, "row-#{row}") if row
    if link.present?
      opt, link_opt = partition_options(opt, :class, :style)
      opt[:'aria-hidden'] ||= true
      link_opt[:tabindex] ||= -1
      # noinspection RubyYardParamTypeMatch
      image = make_link(image, link, **link_opt)
    end
    html_div(image, opt)
  end

  # Placeholder image.
  #
  # If :alt text is provided in *opt* it is preserved as 'data-alt'.
  #
  # @param [String]      url
  # @param [String, nil] image        Default: 'loading-balls.gif'
  # @param [Hash]        opt          Passed to #image_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def image_placeholder(url, image: nil, **opt)
    prepend_css_classes!(opt, PLACEHOLDER_IMAGE_CLASS)
    data = { path: url, 'turbolinks-track': false }
    data[:alt] = opt[:alt] if opt[:alt]
    opt[:data] = opt[:data]&.merge(data) || data
    opt[:alt]  = PLACEHOLDER_IMAGE_ALT
    image ||= asset_path(PLACEHOLDER_IMAGE_ASSET)
    # noinspection RubyYardReturnMatch
    image_tag(image, opt)
  end

end

__loading_end(__FILE__)
