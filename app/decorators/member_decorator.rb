# app/decorators/member_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/member" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Bs::Record::UserAccount]
#
class MemberDecorator < BookshareDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for member: Bs::Record::UserAccount, and: Member

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Paths
    include BookshareDecorator::Paths
  end

  module Methods
    include BookshareDecorator::Methods
  end

  module InstanceMethods
    include BookshareDecorator::InstanceMethods, Paths, Methods
  end

  module ClassMethods
    include BookshareDecorator::ClassMethods, Paths, Methods
  end

  # Cause definitions to be included here and in the associated collection
  # decorator via BaseCollectionDecorator#collection_of.
  #
  module Common
    def self.included(base)
      base.include(InstanceMethods)
      base.extend(ClassMethods)
    end
  end

  include Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # history_data
  #
  # @return [Bs::Message::TitleDownloadList, nil]
  #
  def history_data
    @history_data ||= context_value(:history, :hist)
  end

  # downloads
  #
  # @return [Array<Bs::Record::TitleDownload>]
  #
  def downloads
    @dl ||= history_data.then { |v| v&.try(:titleDownloads) || Array.wrap(v) }
  end

  # preference_data
  #
  # @return [Bs::Message::MyAccountPreferences, nil]
  #
  def preference_data
    @preference_data ||= context_value(:preference, :pref)
  end

  # preferences
  #
  # @return [Bs::Message::MyAccountPreferences, nil]
  #
  def preferences
    preference_data
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Configured member history record fields.
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def history_fields(...)
    model_config[:history] || {}
  end

  # Configured member preference record fields.
  #
  # @return [Hash{Symbol=>Hash}]      Frozen result.
  #
  def preference_fields(...)
    model_config[:preferences] || {}
  end

  # ===========================================================================
  # :section: BaseDecorator::Links overrides
  # ===========================================================================

  public

  # Create a link to the details show page for the given item.
  #
  # NOTE: Over-encoded to allow ID's with '.' to be passed to Rails.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def link(**opt)
    opt[:path] = show_path(id: url_escape(object.identifier))
    super(**opt)
  end

  # This is specifically for the sake of "emma.member.*.display_fields" which
  # expect the view helper to have defined :member_link.
  alias member_link link

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Render a metadata listing of a member account.
  #
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def details(pairs: nil, **opt)
    opt[:pairs] = model_show_fields.merge(pairs || {})
    super(**opt)
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # Render a listing of member preferences.
  #
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to #render_field_values.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def preference_list(pairs: nil, **opt)
    prefs            = preference_decorator(preferences) or return ''.html_safe
    opt[:pairs]      = preference_fields.merge(pairs || {})
    opt[:row_offset] = opt.delete(:row) || opt[:row_offset]
    prefs.render_field_values(**opt)
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  protected

  # Create a decorator variant for preference values.
  #
  # @param [Bs::Message::MyAccountPreferences, nil] prefs
  #
  # @return [BookshareDecorator, nil]
  #
  def preference_decorator(prefs)
    prefs && BookshareDecorator.new(prefs, context: context)
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  public

  # CSS class for the container of the history lis.
  #
  # @type [String]
  #
  HISTORY_CSS_CLASS = 'history-list'

  # history_title
  #
  # @param [String, nil] label
  # @param [Hash]        opt          Passed to #html_tag except for:
  #
  # @option opt [Integer] :level      If missing, defaults to 'div'.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def history_title(label, opt = nil)
    css      = '.list-heading'
    label  ||= config_lookup('history.title')
    html_opt = remainder_hash!(opt, :level)
    prepend_css!(html_opt, css)
    html_tag(opt[:level], label, html_opt)
  end

  # history_control
  #
  # @param [String] id                Control ID (@see #history_list)
  # @param [Hash]   opt               Passed to PanelHelper#toggle_button.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def history_control(id:, **opt)
    toggle_button(id: id, **opt)
  end

  # Render of list of member activity entries.
  #
  # @param [String]    id             Control ID (@see #history_control)
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to #render_field_values.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def history_list(id:, pairs: nil, **opt)
    css = '.history-item'
    opt[:pairs]   = history_fields.merge(pairs || {})
    opt[:index] ||= 0
    html_div(id: id, class: HISTORY_CSS_CLASS) do
      downloads.map do |download|
        next unless (entry = history_decorator(download))
        opt[:index] += 1
        html_div(class: css_classes(css, "row-#{opt[:index]}")) do
          entry.render_field_values(**opt)
        end
      end
    end
  end

  # ===========================================================================
  # :section: Item details (show page) support
  # ===========================================================================

  protected

  # Create a decorator variant which will handle the :title field appropriately
  # for history entries.
  #
  # @param [Bs::Record::TitleDownload, nil] download
  #
  # @return [BookshareDecorator, nil]
  #
  def history_decorator(download)
    return unless download
    ctx = context.except(:action)
    BookshareDecorator.new(download, context: ctx).tap do |decorator|
      decorator.instance_eval do

        # Override of BookshareDecorator#render_value that avoids the default
        # handling of the :title field.
        def render_value(value, field:, **opt)
          opt[:no_link] = true
          if present?
            # noinspection RubyCaseWithoutElseBlockInspection
            case field_category(field || value)
              when :title then super(value, field: :downloaded_title, **opt)
            end
          end || super
        end

        # The method that will be run by BaseDecorator::List#execute when it
        # fails to find it for the instance of Bs::Record::TitleDownload.
        def downloaded_title
          object.title.to_s.presence
        end

      end
    end
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Render a single entry for use within a list of items.
  #
  # @param [Hash, nil] pairs          Additional field mappings.
  # @param [Hash]      opt            Passed to super.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def list_item(pairs: nil, **opt)
    opt[:pairs] = model_index_fields.merge(pairs || {})
    super(**opt)
  end

  # ===========================================================================
  # :section: BookshareDecorator overrides
  # ===========================================================================

  protected

  # form_action_link
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def form_action_link(**opt)
    unless opt[:action] == :new
      opt[:id] ||= context[:memberId]
      opt[:id] ||= context[:userAccountId] || object.try(:userAccountId)
    end
    super(**opt)
  end

  # form_target_description
  #
  # @param [Symbol] action
  #
  # @return [String]
  #
  def form_target_description(action: nil, **)
    case action
      when :edit then 'member information'     # TODO: I18n
      else            'an organization member' # TODO: I18n
    end
  end

end

__loading_end(__FILE__)
