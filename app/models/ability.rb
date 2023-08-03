# app/models/ability.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions for role-based authorization through CanCan.
#
# A method call like `can :read, :upload` basically assumes a few things:
# - There's an UploadController with typical CRUD endpoints.
# - The :read argument implies permission for the :index and :show endpoints.
# - The controller manipulates instances of the Upload resource.
#
class Ability

  include Emma::Common

  include CanCan::Ability

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The standard CRUD actions controller presumed by CanCan.
  #
  # @type [Array<Symbol>]
  #
  ACTIONS = %i[index show new edit destroy].freeze

  # Existing pre-defined action aliases.
  #
  # This does not include the :manage action (which is an implicit alias for
  # "all actions").
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  # @see CanCan::Ability::Actions#default_alias_actions
  # @see CanCan::Rule#matches_action?
  #
  PREDEFINED_ALIAS = {
    read:   %i[index show],
    create: %i[new],
    update: %i[edit],
  }.deep_freeze

  # Locally-defined aliases.
  #
  # Keys with empty values essentially document abilities that are used within
  # the code and are not actually used as CanCan aliases.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  LOCAL_ACTION_ALIAS = {

    # === Any controller

    delete:         %i[destroy],

    # === UploadController

    admin:          %i[manage],
    backup:         %i[records],
    cancel:         [],
    check:          [],
    reedit:         [],
    renew:          [],
    upload:         [],
    bulk_new:       %i[new create],
    bulk_edit:      %i[edit update],
    bulk_delete:    %i[destroy delete],
    bulk_create:    %i[bulk_new],
    bulk_update:    %i[bulk_edit],
    bulk_destroy:   %i[bulk_delete],

    # === UploadController

    download:       [],
    retrieval:      [],

    # === AccountController, User::*Controller

    #edit_select:    %i[edit],
    #delete_select:  %i[destroy],

    # === Any controller

    list:           %i[index],
    view:           %i[show retrieval],
    #modify:         %i[edit edit_select update],
    #remove:         %i[delete delete_select destroy],
    modify:         %i[edit update],
    remove:         %i[delete destroy],
    retrieve:       %i[download retrieval],

  }.deep_freeze

  # Both existing and new action aliases.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  ACTION_ALIAS = PREDEFINED_ALIAS.merge(LOCAL_ACTION_ALIAS).freeze

  # Models which are managed by CanCan (that is the model names implied by all
  # of the controllers which have "authorize_resource").
  #
  # For consistency, each of these should have an entry in
  # "en.unauthorized.manage" (config/locales/cancan.en.yml).
  #
  # @type [Array<Symbol>]
  #
  MODEL_NAMES = I18n.t('unauthorized.manage').except(:all).keys.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [User, nil] user
  #
  # === Usage Notes
  # Define abilities for the passed-in user here. For example:
  #
  #   user ||= User.new # guest user (not logged in)
  #   if user.admin?
  #     can :manage, :all
  #   else
  #     can :read, :all
  #   end
  #
  # The first argument to `can` is the action you are giving the user
  # permission to do.
  # If you pass :manage it will apply to every action. Other common actions
  # here are :read, :create, :update and :destroy.
  #
  # The second argument is the resource the user can perform the action on.
  # If you pass :all it will apply to every resource. Otherwise pass a Ruby
  # class of the resource.
  #
  # The third argument is an optional hash of conditions to further filter the
  # objects.
  # For example, here the user can only update published articles.
  #
  #   can :update, Article, :published => true
  #
  # See the wiki for details:
  # @see https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
  #
  def initialize(user)
    LOCAL_ACTION_ALIAS.each_pair do |name, actions|
      alias_action(*actions, to: name) unless actions.blank?
    end
    # noinspection RubyMismatchedArgumentType
    case Role.prototype_for(user)
      when :developer     then act_as_developer(user)
      when :administrator then act_as_administrator(user)
      when :dso           then act_as_dso(user)
      when :manager       then act_as_dso_delegate(user)
      when :librarian     then act_as_librarian(user)
      when :guest         then act_as_guest(user)
      else                     act_as_anonymous
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Assign the ability to perform as a system developer.
  #
  # @param [User] user
  #
  # @return [void]
  #
  # @see IdentityHelper#developer?
  #
  # === Usage Notes
  # This is functionally equivalent to :administrator in terms of the Ability
  # class. Wherever the distinction needs to be made, the user's role must be
  # explicitly checked.
  #
  def act_as_developer(user)
    act_as_administrator(user)
  end

  # Assign the ability to perform as a system administrator.
  #
  # @param [User] user
  #
  # @return [void]
  #
  #--
  # noinspection RubyUnusedLocalVariable
  #++
  def act_as_administrator(user)
    can :manage, :all
  end

  # Assign the ability to perform as a Disability Service Officer.
  #
  # @param [User] user
  #
  # @return [void]
  #
  def act_as_dso(user)
    act_as_dso_delegate(user)
    can :retrieve, Upload
  end

  # Assign the ability to perform as an assistant to a DSO (without permission
  # to download).
  #
  # @param [User] user
  #
  # @return [void]
  #
  # === Usage Notes
  # Currently, "DSO Delegate" is basically a synonym for "Librarian".
  #
  def act_as_dso_delegate(user)
    act_as_librarian(user)
  end

  # Assign the ability to perform as a librarian.
  #
  # @param [User] user
  #
  # @return [void]
  #
  # === Usage Notes
  # The current idea is that library staff might perform all of the entry
  # creation and maintenance functions that a DSO would (minus the ability to
  # download remediated content files).
  #
  def act_as_librarian(user)
    act_as_authenticated(user)
    can_manage_group_account(user) if user.has_role?(:manager)
    can_manage_own_entries(user)
    can_manage_group_entries(user)
  end

  # Assign the ability to perform as a member organization staff (without permission
  # to download).
  #
  # @param [User] user
  #
  # @return [void]
  #
  def act_as_staff(user)
    act_as_librarian(user)
  end

  # Assign the ability to perform as a signed-in user.
  #
  # @param [User] user
  #
  # @return [void]
  #
  def act_as_authenticated(user)
    act_as_guest(user)
    can_manage_own_account(user)
  end

  # Assign the ability to perform as a guest user.
  #
  # @param [User] user
  #
  # @return [void]
  #
  # === Usage Notes
  # Currently, "Guest" is basically a synonym for "Anonymous".
  #
  def act_as_guest(user)
    act_as_anonymous(user)
  end

  # Assign the ability to perform as an anonymous (unauthenticated) user.
  #
  # @return [void]
  #
  def act_as_anonymous(...)
    can :view,   Upload
    can :backup, Upload
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Allow full control over EMMA submissions which are associated with the
  # user's ID.
  #
  # @param [User] user
  #
  # @return [void]
  #
  def can_manage_own_account(user)
    can_manage_account(id: user.id)
  end

  # Allow full control over EMMA submissions which are associated with the
  # user's group ID.
  #
  # @param [User] user
  #
  # @return [void]
  #
  # @note This is not yet supported by any data model.
  #
  def can_manage_group_account(user)
    Log.debug { "#{__method__}: not implemented for #{user}" }
    # can_manage_records(User, group_id: user.group_id) # TODO: groups
  end

  # Define a set of capabilities on EMMA submissions which allows full control
  # over instances which meet the given constraints.
  #
  # @param [Class] model
  # @param [Hash]  with_constraints
  #
  # @return [void]
  #
  def can_manage_account(model = User, **with_constraints)
    can_manage(model, **with_constraints)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Allow full control over EMMA submissions which are associated with the
  # user's ID.
  #
  # @param [User] user
  #
  # @return [void]
  #
  def can_manage_own_entries(user)
    with_constraints = { user_id: user.id }
    can_manage_entries(**with_constraints)
    can_manage_bulk_operations(**with_constraints)
  end

  # Allow full control over EMMA submissions which are associated with the
  # user's group ID.
  #
  # @param [User] user
  #
  # @return [void]
  #
  # @note This is not yet supported by any data model.
  #
  def can_manage_group_entries(user)
    Log.debug { "#{__method__}: not implemented for #{user}" }
    # can_manage_entries(group_id: user.group_id) # TODO: institutional groups
  end

  # Define a set of capabilities on EMMA bulk operations which allows full
  # control over instances which meet the given constraints.
  #
  # @param [Hash] with_constraints
  #
  # @return [void]
  #
  def can_manage_bulk_operations(**with_constraints)
    can_manage_entries(Manifest,     **with_constraints)
    can_manage_entries(ManifestItem, **with_constraints)
  end

  # Define a set of capabilities on EMMA submissions which allows full control
  # over instances which meet the given constraints.
  #
  # @param [Class] model
  # @param [Hash]  with_constraints
  #
  # @return [void]
  #
  def can_manage_entries(model = Upload, **with_constraints)

    # === Basic record management
    can_manage_records(model, **with_constraints)

    # === Record modification
    can :start_edit,   model, **with_constraints
    can :finish_edit,  model, **with_constraints
    can :row_update,   model, **with_constraints
    can :reedit,       model, **with_constraints

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Allow full control over model instances which are associated with the
  # user's ID.
  #
  # @param [Class] model
  # @param [User]  user
  #
  # @return [void]
  #
  # @note Currently unused
  #
  def can_manage_own(model, user)
    can_manage(model, user_id: user.id)
  end

  # Allow full control over model instances which are associated with the
  # user's group ID.
  #
  # @param [Class] model
  # @param [User]  user
  #
  # @return [void]
  #
  # @note Currently unused
  # @note This is not yet supported by any data model.
  #
  def can_manage_group(model, user)
    Log.debug { "#{__method__}: not implemented for #{model} / #{user}" }
    # can_manage(model, group_id: user.group_id) # TODO: institutional groups
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Define a set of capabilities on a given model type which allows full
  # control over instances which meet the given constraints.
  #
  # @param [Class] model
  # @param [Hash]  with_constraints
  #
  # @return [void]
  #
  def can_manage_records(model, **with_constraints)

    # === Basic record management
    can_manage(model, **with_constraints)

    # === Record creation
    can :new,             model
    can :create,          model
    can :renew,           model
    can :bulk_new,        model
    can :bulk_create,     model

    # === Record workflow
    can :remit,           model
    can :remit_select,    model
    can :start,           model
    can :stop,            model
    can :pause,           model
    can :resume,          model
    can :get_job_result,  model

    # === Other
    can :upload,          model
    can :check,           model

  end

  # Define a set of capabilities on a given model type which allows basic
  # control over instances which meet the given constraints.
  #
  # @param [Class] model
  # @param [Hash]  with_constraints
  #
  # @return [void]
  #
  def can_manage(model, **with_constraints)

    # === List resources
    can :index,         model, **with_constraints
    can :list,          model, **with_constraints

    # === View resource
    can :show,          model
    can :view,          model

    # === Modify resource
    can :edit,          model, **with_constraints
    can :modify,        model, **with_constraints
    can :edit_select,   model, **with_constraints
    can :bulk_edit,     model, **with_constraints
    can :bulk_update,   model, **with_constraints
    can :bulk_fields,   model, **with_constraints

    # === Remove resource
    can :destroy,       model, **with_constraints
    can :remove,        model, **with_constraints
    can :delete_select, model, **with_constraints
    can :bulk_delete,   model, **with_constraints
    can :bulk_destroy,  model, **with_constraints

    # === Other
    can :save,          model
    can :cancel,        model

  end

  # ===========================================================================
  # :section: CanCan::Ability overrides
  # ===========================================================================

  public

  # Check if the user has permission to perform a given action on an object.
  #
  # Always *false* if *action* is *nil*.
  #
  # @param [Symbol, String, nil] action
  # @param [Object, Class, *]    subject
  # @param [*]                   extra_args
  #
  def can?(action, subject, *extra_args)
    action.blank? ? false : super(action.to_sym, subject, *extra_args)
  end

  # Returns the opposite of the #can? method.
  #
  # Always *true* if *action* is *nil*.
  #
  # @param [Symbol, String, nil] action
  # @param [Object, Class, *]    subject
  # @param [*]                   extra_args
  #
  def cannot?(action, subject, *extra_args)
    action.blank? || super(action.to_sym, subject, *extra_args)
  end

  # Add a rule allowing an action.
  #
  # @param [Symbol,String,Array,nil] action
  # @param [*]                       subject
  # @param [Array]                   conditions
  #
  # @return [void]
  #
  def can(action = nil, subject = nil, *conditions, &block)
    action, subject, conditions = prep_conditions(action, subject, conditions)
    all_actions_add(action, subject)
    super(action, subject, *conditions, &block)
  end

  # Add a rule forbidding an action.
  #
  # @param [Symbol,String,Array,nil] action
  # @param [*]                       subject
  # @param [Array]                   conditions
  #
  # @return [void]
  #
  def cannot(action = nil, subject = nil, *conditions, &block)
    action, subject, conditions = prep_conditions(action, subject, conditions)
    all_actions_remove(action, subject)
    super(action, subject, *conditions, &block)
  end

  # ===========================================================================
  # :section: CanCan::Ability extensions
  # ===========================================================================

  public

  # The constraints that apply to the Ability instance for the given
  # action/subject or *nil*.
  #
  # If *nil* is returned, `can?(action,subject)` applies to any applicable
  # record; otherwise, although #can? may return true, the current user is only
  # able to operate on records that match the constraint criteria.
  #
  # @param [Symbol, String, nil] action
  # @param [*]                   subject
  #
  # @return [ActiveRecord::Relation, Hash, Proc, nil]
  #
  def constrained_by(action, subject)
    action = action.presence&.to_sym or return
    rule =
      extract_subjects(subject).lazy.map { |a_subject|
        relevant_rules_for_match(action, a_subject).detect do |rule|
          rule.matches_conditions?(action, a_subject)
        end
      }.reject(&:nil?).first
    rule.conditions.presence || rule.block if rule
  end

  # ===========================================================================
  # :section: CanCan::Ability extensions
  # ===========================================================================

  private

  # Normalize values for use with #can? and #cannot?.
  #
  # @param [Symbol,String,Array,nil] action
  # @param [*]                       subject
  # @param [Array]                   conditions
  #
  # @return [Array<(*,*,*)>]
  #
  def prep_conditions(action, subject, conditions)
    action = action.compact.map!(&:to_sym) if action.is_a?(Array)
    action = action.to_sym                 if action.is_a?(String)
    conditions.compact_blank!
    conditions.map! { |arg| ApplicationRecord.normalize_id_keys(arg, subject) }
    return action, subject, conditions
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  delegate :all_actions,      :all_actions_keys,  to: :class
  delegate :all_actions_sort, :all_actions_for,   to: :class

  def all_actions_inspect
    all_actions_sort.transform_values { |list|
      list.map { |v| v.is_a?(Class) && v.try(:model_type) || v.inspect }.sort
    }.to_h.pretty_inspect
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  def self.all_actions
    # noinspection RbsMissingTypeSignature
    @all_actions ||= {}
  end

  def self.all_actions_sort
    # noinspection RbsMissingTypeSignature
    if defined?(@all_actions_sort)
      @all_actions_sort
    else
      @all_actions_sort = @all_actions = all_actions.sort.to_h
    end
  end

  def self.all_actions_keys
    # noinspection RbsMissingTypeSignature
    @all_actions_keys ||= all_actions_sort.keys
  end

  # @param [ApplicationRecord,Class] model
  def self.all_actions_for(model)
    keys  = all_actions_keys
    ctrlr = model.try(:model_controller)
    ctrlr ? keys.intersection(ctrlr.public_instance_methods(false)) : keys
  end

  def self.all_actions_add(action, subject)
    return unless subject
    Array.wrap(action).each do |act|
      all_actions[act] = [*all_actions[act], *subject].uniq
    end
  end

  def self.all_actions_remove(action, subject)
    return unless subject
    Array.wrap(action).each do |act|
      (list = all_actions[act]) && list.delete(subject) or next
      all_actions[act] = list.presence
    end
    all_actions.compact!
  end

  delegate :all_actions_add, :all_actions_remove, to: :class

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Models which are managed by CanCan
  #
  # @return [Array<Class>]
  #
  # @see #MODEL_NAMES
  #
  def self.models
    MODEL_NAMES.map { |model| to_class(model) }.compact
  end

end

__loading_end(__FILE__)
