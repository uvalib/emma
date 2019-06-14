# app/helpers/resource_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting controllers that manipulate specific types of items.
#
module ResourceHelper

  def self.included(base)
    __included(base, '[ResourceHelper]')
  end

  # Separator for a list formed by HTML elements.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  DEFAULT_ELEMENT_SEPARATOR = "\n".html_safe.freeze

  # Separator for a list formed by text phrases.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  DEFAULT_LIST_SEPARATOR = "<br/>\n".html_safe.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a link to the details show page for the given item.
  #
  # @param [Object]              item
  # @param [Symbol, String, nil] label    Default: `item.label`.
  # @param [Proc, String, nil]   path     From block if not provided here.
  # @param [Hash, nil]           opt
  #
  # @option opt [Boolean]       :no_link
  # @option opt [String]        :tooltip
  # @option opt [Symbol,String] :label
  # @option opt [Symbol,String] :path
  #
  # @yield [path]
  # @yieldparam  [String] terms
  # @yieldreturn [String] path
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def item_link(item, label = nil, path = nil, **opt)
    keys  = %i[no_link tooltip label path]
    local = opt.slice(*keys)
    opt   = opt.except(*keys)
    label = local[:label] || label || :label
    label = item.send(label) if label.is_a?(Symbol)
    if local[:no_link]
      content_tag(:span, label, opt)
    else
      path = yield(label)           if block_given?
      path = local[:path]           if local[:path]
      path = path.call(item, label) if path.is_a?(Proc)
      opt[:title] ||= local[:tooltip] || default_show_tooltip
      link_to(label, path, opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Field/value pairs.
  #
  # If *label_value_pairs* is not provided (as a parameter or through a block)
  # then `item#fields` is used.
  #
  # @param [Api::Record::Base] item
  # @param [Hash, nil]         label_value_pairs
  #
  # @yield [item]
  # @yieldreturn [Hash]                   The value for *label_value_pairs*.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def field_values(item, label_value_pairs = nil)
    label_value_pairs ||=
      block_given? && yield(item) || item.fields.map { |f| [f, f] }.to_h
    label_value_pairs.map { |k, v|
      case v
        when :authors     then v = author_links(item)
        when :categories  then v = category_links(item)
        when :composers   then v = composer_links(item)
        when :countries   then v = country_links(item)
        when :cover       then v = cover_image(item)
        when :cover_image then v = cover_image(item)
        when :format      then v = format_links(item)
        when :formats     then v = format_links(item)
        when :languages   then v = language_links(item)
        when :numImages   then v = item.image_count
        when :numPages    then v = item.page_count
        when :thumbnail   then v = thumbnail(item)
        when Symbol       then v = item.respond_to?(v) && item.send(v)
      end
      field_value(k, v)
    }.compact.join("\n").html_safe
  end

  # Field/value pair.
  #
  # @param [String, Symbol]        label
  # @param [String, Array<String>] value
  # @param [String, nil]           separator    Def.: #DEFAULT_LIST_SEPARATOR
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # == Usage Notes
  # If *label* is HTML then no ".field-???" class is included for the ".label"
  # and ".value" elements.
  #
  def field_value(label, value, separator: DEFAULT_LIST_SEPARATOR)
    return if value.blank? || false?(value)
    type =
      unless label.is_a?(ActiveSupport::SafeBuffer)
        "field-#{label || 'None'}"
      end
    label = content_tag(:div, label.to_s, class: "label #{type}")
    value = safe_join(value, separator) + separator if value.is_a?(Array)
    value = content_tag(:div, value, class: "value #{type}")
    label << value
  end

  # An indicator that can be used to stand for an empty list.
  #
  # @param [String, nil] message
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def empty_field_value(message = 'NONE FOUND') # TODO: I18n
    field_value(nil, message)
  end

end

__loading_end(__FILE__)
