# app/models/concerns/roles.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Role values.
#
module Roles

  # Bookshare user types as documented in API section 1.8 (User Types).
  #
  # NOTE: This is only for documentation at this time.
  # TODO: Harmonize with EMMA_ROLES.
  #
  # @type [Hash{Symbol=>String}]
  #
  # == Implementation Notes
  # Information gathered from the API documentation (section numbers in square
  # brackets).
  #
  # === Individual Member
  # [1.8] [Users] who have a personal subscription to the Bookshare service,
  #         and are able to get books on their own behalf.
  # [1.8] [May] also be, simultaneously, organization members who get some
  #         benefits from organization membership, such as use of the
  #         organization’s subscription.
  #
  # [2.3] Reading lists can be created[/modified] by individual members.
  #
  # === Organization Sponsor
  # [1.8] [Users] who represent members of an organization, such as a school or
  #         a library, who only get books for others on their behalf.
  # [1.8] For example, a teacher at a school will have the role of sponsor, and
  #         will get books on behalf of their students.
  # [1.8] A sponsor may be responsible for a few members or hundreds of
  #         members, and an organization may have a few or many sponsors.
  # [1.8] Many of the resources specifically designed for sponsors will be
  #         described in the "Organization" section.
  #
  # [2.3] Reading lists can be created[/modified] by sponsors.
  # [2.3] [Share reading list] with student members.
  # [2.3] [Add] a member from their organization to [a] reading list.
  #
  # [2.7] [Act] on [...] behalf [of members] to do things like download titles.
  # [2.7] [Have] some limited administrative abilities in their organizations,
  #         to add, update and remove individual members [to the organization].
  #
  # === Organization Member
  # [1.8] [Users] who also represent members of an organization, but are often
  #         minors or users who don’t regularly use the service themselves.
  # [1.8] [May] have *usernames* with which they can authenticate and interact
  #         with the system, or they may not.
  # [1.8] [Typically] limited in what titles they can get on their own, which
  #         will be reflected in the presence or absence of download links when
  #         they search for titles.
  #
  # [2.3] [Able] to use a [shared reading list] but will not be able to modify
  #         it.
  #
  # === Collection Assistant
  # [1.8] [Administrative] users who have the right to manage elements of the
  #         collection, either adding and removing titles, or updating the
  #         metadata of titles.
  # [1.8] [Will] have visibility to those titles that belong to their site.
  # [1.8] The resources specifically designed for these users are described in
  #         the resource sections that begin with "Collection Assistant".
  #
  # [2.8] [Manage] the collection, either by adding or removing *titles*, or by
  #         manipulating their *metadata*.
  # [2.8] This could include
  #         * withdrawing live titles,
  #         * publishing pending titles, or
  #         * reviewing proofread scans.
  # [2.8] [Restricted] to the titles that are associated with their site.
  #
  # [2.9] [Manage] the periodical *series* and *editions*.
  # [2.9] [Restricted] to the periodicals that are associated with their site.
  #
  # === Membership Assistant
  # [1.8] [Administrative] users who have the right to manage user accounts,
  #         either updating aspects such as subscriptions or proof of
  #         disability, creating new users, or looking up information about
  #         users.
  # [1.8] [Will] have visibility to those user accounts that belong to their
  #         site.
  # [1.8] The resources specifically designed for these users are described in
  #         the resource sections that begin with "Membership Assistant".
  #
  # [2.6] [Will] access to see and modify the information about [...] users;
  #         these are the endpoints that start with "/v2/accounts".
  # [2.6] [Allowed] to see and manage only those user accounts that are
  #         associated with their site.
  #
  # [2.10] [Able] to view and update the user accounts for those individual
  #         members who are associated with the Assistant’s site.
  #
  # === Administrator
  # [1.8] [Administrative] users who have the abilities of both
  #         "Collection Assistants" and "Membership Assistants", and whose
  #         visibility lets them manage users or collections that belong to any
  #         site.
  #
  # [2.6] [Will] access to see and modify the information about [...] users;
  #         these are the endpoints that start with "/v2/accounts".
  # [2.6] [Allowed] access to users across all sites.
  #
  # [2.8] Perform as a "Collection Assistant" for all *titles* (not just ones
  #         associated with a specific site).
  #
  # [2.9] Perform as a "Collection Assistant" for all *periodicals* (not just
  #         ones associated with a specific site).
  #
  # [2.10] Perform as a "Membership Assistant" for all individuals.
  #
  # === Volunteer
  # [1.8] These are users who help to add new items to the collection, but with
  #         fewer rights than "Collection Assistants".
  # [1.8] They can submit and proofread scanned titles, but are not approved
  #         members so @note cannot download other titles.
  # [1.8] NOTE: The API does not yet have resources supporting Volunteer users.
  #
  # === Guest
  # [1.8] These are unauthenticated users, meaning that requests are made
  #         without an OAuth token.
  # [1.8] [Allowed] to do things like search the collection and download, but
  #         the resources that will return with a download link will be limited
  #         to those that are either @note in the public domain,
  #         or @note have a Creative Commons license.
  #
  # [1.9] [Will] have their view of the collection limited to that defined by
  #         the site associated with the API key.
  #
  BOOKSHARE_USER_TYPES = {
    'Individual Member':    'able to get books on their own behalf',
    'Organization Sponsor': 'get books for others on their behalf',
    'Organization Member':  'limited in what titles they can get on their own',
    'Collection Assistant': 'add/update/remove titles',
    'Membership Assistant': 'add/update/remove user accounts',
    'Administrator':        'add/update/remove titles and/or user accounts',
    'Volunteer':            'upload/proofread artifacts',
    'Guest':                'unauthenticated users',
  }.freeze

  # Bookshare roles as documented in API section 2.10.3 (Create a user account)
  #
  # It's not clear how these map on to #BOOKSHARE_USER_TYPES but they have been
  # included as :RoleType in Api#ENUMERATIONS
  #
  # NOTE: This is only for documentation at this time.
  # TODO: Harmonize with EMMA_ROLES.
  #
  # @type [Hash{Symbol=>String}]
  #
  # Compare with:
  # @see ApiService::RoleType#values
  #
  # == Implementation Notes
  # With no role (due to lack of user information) an unauthenticated user
  # would be a "Guest" user.  If authenticated (as a guess) that would imply an
  # "Organization Member" user.
  #
  # :individual           Presumably an "Individual Member" user, OR a
  #                         "Organization Member" that also happens to have an
  #                         individual Bookshare account.
  #
  # :volunteer            Presumably a "Volunteer" user.
  #
  # :trustedVolunteer     TODO: ???
  #
  # :collectionAssistant  Presumably a "Collection Assistant" user, OR an
  #                         "Administrator" user.
  #
  # :membershipAssistant  Presumably a "Membership Assistant" user, OR an
  #                         "Administrator" user.
  #
  BOOKSHARE_ROLES = {
    individual:          'API section 1.8',
    volunteer:           'API section 1.8',
    trustedVolunteer:    '???',
    collectionAssistant: 'API sections 1.8, 2.8, 2.9',
    membershipAssistant: 'API sections 1.8, 2.6, 2.10',
  }.freeze

  # Current EMMA roles.
  #
  # @type [Array<Symbol>]
  #
  EMMA_ROLES = %i[
    catalog_searcher
    catalog_curator
    artifact_downloader
    artifact_submitter
    membership_viewer
    membership_manager
    administrator
  ].freeze

  # EMMA role(s) for prototypical users.
  #
  # @type [Hash{Symbol=>Array<Symbol>}]
  #
  DEFAULT_ROLES = {
    collection: %i[
      catalog_searcher
      catalog_curator
    ],
    dso: %i[
      catalog_searcher
      artifact_downloader
      artifact_submitter
      membership_viewer
      membership_manager
    ],
    anonymous: %i[catalog_searcher],
  }.deep_freeze

end

__loading_end(__FILE__)
