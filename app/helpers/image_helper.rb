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

  # ===========================================================================
  # :section: Images
  # ===========================================================================

  public

  # Create an HTML image element.
  #
  # @param [String]      url
  # @param [String, nil] css_class
  # @param [Hash, nil]   opt              See #content_tag
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *url* is invalid.
  #
  def image_element(url, css_class = nil, **opt)
    return if url.blank?
    image = ASYNCHRONOUS_IMAGES ? placeholder(url) : image_tag(url)
    opt   = append_css_classes(opt, css_class)
    content_tag(:div, image, opt)
  end

  # Placeholder image.
  #
  # @param [String]      url
  # @param [String, nil] image        Default: 'loading-balls.gif'
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def placeholder(url, image = nil)
    image ||= asset_path('loading-balls.gif')
    html_data = { path: url, turbolinks_track: false }
    image_tag(image, class: 'placeholder', data: html_data)
  end

end

__loading_end(__FILE__)
