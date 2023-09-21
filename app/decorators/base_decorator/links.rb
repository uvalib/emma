# app/decorators/base_decorator/links.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common methods supporting display of Model instances (both database items and
# API messages).
#
module BaseDecorator::Links

  include BaseDecorator::Common
  include BaseDecorator::Configuration

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include BaseDecorator::SharedInstanceMethods # for link_to_action override
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
    trace_attrs!(opt)
    html_opt = remainder_hash!(opt, *MODEL_LINK_OPTIONS)
    type     = (model_type unless item)
    item   ||= object
    label    = opt[:label] || :label
    label    = item.send(label) if label.is_a?(Symbol)
    if opt[:no_link]
      html_span(label, **html_opt)
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
  # @param [String, Array, nil] css   Optional CSS class(es) to include.
  # @param [Hash]               opt   Passed to #model_link.
  #
  # @return [ActiveSupport::SafeBuffer]   HTML link or text element.
  #
  def link(css: nil, **opt)
    opt[:title] = opt.delete(:tooltip) || opt[:title] || show_tooltip
    prepend_css!(opt, css) if css.present?
    trace_attrs!(opt)
    model_link(object, **opt)
  end

  # Create a link to the details show page for the given model instance.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #link
  #
  # @return [ActiveSupport::SafeBuffer]   HTML link or text element.
  #
  def button_link(css: '.button', **opt)
    opt[:role] ||= 'button'
    trace_attrs!(opt)
    link(css: css, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # show_tooltip
  #
  # @return [String, nil]
  #
  def show_tooltip
    controller_config.dig(:show, :tooltip)
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

  # A list of controller action links.  If the current action is provided,
  # the associated action link will be appear at the top of the list, except
  # for :edit_select and :delete_select where it is not displayed at all (since
  # the link is redundant).
  #
  # @param [String, Symbol, nil]     current      Def: `context[:action]`
  # @param [Hash{Symbol=>Hash}, nil] table        Def: `#action_links`.
  # @param [String]                  css          Characteristic CSS selector.
  # @param [Hash]                    opt          Passed to #action_links.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def action_list(current: nil, table: nil, css: '.page-actions', **opt)
    trace_attrs!(opt)
    t_opt     = trace_attrs_from(opt)
    current ||= context[:action]
    table   ||= action_links(**opt)

    links =
      table.keys.map { |action|
        action_link(action, current: current, table: table, **t_opt)
      }.compact

    # Move the link referencing the current action to the top of the list.
    # E.g.: On an :edit page, the "Edit another..." link is moved to the top.
    first   = links.index { |link| link.include?(ANOTHER) }
    first &&= links.delete_at(first)
    links.prepend(first) if first && !menu_action?(current)

    html_tag(:ul, *links, **prepend_css(t_opt, css)) if links.present?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # An entry in a list of controller actions.
  #
  # @param [String, Symbol, nil]     action   The target controller action.
  # @param [String, Symbol, nil]     current  Def: current `params[:action]`.
  # @param [Hash{Symbol=>Hash}, nil] table    Def: `#action_links`.
  # @param [Hash]                    opt      Passed to #action_links.
  #
  # @return [Hash{Symbol=>String}]
  #
  def action_entry(action = nil, current: nil, table: nil, **opt)
    trace_attrs!(opt)
    current = (opt.delete(:current) || current || context[:action])&.to_sym
    action  = (opt.delete(:action)  || action  || current)&.to_sym
    table ||= action_links(**opt)
    table[action]&.dup&.tap do |entry|
      # noinspection RubyMismatchedArgumentType
      entry[:article]  = ANOTHER if base_action(action) == base_action(current)
      entry[:current]  = current
      entry[:action] ||= action
    end || {}
  end

  # The URL link for an entry in a list of controller actions.
  #
  # @param [String, Symbol, nil] action   The target controller action.
  # @param [String, Symbol, nil] current  Def: current `params[:action]`.
  # @param [String, nil]         label    Override configured label.
  # @param [String]              css      Characteristic CSS class/selector.
  # @param [Hash]                opt      Passed to #action_entry.
  #
  # @option opt [String] :action          Overrides argument if present.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML link element.
  # @return [nil]                         If *action* not configured.
  #
  def action_link(
    action = nil,
    current: nil,
    label:   nil,
    css:     '.page-action',
    **opt
  )
    trace_attrs!(opt)
    t_opt  = trace_attrs_from(opt)
    action = opt.delete(:action) || action
    entry  = action_entry(action, current: current, **opt)
    action, current = entry.values_at(:action, :current)

    return if (action == current) && current&.start_with?('list_')
    return unless can?(action, object_class)

    label  = (label || entry[:label]).presence
    label  = label ? (label % entry) : labelize(action)

    html_tag(:li, **prepend_css(t_opt, css)) do
      link_to_action(label, action: action, **t_opt)
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

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
