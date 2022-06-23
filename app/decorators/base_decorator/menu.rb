# app/decorators/base_decorator/menu.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting selectable lists of Model instances.
#
module BaseDecorator::Menu

  include BaseDecorator::Links

  # ===========================================================================
  # :section: Item forms (edit/delete pages)
  # ===========================================================================

  public

  # Generate a menu of database item entries.
  #
  # @param [Symbol, String, nil] action   Default: `context[:action]`
  # @param [User, Symbol, nil]   user     Default: `current_user`
  # @param [String, nil]         prompt
  # @param [Hash{Symbol=>Hash}]  table
  # @param [Hash]                opt      Passed to #form_tag except for:
  #
  # @option opt [String, Hash] :ujs
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see RouteHelper#get_path_for
  #
  def items_menu(action: nil, user: nil, prompt: nil, table: nil, **opt)
    css      = '.select-entry.menu-control'
    ctrlr    = items_menu_controller
    action ||= context[:action]
    table  ||= action_links

    action = action&.to_sym
    # noinspection RubyMismatchedArgumentType
    action = action && table.dig(action, :action) || action
    path   = h.get_path_for(ctrlr, action)
    model  = object_class

    raise "model: expected Class; got #{model.class}" unless model.is_a?(Class)
    raise "invalid model #{model.inspect}" unless model < ApplicationRecord
    raise "no path for #{ctrlr}/#{action}" unless path

    user   ||= (current_user&.administrator? ? :all : current_user)
    prompt ||= items_menu_prompt(user: user)

    items =
      if user == :all
        model.all
      elsif (user_id = user&.id)
        column = (model <= User) ? :id : :user_id
        model.where(column => user_id)
      end
    menu = items&.order(:id)&.map { |it| [items_menu_label(it), it.id] } || []

    ujs = opt.delete(:ujs) || 'this.form.submit();'
    ujs = ujs.is_a?(Hash) ? ujs.dup : { onchange: ujs }
    select_opt = ujs.merge!(prompt: prompt)

    prepend_css!(opt, css)
    opt[:method] ||= :get
    html_form(path, opt) do
      h.select_tag(:selected, h.options_for_select(menu), select_opt)
    end
  end

  # ===========================================================================
  # :section: Item forms (edit/delete pages)
  # ===========================================================================

  protected

  # The name of the controller used in generating link paths.
  #
  # @return [Symbol]
  #
  def items_menu_controller
    controller_config_base
  end

  # Generate a prompt for #items_menu.
  #
  # @return [String]
  #
  def items_menu_prompt(**)
    item = model_item_name(capitalize: false)
    an   = item.match?(/^[aeiou]/i) ? 'an' : 'a'
    "Select #{an} #{item}" # TODO: I18n
  end

  # Generate a label for a specific menu entry.
  #
  # @param [Model]       item
  # @param [String, nil] label        Override label.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def items_menu_label(item, label: nil)
    name  = model_item_name(capitalize: true)
    index = item.id.to_s.presence || '?'
    align = (index.size == 1) ? ' &thinsp;&nbsp;'.html_safe : ' '
    index = safe_join([name, align, index])
    # noinspection RailsParamDefResolve
    label = label&.to_s || item.try(:menu_label)
    label ? safe_join([index, ' - ', label]) : index
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
