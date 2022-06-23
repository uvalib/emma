# app/decorators/base_decorator/links.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common methods supporting display of Model instances (both database items and
# API messages).
#
module BaseDecorator::Links

  include Emma::Unicode

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include BaseDecorator::InstanceMethods
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Separator for a list formed by HTML elements.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  DEFAULT_ELEMENT_SEPARATOR = "\n".html_safe.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @type [Array<Symbol>]
  MODEL_LINK_OPTIONS =
    %i[label no_link path path_method tooltip scope controller].freeze

  # Create a link to the details show page for the given model instance.
  #
  # @param [Model, nil] item          Default: `#object`.
  # @param [Hash]       opt           Passed to LinkHelper#make_link except:
  #
  # @option opt [Boolean]        :no_link       If *true*, create a *span*.
  # @option opt [String]         :tooltip
  # @option opt [String, Symbol] :label         Default: `item.label`.
  # @option opt [String, Proc]   :path          Default: from block.
  # @option opt [Symbol]         :path_method
  # @option opt [String, Symbol] :scope
  # @option opt [String, Symbol] :controller
  #
  # @return [ActiveSupport::SafeBuffer]   HTML link or text element.
  #
  # @yield [terms] To supply a path based on *terms* to use instead of *path*.
  # @yieldparam  [String] terms
  # @yieldreturn [String]
  #
  def model_link(item, **opt)
    html_opt = remainder_hash!(opt, *MODEL_LINK_OPTIONS)
    type     = (model_type unless item)
    item   ||= object
    label    = opt[:label] || :label
    label    = item.send(label) if label.is_a?(Symbol)
    if opt[:no_link]
      html_span(label, html_opt)
    else
      # noinspection RubyMismatchedArgumentType
      path = (yield(label) if block_given?) || opt[:path] || opt[:path_method]
      path = path.call(item, label) if path.is_a?(Proc)
      html_opt[:title] ||= opt[:tooltip]
      html_opt[:title] ||=
        if (type ||= opt[:scope] || opt[:controller] || Model.for(item))
          I18n.t("emma.#{type}.show.tooltip", default: '')
        end
      # noinspection RubyMismatchedArgumentType
      make_link(label, path, **html_opt)
    end
  end

  # Create a link to the details show page for the given model instance.
  #
  # @param [String, nil] css          Optional CSS class(es) to include.
  # @param [Hash]        opt          Passed to #model_link.
  #
  # @return [ActiveSupport::SafeBuffer]   HTML link or text element.
  #
  def link(css: nil, **opt)
    opt[:tooltip] = show_tooltip unless opt.key?(:tooltip)
    prepend_css!(opt, css) if css.present?
    model_link(object, **opt)
  end

  # Create a link to the details show page for the given model instance.
  #
  # @param [Hash] opt                 Passed to #link
  #
  # @return [ActiveSupport::SafeBuffer]   HTML link or text element.
  #
  def button_link(**opt)
    opt[:css]  ||= '.button'
    opt[:role] ||= 'button'
    link(**opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # TODO: I18n
  #
  # @type [String]
  #
  ANOTHER = 'another'

  # List controller actions.  If the current action is provided, the associated
  # action link will be appear at the top of the list.
  #
  # @param [String, Symbol, nil]     current      Def: `context[:action]`
  # @param [Hash{Symbol=>Hash}, nil] table        Def: `#action_links`.
  # @param [Hash]                    opt          Passed to #action_links.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def action_list(current: nil, table: nil, **opt)
    css = '.page-actions'
    current ||= context[:action]
    table   ||= action_links(**opt)
    html_tag(:ul, prepend_css(css)) do
      link_opt = { current: current, table: table }
      # noinspection RubyNilAnalysis, RubyMismatchedReturnType
      links = table.keys.map { |action| action_link(action, **link_opt) }
      first = links.index { |link| link.include?(ANOTHER) }
      first ? [links.delete_at(first), *links] : links
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # action_entry
  #
  # @param [String, Symbol, nil]     action   The target controller action.
  # @param [String, Symbol, nil]     current  Def: current `params[:action]`.
  # @param [Hash{Symbol=>Hash}, nil] table    Def: `#action_links`.
  # @param [Hash]                    opt      Passed to #action_links.
  #
  # @return [Hash{Symbol=>String}]
  #
  def action_entry(action = nil, current: nil, table: nil, **opt)
    current = (opt.delete(:current) || current || context[:action])&.to_sym
    action  = (opt.delete(:action)  || action  || current)&.to_sym
    table ||= action_links(**opt)
    entry   = table[action]
    return {} if entry.blank?
    (action == current) ? entry.merge(article: ANOTHER) : entry.dup
  end

  # action_link
  #
  # @param [String, Symbol, nil] action   The target controller action.
  # @param [String, Symbol, nil] current  Def: current `params[:action]`.
  # @param [String, nil]         label    Override configured label.
  # @param [Hash]                opt      Passed to #action_entry.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML link element.
  # @return [nil]                         If *action* not configured.
  #
  def action_link(action = nil, current: nil, label: nil, **opt)
    css     = '.page-action'
    action  = opt.delete(:action) || action
    entry   = action_entry(action, current: current, **opt)
    return if entry.blank? && path.blank?
    action  = entry[:action]
    label   = (label || entry[:label]).presence
    label &&= label % entry
    label ||= labelize(action)
    html_tag(:li, prepend_css(css)) do
      link_to_action(label, action: action)
    end
  end

  # Action links configured for the controller.
  #
  # @param [String, Symbol, nil] action   Default: :index.
  # @param [Hash]                opt      Passed to #config_lookup.
  #
  # @return [Hash]
  #
  def action_links(action: nil, **opt)
    opt[:action] = action || :index
    config_lookup('action_links', **opt) || {}
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Control icon definitions.
  #
  # @type [Hash{Symbol=>Hash{Symbol=>Any}}]
  #
  CONTROL_ICONS = {
    show: {
      icon:    STAR,
      tip:     'View this %{item}',
      enabled: false,
    },
    edit: {
      icon:    DELTA,
      tip:     'Modify this %{item}',
      enabled: false,
    },
    delete: {
      icon:    HEAVY_X,
      tip:     'Delete this %{item}',
      enabled: false,
    },
  }.deep_freeze

  # Control icon definitions.
  #
  # @param [Hash{Symbol=>Hash{Symbol=>Any}}] icons
  # @param [Boolean]                         authorized
  #
  # @return [Hash{Symbol=>Hash{Symbol=>Any}}]
  #
  def control_icons(icons: CONTROL_ICONS, authorized: true)
    if authorized
      icons.select { |act_on, _| can?(act_on, object) }
    else
      icons
    end
  end

  # Generate an element with icon controls for the operation(s) the user is
  # authorized to perform on the item.
  #
  # @param [Hash] opt                   Passed to #control_icon_button
  #
  # @return [ActiveSupport::SafeBuffer] An HTML element.
  # @return [nil]                       If no operations are authorized.
  #
  # @see #control_icons
  #
  def control_icon_buttons(**opt)
    return if blank?
    css = '.icon-tray'
    # noinspection RubyMismatchedReturnType
    icons =
      control_icons.map { |operation, properties|
        action_opt = properties.merge(opt)
        control_icon_button(operation, **action_opt)
      }.compact
    html_span(icons, class: css_classes(css)) if icons.present?
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  protected

  # Produce an action icon based on either :path or :id.
  #
  # @param [Symbol] action                One of #CONTROL_ICONS.keys.
  # @param [Hash]   opt                   To LinkHelper#make_link except for:
  #
  # @option opt [String, Proc]  :path
  # @option opt [String]        :icon
  # @option opt [String]        :tip
  # @option opt [Boolean, Proc] :enabled
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML link element.
  # @return [nil]                         If *item* unrelated to a submission.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def control_icon_button(action, **opt)
    css = '.icon'

    case (enabled = opt.delete(:enabled))
      when nil         then # Enabled if not specified otherwise.
      when true, false then return unless enabled
      when Proc        then return unless enabled.call(object)
      else                  return unless true?(enabled)
    end
    case (path = opt.delete(:path))
      when Symbol then # deferred
      when Proc   then path = path.call(object)
      else             path ||= path_for(object, action: action)
    end
    return if path.blank?

    tip  = opt.delete(:tip)
    opt[:title] ||= tip&.include?('%') && (tip % { item: model_type }) || tip
    return yield(path, opt) if block_given?

    icon = opt.delete(:icon) || STAR
    prepend_css!(opt, css, action)
    # noinspection RubyMismatchedArgumentType
    make_link(icon, path, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a link to the details show page for the given item.
  #
  # @param [Hash] opt                 Passed to #link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def show_link(**opt)
    icon_link(:show, **opt)
  end

  # Create a link to the edit page for the given item.
  #
  # @param [Hash] opt                 Passed to #icon_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def edit_link(**opt)
    icon_link(:edit, **opt)
  end

  # Create a link to remove the given item.
  #
  # @param [Hash] opt                 Passed to #icon_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def delete_link(**opt)
    icon_link(:delete, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Create an icon button link.
  #
  # @param [Hash] opt                 Passed to #button_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def icon_link(type, **opt)
    opt[:css]          ||= '.icon'
    opt[:path]         ||= send("#{type}_path")
    opt[:label]        ||= CONTROL_ICONS.dig(type.to_sym, :icon)
    opt[:'aria-label'] ||= type.to_s.capitalize # TODO: I18n
    button_link(**opt)
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
