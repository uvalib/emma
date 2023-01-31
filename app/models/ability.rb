# app/models/ability.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions for role-based authorization through CanCan.
#
# A method call like `can :read, :artifact` basically assumes a few things:
# - There's an ArtifactController with typical CRUD endpoints.
# - The :read argument implies permission for the :index and :show endpoints.
# - The controller manipulates instances of the Artifact resource.
#
#--
# noinspection RubyTooManyMethodsInspection
#++
class Ability

  include Emma::Common

  include CanCan::Ability
  include Roles

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

    # == Any controller

    delete:         %i[destroy],

    # == UploadController

    admin:          %i[manage],
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

    # == UploadController, ArtifactController, EditionController

    download:       [],
    retrieval:      [],

    # == MemberController, TitleController

    history:        %i[manage],
    show_history:   %i[history],

    # == AccountController, User::*Controller

    #edit_select:    %i[edit],
    #delete_select:  %i[destroy],

    # == Any controller

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
  # @see User#
  # @see Member#
  # @see Roles#role_prototype_for
  #
  # == Usage Notes
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
    case role_prototype_for(user)
      when :developer     then act_as_developer(user)
      when :administrator then act_as_administrator(user)
      when :dso           then act_as_dso(user)
      when :librarian     then act_as_librarian(user)
      when :member        then act_as_member(user)
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
  # @see RoleHelper#developer?
  #
  # == Usage Notes
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
  # == Usage Notes
  # This is not related to any Bookshare "role" -- it is exclusively for
  # authorization to access local EMMA resources.
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
    dso_type = nil # TODO: Distinguish between DSO types?
    case dso_type&.to_sym
      when :primary then act_as_dso_primary(user)
      when :staff   then act_as_dso_staff(user)
      else               act_as_dso_sponsor(user)
    end
  end

  # Assign the ability to perform as a DSO Primary.
  #
  # @param [User] user
  #
  # @return [void]
  #
  # == Usage Notes
  # Based on https://www.bookshare.org/orgAccountSponsors it would not appear
  # that the "primary contact" for an organization has any special significance
  # other than that "sponsor" cannot be removed.  (Another "sponsor" would need
  # to be designated as the primary contact first.)
  #
  def act_as_dso_primary(user)
    act_as_dso_staff(user)
  end

  # Assign the ability to perform as a DSO Staff member.
  #
  # @param [User] user
  #
  # @return [void]
  #
  # == Usage Notes
  # There is currently no distinction between "DSO Staff" and "DSO Sponsor"
  # (which is Bookshare's term for "DSO Staff").
  #
  def act_as_dso_staff(user)
    act_as_dso_sponsor(user)
    can_manage_group_account(user)
  end

  # Assign the ability to perform as an assistant to a DSO Sponsor.
  #
  # @param [User] user
  #
  # @return [void]
  #
  # == Usage Notes
  # From https://www.bookshare.org/orgAccountSponsors:
  # Sponsors must be staff or faculty, or professionals working with your
  # organization.  Sponsors cannot be parents (unless employed by your
  # organization) or volunteers.
  #
  def act_as_dso_sponsor(user)
    act_as_individual_member(user)
    can_manage_own_entries(user)
    can :manage, Artifact
    can :manage, Member
    can :manage, ReadingList
  end

  # Assign the ability to perform as an assistant to a DSO Staff member.
  #
  # @param [User] user
  #
  # @return [void]
  #
  # == Usage Notes
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
  # == Usage Notes
  # The current idea is that library staff might perform all of the entry
  # creation and maintenance functions that a DSO would (minus the ability to
  # download artifacts).
  #
  def act_as_librarian(user)
    act_as_authenticated(user)
    can_manage_own_entries(user)
    can_manage_group_entries(user)
    can :create, Artifact
    can :modify, Artifact
  end

  # Assign the ability to perform as a student with a Bookshare account.
  #
  # @param [User] user
  #
  # @return [void]
  #
  def act_as_member(user)
    if user.linked_account?
      act_as_individual_member(user)
    else
      act_as_organization_member(user)
    end
  end

  # Assign the ability to perform as a student with a personal Bookshare
  # account (i.e., an Individual Member).
  #
  # @param [User] user
  #
  # @return [void]
  #
  # == Usage Notes
  # From @see https://www.bookshare.org/cms/help-center/what-kind-account-should-my-students-use
  #
  # === Benefits
  # * Search for and download books independently.
  # * Download accessible formats (BRF, DAISY, Audio) from Bookshare.org.
  # * Log in and download through Bookshare-integrated applications.
  #
  # === Drawbacks
  # * Username & password hidden; for privacy reasons we only release login
  #   information to parents.
  # * No direct access to NIMAC books.
  #
  # @see https://www.bookshare.org/cms/help-center/access-nimac-books
  #
  def act_as_individual_member(user)
    act_as_authenticated(user)
    can :retrieve, Artifact
    can :retrieve, Upload # TODO: remove after upload -> entry
    can :retrieve, Entry
  end

  # Assign the ability to perform as a student with a membership account
  # through the organization (i.e., an Organizational Member).
  #
  # @param [User] user
  #
  # Organizational members do not have direct access to Bookshare; instead,
  # artifacts must be acquired on their behalf by a "sponsor" (e.g. DSO staff).
  #
  # @return [void]
  #
  # == Usage Notes
  # From @see https://www.bookshare.org/myOrgAddIndividualMember:
  #
  # Individual Membership lets a user personally log into Bookshare and
  # download books for their own use, including books you assign via shared
  # Reading Lists. An Individual Member can access Bookshare through our
  # website, mobile applications, and enabled partner devices.
  #
  # From @see https://www.bookshare.org/cms/help-center/what-kind-account-should-my-students-use
  #
  # === Benefits
  # * Teachers manage account and can easily reset student's username/password.
  # * Access to NIMAC books (K-12 textbooks).
  # * Proof of Disability from school.
  # * Log in and download through Bookshare-integrated applications.
  #
  # === Drawbacks
  # * Can only read books shared on Reading Lists.
  #
  # @see https://www.bookshare.org/cms/help-center/access-nimac-books
  #
  def act_as_organization_member(user)
    act_as_authenticated(user)
    can :retrieve, Artifact do |artifact|
      ReadingList.any? { |list| list.has_artifact?(artifact) }
    end
    can :retrieve, Upload do |upload| # TODO: remove after upload -> entry
      title = upload.emma_data&.dig(:dc_title)
      title.present? && ReadingList.any? { |list| list.has_title?(title) }
    end
    can :retrieve, Entry do |entry|
      title = entry.emma_data&.dig(:dc_title)
      title.present? && ReadingList.any? { |list| list.has_title?(title) }
    end
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
  # == Usage Notes
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
    can :list, Artifact
    can :read, Title
    can :read, Periodical
    can :read, Edition
    can :view, Upload # TODO: remove after upload -> entry
    can :view, Entry
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
    can_manage_entries(Upload, **with_constraints) # TODO: remove after upload -> entry
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
  def can_manage_entries(model = Entry, **with_constraints)

    # == Basic record management
    can_manage_records(model, **with_constraints)

    # == Record modification
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

    # == Basic record management
    can_manage(model, **with_constraints)

    # == Record creation
    can :new,             model
    can :create,          model
    can :renew,           model
    can :bulk_new,        model
    can :bulk_create,     model

    # == Record workflow
    can :remit,           model
    can :remit_select,    model
    can :start,           model
    can :stop,            model
    can :pause,           model
    can :resume,          model
    can :get_job_result,  model

    # == Other
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

    # == List resources
    can :index,         model, **with_constraints
    can :list,          model, **with_constraints

    # == View resource
    can :show,          model
    can :view,          model

    # == Modify resource
    can :edit,          model, **with_constraints
    can :modify,        model, **with_constraints
    can :edit_select,   model, **with_constraints
    can :bulk_edit,     model, **with_constraints
    can :bulk_update,   model, **with_constraints

    # == Remove resource
    can :destroy,       model, **with_constraints
    can :remove,        model, **with_constraints
    can :delete_select, model, **with_constraints
    can :bulk_delete,   model, **with_constraints
    can :bulk_destroy,  model, **with_constraints

    # == Other
    can :save,          model
    can :cancel,        model

  end

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
