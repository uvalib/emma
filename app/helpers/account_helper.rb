# app/helpers/account_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AccountHelper
#
module AccountHelper

  def self.included(base)
    __included(base, '[AccountHelper]')
  end

  include ModelHelper
  include ConfigurationHelper
  include I18nHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values for this model.
  #
  # @type {Hash{Symbol=>Hash}}
  #
  ACCOUNT_FIELDS       = Model.configured_fields(:account).deep_freeze
  ACCOUNT_INDEX_FIELDS = ACCOUNT_FIELDS[:index] || {}
  ACCOUNT_SHOW_FIELDS  = ACCOUNT_FIELDS[:show]  || {}

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a link to the details show page for the given item.
  #
  # @param [User] item
  # @param [Hash] opt                 Passed to #item_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def account_link(item, **opt)
    prepend_css_classes!(opt, 'button')
    opt[:role]  ||= 'button'
    opt[:label] ||= 'Show' # TODO: ?
    opt[:path]  ||= show_account_path(item)
    item_link(item, **opt)
  end

  # Create a link to the edit page for the given item.
  #
  # @param [User] item
  # @param [Hash] opt                 Passed to #item_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def edit_account_link(item, **opt)
    prepend_css_classes!(opt, 'icon')
    opt[:role]         ||= 'button'
    opt[:label]        ||= UploadHelper::UPLOAD_ICONS.dig(:edit, :icon) # TODO: ?
    opt[:'aria-label'] ||= 'Edit'
    opt[:path]         ||= edit_account_path(item)
    item_link(item, **opt)
  end

  # Create a link to remove the given item.
  #
  # @param [User] item
  # @param [Hash] opt                 Passed to #item_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def delete_account_link(item, **opt)
    prepend_css_classes!(opt, 'icon')
    opt[:role]         ||= 'button'
    opt[:label]        ||= UploadHelper::UPLOAD_ICONS.dig(:delete, :icon) # TODO: ?
    opt[:'aria-label'] ||= 'Delete'
    opt[:path]         ||= delete_select_account_path(selected: item)
    item_link(item, **opt)
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render an account metadata listing.
  #
  # @param [User]            item
  # @param [String, Symbol, nil, Array<String,Symbol,nil>] columns
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #item_details.
  #
  def account_details(item, columns: nil, pairs: nil, **opt)
    pairs = account_field_values(item, columns: columns).merge(pairs || {})
    # noinspection RubyNilAnalysis
    count = pairs.size
    append_css_classes!(opt, "columns-#{count}") if count.positive?
    item_details(item, model: :account, pairs: pairs, **opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [User]      item
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to #item_list_entry.
  #
  def account_list_entry(item, pairs: nil, **opt)
    opt[:model] = :account
    opt[:pairs] = ACCOUNT_INDEX_FIELDS.merge(pairs || {})
    item_list_entry(item, **opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render accounts as a table.
  #
  # @param [User, Array<User>] list
  # @param [Hash]              opt    Passed to #item_table
  #
  def account_table(list, **opt)
    opt[:model] ||= :account
    # noinspection RubyYardParamTypeMatch
    item_table(list, **opt) do |parts, b_list, **b_opt|
      parts[:thead] ||= account_table_headings(b_list, **b_opt)
      parts[:tbody] ||= account_table_entries(b_list, **b_opt)
    end
  end

  # Render one or more entries for use within a <tbody>.
  #
  # @param [User, Array<User>] list
  # @param [Hash]              opt    Passed to #item_table_entries
  #
  def account_table_entries(list, **opt)
    # noinspection RubyYardParamTypeMatch
    item_table_entries(list, **opt) do |item, **row_opt|
      account_table_entry(item, **row_opt)
    end
  end

  # Render a single entry for use within a table of items.
  #
  # @param [User] item
  # @param [Hash] opt                 Passed to #item_table_entry
  #
  def account_table_entry(item, **opt)
    # noinspection RubyYardParamTypeMatch
    item_table_entry(item, **opt) do |b_item, **b_opt|
      account_columns(b_item, **b_opt)
    end
  end

  # Render column headings for an account table.
  #
  # @param [User, Array<User>] item
  # @param [Hash]              opt    Passed to #item_table_headings
  #
  def account_table_headings(item, **opt)
    # noinspection RubyYardParamTypeMatch
    item_table_headings(item, **opt) do |b_item, **b_opt|
      account_columns(b_item, **b_opt)
    end
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  protected

  # @type [Array<String,Regexp>]
  ACCOUNT_FIELD_FILTERS = %w(password remember).freeze

  # Specified field selections from the given User instance.
  #
  # @param [User, nil] item
  # @param [Hash]      opt            Passed to #item_field_values
  #
  def account_field_values(item, **opt)
    return {} unless item.is_a?(User)
    opt[:filter] ||= ACCOUNT_FIELD_FILTERS
    item_field_values(item, **opt)
  end

  # account_columns
  #
  # @param [User] item
  # @param [Hash] opt                 Passed to #account_field_values
  #
  # @return [Hash{Symbol=>*}]
  #
  def account_columns(item = nil, **opt)
    actions = []
    # noinspection RubyYardParamTypeMatch
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

  # Fields for new/edit user account forms.
  #
  # @type [Hash{Symbol=>Hash}]
  #
  ACCOUNT_FORM_FIELDS = ACCOUNT_FIELDS[:all]

  # Render pre-populated form fields.
  #
  # @param [User]      item
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to #render_form_fields.
  #
  def account_form_fields(item, pairs: nil, **opt)
    opt[:model] = :account
    opt[:pairs] = ACCOUNT_FORM_FIELDS.merge(pairs || {})
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

    prepend_css_classes!(opt, 'account-form', action)

    html_div(class: "account-form-container #{action}") do
      form_with(model: item, **opt) do
        # Button tray.
        tray = []
        tray << account_submit_button(action: action, label: label)
        tray << account_cancel_button(action: action, url: cancel)
        tray = html_div(class: 'button-tray') { tray }

        # Control elements which are always visible at the top of the input form.
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
  # @option opt [String, Symbol] :action    Default: `#params[:action]`.
  # @option opt [String]         :label     Default: based on :action.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see submitButton() in app/assets/javascripts/feature/download.js
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
  # @see cancelButton() in app/assets/javascripts/feature/download.js
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
    prepend_css_classes!(opt, 'account-fields')
    html_div(opt) do
      account_form_fields(item)
    end
  end

  # ===========================================================================
  # :section: Item forms (edit/delete pages)
  # ===========================================================================

  public

  # Generate a menu of local EMMA user account entries.
  #
  # @param [Symbol, String] action    Default: `#params[:action]`
  # @param [User, String]   user      Default: @user
  # @param [String]         prompt
  # @param [Hash]           opt       Passed to #form_tag.
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
  # @param [Array<String,Upload>] items
  # @param [String]               label   Label for the submit button.
  # @param [Hash]                 opt     Passed to 'account-delete-form'
  #                                         except for:
  #
  # @option opt [String]  :cancel         Cancel button redirect URL passed to
  #                                         #account_delete_cancel.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def account_delete_form(*items, label: nil, **opt)
    opt, html_opt = partition_options(opt, :cancel)
    cancel = account_delete_cancel(url: opt[:cancel])
    submit = account_delete_submit(*items, label: label)
    html_div(class: 'account-form-container delete') do
      prepend_css_classes!(html_opt, 'account-delete-form')
      html_div(html_opt) { submit << cancel }
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
    min = User.minimum(:id).to_i
    max = User.maximum(:id).to_i
    ids = Upload.compact_ids(*items, min_id: min, max_id: max).join(',')
    url = (destroy_account_path(id: ids) if ids.present?)
    delete_submit_button(config: ACCOUNT_ACTION_VALUES, url: url, **opt)
  end

  # Cancel button for the delete account form.
  #
  # @param [Hash] opt                 Passed to #account_cancel_button
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see cancelAction() in app/assets/javascripts/feature/download.js
  #
  def account_delete_cancel(**opt)
    opt[:action] ||= :delete
    account_cancel_button(**opt)
  end

end

__loading_end(__FILE__)
