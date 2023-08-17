# app/decorators/org_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/org" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Org]
#
class OrgDecorator < BaseDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for Org

  # ===========================================================================
  # :section: Definitions shared with OrgsDecorator
  # ===========================================================================

  public

  module SharedPathMethods
    include BaseDecorator::SharedPathMethods
  end

  # Definitions available to both classes and instances of either this
  # decorator or its related collection decorator.
  #
  module SharedGenericMethods

    include BaseDecorator::SharedGenericMethods

    # =========================================================================
    # :section: BaseDecorator::Menu overrides
    # =========================================================================

    public

    # Generate a menu of org instances.
    #
    # @param [Hash] opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def items_menu(**opt)
      unless administrator?
        hash = opt[:constraints]&.dup || {}
        user = hash.extract!(:user, :user_id).compact.values.first
        org  = hash.extract!(:org, :org_id).compact.values.first
        if !user && !org && (org = current_org).present?
          added = { org: org }
          opt[:constraints] = added.merge!(hash)
        end
      end
      opt[:sort] ||= { id: :asc }
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
      'Select an EMMA member organization' # TODO: I18n
    end

    # Generate a label for a specific menu entry.
    #
    # @param [Manifest]    item
    # @param [String, nil] label      Override label.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def items_menu_label(item, label: nil)
      label ||= item.menu_label
      label ||= "#{model_item_name(capitalize: true)} #{item.id}"
      ERB::Util.h(label)
    end

    # Descriptive term for an item of the given type.
    #
    # @param [Symbol, String, nil] model        Default: `#model_type`.
    # @param [Boolean]             capitalize
    #
    # @return [String]
    #
    def model_item_name(model: nil, capitalize: true)
      model ? super : 'EMMA Member Organization' # TODO: I18n
    end

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

    # =========================================================================
    # :section: BaseDecorator::SharedInstanceMethods overrides
    # =========================================================================

    public

    # options
    #
    # @return [Org::Options]
    #
    def options
      context[:options] || Org::Options.new
    end

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

class OrgDecorator

  include SharedDefinitions

end

__loading_end(__FILE__)
