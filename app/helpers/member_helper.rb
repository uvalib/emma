# app/helpers/member_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# MemberHelper
#
module MemberHelper

  def self.included(base)
    __included(base, '[MemberHelper]')
  end

  include ModelHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configuration values for this model.
  #
  # @type {Hash{Symbol=>Hash}}
  #
  MEMBER_CONFIGURATION      = Model.configuration('emma.member').deep_freeze
  MEMBER_INDEX_FIELDS       = MEMBER_CONFIGURATION.dig(:index,       :fields)
  MEMBER_SHOW_FIELDS        = MEMBER_CONFIGURATION.dig(:show,        :fields)
  MEMBER_HISTORY_FIELDS     = MEMBER_CONFIGURATION.dig(:history,     :fields)
  MEMBER_PREFERENCES_FIELDS = MEMBER_CONFIGURATION.dig(:preferences, :fields)

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
  # @param [Hash]            opt      Passed to #item_link.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def member_link(item, **opt)
    opt[:path]    = member_path(id: url_escape(item.identifier))
    opt[:tooltip] = MEMBER_SHOW_TOOLTIP
    item_link(item, **opt)
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render an item metadata listing.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #item_details.
  #
  def member_details(item, pairs: nil, **opt)
    opt[:model] = :member
    opt[:pairs] = MEMBER_SHOW_FIELDS.merge(pairs || {})
    item_details(item, **opt)
  end

  # Render a listing of member preferences.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash, nil]       pairs    Additional field mappings.
  # @param [Hash]            opt      Passed to #render_field_values.
  #
  def member_preferences_values(item, pairs: nil, **opt)
    opt[:model]      = :member
    opt[:pairs]      = MEMBER_PREFERENCES_FIELDS.merge(pairs || {})
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
    opt, html_opt = partition_options(opt, :level)
    label ||= t('emma.member.history.title')
    prepend_css_classes!(html_opt, 'list-heading')
    html_tag(opt[:level], h(label), html_opt)
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
    item = item.titleDownloads if item.respond_to?(:titleDownloads)
    opt[:model]   = :member
    opt[:pairs]   = MEMBER_HISTORY_FIELDS.merge(pairs || {})
    opt[:index] ||= 0
    html_div(id: id, class: MEMBER_HISTORY_CSS_CLASS) do
      Array.wrap(item).map do |entry|
        opt[:index] += 1
        html_div(class: "history-entry row-#{opt[:index]}") do
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
  # @param [Hash]            opt      Passed to #item_list_entry.
  #
  def member_list_entry(item, pairs: nil, **opt)
    opt[:model] = :member
    opt[:pairs] = MEMBER_INDEX_FIELDS.merge(pairs || {})
    item_list_entry(item, **opt)
  end

end

__loading_end(__FILE__)
