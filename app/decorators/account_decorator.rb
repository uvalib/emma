# app/decorators/account_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/account" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [User]
#
class AccountDecorator < BaseDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for account: User

  # ===========================================================================
  # :section: Definitions shared with AccountsDecorator
  # ===========================================================================

  public

  module SharedPathMethods
    include BaseDecorator::SharedPathMethods
  end

  # Definitions available to both classes and instances of either this
  # decorator or its related collection decorator.
  #
  module SharedGenericMethods

    include BaseDecorator::SharedGenericMethods

    # =========================================================================
    # :section: BaseDecorator::Controls overrides
    # =========================================================================

    public

    # Control icon definitions.
    #
    # @type [Hash{Symbol=>Hash{Symbol=>*}}]
    #
    # @see BaseDecorator::Controls#ICON_PROPERTIES
    #
    ICONS =
      BaseDecorator::Controls::ICONS.except(:show).transform_values { |v|
        v.dup.tap do |entry|
          tip = entry[:tooltip]
          entry[:tooltip] %= { item: 'account' } if tip&.include?('%')
          entry[:active] = true
        end
      }.deep_freeze

    # Icon definitions for this decorator.
    #
    # @return [Hash{Symbol=>Hash{Symbol=>*}}]
    #
    def icon_definitions
      ICONS
    end

    # =========================================================================
    # :section: BaseDecorator::Form overrides
    # =========================================================================

    public

    # Render a single label/value pair, ensuring :email is fixed if editing
    # the user's own account.
    #
    # @param [String, Symbol] label
    # @param [*]              value
    # @param [Hash]           opt     Passed to super
    #
    # @return [ActiveSupport::SafeBuffer, nil]
    #
    def render_form_pair(label, value, **opt)
      edit  = current_user && (context[:action] == :edit)
      field = (opt.dig(:prop, :field) || opt[:field] if edit)
      if field == :email
        data = value.is_a?(Field::Type) ? value.value : value
        data = Array.wrap(data).presence
        opt[:fixed] = true if data&.excluding(current_user.email)&.blank?
      end
      super(label, value, **opt)
    end

    # =========================================================================
    # :section: BaseDecorator::Menu overrides
    # =========================================================================

    public

    # Generate a menu of user instances.
    #
    # @param [Hash] opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def items_menu(**opt)
      items_menu_role_constraints!(opt)
      opt[:sort] ||= { id: :asc }
      super(**opt)
    end

    # =========================================================================
    # :section: BaseDecorator::Menu overrides
    # =========================================================================

    protected

    # Generate a prompt for #items_menu.
    #
    # @return [String]
    #
    def items_menu_prompt(**)
      'Select an EMMA user account' # TODO: I18n
    end

    # Descriptive term for an item of the given type.
    #
    # @param [Symbol, String, nil] model        Default: `#model_type`.
    # @param [Boolean]             capitalize
    #
    # @return [String]
    #
    def model_item_name(model: nil, capitalize: true)
      model ? super : 'EMMA User Account' # TODO: I18n
    end

    # =========================================================================
    # :section: BaseDecorator::Form overrides
    # =========================================================================

    public

    # Tooltip giving the reason why the field cannot be changed. # TODO: I18n
    #
    # @type [String]
    #
    EMAIL_FIELD_READONLY = 'Cannot change the account identifier'

    # Input placeholder to indicate that the password field does not need to be
    # filled out.
    #
    # @type [String, nil]
    #
    PASSWORD_PLACEHOLDER =
      I18n.t('emma.user.registrations.edit.password').freeze

    # If set, the minimum number of characters accepted for passwords.
    #
    # @type [Integer, nil]
    #
    MINIMUM_PASSWORD_LENGTH = 8

    # If set, the maximum number of characters accepted for passwords.
    #
    # @type [Integer, nil]
    #
    MAXIMUM_PASSWORD_LENGTH = nil

  end

  # Definitions available to instances of either this decorator or its related
  # collection decorator.
  #
  # (Definitions that are only applicable to instances of this decorator but
  # *not* to collection decorator instances are not included here.)
  #
  module SharedInstanceMethods
    include BaseDecorator::SharedInstanceMethods
    include SharedPathMethods
    include SharedGenericMethods
  end

  # Definitions available to both this decorator class and the related
  # collector decorator class.
  #
  # (Definitions that are only applicable to this class but *not* to the
  # collection class are not included here.)
  #
  module SharedClassMethods
    include BaseDecorator::SharedClassMethods
    include SharedPathMethods
    include SharedGenericMethods
  end

  # Cause definitions to be included here and in the associated collection
  # decorator via BaseCollectionDecorator#collection_of.
  #
  module SharedDefinitions
    def self.included(base)
      base.include(SharedInstanceMethods)
      base.extend(SharedClassMethods)
    end
  end

