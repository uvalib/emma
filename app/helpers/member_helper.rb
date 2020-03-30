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
  MEMBER_CONFIGURATION      = model_configuration('emma.member').deep_freeze
  MEMBER_INDEX_FIELDS       = MEMBER_CONFIGURATION.dig(:index,       :fields)
  MEMBER_SHOW_FIELDS        = MEMBER_CONFIGURATION.dig(:show,        :fields)
  MEMBER_HISTORY_FIELDS     = MEMBER_CONFIGURATION.dig(:history,     :fields)
  MEMBER_PREFERENCES_FIELDS = MEMBER_CONFIGURATION.dig(:preferences, :fields)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Current page of member results.
  #
  # @return [Array<Bs::Record::UserAccount>]
  #
  def member_list
    page_items
  end

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
  # @param [Hash]            opt      Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If *item* is blank.
  #
  def member_details(item, opt = nil)
    pairs = MEMBER_SHOW_FIELDS.merge(opt || {})
    item_details(item, :member, pairs)
  end

  # Render a listing of member preferences.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #render_field_values
  #
  def member_preferences_values(item, opt = nil)
    pairs = MEMBER_PREFERENCES_FIELDS
    opt ||= {}
    render_field_values(item, model: :member, row_offset: opt[:row]) do
      pairs.merge(opt)
    end
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
  # @param [Hash]        opt          Passed to #content_tag except for:
  #
  # @option opt [Integer] :level
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def member_history_title(label, opt = nil)
    opt, html_opt = partition_options(opt, :level)
    level = opt[:level].to_i
    label ||= t('emma.member.history.title')
    prepend_css_classes!(html_opt, 'list-heading')
    tag = level.zero? ? 'div' : "h#{level}"
    content_tag(tag, h(label), html_opt)
  end

  # member_history_title
  #
  # @param [Hash] opt                 Passed to #toggle_button
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def member_history_control(**opt)
    opt[:selector] = ".#{MEMBER_HISTORY_CSS_CLASS}"
    toggle_button(**opt)
  end

  # Render of list of member activity entries.
  #
  # @param [Bs::Api::Record, Array<Bs::Record::TitleDownload>] item
  # @param [Hash] opt                 Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #render_field_values
  #
  def member_history(item, opt = nil)
    item  = item.titleDownloads if item.respond_to?(:titleDownloads)
    pairs = MEMBER_HISTORY_FIELDS.merge(opt || {})
    content_tag(:div, class: MEMBER_HISTORY_CSS_CLASS) do
      pairs[:index] = 0
      Array.wrap(item).map { |entry|
        pairs[:index] += 1
        content_tag(:div, class: "history-entry row-#{pairs[:index]}") do
          render_field_values(entry, model: :member, pairs: pairs)
        end
      }.join("\n").html_safe
    end
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Bs::Api::Record] item
  # @param [Hash]            opt      Additional field mappings.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def member_list_entry(item, opt = nil)
    pairs = MEMBER_INDEX_FIELDS.merge(opt || {})
    item_list_entry(item, :member, pairs)
  end

end

__loading_end(__FILE__)
