# app/decorators/edition_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/edition" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Bs::Record::PeriodicalEdition]
#
class EditionDecorator < BookshareDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for edition: Bs::Record::PeriodicalEdition, and: Edition

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
  # :section: BaseDecorator::Links overrides
  # ===========================================================================

  public

  # Create a link to the details show page for the given item.
  #
  # @param [Hash] opt                 Passed to super except for:
  #
  # @option opt [String] :editionId
  # @option opt [String] :edition       Alias for :editionId
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def link(**opt)
    local = extract_hash!(opt, :editionId, :edition)
    if (eid = local.values.first).present?
      opt[:path]    = "#edition-#{eid}" # TODO: edition show page?
    else
      opt[:no_link] = true
    end
    super(**opt)
  end

  # ===========================================================================
  # :section: BaseDecorator::List overrides
  # ===========================================================================

  public

  # Render a metadata listing of an edition.
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
    # noinspection RailsParamDefResolve
    unless opt[:action] == :new
      opt[:id]       ||= context[:editionId] || object.try(:editionId)
      opt[:seriesId] ||= context[:seriesId]  || object.try(:seriesId)
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
      when :edit, :delete then 'edition metadata' # TODO: I18n
      else                     'an edition'       # TODO: I18n
    end
  end

end

__loading_end(__FILE__)