end

class AccountDecorator

  include SharedDefinitions

  # ===========================================================================
  # :section: BaseDecorator::Controls overrides
  # ===========================================================================

  public

  # Create a link to the details show page for the given item.
  #
  # @param [Hash] opt                 Passed to #link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def show_control(**opt)
    opt[:label] ||= 'Show' # TODO: I18n
    opt[:path]  ||= show_path
    button_link(**opt)
  end

  # ===========================================================================
  # :section: BaseDecorator::Table overrides
  # ===========================================================================

  public

  # Fields and configurations augmented with a :value entry containing the
  # current field value.
  #
  # @param [Hash] opt                 Passed to super.
  #
  # @return [Hash{Symbol=>FieldConfig}]
  #
  def table_field_values(**opt)
    trace_attrs!(opt)
    t_opt    = trace_attrs_from(opt)
    controls = control_group { control_icon_buttons(**t_opt) }
    super(**opt, before: { actions: controls })
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Patterns for User record columns which are not included for
  # non-developers.
  #
  # @type [Array<String,Symbol,Regexp>]
  #
  FIELD_FILTERS = %w[token password remember].freeze

  # Fields and configurations augmented with a :value entry containing the
  # current field value.
  #
  # @param [Hash] opt                 Passed to super
  #
  # @return [Hash{Symbol=>FieldConfig}]
  #
  def list_field_values(**opt)
    opt[:except] ||= FIELD_FILTERS unless developer?
    trace_attrs!(opt)
    super(**opt)
  end

  # ===========================================================================
  # :section: BaseDecorator::Form overrides
  # ===========================================================================

  public

  # Render pre-populated form fields, manually adding password field(s) (which
  # are not in "emma.account.record").
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_field_rows(**opt)
    trace_attrs!(opt)
    fields = AccountConcern::PASSWORD_KEYS
    fields = fields.excluding(:current_password) if manager? || administrator?
    fields = fields.map { |k| [k, nil] }.to_h
    opt[:after] = opt[:after]&.merge(fields) || fields
    super
  end

  # Single-select menu - drop-down.
  #
  # @param [String]      name
  # @param [Array]       value
  # @param [Hash]        opt          Passed to super
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_form_menu_single(name, value, **opt)
    form_menu_role_constraints!(opt)
    super(name, value, **opt)
  end

  # render_form_email
  #
  # @param [String] name
  # @param [*]      value
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_form_email(name, value, **opt)
    action = opt.delete(:action) || context[:action]
    edit   = (action == :edit)
    opt[:readonly]     = true                 if edit
    opt[:title]        = EMAIL_FIELD_READONLY if edit
    opt[:autocomplete] = 'email'              unless opt.key?(:autocomplete)
    super
  end

  # render_form_password
  #
  # @param [String] name
  # @param [*]      value
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_form_password(name, value, **opt)
    field     = opt[:'data-field'] ||= name&.to_sym
    current   = (field == :current_password)
    action    = opt.delete(:action) || context[:action]
    edit      = (action == :edit)
    required  = current || !edit
    min, max  = opt.values_at(:minlength, :maxlength)
    if field == :password
      min = MINIMUM_PASSWORD_LENGTH and opt.merge!(minlength: min) unless min
      max = MAXIMUM_PASSWORD_LENGTH and opt.merge!(maxlength: max) unless max
    end
    length    = (min_length_note(**opt)       if min || max)
    curr_note = (current_password_note(**opt) if current && edit)

    unless opt.key?(:autocomplete)
      opt[:autocomplete] = '%s-password' % (current ? 'current' : 'new')
    end
    unless required || opt.key?(:placeholder)
      opt[:placeholder] = PASSWORD_PLACEHOLDER
    end

    super.tap do |input|
      input << form_note_pair(length,    **opt) if length
      input << form_note_pair(curr_note, **opt) if curr_note
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # min_length_note
  #
  # @param [String, nil] note
  # @param [Integer, nil] min
  # @param [Hash]         opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def min_length_note(note = nil, min: nil, **opt)
    min  ||= MINIMUM_PASSWORD_LENGTH or return
    note ||= I18n.t('emma.user.password.length', min: min)
    form_input_note(note, **opt) if note
  end

  # current_password_note
  #
  # @param [String, nil] note
  # @param [Hash]        opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def current_password_note(note = nil, **opt)
    note ||= I18n.t('emma.user.registrations.edit.current')
    form_input_note(note, **opt) if note
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  ABILITY_ACTIONS = %i[
    index     list_all    list_org  list_own
    show      download    admin
    new       create      edit      update      delete      destroy
    bulk_new  bulk_create bulk_edit bulk_update bulk_delete bulk_destroy
  ].freeze

  ABILITY_COLUMNS = {
    model:  'Model',        # TODO: I18n
    action: 'Action',       # TODO: I18n
    status: 'Can perform?', # TODO: I18n
  }.freeze

  # A table of abilities.
  #
  # @param [User, Ability, nil] target      Default: #current_ability.
  # @param [Hash]               columns:    Default: #ABILITY_COLUMNS.
  # @param [Hash]               table_opt   To outer `<table>` element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def ability_table(target = nil, columns: ABILITY_COLUMNS, **table_opt)
    rows = 0

    heading_rows =
      html_tag(:thead, role: 'rowgroup') do
        rows += 1
        html_tag(:tr, role: 'row', 'aria-rowindex': rows) do
          columns.map do |css_class, label|
            html_tag(:th, label, role: 'columnheader', class: css_class)
          end
        end
      end

    data_rows =
      html_tag(:tbody, role: 'rowgroup') do
        divider = ability_table_divider
        ability_table_rows(target, start: rows).flat_map do |_, row_group|
          rows += row_group.size
          row_group.values << divider
        end
      end

    table_opt[:role] ||= 'table'
    table_opt[:'aria-colcount'] = columns.size
    table_opt[:'aria-rowcount'] = rows
    html_tag(:table, **table_opt) do
      heading_rows << data_rows
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A table of models where each value is a sub-table of rows for each action.
  #
  # @param [User, Ability, nil] target    Default: #current_ability.
  # @param [Array<Class>, nil]  models    Default: Ability#models.
  # @param [Array<Symbol>, nil] actions   Default: #ABILITY_ACTIONS
  # @param [Integer]            start     First row number.
  #
  # @return [Hash{Class=>Hash{Symbol=>ActiveSupport::SafeBuffer}}]
  #
  def ability_table_rows(target = nil, models: nil, actions: nil, start: 1)
    actions ||= ABILITY_ACTIONS
    models  ||= Ability.models
    target  ||= object || current_ability
    target    = target.ability if target.is_a?(User)
    row       = start

    models.map { |model|
      ctrlr_actions = model.model_controller.public_instance_methods(false)
      actions.intersection(ctrlr_actions).map { |action|
        row_opt = { role: 'row', 'aria-rowindex': (row += 1) }
        status  = target.can?(action, model)
        can     = status ? 'can' : 'cannot'
        if status.nil?
          can    = 'error'
          status = EMPTY_VALUE
        elsif status && (cond = target.constrained_by(action, model))
          if cond.is_a?(Hash)
            cond = pretty_json(cond).sub(/\A{\s*(.+)\s*}\z/, '\1')
          else
            cond = cond.inspect
          end
          status = "true for #{cond}"
        end
        append_css!(row_opt, can, action, model)
        html_tag(:tr, **row_opt) {
          columns = { model: model, action: action, status: status }
          columns.map.with_index(1) { |(cls, val), col|
            id  = unique_id(action, model)
            opt = { role: 'cell', 'aria-labelledby': id, 'aria-colindex': col }
            append_css!(opt, cls, can)
            html_tag(:td, **opt) { html_span(val.to_s, id: id) }
          }
        }.then { |column| [action, column] }
      }.to_h.then { |rows| [model, rows] }
    }.to_h
  end

  # A table row to visually separate groups of rows.
  #
  # @param [String] css               Characteristic CSS class/selector.
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def ability_table_divider(css: '.blank-row', **opt)
    opt.reverse_merge!(role: 'presentation', 'aria-hidden': true)
    prepend_css!(opt, css)
    html_tag(:tr, **opt) do
      col_opt = { role: 'cell', class: 'blank' }
      ABILITY_COLUMNS.keys.map.with_index(1) do |cls, idx|
        html_tag(:td, **prepend_css(col_opt, cls).merge!('aria-colindex': idx))
      end
    end
  end

end

__loading_end(__FILE__)
