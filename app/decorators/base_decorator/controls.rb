# app/decorators/base_decorator/controls.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common methods supporting display of Model instances (both database items and
# API messages).
#
module BaseDecorator::Controls

  include BaseDecorator::Common
  include BaseDecorator::Configuration
  include BaseDecorator::Links

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Valid properties for entries under #ICONS.
  #
  # * :icon     [String]                Unicode character.
  # * :tooltip  [String]                Tooltip on hover.
  # * :path     [String, Symbol, Proc]  Activation action (see below).
  # * :auto     [Boolean]               If *true* authorization is not checked.
  # * :active   [Boolean, Proc]         If *false* do not show.
  # * :enabled  [Hash]                  Overrides if active.
  # * :disabled [Hash]                  Overrides if not active.
  #
  ICON_PROPERTIES = %i[icon tooltip path auto active enabled disabled].freeze

  # Control icon definitions.
  #
  # @type [Hash{Symbol=>Hash{Symbol=>*}}]
  #
  # @see BaseDecorator::Controls#ICON_PROPERTIES
  #
  ICONS = I18n.t('emma.control_icons', default: {}).deep_freeze

  # The name of the attribute indicating the action of a control button.
  #
  # @type [Symbol]
  #
  ACTION_ATTR = :'data-action'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Icon definitions relative to the decorator subclass.
  #
  # @return [Hash{Symbol=>Hash{Symbol=>*}}]
  #
  def icon_definitions
    ICONS
  end

  # Control icon definitions.
  #
  # @param [Hash{Symbol=>Hash{Symbol=>*}}] icons
  # @param [Boolean, Array<Symbol>]        authorized
  #
  # @return [Hash{Symbol=>Hash{Symbol=>*}}]
  #
  def control_icons(icons: icon_definitions, authorized: false)
    if authorized.blank?
      icons.select { |act_on, prop| prop[:auto] || can?(act_on, object) }
    elsif authorized.is_a?(Array)
      icons.slice(*authorized)
    else
      icons
    end
  end

  # Generate an element with icon controls for the operation(s) the user is
  # authorized to perform on the item.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #control_icon_button
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If no operations are authorized.
  #
  # @see #control_icons
  #
  def control_icon_buttons(css: '.icon-tray', **opt)
    return if blank?
    icons =
      control_icons.map { |operation, properties|
        action_opt = properties.merge(opt)
        control_icon_button(operation, **action_opt)
      }.compact
    html_div(icons, class: css_classes(css)) if icons.present?
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  protected

  # Produce an action icon based on either :path or :id.
  #
  # If :path is :button then the generated item is a button (which is expected
  # to be handled client-side.)
  #
  # @param [Symbol]             action    One of #icon_definitions.keys.
  # @param [GridIndex, Integer] index
  # @param [String]             unique
  # @param [String]             css       Characteristic CSS class/selector.
  # @param [Hash]               opt       To LinkHelper#make_link except for
  #                                         #ICON_PROPERTIES.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML link element.
  # @return [nil]                         If *item* unrelated to a submission.
  #
  def control_icon_button(action, index: nil, unique: nil, css: '.icon', **opt)
    prop = extract_hash!(opt, *ICON_PROPERTIES)
    case (active = prop[:active])
      when nil         then # Enabled if not specified otherwise.
      when true, false then return unless active
      when Proc        then return unless active.call(object)
      else                  return unless true?(active)
    end
    case (path = prop[:path])
      when Symbol then # deferred
      when Proc   then path = path.call(object)
      else             path ||= path_for(object, action: action)
    end
    return if path.blank?

    uniq_opt = { index: index, unique: unique }.compact
    opt[:id] = unique_id(*opt[:id], **uniq_opt) if uniq_opt.present?

    if opt[:title].blank? && (tip = prop[:tooltip]).present?
      tip = tip.include?('%') ? (tip % { item: model_type }) : tip.dup
      tip = "#{tip} #{index.next}" if index && tip.sub!(' this ', ' ')
      opt[:title] = tip
    end

    opt[ACTION_ATTR] ||= action

    return yield(path, opt) if block_given?

    icon = prop[:icon] || BLACK_STAR
    icon = symbol_icon(icon)

    prepend_css!(opt, css, action)
    if path == :button
      html_button(icon, **opt)
    else
      # noinspection RubyMismatchedArgumentType
      make_link(icon, path, **opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a link to the details show page for the given item.
  #
  # @param [Hash] opt                 Passed to #icon_control
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def show_control(**opt)
    icon_control(:show, **opt)
  end

  # Create a link to the edit page for the given item.
  #
  # @param [Hash] opt                 Passed to #icon_control
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def edit_control(**opt)
    icon_control(:edit, **opt)
  end

  # Create a link to remove the given item.
  #
  # @param [Hash] opt                 Passed to #icon_control
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def delete_control(**opt)
    icon_control(:delete, **opt)
  end

  # Make a Unicode character (sequence) into a decorative element that is not
  # pronounced by screen readers.
  #
  # @param [String|Symbol] icon       Unicode character or #ICON key.
  # @param [String]        css        Characteristic CSS class/selector.
  # @param [Hash]          opt        Passed to #html_span.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def symbol_icon(icon, css: '.symbol', **opt)
    icon = icon_definitions.dig(icon, :icon) if icon.is_a?(Symbol)
    opt[:'aria-hidden'] = true unless opt.key?(:'aria-hidden')
    prepend_css!(opt, css)
    html_span(icon, opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Create an icon button link.
  #
  # @param [Symbol] type
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #button_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def icon_control(type, css: '.icon', **opt)
    opt[:path]         ||= send("#{type}_path")
    opt[:label]        ||= symbol_icon(type)
    opt[:'aria-label'] ||= type.to_s.capitalize # TODO: I18n
    button_link(css: css, **opt)
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
