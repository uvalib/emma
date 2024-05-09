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
  # :section: Control icons
  # ===========================================================================

  public

  # Valid properties for entries under #ICONS.
  #
  # * :icon        [String]             Unicode character.
  # * :spoken      [String]             Textual description of the character.
  # * :tooltip     [String]             Tooltip on hover.
  # * :path        [String,Symbol,Proc] Activation action (see below).
  # * :auto        [Boolean]            If *true* authorization is not checked.
  # * :enabled     [Boolean, Proc]      If *false* do not show.
  # * :visible     [Boolean, Proc]      If *false* make opaque.
  # * :if_enabled  [Hash]               Only "emma.bulk.grid.icons"
  # * :if_disabled [Hash]               Only "emma.bulk.grid.icons"
  #
  ICON_PROPERTIES = %i[
    icon
    spoken
    tooltip
    path
    auto
    enabled
    visible
    if_enabled
    if_disabled
  ].freeze

  # Control icon definitions.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  # @see BaseDecorator::Controls#ICON_PROPERTIES
  #
  ICONS = config_section('emma.control_icons').deep_freeze

  # The name of the attribute indicating the action of a control button.
  #
  # @type [Symbol]
  #
  ACTION_ATTR = :'data-action'

  # ===========================================================================
  # :section: Control icons
  # ===========================================================================

  public

  # Icon definitions relative to the decorator subclass.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def icon_definitions
    ICONS
  end

  # The configuration entry for the named icon.
  #
  # @param [Symbol,String,nil] action #icon_definitions key.
  #
  # @return [Hash]                    Empty if *action* not found.
  #
  def icon_definition(action)
    icon_definitions[action&.to_sym] || {}
  end

  # Control icon definitions.
  #
  # @param [Boolean] authorized       If *true* show all enabled icons.
  #
  # @return [Hash{Symbol=>Hash}]
  #
  # @see #icon_definitions
  #
  def control_icons(authorized: false)
    icon_definitions.map { |action, prop|
      allowed = authorized || true?(prop[:auto]) || can?(action, object)
      enabled = allowed && prop[:enabled]
      prop    = prop.merge(auto: true, enabled: enabled)
      [action, prop]
    }.to_h
  end

  # Generate an element with icon controls for the operation(s) the user is
  # authorized to perform on the item.
  #
  # @param [Array, Symbol, nil] except
  # @param [String]             css     Characteristic CSS class/selector.
  # @param [Hash]               opt     Passed to #control_icon_button
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML element.
  # @return [nil]                         If no operations are authorized.
  #
  # @see #control_icons
  #
  def control_icon_buttons(except: nil, css: '.icon-tray', **opt)
    return if blank?
    trace_attrs!(opt)
    icons =
      control_icons.except(*except).map { |action, prop|
        control_icon_button(action, **prop.merge(opt))
      }.compact.presence or return
    t_opt = trace_attrs_from(opt)
    outer = prepend_css!(t_opt, css)
    html_div(icons, **outer)
  end

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
    prop    = opt.extract!(*ICON_PROPERTIES)
    allowed = true?(prop[:auto]) || can?(action, object)
    enabled = check_setting(prop[:enabled])
    return unless (allowed && enabled) || prop.key?(:visible)

    case (path = prop[:path])
      when Symbol then # deferred
      when Proc   then path = path.call(object)
      else             path ||= path_for(object, action: action)
    end
    return if path.blank?

    uniq_opt = { index: index, unique: unique }.compact
    opt[:id] = unique_id(*opt[:id], **uniq_opt) if uniq_opt.present?

    if opt[:title].blank? && (tip = prop[:tooltip]).present?
      tip = interpolate!(tip, item: model_type) || tip.dup
      tip = "#{tip} #{index.next}" if index && tip.sub!(' this ', ' ')
      opt[:title] = tip
    end

    opt[ACTION_ATTR] ||= action

    return yield(path, opt) if block_given?

    icon    = prop[:icon] || DEFAULT_ICON
    icon    = symbol_icon(icon)
    visible = check_setting(prop[:visible])

    append_css!(opt, 'invisible') unless allowed && visible
    prepend_css!(opt, css, action)
    trace_attrs!(opt)
    # noinspection RubyMismatchedArgumentType
    case path
      when :button then html_button(icon, **opt)
      else              make_link(path, icon, **opt)
    end
  end

  # Make a Unicode character (sequence) into a decorative element that is not
  # pronounced by screen readers.
  #
  # @param [any, nil] icon            Unicode character or #ICON key.
  # @param [Hash]     opt             Passed to HtmlHelper#symbol_icon.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def symbol_icon(icon, **opt)
    trace_attrs!(opt)
    icon = icon_definition(icon)[:icon] if icon.is_a?(Symbol)
    super
  end

  # ===========================================================================
  # :section: Control groups
  # ===========================================================================

  public

  # Wrapper for a group of one or more focusables.
  #
  # @param [String, nil] id
  # @param [String]      css          Characteristic CSS class/selector.
  # @param [Hash]        opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def control_group(id = nil, css: '.control-group', **opt, &blk)
    opt[:'aria-labelledby'] = id if id
    opt[:role] ||= 'group'
    prepend_css!(opt, css)
    trace_attrs!(opt)
    html_div(**opt, &blk)
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
