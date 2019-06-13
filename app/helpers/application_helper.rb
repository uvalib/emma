# app/helpers/application_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common helper methods.
#
module ApplicationHelper

  def self.included(base)
    __included(base, '[ApplicationHelper]')
  end

  include Emma::Constants
  include ParamsHelper

  # The name of this application for display purposes.
  #
  # @type [String]
  #
  APP_NAME = I18n.t('emma.application.name')

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
  # :section:
  # ===========================================================================

  public

  # The name of this application for display purposes.
  #
  # @return [String]
  #
  def app_name
    APP_NAME
  end

  # Indicate whether the ultimate target format is HTML.
  #
  # @param [Hash, nil] opt
  #
  def rendering_html?(opt)
    ((opt[:format].to_s.downcase == 'html') if opt.is_a?(Hash)) ||
      (request.format.html? if defined?(request))
  end

  # Indicate whether the ultimate target format is something other than HTML.
  #
  # @param [Hash, nil] opt
  #
  def rendering_non_html?(opt)
    !rendering_html?(opt)
  end

  # Indicate whether the ultimate target format is JSON.
  #
  # @param [Hash, nil] opt
  #
  def rendering_json?(opt)
    ((opt[:format].to_s.downcase == 'json') if opt.is_a?(Hash)) ||
      (request.format.json? if defined?(request))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Combine arrays and space-delimited strings to produce a space-delimited
  # string of CSS class names for use inline.
  #
  # @param [Array<String, Array>] args
  #
  # @yield [Array<String>]
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def css_classes(*args)
    yield(args) if block_given?
    args.flat_map { |a|
      a.is_a?(Array) ? a : a.to_s.squish.split(' ') if a.present?
    }.compact.uniq.join(' ').html_safe
  end

  # ===========================================================================
  # :section: Links
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
    label = I18n.t('emma.home.dashboard.label')
    path  = dashboard_path
    links <<
      if path == current_path
        content_tag(:span, label, class: 'active disabled')
      elsif !current_user
        content_tag(:span, label, class: 'disabled')
      elsif path == current_base_path
        link_to(label, path, class: 'active')
      else
        link_to(label, path)
      end

    # Entries for the main page of each controller.
    links +=
      %i[category title periodical member api].map do |controller|
        label = I18n.t("emma.#{controller}.label")
        path  = send("#{controller}_index_path")
        if path == current_path
          content_tag(:span, label, class: 'active disabled')
        elsif path == current_base_path
          link_to(label, path, class: 'active')
        else
          link_to(label, path)
        end
      end

    # Element containing links.
    content_tag(:div, class: 'links') do
      separator = content_tag(:span, '|', class: 'separator')
      safe_join(links, separator).html_safe
    end

  end

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
    opt   = opt.merge(class: css_classes(opt[:class], css_class)) if css_class
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
