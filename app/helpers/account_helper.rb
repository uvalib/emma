# app/helpers/account_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for "/account" pages.
#
module AccountHelper

  include ModelHelper
  include ConfigurationHelper
  include I18nHelper
  include RoleHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a link to the details show page for the given item.
  #
  # @param [User] item
  # @param [Hash] opt                 Passed to #model_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def account_link(item, **opt)
    css_selector  = '.button'
    opt[:role]  ||= 'button'
    opt[:label] ||= 'Show' # TODO: ?
    opt[:path]  ||= show_account_path(item)
    model_link(item, **prepend_classes!(opt, css_selector))
  end

  # Create a link to the edit page for the given item.
  #
  # @param [User] item
  # @param [Hash] opt                 Passed to #model_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def edit_account_link(item, **opt)
    css_selector         = '.icon'
    opt[:role]         ||= 'button'
    opt[:label]        ||= UploadHelper::UPLOAD_ICONS.dig(:edit, :icon) # TODO: ?
    opt[:'aria-label'] ||= 'Edit'
    opt[:path]         ||= edit_account_path(item)
    model_link(item, **prepend_classes!(opt, css_selector))
  end

  # Create a link to remove the given item.
  #
  # @param [User] item
  # @param [Hash] opt                 Passed to #model_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def delete_account_link(item, **opt)
    css_selector         = '.icon'
    opt[:role]         ||= 'button'
    opt[:label]        ||= UploadHelper::UPLOAD_ICONS.dig(:delete, :icon) # TODO: ?
    opt[:'aria-label'] ||= 'Delete'
    opt[:path]         ||= delete_select_account_path(selected: item)
    model_link(item, **prepend_classes!(opt, css_selector))
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [User] item
  # @param [*]    value
  # @param [Hash] opt                 Passed to the render method.
  #
  # @return [Any]   HTML or scalar value.
  # @return [nil]   If *value* was *nil* or *item* resolved to *nil*.
  #
  # @see ModelHelper#render_value
  #
  def account_render_value(item, value, **opt)
    case field_category(value)
      when :roles then account_roles(item, **opt)
      else             render_value(item, value, **opt)
    end
  end

  # Create a list of User roles.
  #
  # @param [User] item
  # @param [Hash] opt                 Passed to #html_tag
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def account_roles(item, **opt)
    html_tag(:ul, **opt) do
      item.role_list.map do |role|
        html_tag(:li, role)
      end
    end
  end

  # Create a single term which describes the role level of *item*.
  #
  # @param [User] item
  # @param [Hash] opt                 Passed to #html_tag
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def account_role_prototype(item, **opt)
    role_prototype = Roles.role_prototype_for(item)
    prepend_classes!(opt, 'role-prototype')
    html_div(opt) do
      (role_prototype == :dso) ? 'DSO' : role_prototype.to_s.titleize
    end
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render details of an account.
  #
  # @param [User]      item
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to #account_field_values and
  #                                     #model_details.
  #
  def account_details(item, pairs: nil, **opt)
    opt[:model] = :account
    fv_opt, opt = partition_hash(opt, :columns, :filter)
    opt[:pairs] = account_field_values(item, **fv_opt)
    opt[:pairs].merge!(pairs) if pairs.present?
    count = opt[:pairs].size
    append_classes!(opt, "columns-#{count}") if count.positive?
    model_details(item, **opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [User]      item
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to #model_list_item.
  #
  def account_list_item(item, pairs: nil, **opt)
    opt[:model] = model = :account
    opt[:pairs] = index_fields(model).merge(pairs || {})
    model_list_item(item, **opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render accounts as a table.
  #
  # @param [User, Array<User>] list
  # @param [Hash]              opt    Passed to #model_table
  #
  def account_table(list, **opt)
    opt[:model] ||= :account
    opt[:thead] ||= account_table_headings(list, **opt)
    opt[:tbody] ||= account_table_entries(list, **opt)
    model_table(list, **opt)
  end

  # Render one or more entries for use within a <tbody>.
  #
  # @param [User, Array<User>] list
  # @param [Hash]              opt    Passed to #model_table_entries
  #
  def account_table_entries(list, **opt)
    # noinspection RubyMismatchedParameterType
    model_table_entries(list, **opt) do |item, **row_opt|
      account_table_entry(item, **row_opt)
    end
  end

  # Render a single entry for use within a table of items.
  #
  # @param [User] item
  # @param [Hash] opt                 Passed to #model_table_entry
  #
  def account_table_entry(item, **opt)
    # noinspection RubyMismatchedParameterType
    model_table_entry(item, **opt) do |b_item, **b_opt|
      account_columns(b_item, **b_opt)
    end
  end

  # Render column headings for an account table.
  #
  # @param [User, Array<User>] item
  # @param [Hash]              opt    Passed to #model_table_headings
  #
  def account_table_headings(item, **opt)
    # noinspection RubyMismatchedParameterType
    model_table_headings(item, **opt) do |b_item, **b_opt|
      account_columns(b_item, **b_opt)
    end
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  protected

  # Patterns for User record columns which are not included for non-developers.
  #
  # @type [Array<String,Regexp>]
  #
  ACCOUNT_FIELD_FILTERS = %w(token password remember).freeze

  # Specified field selections from the given User instance.
  #
  # @param [User, *] item
  # @param [Hash]    opt              Passed to #model_field_values
  #
  def account_field_values(item, **opt)
    model = User
    return {} unless item.is_a?(model)
    opt[:filter] ||= ACCOUNT_FIELD_FILTERS unless developer?
    pairs = model_field_values(item, **opt)
    show_fields(model).map { |field, config|
      next if config[:ignored]
      next if config[:role] && !has_role?(config[:role])
      k = config[:label] || field
      v = pairs[field]
      v = model.find_record(v)&.uid || pairs[:email] if field == :effective_id
      v = EMPTY_VALUE if v.nil?
      [k, v]
    }.compact.to_h.merge('Role Prototype': account_role_prototype(item))
  end

  # account_columns
  #
  # @param [User, nil] item
  # @param [Hash]      opt            Passed to #account_field_values
  #
  # @return [Hash{Symbol=>*}]
  #
  def account_columns(item = nil, **opt)
    actions = []
    # noinspection RubyMismatchedParameterType
    if item
      actions << account_link(item)
      actions << edit_account_link(item)
      actions << delete_account_link(item)
    end
    action_column = { actions: actions }
    data_columns  = account_field_values(item, **opt)
    action_column.merge!(data_columns)
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Render pre-populated form fields.
  #
  # @param [User]      item
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to #render_form_fields.
  #
  def account_form_fields(item, pairs: nil, **opt)
    opt[:model] = model = :account
    opt[:pairs] = database_fields(model).merge(pairs || {})
    render_form_fields(item, **opt)
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Button information for account actions.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  ACCOUNT_ACTION_VALUES =
    %i[new edit delete].map { |action|
      [action, config_button_values(:account, action)]
    }.to_h.deep_freeze

  # Generate a form with controls for accounting a file, entering metadata, and
  # submitting.
  #
  # @param [User]           item
  # @param [String]         label     Label for the submit button.
  # @param [String, Symbol] action    Either :new or :edit.
  # @param [Hash]           opt       Passed to #form_with except for:
  #
  # @option opt [String] :cancel      URL for cancel button action (default:
  #                                     :back).
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def account_form(item, label: nil, action: nil, **opt)
    css_selector = '.account-form'
    action ||= params[:action]
    cancel   = opt.delete(:cancel)

    # noinspection RubyCaseWithoutElseBlockInspection
    case action
      when :new
        opt[:url]      = new_account_path
      when :edit
        opt[:url]      = update_account_path
        opt[:method] ||= :put
    end
    opt[:multipart]    = true
    opt[:autocomplete] = 'off'

    html_div(class: "account-form-container #{action}") do
      form_with(model: item, **prepend_classes!(opt, css_selector, action)) do
        # Button tray.
        tray = []
        tray << account_submit_button(action: action, label: label)
        tray << account_cancel_button(action: action, url: cancel)
        tray = html_div(class: 'button-tray') { tray }

        # Control elements always visible at the top of the input form.
        controls = html_div(class: 'controls') { tray }

        # Form fields.
        fields = account_field_container(item)

        # All form sections.
        [controls, fields].compact.join("\n").html_safe
      end
    end
  end

  # Account submit button.
  #
  # @param [Hash] opt                 Passed to #submit_tag except for:
  #
  # @option opt [String, Symbol] :action    Default: `params[:action]`.
  # @option opt [String]         :label     Default: based on :action.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/download.js *submitButton()*
  #
  def account_submit_button(**opt)
    opt[:config] ||= ACCOUNT_ACTION_VALUES
    form_submit_button(**opt)
  end

  # Account cancel button.
  #
  # @param [Hash] opt                 Passed to #button_tag except for:
  #
  # @option opt [String, Symbol] :action    Default: `params[:action]`.
  # @option opt [String]         :label     Default: based on :action.
  # @option opt [String]         :url       Default: `params[:cancel]` or
  #                                           `request.referer`.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/download.js *cancelButton()*
  #
  def account_cancel_button(**opt)
    opt[:model]  ||= :account
    opt[:config] ||= ACCOUNT_ACTION_VALUES
    form_cancel_button(**opt)
  end

  # ===========================================================================
  # :section: Item forms (new/edit/delete pages)
  # ===========================================================================

  public

  # Form fields are wrapped in an element for easier grid manipulation.
  #
  # @param [User] item
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def account_field_container(item, **opt)
    css_selector = '.account-fields'
    html_div(prepend_classes!(opt, css_selector)) do
      account_form_fields(item)
    end
  end

  # ===========================================================================
  # :section: Item forms (edit/delete pages)
  # ===========================================================================

  public

  # Generate a menu of local EMMA user account entries.
  #
  # @param [Symbol, String] action    Default: `params[:action]`
  # @param [User, String]   user      Default: '@user'
  # @param [String]         prompt
  # @param [Hash]           opt       Passed to #page_items_menu.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def account_items_menu(action: nil, user: nil, prompt: nil, **opt)
    opt[:action] = action if action
    opt[:user]   = user   if user
    opt[:prompt] = prompt if prompt
    opt[:model]  = User
    opt[:controller] ||= :account
    opt[:prompt]     ||= 'Select an EMMA user account' # TODO: I18n
    page_items_menu(**opt)
  end

  # ===========================================================================
  # :section: Item forms (delete pages)
  # ===========================================================================

  public

  # Generate a form with controls for deleting a local EMMA user account.
  #
  # @param [Array<String,User>] items
  # @param [String]             label   Label for the submit button.
  # @param [Hash]               opt     Passed to 'account-delete-form' except:
  #
  # @option opt [String] :cancel        Cancel button redirect URL passed to
  #                                       #account_delete_cancel.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def account_delete_form(*items, label: nil, **opt)
    css_selector  = '.account-delete-form'
    opt, html_opt = partition_hash(opt, :cancel)
    cancel = account_delete_cancel(url: opt[:cancel])
    submit = account_delete_submit(*items, label: label)
    html_div(class: 'account-form-container delete') do
      html_div(prepend_classes!(html_opt, css_selector)) do
        submit << cancel
      end
    end
  end

  # Submit button for the delete upload form.
  #
  # @param [Array<String,User>] items
  # @param [Hash]               opt     Passed to #delete_submit_button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def account_delete_submit(*items, **opt)
    ids = User.compact_ids(*items).join(',')
    url = (destroy_account_path(id: ids) if ids.present?)
    delete_submit_button(config: ACCOUNT_ACTION_VALUES, url: url, **opt)
  end

  # Cancel button for the delete account form.
  #
  # @param [Hash] opt                 Passed to #account_cancel_button
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see file:app/assets/javascripts/feature/download.js *cancelAction()*
  #
  def account_delete_cancel(**opt)
    opt[:action] ||= :delete
    account_cancel_button(**opt)
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
