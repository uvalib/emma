# app/decorators/user_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Item presenter for "/user" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [User]
#
class UserDecorator < AccountDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  decorator_for User

  # ===========================================================================
  # :section: Definitions shared with UsersDecorator
  # ===========================================================================

  public

  module SharedPathMethods

    include AccountDecorator::SharedPathMethods

    # =========================================================================
    # :section: AccountDecorator::SharedPathMethods overrides
    # =========================================================================

    public

    def index_path(*, **opt)
      h.user_registration_path(**opt)
    end

    def show_path(item = nil, **opt)
      opt[:id] = id_for(item, **opt)
      h.show_user_registration_path(**opt)
    end

    def new_path(*, **opt)
      h.new_user_path(**opt)
    end

    def create_path(*, **opt)
      h.create_user_path(**opt)
    end

    def edit_select_path(*, **opt)
      h.edit_select_user_path(**opt)
    end

    def edit_path(item = nil, **opt)
      return edit_select_path(item, **opt) if opt[:selected]
      opt[:id] = id_for(item, **opt)
      h.edit_user_path(**opt)
    end

    def update_path(item = nil, **opt)
      opt[:id] = id_for(item, **opt)
      h.update_user_path(**opt)
    end

    def delete_select_path(*)
      # NOTE: not applicable to this model
    end

    def delete_path(*)
      # NOTE: not applicable to this model
    end

    def destroy_path(*)
      # NOTE: not applicable to this model
    end

  end

  # Definitions available to both classes and instances of either this
  # decorator or its related collection decorator.
  #
  module SharedGenericMethods

    include AccountDecorator::SharedGenericMethods

    # =========================================================================
    # :section: BaseDecorator::Configuration overrides
    # =========================================================================

    public

    # The model associated with the decorator (Model#fields_table key).
    #
    # @return [Symbol]
    #
    def model_config_key
      :account
    end

    # =========================================================================
    # :section: BaseDecorator::Menu overrides
    # =========================================================================

    public

    # Generate a menu of user instances.
    #
    # @param [Hash] opt
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    def items_menu(**opt)
      opt[:user] ||= :all
      super(**opt)
    end

  end

  # Definitions available to instances of either this decorator or its related
  # collection decorator.
  #
  # (Definitions that are only applicable to instances of this decorator but
  # *not* to collection decorator instances are not included here.)
  #
  module SharedInstanceMethods

    include AccountDecorator::SharedInstanceMethods
    include SharedPathMethods
    include SharedGenericMethods

    # =========================================================================
    # :section: BaseDecorator::SharedInstanceMethods overrides
    # =========================================================================

    public

    # help_topic
    #
    # @param [Symbol, nil] sub_topic  Default: `context[:action]`.
    # @param [Symbol, nil] topic      Default: `model_type`.
    #
    # @return [Array<Symbol>]
    #
    def help_topic(sub_topic = nil, topic = nil)
      super(sub_topic, (topic || :account))
    end

  end

  # Definitions available to both this decorator class and the related
  # collector decorator class.
  #
  # (Definitions that are only applicable to this class but *not* to the
  # collection class are not included here.)
  #
  module SharedClassMethods
    include AccountDecorator::SharedClassMethods
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

class UserDecorator

  include SharedDefinitions

end

__loading_end(__FILE__)
