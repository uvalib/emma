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
    # :section: BaseDecorator::List overrides
    # =========================================================================

    public

    # Render a single entry for use within a list of items.
    #
    # @param [Hash, nil] pairs        Additional field mappings.
    # @param [Hash]      opt          Passed to super.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def list_item(pairs: nil, **opt)
      opt[:pairs] = model_index_fields.merge(pairs || {})
      super(**opt)
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
      unless administrator?
        hash = opt[:constraints]&.dup || {}
        user = hash.extract!(:user, :user_id).compact.values.first
        org  = hash.extract!(:org, :org_id).compact.values.first
        if !user && !org && (user = current_user).present?
          added = (org = user.org) ? { org: org } : { user: user }
          opt[:constraints] = added.merge!(hash)
        end
      end
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
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [*]         value
  # @param [Symbol, *] field
  # @param [Hash]      opt            Passed to the render method or super.
  #
  # @return [Any]                     HTML or scalar value.
  # @return [nil]                     If *value* or *object* is *nil*.
  #
  def render_value(value, field:, **opt)
    (value.to_s == 'roles') ? roles(**opt) : super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Create a list of User roles.
  #
  # @param [Hash] opt                 Passed to #html_tag
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def roles(**opt)
    roles = present? && object.role_list || []
    html_tag(:ul, opt) do
      roles.map do |role|
        html_tag(:li, role)
      end
    end
  end

  # Create a single term which describes the role level of *item*.
  #
  # @param [Hash] opt                 Passed to #html_tag
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def role_prototype(**opt)
    prototype = Role.prototype_for(object)
    prepend_css!(opt, 'role-prototype')
    html_div(opt) do
      (prototype == :dso) ? 'DSO' : prototype.to_s.titleize
    end
  end

  # ===========================================================================
  # :section: BaseDecorator::Table overrides
  # ===========================================================================

  public

  # Table values associated with the current decorator.
  #
  # @param [Hash] opt
  #
  # @return [Hash]
  #
  def table_values(**opt)
    controls = control_group { [show_control, edit_control, delete_control] }
    { actions: controls, **super }
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  protected

  # Patterns for User record columns which are not included for
  # non-developers.
  #
  # @type [Array<String,Symbol,Regexp>]
  #
  FIELD_FILTERS = %w[token password remember].freeze

  # Specified field selections from the given User instance.
  #
  # @param [User, Hash, nil] item     Default: `#object`.
  # @param [Hash]            opt      Passed to super.
  #
  # @return [Hash{String=>ActiveSupport::SafeBuffer}]
  #
  def model_field_values(item = nil, **opt)
    opt[:filter] ||= FIELD_FILTERS unless developer?
    pairs = super(item, **opt)
    cfg   = model_context_fields || model_show_fields
    cfg.map { |field, config|
      next if config[:ignored]
      next unless user_has_role?(config[:role])
      k = config[:label] || field
      v = pairs[field]
      v = EMPTY_VALUE if v.nil?
      [k, v]
    }.compact.to_h.merge!('Role Prototype' => role_prototype)
  end

  # ===========================================================================
  # :section: BaseDecorator::Form overrides
  # ===========================================================================

  public

  # Render pre-populated form fields, manually adding password field(s) (which
  # are not in "emma.account.record").
  #
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to #render_form_fields.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_fields(pairs: nil, **opt)
    fields = AccountConcern::PASSWORD_KEYS
    fields = fields.excluding(:current_password) if manager? || administrator?
    added  = fields.map { |k| [k.to_s.titleize, k] }.to_h
    pairs  = pairs&.merge(added) || added
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
    constraints = nil
    if administrator?
      case opt[:range].try(:model_type)
        when :user then constraints = { prepend: { 0 => 'NONE' } };
        when :org  then constraints = { prepend: { 0 => 'NONE' } };
      end
    elsif current_org
      case opt[:range].try(:model_type)
        when :user then constraints = { org: current_org }
        when :org  then opt[:fixed] = true
      end
    end
    opt[:constraints] = opt[:constraints]&.dup || {} if constraints
    opt.merge!(constraints: constraints)             if constraints
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
    row_count = 0

    heading_rows =
      html_tag(:thead, role: 'rowgroup') do
        html_tag(:tr, role: 'row') do
          row_count += 1
          columns.map do |css_class, label|
            html_tag(:th, label, role: 'columnheader', class: css_class)
          end
        end
      end

    data_rows =
      html_tag(:tbody, role: 'rowgroup') do
        divider = ability_table_divider
        ability_table_rows(target).flat_map do |_, rows|
          row_count += rows.size
          rows.values << divider
        end
      end

    table_opt[:role] ||= 'table'
    table_opt[:'aria-colcount'] = columns.size
    table_opt[:'aria-rowcount'] = row_count
    html_tag(:table, table_opt) do
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
  #
  # @return [Hash{Class=>Hash{Symbol=>ActiveSupport::SafeBuffer}}]
  #
  def ability_table_rows(target = nil, models: nil, actions: nil)
    actions ||= ABILITY_ACTIONS
    models  ||= Ability.models
    target  ||= object || current_ability
    target    = target.ability if target.is_a?(User)

    r = 0
    models.map { |model|
      ctrlr_actions = model.model_controller.public_instance_methods(false)
      actions.intersection(ctrlr_actions).map { |action|
        status = target.can?(action, model)
        can    = status ? 'can' : 'cannot'
        if status.nil?
          can    = 'error'
          status = Emma::Unicode::EN_DASH
        elsif status && (cond = target.constrained_by(action, model))
          if cond.is_a?(Hash)
            cond = pretty_json(cond).sub(/\A{\s*(.+)\s*}\z/, '\1')
          else
            cond = cond.inspect
          end
          status = "true for #{cond}"
        end
        row_css = css_classes(can, action, model)
        row_opt = { role: 'row', class: row_css, 'aria-rowindex': (r += 1) }
        html_tag(:tr, row_opt) {
          columns = { model: model, action: action, status: status }
          columns.map.with_index(1) { |(cls, val), idx|
            id  = unique_id(action, model)
            opt = append_css(cls, can).merge!(role: 'cell')
            opt.merge!('aria-labelledby': id, 'aria-colindex': idx)
            html_tag(:td, opt) { html_span(val.to_s, id: id) }
          }
        }.then { |row| [action, row] }
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
    html_tag(:tr, opt) do
      ABILITY_COLUMNS.keys.map.with_index(1) do |cls, idx|
        html_tag(:td, role: 'cell', class: cls, 'aria-colindex': idx)
      end
    end
  end

end

__loading_end(__FILE__)
