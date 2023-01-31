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

    # =========================================================================
    # :section: BaseDecorator::SharedPathMethods overrides
    # =========================================================================

    public

    def index_path(*, **opt)
      h.account_index_path(**opt)
    end

    def show_path(item = nil, **opt)
      opt[:id] = id_for(item, **opt)
      h.show_account_path(**opt)
    end

    def new_path(*, **opt)
      h.new_account_path(**opt)
    end

    def create_path(*, **opt)
      h.create_account_path(**opt)
    end

    def edit_select_path(*, **opt)
      h.edit_select_account_path(**opt)
    end

    def edit_path(item = nil, **opt)
      return edit_select_path(item, **opt) if opt[:selected]
      opt[:id] = id_for(item, **opt)
      h.edit_account_path(**opt)
    end

    def update_path(item = nil, **opt)
      opt[:id] = id_for(item, **opt)
      h.update_account_path(**opt)
    end

    def delete_select_path(*, **opt)
      h.delete_select_account_path(**opt)
    end

    def delete_path(item = nil, **opt)
      return delete_select_path(item, **opt) if opt[:selected]
      opt[:id] = id_for(item, **opt)
      h.delete_account_path(**opt)
    end

    def destroy_path(item = nil, **opt)
      opt[:id] = id_for(item, **opt)
      h.destroy_account_path(**opt)
    end

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

    # Control icon definitions.
    #
    # @return [Hash{Symbol=>Hash{Symbol=>*}}]
    #
    def control_icons
      super(icons: ICONS)
    end

    # =========================================================================
    # :section: BaseDecorator::List overrides
    # =========================================================================

    public

    # Render details of an account.
    #
    # @param [Hash, nil] pairs        Additional field mappings.
    # @param [Hash]      opt          Passed to super except:
    #
    # @option opt [String, Symbol, Array<String,Symbol>] :columns
    # @option opt [String, Regexp, Array<String,Regexp>] :filter
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # @see #model_field_values
    #
    def details(pairs: nil, **opt)
      fv_opt      = extract_hash!(opt, :columns, :filter)
      opt[:pairs] = model_field_values(**fv_opt).merge!(pairs || {})
      count       = opt[:pairs].size
      append_css!(opt, "columns-#{count}") if count.positive?
      super(**opt)
    end

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
    prototype = Roles.role_prototype_for(object)
    prepend_css!(opt, 'role-prototype')
    html_div(opt) do
      (prototype == :dso) ? 'DSO' : prototype.to_s.titleize
    end
  end

  # ===========================================================================
  # :section: BaseDecorator::Table overrides
  # ===========================================================================

  public

  # table_columns
  #
  # @param [Hash] opt
  #
  # @return [Hash]
  #
  def table_columns(**opt)
    { actions: [show_control, edit_control, delete_control], **super }
  end

  # ===========================================================================
  # :section: BaseDecorator::Table overrides
  # ===========================================================================

  protected

  # Patterns for User record columns which are not included for
  # non-developers.
  #
  # @type [Array<String,Symbol,Regexp>]
  #
  FIELD_FILTERS = %w(token password remember).freeze

  # Specified field selections from the given User instance.
  #
  # @param [User, Hash, nil] item     Default: `#object`.
  # @param [Hash]            opt      Passed to super.
  #
  # @return [Hash{String=>ActiveSupport::SafeBuffer}]
  #
  def model_field_values(item = nil, **opt)
    opt[:filter] ||= FIELD_FILTERS unless developer?
    table = object_class
    pairs = super(item, **opt)
    model_show_fields.map { |field, config|
      next if config[:ignored]
      next if config[:role] && !has_role?(config[:role])
      k = config[:label] || field
      v = pairs[field]
      v = table.find_record(v)&.uid || pairs[:email] if field == :effective_id
      v = EMPTY_VALUE if v.nil?
      [k, v]
    }.compact.to_h.merge!('Role Prototype' => role_prototype)
  end

  # ===========================================================================
  # :section: BaseDecorator::Form overrides
  # ===========================================================================

  public

  # Render pre-populated form fields, manually adding password field(s) (which
  # are not in "emma.account.record") and overriding the :effective_id field
  # (which is) for the administrator to set/modify the effective Bookshare
  # account associated with the EMMA account.
  #
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to #render_form_fields.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_fields(pairs: nil, **opt)
    edit  = (context[:action] == :edit)
    admin = current_user&.administrator?

    get_password         = !edit ||  admin
    get_effective_id     =  edit &&  admin
    get_current_password =  edit && !admin

    fields = []
    fields << :password << :password_confirmation if get_password
    fields << :current_password                   if get_current_password

    added = fields.map { |k| [k, k] }.to_h
    added[:effective_id] = bookshare_user_menu    if get_effective_id

    opt[:pairs] = pairs&.merge(added) || added
    super(**opt)
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

  # @private # TODO: I18n
  DEFAULT_BOOKSHARE_ENTRY = 'Not applicable'

  # Generate data for :effective_id rendered as a menu instead of a fixed
  # value.
  #
  # @param [Integer, nil] selected    Default: `object.effective_id`
  # @param [String, nil]  default
  #
  # @return [Hash]
  #
  def bookshare_user_menu(selected: nil, default: DEFAULT_BOOKSHARE_ENTRY)
    label    = 'Equivalent Bookshare user' # TODO: I18n
    value    = selected || object&.effective_id
    choices  = []
    choices << [default, ''] if default # TODO: I18n
    choices += User.test_user_menu
    { label: label, value: value, range: choices.map! { |k, v| [v, k] } }
  end

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

end

__loading_end(__FILE__)
