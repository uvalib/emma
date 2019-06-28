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

  include HtmlHelper

  # If this value is true, a placeholder image will be displayed initially and
  # client-side JavaScript will be responsible for replacing fetching the image
  # asynchronously via "/api/image".
  #
  # @type [Boolean]
  #
  # == Implementation Notes
  # This will be useful when caching is implemented, but for now it results in
  # too much re-fetching of images.
  #
  ASYNCHRONOUS_IMAGES = false

  # Asynchronous image placeholder image relative asset path.
  #
  # @type [String]
  #
  PLACEHOLDER_ASSET =
    I18n.t('emma.title.show.cover.placeholder.image.asset').freeze

  # Asynchronous image placeholder image alt text.
  #
  # @type [String]
  #
  PLACEHOLDER_ALT_TEXT =
    I18n.t('emma.title.show.cover.placeholder.image.alt').freeze

  # ===========================================================================
  # :section: Images
  # ===========================================================================

  public

  # Create an HTML image element.
  #
  # @param [String]    url
  # @param [Hash, nil] opt                Passed to #content_tag except for:
  #
  # @option opt [String] :link            If *true* make the image a link to
  #                                         the given path.
  # @option opt [String] :alt             Passed to #image_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *url* is invalid.
  #
  def image_element(url, **opt)
    return if url.blank?
    opt, local = extract_local_options(opt, :alt, :link)
    image =
      if ASYNCHRONOUS_IMAGES
        placeholder(url)
      else
        alt = local[:alt] || 'Placeholder' # TODO: I18n
        image_tag(url, alt: alt)
      end
    if local[:link].is_a?(String)
      link_to(image, local[:link], opt)
    else
      content_tag(:div, image, opt)
    end
  end

  # Placeholder image.
  #
  # @param [String]      url
  # @param [String, nil] image        Default: 'loading-balls.gif'
  # @param [Hash, nil]   opt          Passed to #image_tag.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def placeholder(url, image = nil, **opt)
    opt = prepend_css_classes(opt, 'placeholder')
    opt[:alt]  ||= PLACEHOLDER_ALT_TEXT
    opt[:data] ||= {}
    opt[:data].merge!(path: url, turbolinks_track: false)
    image ||= asset_path(PLACEHOLDER_ASSET)
    image_tag(image, opt)
  end

end

__loading_end(__FILE__)
