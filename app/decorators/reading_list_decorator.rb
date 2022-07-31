# app/decorators/reading_list_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/reading_list" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Bs::Record::ReadingListUserView]
#
class ReadingListDecorator < BookshareDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for reading_list: Bs::Record::ReadingListUserView, and: ReadingList

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Paths
    include BookshareDecorator::Paths
  end

  # Definitions available to both classes and instances of either this
  # decorator or its related collection decorator.
  #
  module Methods
    include BookshareDecorator::Methods
  end

  # Definitions available to instances of either this decorator or its related
  # collection decorator.
  #
  # (Definitions that are only applicable to instances of this decorator but
  # *not* to collection decorator instances are not included here.)
  #
  module InstanceMethods
    include BookshareDecorator::InstanceMethods, Paths, Methods
  end

  # Definitions available to both this decorator class and the related
  # collector decorator class.
  #
  # (Definitions that are only applicable to this class but *not* to the
  # collection class are not included here.)
  #
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

  # titles_data
  #
  # @return [Bs::Message::ReadingListTitlesList, nil]
  #
  def titles_data
    context[:titles]
  end

  # titles
  #
  # @return [Array<Bs::Record::ReadingListTitle>]
  #
  def titles
    @titles ||=
      titles_data.then { |titles| titles&.try(:lists) || Array.wrap(titles) }
  end

  # ===========================================================================
  # :section: BaseDecorator::Links overrides
  # ===========================================================================

  public

  # Create a link to the details show page for the given item.
  #
  # @param [Hash] opt                 Passed to super except for:
  #
  # @option opt [String] :readingListId
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def link(**opt)
    reading_list = opt.delete(:readingListId) || object.identifier
    opt[:path]   = show_path(id: reading_list)
    super(**opt)
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Transform a field value for HTML rendering.
  #
  # @param [Any]       value
  # @param [Symbol, *] field
  # @param [Hash]      opt            Passed to the render method or super.
  #
  # @return [Any]                     HTML or scalar value.
  # @return [nil]                     If *value* or *object* is *nil*.
  #
  def render_value(value, field:, **opt)
    if present?
      # noinspection RubyCaseWithoutElseBlockInspection
      case field_category(field || value)
        when :name         then link(**opt)
        when :label        then link(**opt)
        when :subscription then subscriptions(**opt)
      end
    end || super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Show reading list subscriptions.
  #
  # NOTE: The Bookshare API doesn't seem to provide useful information here.
  #
  # @param [Hash] opt                 Passed to #record_links.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def subscriptions(**opt)
    subscription = object.try(:subscription)
    record_links(subscription.links, **opt) if subscription&.enabled
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Render a metadata listing of a reading list.
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

  # details_element
  #
  # @param [Integer, nil]        level
  # @param [String, Symbol, nil] role
  # @param [Hash]                opt    Passed to #details.
  # @param [Proc]                block  Passed to #html_join.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def details_element(level: nil, role: nil, **opt, &block)
    role ||= (:article if level == 1)
    skip   = Array.wrap(opt.delete(:skip))
    list   = (''.html_safe if skip.include?(:titles))
    list ||= title_list(level: (level + 1), skip: skip)
    added  = block ? h.capture(&block) : ''
    html_div(class: "#{model_type}-container", role: role) do
      details(**opt) << list << added
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A sub-section displaying the titles in the reading list.
  #
  # @param [Hash] **opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def title_list(**opt)
    css    = 'title-list'
    skip   = Array.wrap(opt.delete(:skip))
    level  = opt.delete(:level)  || 1
    count  = opt.delete(:count)  || titles.size

    # A heading for the sub-section.
    title  = 'Reading List Titles' # TODO: I18n
    title += " (#{count})" unless skip.include?(:count)
    h_opt  = { class: 'list-heading' }
    append_css!(h_opt, 'empty') if count.zero?
    title  = html_tag(level, title, h_opt)

    # The list of titles.
    l_opt  = { skip: skip, count: count, level: (level + 1) }
    list   = TitlesDecorator.new(titles).render(**l_opt)

    opt[:role] = 'complementary' if level > 1
    prepend_css!(opt, css)
    html_div(opt) do
      title << list
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
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Control whether thumbnails are shown for reading list entries.
  #
  # @type [Boolean]
  #
  FIND_THUMBNAIL = true

  # get_thumbnail_image
  #
  # NOTE: ReadingListTitle does not (currently) include a thumbnail link.
  #
  # As long as this is still the case, this method will discover the link by
  # explicitly by fetching the catalog item.
  #
  # If #FIND_THUMBNAIL is *false*, this method always returns *nil*.
  #
  # @return [String, nil]
  #
  def get_thumbnail_image(**)
    super || (super(meth: :find_thumbnail) if FIND_THUMBNAIL)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Attempt to fetch the thumbnail image associated with the item.
  #
  # @param [Bs::Api::Record] item
  #
  # @return [String, nil]
  #
  def find_thumbnail(item = nil)
    item ||= object
    # noinspection RailsParamDefResolve
    id = item.try(:bookshareId)
    id && h.bs_api.get_title(bookshareId: id, no_raise: true)&.thumbnail_image
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
      opt[:id] ||= context[:readingListId] || object.try(:readingListId)
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
      when :edit, :delete then 'catalog title metadata' # TODO: I18n
      else                     'a catalog title'        # TODO: I18n
    end
  end

end

__loading_end(__FILE__)
