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
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include BaseDecorator::SharedInstanceMethods # for link_to_action override
  end
  # :nocov:

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
  MODEL_LINK_OPT =
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
    trace_attrs!(opt, __method__)
    local  = opt.extract!(*MODEL_LINK_OPT)
    type   = (ctrlr_type unless item)
    item ||= object
    label  = local[:label] || :label
    label  = item.send(label) if label.is_a?(Symbol)
    if local[:no_link]
      html_span(label, **opt)
    else
      path   = (yield(label) if block_given?)
      path ||= local[:path] || local[:path_method]
      path   = path.call(item, label) if path.is_a?(Proc)
      opt[:title] ||= local[:tooltip]
      opt[:title] ||=
        if (type ||= local[:scope] || local[:controller] || Model.for(item))
          config_page(type, :show, :tooltip, fallback: '')
        end
      make_link(path, label, **opt)
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
    trace_attrs!(opt, __method__)
    prepend_css!(opt, css) if css.present?
    model_link(object, **opt)
  end

  # Create a link to the details show page for the given model instance.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt               Passed to #link
  #
  # @return [ActiveSupport::SafeBuffer]   HTML link or text element.
  #
  # @note Currently unused.
  # :nocov:
  def button_link(css: '.button', **opt)
    opt[:role] ||= 'button'
    trace_attrs!(opt, __method__)
    link(css: css, **opt)
  end
  # :nocov:

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Tooltip for the :show action for the current model.
  #
  # @return [String, nil]
  #
  def show_tooltip
    action_config(:show)&.dig(:tooltip)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  ANOTHER = config_term(:another).freeze

  # A list of controller action links.  If the current action is provided, the
  # associated action link will appear at the top of the list, except for
  # :edit_select and :delete_select where it is not displayed at all (since
  # the link is redundant).
  #
  # @param [String, Symbol, nil]     current      Def: `context[:action]`
  # @param [Hash{Symbol=>Hash}, nil] table        Def: `#action_links`.
  # @param [Symbol, nil]             tag
  # @param [String]                  css          Characteristic CSS selector.
  # @param [Hash]                    opt          Passed to #action_links.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def action_list(
    current:  nil,
    table:    nil,
    tag:      :ul,
    css:      '.page-actions',
    **opt
  )
    trace_attrs!(opt, __method__)
    t_opt     = trace_attrs_from(opt)
    current ||= context[:action]
    table   ||= action_links(**opt)

    l_opt = { current: current, table: table, **t_opt }
    l_opt.merge!(tag: tag) if tag.nil?
    links = table.keys.map { action_link(_1, **l_opt) }.compact

    # Move the link referencing the current action to the top of the list.
    # E.g.: On an :edit page, the "Edit another..." link is moved to the top.
    first   = links.index { _1.include?(ANOTHER) }
    first &&= links.delete_at(first)
    links.prepend(first) if first && !menu_action?(current)

    html_tag(tag, *links, **prepend_css(t_opt, css)) if links.present?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # The URL link for an entry in a list of controller actions.
  #
  # @param [String, Symbol, nil] action   The target controller action.
  # @param [String, Symbol, nil] current  Def: current `params[:action]`.
  # @param [String, nil]         label    Override configured label.
  # @param [Symbol, nil]         tag
  # @param [String]              css      Characteristic CSS class/selector.
  # @param [Hash]                opt      Passed to #action_entry.
  #
  # @option opt [String] :action          Overrides argument if present.
  #
  # @return [ActiveSupport::SafeBuffer]   An HTML link element.
  # @return [nil]                         If *action* not configured.
  #
  def action_link(
    action =  nil,
    current:  nil,
    label:    nil,
    tag:      :li,
    css:      '.page-action',
    **opt
  )
    trace_attrs!(opt, __method__)
    t_opt  = trace_attrs_from(opt)
    action = opt.delete(:action) || action
    entry  = action_entry(action, current: current, **opt)
    action, current = entry.values_at(:action, :current)

    return if (action == current) && current&.start_with?('list_')
    return unless can?(action, object_class)

    label  = (label || entry[:label]).presence
    label  = label ? (label % entry) : labelize(action)

    html_tag(tag, **prepend_css(t_opt, css)) do
      link_to_action(label, action: action, **t_opt)
    end
  end

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
    trace_attrs!(opt, __method__)
    current = (opt.delete(:current) || current || context[:action])&.to_sym
    action  = (opt.delete(:action)  || action  || current)&.to_sym
    table ||= action_links(**opt)
    table[action]&.dup&.tap do |entry|
      if base_action(action) == base_action(current)
        entry[:an] = ANOTHER
      elsif entry[:an].nil?
        entry[:an] = indefinite_article(opt[:label] || entry[:label])
      end
      entry[:current]  = current
      entry[:action] ||= action
    end || {}
  end

  # Action links configured for the controller, limited to those which are
  # appropriate for the current user.
  #
  # @param [String, Symbol, nil] action   Default: :index.
  # @param [Hash]                opt      Passed to #config_lookup.
  #
  # @return [Hash]
  #
  def action_links(action: nil, **opt)
    opt[:action] = action || :index
    links = config_lookup('action_links', **opt)
    links&.select { |_, prop| user_has_role?(prop[:role]) } || {}
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
