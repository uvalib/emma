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
  # :section: Item forms (edit/delete pages)
  # ===========================================================================

  public

  # Generate a menu of database item entries.
  #
  # @param [Symbol, String, nil] action      Default: `context[:action]`
  # @param [Hash, nil]           constraint
  # @param [Hash, nil]           sort
  # @param [String, nil]         prompt
  # @param [Hash{Symbol=>Hash}]  table
  # @param [String, Hash]        ujs         JavaScript selection action.
  # @param [String]              css         Characteristic CSS class/selector.
  # @param [Hash]                opt         Passed to #html_form.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see RouteHelper#get_path_for
  #
  def items_menu(
    action:     nil,
    constraint: nil,
    sort:       nil,
    prompt:     nil,
    table:      nil,
    ujs:        'this.form.submit();',
    css:        '.select-entry.menu-control',
    **opt
  )
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

    user = constraint&.values_at(:user, :user_id)&.first
    org  = constraint&.values_at(:org, :org_id)&.first
    case
      when (item = user) then column = (model <= User) ? :id : :user_id
      when (item = org)  then column = (model <= Org)  ? :id : :org_id
      else                    column = item = nil
    end
    sort = sort&.dup
    term =
      if column && model.field_names.include?(column)
        sort ||= { column => :asc }
        case item
          when ApplicationRecord then { column => item.id }
          when Integer           then { column => item }
          else                        item unless item == :all
        end
      end
    sort ||= { updated_at: :desc }
    case
      when term then menu = model.where(term)
      when user then menu = model.for_user(user)
      when org  then menu = model.for_org(org)
      else           menu = model.all
    end
    menu = menu.order(sort.merge!(created_at: :desc))
    menu = menu.map { |it| [items_menu_label(it), it.id] }

    prompt ||= items_menu_prompt(user: user)
    ujs = ujs.is_a?(Hash) ? ujs.dup : { onchange: ujs }
    select_opt = ujs.merge!(prompt: prompt, name: 'id')

    prepend_css!(opt, css)
    opt[:method] ||= :get
    html_form(path.delete_suffix(SELECT_ACTION_SUFFIX), opt) do
      label = h.label_tag(:selected, prompt, class: 'sr-only')
      menu  = h.select_tag(:selected, h.options_for_select(menu), select_opt)
      label << menu
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
    controller_config_key
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
