# app/models/ability.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions for role-based authorization through CanCan.
#
# NOTE: This gem is very model/controller oriented and may not be helpful...
#
# A method call like `can :read, :artifact` basically assumes a few things:
# - There's an ArtifactController with typical CRUD endpoints.
# - The :read argument implies permission for the :index and :show endpoints.
# - The controller manipulates instances of the Artifact resource.
#
class Ability

  include CanCan::Ability

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
  PREDEFINED_ACTION_ALIAS = {
    read:   %i[index show],
    create: %i[new],
    update: %i[edit],
  }.deep_freeze

  # Locally-defined aliases.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  LOCAL_ACTION_ALIAS = {
    admin:       %i[manage],          # NOTE: only used for upload/admin
    list:        %i[index],
    delete:      %i[destroy],
    history:     %i[manage],          # NOTE: only used for Title and Member
    bulk_new:    %i[new],
    bulk_edit:   %i[edit],
    bulk_delete: %i[destroy],
  }.deep_freeze

  # Both existing and new action aliases.
  #
  # This does not include the standard CRUD controller actions:
  #
  # :index    (included in alias :read)
  # :show     (included in alias :read)
  # :new      (alias :create)
  # :edit     (alias :update)
  # :destroy  (alias :delete)
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  ACTION_ALIAS = LOCAL_ACTION_ALIAS.merge(PREDEFINED_ACTION_ALIAS).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [::User, nil] user
  #
  # @see User#
  # @see Member#
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
  #--
  # noinspection RubyNilAnalysis
  #++
  def initialize(user)
    ACTION_ALIAS.each_pair do |actions, action_alias|
      alias_action actions, to: action_alias
    end
    user ||= User.new # Guest user (not logged in).
    roles  = user.roles.map { |r| r&.name&.to_sym }.compact
    case
      when roles.include?(:administrator)       then act_as_administrator
      when roles.include?(:membership_manager)  then act_as_dso_primary
      when roles.include?(:membership_viewer)   then act_as_dso_staff
      when roles.include?(:artifact_submitter)  then act_as_dso_delegate
      when user.linked_account?                 then act_as_individual_member
      when roles.include?(:artifact_downloader) then act_as_organization_member
      when roles.include?(:catalog_curator)     then act_as_library_staff
      else                                           act_as_guest
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Indicate that the user can perform as a system administrator.
  #
  # NOTE: This does not appear to relate to any current Bookshare "role".
  #
  # @return [void]
  #
  def act_as_administrator
    can :manage, :all
  end

  # Indicate that the user can perform as a DSO Primary.
  #
  # TODO: It's unclear whether this is really distinct from DSO Staff.
  #
  # @return [void]
  #
  # == Usage Notes
  # Based on https://www.bookshare.org/orgAccountSponsors it would not appear
  # that the "primary contact" for an organization has any special significance
  # other than that "sponsor" cannot be removed.  (Another "sponsor" would need
  # to be designated as the primary contact first.)
  #
  def act_as_dso_primary
    act_as_dso_staff
  end

  # Indicate that the user can perform as a DSO Staff member.
  #
  # TODO: Maybe this should be merged with DSO Primary and/or DSO "sponsor"?
  #
  # @return [void]
  #
  def act_as_dso_staff
    act_as_dso_sponsor
  end

  # Indicate that the user can perform as an assistant to a DSO Sponsor.
  #
  # @return [void]
  #
  # == Usage Notes
  # From https://www.bookshare.org/orgAccountSponsors:
  # Sponsors must be staff or faculty, or professionals working with your
  # organization.  Sponsors cannot be parents (unless employed by your
  # organization) or volunteers.
  #
  def act_as_dso_sponsor
    act_as_individual_member
    can :manage, Artifact
    can :manage, Member
    can :manage, ReadingList
    can :manage, Upload
  end

  # Indicate that the user can perform as an assistant to a DSO Staff member.
  #
  # NOTE: This does not appear to relate to any current Bookshare "role".
  #
  # TODO: Is this really a valid user prototype concept?
  #
  # @return [void]
  #
  def act_as_dso_delegate
    act_as_guest
    can :create, Artifact
    can :update, Artifact
    can :create, Upload
    can :update, Upload
    can :delete, Upload
  end

  # Indicate that the user can perform as a library member.
  #
  # NOTE: This does not appear to relate to any current Bookshare "role".
  #
  # @return [void]
  #
  def act_as_library_staff
    act_as_guest
    can :update, Upload
    can :delete, Upload
  end

  # Indicate that the user can act as a student with a personal Bookshare
  # account (i.e., an Individual Member).
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
  def act_as_individual_member
    act_as_guest
    can :download, Artifact
  end

  # Indicate that the user can act as a student with a membership account
  # through the organization (i.e., an Organizational Member).
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
  def act_as_organization_member
    act_as_guest
    can :download, Artifact do |artifact|
      ReadingList.any? { |list| list.include?(artifact) }
    end
  end

  # Indicate that the user can perform as a guest user.
  #
  # @return [void]
  #
  def act_as_guest
    can :list, Artifact
    can :read, Title
    can :read, Periodical
    can :read, Edition
    can :read, Upload # TODO: probably temporary
  end

end

__loading_end(__FILE__)
