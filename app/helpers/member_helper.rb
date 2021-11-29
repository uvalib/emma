# app/helpers/member_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for "/member" pages.
#
module MemberHelper

  include BookshareHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Default link tooltip.
  #
  # @type [String]
  #
  MEMBER_SHOW_TOOLTIP = I18n.t('emma.member.show.tooltip').freeze

  # Create a link to the details show page for the given item.
  #
  # NOTE: Over-encoded to allow ID's with '.' to be passed to Rails.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Passed to #model_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def member_link(item, **opt)
    opt[:path]    = member_path(id: url_escape(item.identifier))
    opt[:tooltip] = MEMBER_SHOW_TOOLTIP
    model_link(item, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configured member history record fields.
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def member_history_fields(*)
    Model.configuration_fields(:member)[:history] || {}
  end

  # Configured member preference record fields.
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def member_preference_fields(*)
    Model.configuration_fields(:member)[:preferences] || {}
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [Bs::Api::Record] item
  # @param [*]               value
  # @param [Hash]            opt        Passed to the render method.
  #
  # @return [Any]   HTML or scalar value.
  # @return [nil]   If *value* was *nil* or *item* resolved to *nil*.
  #
  # @see BookshareHelper#bookshare_render_value
  #
  def member_render_value(item, value, **opt)
    bookshare_render_value(item, value, **opt)
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render a metadata listing of a member account.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #model_details.
  #
  def member_details(item, pairs: nil, **opt)
    opt[:model] = model = :member
    opt[:pairs] = Model.show_fields(model).merge(pairs || {})
    model_details(item, **opt)
  end

  # Render a listing of member preferences.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #render_field_values.
  #
  def member_preferences_values(item, pairs: nil, **opt)
    opt[:model]      = model = :member
    opt[:pairs]      = member_preference_fields(model).merge(pairs || {})
    opt[:row_offset] = opt.delete(:row) || opt[:row_offset]
    render_field_values(item, **opt)
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # CSS class for the container of the history lis.
  #
  # @type [String]
  #
  MEMBER_HISTORY_CSS_CLASS = 'history-list'

  # member_history_title
  #
  # @param [String, nil] label
  # @param [Hash]        opt          Passed to #html_tag except for:
  #
  # @option opt [Integer] :level      If missing, defaults to 'div'.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def member_history_title(label, opt = nil)
    css_selector  = '.list-heading'
    opt, html_opt = partition_hash(opt, :level)
    label ||= t('emma.member.history.title')
    html_tag(opt[:level], h(label), prepend_classes!(html_opt, css_selector))
  end

  # member_history_title
  #
  # @param [String] id                Control ID (@see #member_history)
  # @param [Hash]   opt               Passed to #toggle_button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def member_history_control(id:, **opt)
    toggle_button(id: id, **opt)
  end

  # Render of list of member activity entries.
  #
  # @param [Bs::Api::Record, Array<Bs::Record::TitleDownload>] item
  # @param [String]    id             Control ID (@see #member_history_control)
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to #render_field_values.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def member_history(item, id:, pairs: nil, **opt)
    css_selector  = '.history-item'
    item          = item.titleDownloads if item.respond_to?(:titleDownloads)
    opt[:model]   = model = :member
    opt[:pairs]   = member_history_fields(model).merge(pairs || {})
    opt[:index] ||= 0
    html_div(id: id, class: MEMBER_HISTORY_CSS_CLASS) do
      Array.wrap(item).map do |entry|
        opt[:index] += 1
        html_div(class: css_classes(css_selector, "row-#{opt[:index]}")) do
          render_field_values(entry, **opt)
        end
      end
    end
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #model_list_item.
  #
  def member_list_item(item, pairs: nil, **opt)
    opt[:model] = model = :member
    opt[:pairs] = Model.index_fields(model).merge(pairs || {})
    model_list_item(item, **opt)
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
