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
  # :section:
  # ===========================================================================

  public

  module Paths

    include AccountDecorator::Paths

    # =========================================================================
    # :section: AccountDecorator::Paths overrides
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

    def edit_select_path(**opt)
      h.edit_select_user_path(**opt)
    end

    def edit_path(item = nil, **opt)
      if opt[:selected]
        edit_select_path(**opt)
      else
        opt[:id] = id_for(item, **opt)
        h.edit_user_path(**opt)
      end
    end

    def update_path(item = nil, **opt)
      opt[:id] = id_for(item, **opt)
      h.update_user_path(**opt)
    end

  end

  module Methods

    include AccountDecorator::Methods

    # =========================================================================
    # :section: BaseDecorator::Configuration overrides
    # =========================================================================

    public

    # The start of a configuration YAML path (including the leading "emma.")
    #
    # @return [Symbol]
    #
    def model_config_base
      :account
    end

  end

  module InstanceMethods

    include AccountDecorator::InstanceMethods, Paths, Methods

    # =========================================================================
    # :section: BaseDecorator::InstanceMethods overrides
    # =========================================================================

    public

    # help_topic
    #
    # @return [Array<Symbol>]
    #
    def help_topic
      action = context[:action]
      action = nil if action == :index
      [:account, action].compact
    end

  end

  module ClassMethods
    include AccountDecorator::ClassMethods, Paths, Methods
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
  # :section: BaseDecorator::Menu overrides
  # ===========================================================================

  protected

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

__loading_end(__FILE__)
