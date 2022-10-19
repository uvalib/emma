# app/decorators/periodical_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/periodical" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Bs::Record::PeriodicalSeriesMetadataSummary]
#
class PeriodicalDecorator < BookshareDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for periodical: Bs::Record::PeriodicalSeriesMetadataSummary,
                and: Periodical

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

  # editions_data
  #
  # @return [Bs::Message::PeriodicalEditionList, nil]
  #
  def editions_data
    context[:editions]
  end

  # editions
  #
  # @return [Array<Bs::Record::PeriodicalEdition>]
  #
  def editions
    @editions ||=
      editions_data.then { |v| v&.try(:periodicalEditions) || Array.wrap(v) }
  end

  # ===========================================================================
  # :section: BaseDecorator::Links overrides
  # ===========================================================================

  public

  # Create a link to the details show page for the given item.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def link(**opt)
    opt[:path] = show_path(id: object.identifier)
    super(**opt)
  end

  # ===========================================================================
  # :section: BookshareDecorator overrides
  # ===========================================================================

  public

  # Catalog item search links.
  #
  # @param [Hash] opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def search_links(**opt)
    opt[:field] ||= :title
    super(**opt)
  end

  # Create a link to the search results index page for the given term(s).
  #
  # @param [String] terms
  # @param [Hash]   opt
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def search_link(terms, **opt)
    opt[:field] ||= :title
    super(terms, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a link to latest periodical edition.
  #
  # @param [Hash] opt                 Passed to EditionDecorator#link.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def latest_edition_link(**opt)
    edition = object.latestEdition.presence or return
    ctx     = context.except(:action)
    EditionDecorator.new(edition, context: ctx).link(**opt)
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
    if present?
      # noinspection RubyCaseWithoutElseBlockInspection
      case field_category(field || value)
        when :latestEdition then latest_edition_link(**opt)
      end
    end || super
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Render a metadata listing of an periodical.
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
    list   = (''.html_safe if skip.include?(:editions))
    list ||= edition_list(level: (level + 1), skip: skip)
    added  = block ? h.capture(&block) : ''
    html_div(class: "#{model_type}-container", role: role) do
      details(**opt) << list << added
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # A sub-section displaying the editions for the periodical.
  #
  # @param [Hash] **opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def edition_list(**opt)
    css    = 'edition-list'
    skip   = Array.wrap(opt.delete(:skip))
    level  = opt.delete(:level)  || 1
    count  = opt.delete(:count)  || editions.size

    # A heading for the sub-section.
    title  = 'Periodical Editions' # TODO: I18n
    title += " (#{count})" unless skip.include?(:count)
    h_opt  = { class: 'list-heading' }
    append_css!(h_opt, 'empty') if count.zero?
    title  = html_tag(level, title, h_opt)

    # The list of titles.
    l_opt  = { skip: skip, count: count, level: (level + 1) }
    list   = EditionsDecorator.new(editions).render(**l_opt)

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
      opt[:id] ||= context[:seriesId] || object.try(:seriesId)
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
      when :edit, :delete then 'periodical metadata' # TODO: I18n
      else                     'a periodical'        # TODO: I18n
    end
  end

end

__loading_end(__FILE__)
