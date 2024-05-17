# app/decorators/base_decorator/menu.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting selectable lists of Model instances.
#
module BaseDecorator::Menu

  include BaseDecorator::Common
  include BaseDecorator::Configuration
  include BaseDecorator::Links

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a menu of database item entries.
  #
  # @param [Symbol, String, nil] action      Default: `context[:action]`
  # @param [Hash, nil]           constraints
  # @param [Boolean, nil]        secondary
  # @param [Hash, nil]           sort
  # @param [String, nil]         prompt
  # @param [Hash{Symbol=>Hash}]  table
  # @param [String, nil]         id
  # @param [String, Symbol]      name
  # @param [String, Hash]        ujs         JavaScript selection action.
  # @param [String]              css         Characteristic CSS class/selector.
  # @param [Hash]                opt         Passed to #html_form.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see RouteHelper#get_path_for
  # @see TestHelper::SystemTests::Common#item_menu_select
  #
  def items_menu(
    action:      nil,
    constraints: nil,
    secondary:   nil,
    sort:        nil,
    prompt:      nil,
    table:       nil,
    id:          nil,
    name:        'id',
    ujs:         'this.form.submit();',
    css:         '.select-entry.menu-control',
    **opt
  )
    ctrlr    = items_menu_controller
    action ||= context[:action]
    table  ||= action_links

    action   = action&.to_sym
    # noinspection RubyMismatchedArgumentType
    action   = action && table.dig(action, :action) || action
    path     = h.get_path_for(ctrlr, action)
    model    = object_class

    raise "model: expected Class; got #{model.class}" unless model.is_a?(Class)
    raise "invalid model #{model.inspect}" unless model < ApplicationRecord
    raise "no path for #{ctrlr}/#{action}" unless path

    id     ||= unique_id(name)
    l_opt    = { for: id, class: 'sr-only' }
    label    = h.label_tag(name, prompt, l_opt)
    prompt ||= items_menu_prompt

    sort  = sort.dup         if sort.is_a?(Hash)
    sort  = {}               if sort.nil?
    sort  = { sort => :asc } unless sort.is_a?(Hash)
    sort.merge!(created_at: :desc)
    cons  = constraints || {}
    pairs = model.pairs(sort: sort, **cons) { |r| [items_menu_label(r), r.id] }
    pairs = h.options_for_select(pairs)

    ujs   = { onchange: ujs } unless ujs.is_a?(Hash)
    s_opt = { id: id, name: name, prompt: prompt, **ujs }
    s_opt.merge!(class: 'advanced single')
    s_opt.merge!('data-secondary': true) if secondary
    menu  = h.select_tag(name, pairs, s_opt)

    opt[:method] ||= :get
    prepend_css!(opt, css)
    trace_attrs!(opt)
    html_form(path.delete_suffix(SELECT_ACTION_SUFFIX), **opt) do
      label << menu
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # @private
  ITEM_PROMPT = config_text(:menu, :item_prompt).freeze

  # The name of the controller used in generating link paths.
  #
  # @return [Symbol]
  #
  def items_menu_controller
    controller_config_key
  end

  # Generate a prompt for #items_menu.
  #
  # @param [Hash] opt
  #
  # @return [String]
  #
  def items_menu_prompt(**opt)
    opt[:item] ||= model_item_name(capitalize: false)
    opt[:an]   ||= indefinite_article(opt[:item])
    interpolate(ITEM_PROMPT, **opt)
  end

  # Generate a label for a specific menu entry.
  #
  # @param [Model]       item
  # @param [String, nil] label        Override label.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def items_menu_label(item, label: nil)
    label ||= item.menu_label
    label ||= "#{model_item_name(capitalize: true)} #{item.id}"
    ERB::Util.h(label)
  end

  # Descriptive term for an item of the given type.
  #
  # @param [Symbol, String, nil] model        Default: `#model_type`.
  # @param [Boolean]             capitalize
  #
  # @return [String]
  #
  def model_item_name(model: nil, capitalize: true)
    (model || model_type).to_s.humanize(capitalize: capitalize)
  end

  # Update `opt[:constraints]` based on the role of the user.
  #
  # @param [Hash] opt
  #
  # @return [Hash]                    The possibly-modified *opt* argument.
  #
  def items_menu_role_constraints!(opt)
    cons = opt[:constraints]
    user = org = nil

    if !administrator? && !manager?
      # Normal user constrained by organization.
      cons = cons&.except(:org, :org_id) || {}
      user = cons.extract!(:user, :user_id).compact.values.first
      org  = current_user.org_id
      org  = nil if user && (User.uid(user) == current_user.id)

    elsif !administrator?
      # Manager constrained by organization or its users.
      cons = cons&.except(:org, :org_id) || {}
      user = cons.extract!(:user, :user_id).compact.values.first
      org  = current_user.org_id
      org  = nil if user && (User.oid(user) == org)

    elsif cons.present?
      # Administrator only constrained if explicitly requested.
      cons = cons.dup
      user = cons.extract!(:user, :user_id).compact.values.first
      org  = cons.extract!(:org, :org_id).compact.values.first
      org  = nil if user
    end

    case
      when org  then opt.merge!(constraints: cons.merge!(org:  org))
      when user then opt.merge!(constraints: cons.merge!(user: user))
      else           opt
    end
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
