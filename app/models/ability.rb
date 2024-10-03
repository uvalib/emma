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
#--
# noinspection RubyTooManyMethodsInspection
#++
class Ability

  include Emma::Common
  include Emma::TypeMethods
  include CanCan::Ability
  include Ability::Role
  include IdMethods

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

    # === HomeController

    dashboard:      %i[],

    # === UploadController

    admin:          %i[manage],
    backup:         %i[records],
    cancel:         [],
    check:          [],
    download:       [],
    reedit:         [],
    renew:          [],
    retrieval:      [],
    upload:         [],

    # === UploadController, ManifestItemController

    bulk_new:       %i[new create],
    bulk_edit:      %i[edit update],
    bulk_delete:    %i[destroy delete],
    bulk_create:    %i[bulk_new],
    bulk_update:    %i[bulk_edit],
    bulk_destroy:   %i[bulk_delete],

    # === AccountController, OrgController

    show_current:   [],
    edit_current:   [],

    # === Any controller

    list:           %i[index],
    list_all:       [],
    list_org:       [],
    list_own:       [],
    view:           %i[show retrieval probe_retrieval],
    modify:         %i[edit update],
    remove:         %i[delete destroy],
    retrieve:       %i[download retrieval probe_retrieval],

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
  MODEL_NAMES = %i[user org upload manifest manifest_item search_call].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [User, nil] user
  # @param [*, nil]    role
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
  def initialize(user = nil, role = nil)
    LOCAL_ACTION_ALIAS.each_pair do |name, actions|
      alias_action(*actions, to: name) unless actions.blank?
    end
    user, role = [nil, user] unless user.is_a?(User) || role.nil?
    # noinspection RubyMismatchedVariableType
    @role = RolePrototype.cast(user&.role || role)
    @role = RolePrototype(:anonymous) unless @role&.valid?
    # noinspection RubyMismatchedArgumentType
    case @role.to_sym
      when :developer     then act_as_developer(user)
      when :administrator then act_as_administrator(user)
      when :manager       then act_as_manager(user)
      when :member        then act_as_full_member(user)
      when :staff         then act_as_staff(user)
      when :guest         then act_as_guest(user)
      else                     act_as_anonymous
    end
  end

  # @type [RolePrototype]
  attr_reader :role

  # The role capabilities associated with the Ability instance.
  #
  # @return [Array<RoleCapability>]
  #
  def capabilities
    @capabilities ||= CAPABILITIES[role.to_sym].map { RoleCapability(_1) }
  end

  alias :role_prototype    :role
  alias :role_capabilities :capabilities

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
  def act_as_developer(user, **)
    act_as_administrator(user)
  end

  # Assign the ability to perform as a system administrator.
  #
  # @param [User] _user               Unused.
  #
  # @return [void]
  #
  def act_as_administrator(_user, **)
    can :manage, :all
    cannot :show_current, Org
    cannot :edit_current, Org
    cannot :list_org,     :all
  end

  # Assign the ability to perform as an EMMA member organization manager.
  #
  # @param [User] user
  # @param [Hash] constraints
  #
  # @return [void]
  #
  def act_as_manager(user, **constraints)
    constraints[:meth] ||= __method__
    set_org!(constraints, user) or return
    act_as_full_member(user, **constraints)
    can_manage_user(**constraints)
    can_manage_org(**constraints)
    cannot :edit_select,   Org
    cannot :delete_select, Org
  end

  # Assign the ability to perform as an EMMA member organization full user who
  # is able to upload and download items.
  #
  # @param [User] user
  # @param [Hash] constraints
  #
  # @return [void]
  #
  def act_as_full_member(user, **constraints)
    constraints[:meth] ||= __method__
    act_as_staff(user, **constraints)
    can :download, Upload
    can :retrieve, Upload
  end

  # Assign the ability to perform as an EMMA member organization staff user who
  # is able to upload items but without the permission to download.
  #
  # @param [User] user
  # @param [Hash] constraints
  #
  # @return [void]
  #
  def act_as_staff(user, **constraints)
    constraints[:meth] ||= __method__
    act_as_guest(user, **constraints)
    can_manage_account(user, **constraints)
    can_manage_user_submissions(user, **constraints)
    can_manage_group_submissions(user, **constraints)
  end

  # Assign the ability to perform as a guest of an EMMA member organization.
  #
  # @param [User] user
  # @param [Hash] constraints
  #
  # @return [void]
  #
  def act_as_guest(user, **constraints)
    constraints[:meth] ||= __method__
    act_as_anonymous(user, **constraints)
    act_as_org_user(user, **constraints)
    can :dashboard, :all
  end

  # Assign the ability to perform as an anonymous (unauthenticated) user.
  #
  # @return [void]
  #
  def act_as_anonymous(...)
    can :show,   Upload
    can :backup, Upload
    can :create, Enrollment
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Allow visibility into an EMMA member organization and its users.
  #
  # @param [User] user
  # @param [Hash] constraints
  #
  # @return [void]
  #
  def act_as_org_user(user, **constraints)
    constraints[:meth] ||= __method__
    set_org!(constraints, user) or return
    can_view_content(Org,  **constraints)
    can_view_content(User, **constraints)
    can_view_group_submissions(user, **constraints)
  end

  # ===========================================================================
  # :section: Identity
  # ===========================================================================

  protected

  # Allow full (user-level) control over a single EMMA user account.
  #
  # @param [User, nil] user
  # @param [Hash]      constraints
  #
  # @return [void]
  #
  def can_manage_account(user, **constraints)
    meth = constraints[:meth] || __method__
    if user.is_a?(User)
      can_manage_user(user, **constraints)
    else
      Log.debug { "#{meth}: #{user.inspect}: not a User" }
    end
  end

  # Allow full (user-level) control over EMMA user account(s).
  #
  # @param [User, Integer, nil] user
  # @param [Hash]               constraints
  #
  # @option constraints [Integer] :id
  # @option constraints [User]    :user
  # @option constraints [Integer] :user_id
  #
  # @return [void]
  #
  def can_manage_user(user = nil, **constraints)
    constraints[:user] = user if user
    can_manage_identity(User, **constraints)
    user = constraints.extract!(*identity_keys(User)).values.first
    org  = constraints.extract!(*identity_keys(Org)).values.first || user&.org
    constraints[:org] ||= org || user&.org or return
    can :index,    User, constraints
    can :list,     User, constraints
    can :list_org, User, constraints
  end

  # Allow full (user-level) control over an EMMA member organization.
  #
  # @param [Org, Integer, nil] org
  # @param [Hash]              constraints
  #
  # @option constraints [Integer] :id
  # @option constraints [Org]     :org
  # @option constraints [Integer] :org_id
  #
  # @return [void]
  #
  def can_manage_org(org = nil, **constraints)
    constraints[:org] = org if org
    can_manage_identity(Org, **constraints)
  end

  # Allow full (user-level) control over identity records.
  #
  # @param [Class] model
  # @param [Hash]  constraints
  #
  # @return [void]
  #
  def can_manage_identity(model, **constraints)
    keys = identity_keys(model)
    obj  = constraints.extract!(*keys).compact.values.first
    if obj.present?
      constraints[model.model_key] = obj
      can_manage_content(model, **constraints)
    else
      can_manage_records(model, **constraints)
    end
  end

  # ===========================================================================
  # :section: Submissions
  # ===========================================================================

  protected

  # Allow full control over EMMA submissions which are associated with the
  # user's ID.
  #
  # @param [User] user
  # @param [Hash] constraints
  #
  # @return [void]
  #
  def can_manage_user_submissions(user, **constraints)
    constraints[:user] = user
    can_manage_submissions(**constraints)
    can_manage_bulk_submissions(**constraints)
  end

  # Allow full control over EMMA submissions which are associated with the
  # user's organization.
  #
  # @param [User] user
  # @param [Hash] constraints
  #
  # @return [void]
  #
  def can_manage_group_submissions(user, **constraints)
    constraints[:meth] ||= __method__
    set_org!(constraints, user) or return
    can_manage_submissions(**constraints)
    can_manage_bulk_submissions(**constraints)
  end

  # Define a set of capabilities on EMMA bulk operations which allows full
  # control over instances which meet the given constraints.
  #
  # @param [Hash] constraints
  #
  # @return [void]
  #
  def can_manage_bulk_submissions(**constraints)
    can_manage_submissions(Manifest,     **constraints)
    can_manage_submissions(ManifestItem, **constraints)
  end

  # Define a set of capabilities on EMMA submissions which allows full control
  # over instances which meet the given constraints.
  #
  # @param [Class] model
  # @param [Hash]  constraints
  #
  # @return [void]
  #
  def can_manage_submissions(model = Upload, **constraints)
    constraints[:meth] ||= __method__

    # === Basic record management
    can_manage_records(model, **constraints)

    # === Record modification
    can :start_edit,  model, constraints
    can :finish_edit, model, constraints
    can :row_update,  model, constraints
    can :reedit,      model, constraints

  end

  # Allow visibility to EMMA submissions which are associated with the user's
  # organization.
  #
  # @param [User] user
  # @param [Hash] constraints
  #
  # @return [void]
  #
  def can_view_group_submissions(user, **constraints)
    constraints[:meth] ||= __method__
    set_org!(constraints, user) or return
    can_view_submissions(**constraints)
    can_view_bulk_submissions(**constraints)
  end

  # Allow visibility to EMMA bulk submissions which are associated with the
  # user's organization.
  #
  # @param [Hash] constraints
  #
  # @return [void]
  #
  def can_view_bulk_submissions(**constraints)
    can_view_submissions(Manifest,     **constraints)
    can_view_submissions(ManifestItem, **constraints)
  end

  # Allow visibility to instances of a model related to EMMA submissions.
  #
  # @param [Class] model
  # @param [Hash]  constraints
  #
  # @return [void]
  #
  def can_view_submissions(model = Upload, **constraints)
    can_view_content(model, **constraints)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Define a set of capabilities on a given model type which allows full
  # control over instances which meet the given constraints.
  #
  # @param [Class] model
  # @param [Hash]  constraints
  #
  # @return [void]
  #
  def can_manage_records(model, **constraints)
    constraints[:meth] ||= __method__
    no_bulk = constraints[:no_bulk]
    no_bulk = set_no_bulk!(constraints, model, 'no_bulk for') if no_bulk.nil?

    # === Basic record management
    can_manage_content(model, **constraints)

    # === Record creation
    can :new,           model
    can :create,        model
    can :renew,         model
    can :bulk_new,      model
    can :bulk_create,   model

    # === Record deletion
    can :delete_select, model, constraints
    can :delete,        model, constraints
    can :destroy,       model, constraints
    can :remove,        model, constraints
    can :bulk_delete,   model, constraints unless no_bulk
    can :bulk_destroy,  model, constraints unless no_bulk

    # === Record workflow
    can :remit_select,  model, constraints
    can :remit,         model, constraints
    can :start,         model
    can :stop,          model
    can :pause,         model
    can :resume,        model

    # === Other
    can :upload,        model
    can :check,         model

  end

  # Define a set of capabilities on a given model type which allows basic
  # control over instances which meet the given constraints.
  #
  # This includes modification of records, but not creation or deletion.
  #
  # @param [Class] model
  # @param [Hash]  constraints
  #
  # @return [void]
  #
  def can_manage_content(model, **constraints)
    constraints[:meth] ||= __method__
    no_bulk = constraints[:no_bulk]
    no_bulk = set_no_bulk!(constraints, model, 'limited by') if no_bulk.nil?

    # === List/view resources
    can_view_content(model, **constraints)

    # === Modify resource
    can :edit_current,    model, constraints
    can :edit_select,     model, constraints
    can :edit,            model, constraints
    can :update,          model, constraints
    can :modify,          model, constraints
    can :bulk_edit,       model, constraints unless no_bulk
    can :bulk_update,     model, constraints unless no_bulk
    can :bulk_fields,     model, constraints unless no_bulk

    # === Other
    can :save,            model
    can :cancel,          model
    can :get_job_result,  model

  end

  # Define a set of capabilities on a given model type which allows visibility
  # for instances which meet the given constraints.
  #
  # @param [Class] model
  # @param [Hash]  constraints
  #
  # @return [void]
  #
  def can_view_content(model, **constraints)
    can :index,        model, constraints
    can :list,         model, constraints
    can :list_org,     model, constraints
    can :list_own,     model
    can :show_current, model, constraints
    can :show_select,  model, constraints
    can :show,         model
    can :view,         model
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Set `constraints[:org]` if not already assigned.
  #
  # @param [Hash] constraints
  # @param [User] user
  #
  # @return [Boolean]                 False if :org could not be set.
  #
  def set_org!(constraints, user)
    unless (org = constraints[:org])
      meth = constraints[:meth] || __method__
      org  = org_for(user, caller: meth)
      Log.warn { "#{meth}: no org for #{user.inspect}" } unless org
      constraints.merge!(org: org) if org
    end
    org.present?
  end

  # Set `constraints[:no_bulk]` if not already assigned.
  #
  # @param [Hash]        constraints
  # @param [Class]       model
  # @param [String, nil] label
  #
  # @return [Boolean]                 Value of `constraints[:no_bulk]`.
  #
  def set_no_bulk!(constraints, model, label = nil)
    unless constraints.key?(:no_bulk)
      cons    = constraints.except(:meth)
      keys    = cons.keys
      no_bulk = keys.present? && identity_keys(model).intersect?(keys)
      Log.debug do
        meth  = constraints[:meth] || __method__
        label = [label, constraints.except(:meth, :no_bulk)].compact.join(' ')
        "#{meth}: #{model}: #{label}"
      end if no_bulk
      constraints.merge!(no_bulk: no_bulk)
    end
    constraints[:no_bulk]
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
  # @param [any, nil]            subject      Object, Class
  # @param [any, nil]            extra_args
  #
  def can?(action, subject, *extra_args)
    return false if action.blank?
    action = action.to_sym
    if subject.is_a?(Array)
      subject = subject.first unless subject.any? { _1.is_a?(Class) }
    end
    super
  end

  # Returns the opposite of the #can? method.
  #
  # Always *true* if *action* is *nil*.
  #
  # @param [Symbol, String, nil] action
  # @param [any, nil]            subject      Object, Class
  # @param [any, nil]            extra_args
  #
  def cannot?(action, subject, *extra_args)
    return true if action.blank?
    action = action.to_sym
    if subject.is_a?(Array)
      subject = subject.first unless subject.any? { _1.is_a?(Class) }
    end
    super
  end

  # Add a rule allowing an action.
  #
  # @param [Symbol,String,Array,nil] action
  # @param [any, nil]                subject
  # @param [Array]                   conditions
  #
  # @return [void]
  #
  def can(action = nil, subject = nil, *conditions, &blk)
    action, subject, conditions = prep_conditions(action, subject, conditions)
    super
  end

  # Add a rule forbidding an action.
  #
  # @param [Symbol,String,Array,nil] action
  # @param [any, nil]                subject
  # @param [Array]                   conditions
  #
  # @return [void]
  #
  def cannot(action = nil, subject = nil, *conditions, &blk)
    action, subject, conditions = prep_conditions(action, subject, conditions)
    super
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
  # @param [any, nil]            subject
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
  # @param [any, nil]                subject
  # @param [Array]                   conditions
  #
  # @return [Array(*,*,*)]
  #
  def prep_conditions(action, subject, conditions)
    action = action.compact.map!(&:to_sym) if action.is_a?(Array)
    action = action.to_sym                 if action.is_a?(String)
    conditions.map! { _1.except(:meth, :no_bulk) }.compact_blank!
    conditions.map! { normalize_id_keys(_1, subject) }
    return action, subject, conditions
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Models which are managed by CanCan.
  #
  # @return [Array<Class>]
  #
  def self.models
    MODEL_NAMES.map { to_class(_1) }.compact
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  protected

  # The URL parameters which imply operations on a specific model instance.
  #
  # @param [any, nil] model           Object, Class
  #
  # @return [Array<Symbol>]
  #
  def self.identity_keys(model)
    [:id, model.model_key, model.model_id_key]
  end

  # Return the organization represented by *rec*.
  #
  # @param [any, nil]    rec
  # @param [Symbol, nil] caller       For diagnostics.
  #
  # @return [Integer, nil]
  #
  def self.org_for(rec, caller: nil)
    org  = Org.instance_for(rec) || Org.instance_for(User.instance_for(rec))
    return org.id if org.is_a?(Org)
    meth = caller || __method__
    warn = rec ? "#{rec.class} unexpected: #{rec.inspect}" : 'nil argument'
    Log.warn("#{meth}: #{warn}")
  end

  delegate :identity_keys, :org_for, to: :class

end

__loading_end(__FILE__)
