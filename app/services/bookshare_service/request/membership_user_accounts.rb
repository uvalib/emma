# app/services/bookshare_service/request/membership_user_accounts.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Request::MembershipUserAccounts
#
# == Usage Notes
#
# === From Membership Management API 2.1 (Membership Assistant - User Accounts)
# Membership Assistant users are able to view and update the user accounts for
# those individual members who are associated with the Assistant’s site.
#
#--
# noinspection RubyParameterNamingConvention, RubyLocalVariableNamingConvention
#++
module BookshareService::Request::MembershipUserAccounts

  include BookshareService::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /v2/accounts/(userIdentifier)
  #
  # == 2.1.1. Look up user account
  # Get details about the specified user account.  (Membership Assistants are
  # only allowed to search for users associated with the same Site as them.)
  #
  # @param [User, String, nil] user   Default: `@user`.
  # @param [Hash]              opt    Passed to #api.
  #
  # @return [Bs::Message::UserAccount]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_get-useraccount-search
  #
  def get_account(user: nil, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:get, 'accounts', userId, **opt)
    Bs::Message::UserAccount.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
        },
        reference_page:   'membership',
        reference_id:     '_get-useraccount-search'
      }
    end

  # == PUT /v2/accounts/(userIdentifier)
  #
  # == 2.1.2. Update a user account
  # Update an existing user account.
  #
  # @param [User, String, nil] user   Default: `@user`.
  # @param [Hash]              opt    Passed to #api.
  #
  # @option opt [String]        :firstName
  # @option opt [String]        :lastName
  # @option opt [String]        :phoneNumber
  # @option opt [String]        :emailAddress
  # @option opt [String]        :address1
  # @option opt [String]        :address2
  # @option opt [String]        :city
  # @option opt [String]        :state
  # @option opt [String]        :country
  # @option opt [String]        :postalCode
  # @option opt [String]        :guardianFirstName
  # @option opt [String]        :guardianLastName
  # @option opt [String]        :dateOfBirth
  # @option opt [IsoLanguage]   :language
  # @option opt [Boolean]       :allowAdultContent
  # @option opt [BsSiteType]    :site
  # @option opt [BsRoleType]    :role
  # @option opt [String]        :password
  #
  # @return [Bs::Message::UserAccount]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_update-useraccount
  #
  def update_account(user: nil, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:put, 'accounts', userId, **opt)
    Bs::Message::UserAccount.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:               :userIdentifier,
        },
        required: {
          userIdentifier:     String,
        },
        optional: {
          firstName:          String,
          lastName:           String,
          phoneNumber:        String,
          emailAddress:       String,
          address1:           String,
          address2:           String,
          city:               String,
          state:              String,
          country:            String,
          postalCode:         String,
          guardianFirstName:  String,
          guardianLastName:   String,
          dateOfBirth:        String,
          language:           IsoLanguage,
          allowAdultContent:  Boolean,
          site:               BsSiteType,
          role:               BsRoleType,
          password:           String,
        },
        reference_page:       'membership',
        reference_id:         '_update-useraccount'
      }
    end

  # == POST /v2/accounts
  #
  # == 2.1.3. Create a user account
  # Create a new user account.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]        :firstName                          *REQUIRED*
  # @option opt [String]        :lastName                           *REQUIRED*
  # @option opt [String]        :phoneNumber
  # @option opt [String]        :emailAddress                       *REQUIRED*
  # @option opt [String]        :address1                           *REQUIRED*
  # @option opt [String]        :address2
  # @option opt [String]        :city                               *REQUIRED*
  # @option opt [String]        :state
  # @option opt [String]        :country                            *REQUIRED*
  # @option opt [String]        :postalCode                         *REQUIRED*
  # @option opt [String]        :guardianFirstName
  # @option opt [String]        :guardianLastName
  # @option opt [String]        :dateOfBirth
  # @option opt [IsoLanguage]   :language
  # @option opt [Boolean]       :allowAdultContent
  # @option opt [BsSiteType]    :site
  # @option opt [BsRoleType]    :role
  # @option opt [String]        :password
  #
  # @return [Bs::Message::UserAccount]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_create-useraccount
  #
  def create_account(**opt)
    opt = get_parameters(__method__, **opt)
    api(:post, 'accounts', **opt)
    Bs::Message::UserAccount.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          firstName:          String,
          lastName:           String,
          emailAddress:       String,
          address1:           String,
          city:               String,
          country:            String,
          postalCode:         String,
        },
        optional: {
          phoneNumber:        String,
          address2:           String,
          state:              String,
          guardianFirstName:  String,
          guardianLastName:   String,
          dateOfBirth:        String,
          language:           IsoLanguage,
          allowAdultContent:  Boolean,
          site:               BsSiteType,
          role:               BsRoleType,
          password:           String,
        },
        reference_page:       'membership',
        reference_id:         '_create-useraccount'
      }
    end

  # == PUT /v2/accounts/(userIdentifier)/password
  #
  # == 2.1.16. Update user password
  # Update the password for an existing user.
  #
  # @param [User, String, nil] user       Default: `@user`.
  # @param [String]            password
  # @param [Hash]              opt        Passed to #api.
  #
  # @return [Bs::Message::StatusModel]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_update-membership-password
  #
  def update_account_password(user: nil, password:, **opt)
    opt.merge!(password: password)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:put, 'accounts', userId, 'password', **opt)
    Bs::Message::StatusModel.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          password:       String,
        },
        reference_page:   'membership',
        reference_id:     '_update-membership-password'
      }
    end

  # ===========================================================================
  # :section: Subscriptions
  # ===========================================================================

  public

  # == GET /v2/accounts/(userIdentifier)/subscriptions
  #
  # == 2.1.4. Get subscriptions
  # Get the list of membership subscriptions for an existing user.
  #
  # @param [User, String, nil] user   Default: `@user`.
  # @param [Hash]              opt    Passed to #api.
  #
  # @return [Bs::Message::UserSubscriptionList]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_get-membership-subscriptions
  #
  def get_subscriptions(user: nil, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:get, 'accounts', userId, 'subscriptions', **opt)
    Bs::Message::UserSubscriptionList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
        },
        reference_page:   'membership',
        reference_id:     '_get-membership-subscriptions'
      }
    end

  # == POST /v2/accounts/(userIdentifier)/subscriptions
  #
  # == 2.1.5. Create a subscription
  # Create a new membership subscription for an existing user.
  #
  # @param [User, String, nil] user   Default: `@user`.
  # @param [Hash]              opt    Passed to #api.
  #
  # @option opt [IsoDay]      :startDate                            *REQUIRED*
  # @option opt [IsoDay]      :endDate
  # @option opt [String]      :userSubscriptionType                 *REQUIRED*
  # @option opt [Integer]     :numBooksAllowed
  # @option opt [BsTimeframe] :downloadTimeframe
  # @option opt [String]      :notes
  #
  # @return [Bs::Message::UserSubscription]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_create-membership-subscription
  #
  def create_subscription(user: nil, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:post, 'accounts', userId, 'subscriptions', **opt)
    Bs::Message::UserSubscription.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:                 :userIdentifier,
        },
        required: {
          userIdentifier:       String,
          startDate:            String,
          userSubscriptionType: String,
        },
        optional: {
          endDate:              IsoDay,
          numBooksAllowed:      Integer,
          downloadTimeframe:    BsTimeframe,
          notes:                String,
        },
        reference_page:         'membership',
        reference_id:           '_create-membership-subscription'
      }
    end

  # == GET /v2/accounts/(userIdentifier)/subscriptions/(subscriptionId)
  #
  # == 2.1.6. Get single subscription
  # Get the specified membership subscription for an existing user.
  #
  # @param [User, String, nil] user             Default: `@user`.
  # @param [String]            subscriptionId
  # @param [Hash]              opt              Passed to #api.
  #
  # @return [Bs::Message::UserSubscription]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_get-single-membership-subscription
  #
  def get_subscription(user: nil, subscriptionId:, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:get, 'accounts', userId, 'subscriptions', subscriptionId, **opt)
    Bs::Message::UserSubscription.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          subscriptionId: String,
        },
        reference_page:   'membership',
        reference_id:     '_get-single-membership-subscription'
      }
    end

  # == PUT /v2/accounts/(userIdentifier)/subscriptions/(subscriptionId)
  #
  # == 2.1.7. Update a subscription
  # Update an existing membership subscription for an existing user.
  #
  # @param [User, String, nil] user             Default: `@user`.
  # @param [String]            subscriptionId
  # @param [Hash]              opt              Passed to #api.
  #
  # @option opt [IsoDay]      :startDate                            *REQUIRED*
  # @option opt [IsoDay]      :endDate
  # @option opt [String]      :userSubscriptionType                 *REQUIRED*
  # @option opt [Integer]     :numBooksAllowed
  # @option opt [BsTimeframe] :downloadTimeframe
  # @option opt [String]      :notes
  #
  # @return [Bs::Message::UserSubscription]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_update-membership-subscription
  #
  def update_subscription(user: nil, subscriptionId:, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:put, 'accounts', userId, 'subscriptions', subscriptionId, **opt)
    Bs::Message::UserSubscription.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:                 :userIdentifier,
        },
        required: {
          userIdentifier:       String,
          subscriptionId:       String,
          startDate:            String,
          userSubscriptionType: String,
        },
        optional: {
          endDate:              IsoDay,
          numBooksAllowed:      Integer,
          downloadTimeframe:    BsTimeframe,
          notes:                String,
        },
        reference_page:         'membership',
        reference_id:           '_update-membership-subscription'
      }
    end

  # == GET /v2/subscriptiontypes
  #
  # == 2.1.8. Get subscription types
  # Get the list of subscription types available to users of the Membership
  # Assistant’s site.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @return [Bs::Message::UserSubscriptionTypeList]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_get-membership-subscription-types
  #
  def get_subscription_types(**opt)
    opt = get_parameters(__method__, **opt)
    api(:get, 'subscriptiontypes', **opt)
    Bs::Message::UserSubscriptionTypeList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        reference_page: 'membership',
        reference_id:   '_get-membership-subscription-types'
      }
    end

  # ===========================================================================
  # :section: Proof of disability
  # ===========================================================================

  public

  # == GET /v2/accounts/(userIdentifier)/pod
  #
  # == 2.1.9. Get proof of disability
  # Get the list of disabilities for an existing user, with their proof source.
  #
  # @param [User, String, nil] user   Default: `@user`.
  # @param [Hash]              opt    Passed to #api.
  #
  # @return [Bs::Message::UserPodList]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_get-membership-pods
  #
  def get_user_pod(user: nil, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:post, 'accounts', userId, 'pod', **opt)
    Bs::Message::UserPodList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
        },
        reference_page:   'membership',
        reference_id:     '_get-membership-pods'
      }
    end

  # == POST /v2/accounts/(userIdentifier)/pod
  #
  # == 2.1.10. Create a proof of disability
  # Create a new record of a disability for an existing user, with its proof
  # source.
  #
  # @param [User, String, nil]         user             Default: `@user`.
  # @param [BsDisabilityType]          disabilityType
  # @param [BsProofOfDisabilitySource] proofSource
  # @param [Hash]                      opt              Passed to #api.
  #
  # @return [Bs::Message::UserPodList]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_create-membership-pod
  #
  def create_user_pod(user: nil, disabilityType:, proofSource:, **opt)
    opt.merge!(disabilityType: disabilityType, proofSource: proofSource)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:post, 'accounts', userId, 'pod', **opt)
    Bs::Message::UserPodList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          disabilityType: BsDisabilityType,
          proofSource:    BsProofOfDisabilitySource,
        },
        reference_page:   'membership',
        reference_id:     '_create-membership-pod'
      }
    end

  # == PUT /v2/accounts/(userIdentifier)/pod/(disabilityType)
  #
  # == 2.1.11. Update a proof of disability
  # Update the proof source for a disability for an existing user.
  #
  # @param [User, String, nil]       user             Default: `@user`.
  # @param [BsDisabilityType]        disabilityType
  # @param [ProofOfDisabilitySource] proofSource
  # @param [Hash]                    opt              Passed to #api.
  #
  # @return [Bs::Message::UserPodList]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_update-membership-pod
  #
  def update_user_pod(user: nil, disabilityType:, proofSource:, **opt)
    opt.merge!(proofSource: proofSource)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:put, 'accounts', userId, 'pod', disabilityType, **opt)
    Bs::Message::UserPodList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          disabilityType: BsDisabilityType,
          proofSource:    BsProofOfDisabilitySource,
        },
        reference_page:   'membership',
        reference_id:     '_update-membership-pod'
      }
    end

  # == DELETE /v2/accounts/(userIdentifier)/pod/(userIdentifier)
  #
  # == 2.1.12. Remove a proof of disability
  # Remove a proof of disability for an existing user.
  #
  # @param [User, String, nil] user             Default: `@user`.
  # @param [BsDisabilityType]  disabilityType
  # @param [Hash]              opt              Passed to #api.
  #
  # @return [Bs::Message::UserPodList]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_delete-membership-pod
  #
  def remove_user_pod(user: nil, disabilityType:, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:delete, 'accounts', userId, 'pod', disabilityType, **opt)
    Bs::Message::UserPodList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          disabilityType: BsDisabilityType,
        },
        reference_page:   'membership',
        reference_id:     '_delete-membership-pod'
      }
    end

  # ===========================================================================
  # :section: Agreements
  # ===========================================================================

  public

  # == GET /v2/accounts/(userIdentifier)/agreements
  #
  # == 2.1.13. Get a list of signed agreements
  # Get the list of signed agreements for an existing user.
  #
  # @param [User, String, nil] user   Default: `@user`.
  # @param [Hash]              opt    Passed to #api.
  #
  # @return [Bs::Message::UserSignedAgreementList]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_get-signed-agreements
  #
  def get_user_agreements(user: nil, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:post, 'accounts', userId, 'agreements', **opt)
    Bs::Message::UserSignedAgreementList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
        },
        reference_page:   'membership',
        reference_id:     '_get-signed-agreements'
      }
    end

  # == POST /v2/accounts/(userIdentifier)/agreements
  #
  # == 2.1.14. Create a new signed agreement
  # Create a new signed agreement record for an existing user
  #
  # @param [User, String, nil] user   Default: `@user`.
  # @param [Hash]              opt    Passed to #api.
  #
  # @option opt [BsAgreementType] :agreementType                     *REQUIRED*
  # @option opt [String]          :dateSigned                        *REQUIRED*
  # @option opt [String]          :printName                         *REQUIRED*
  # @option opt [String]          :signedByLegalGuardian
  #
  # @return [Bs::Message::UserSignedAgreement]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_create-signed-agreement
  #
  def create_user_agreement(user: nil, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:post, 'accounts', userId, 'agreements', **opt)
    Bs::Message::UserSignedAgreement.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:                   :userIdentifier,
        },
        required: {
          userIdentifier:         String,
          agreementType:          BsAgreementType,
          dateSigned:             String,
          printName:              String,
        },
        optional: {
          signedByLegalGuardian:  String,
        },
        reference_page:           'membership',
        reference_id:             '_create-signed-agreement'
      }
    end

  # == POST /v2/accounts/(userIdentifier)/agreements/(id)/expired
  #
  # == 2.1.15. Expire a signed agreement
  # Expire a signed agreement.
  #
  # @param [User, String, nil] user   Default: `@user`.
  # @param [String]            id     Agreement ID
  # @param [Hash]              opt    Passed to #api.
  #
  # @return [Bs::Message::UserSignedAgreement]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_expire-signed-agreement
  #
  def remove_user_agreement(user: nil, id:, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:post, 'accounts', userId, 'agreements', id, 'expired', **opt)
    Bs::Message::UserSignedAgreement.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          id:             String,
        },
        reference_page:   'membership',
        reference_id:     '_expire-signed-agreement'
      }
    end

  # ===========================================================================
  # :section: Recommendation profile
  # ===========================================================================

  public

  # == GET /v2/accounts/(userIdentifier)/recommendationProfile
  #
  # == 2.1.17. Get recommendation profile
  # Get property choices that guide title recommendations for the given user.
  #
  # @param [User, String, nil] user   Default: `@user`.
  # @param [Hash]              opt    Passed to #api.
  #
  # @return [Bs::Message::RecommendationProfile]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_get-recommendation-profile
  #
  def get_recommendation_profile(user: nil, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:get, 'accounts', userId, 'recommendationProfile', **opt)
    Bs::Message::RecommendationProfile.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
        },
        reference_page:   'membership',
        reference_id:     '_get-recommendation-profile'
      }
    end

  # == PUT /v2/accounts/(userIdentifier)/recommendationProfile
  #
  # == 2.1.18. Update recommendation profile
  # Update property choices that guide title recommendations for the given
  # user.
  #
  # @param [User, String, nil] user   Default: `@user`.
  # @param [Hash]              opt    Passed to #api.
  #
  # @option opt [Boolean]                                  :includeGlobalCollection   Default: *false*
  # @option opt [BsNarratorType]                           :narratorType
  # @option opt [BsGender]                                 :narratorGender
  # @option opt [Integer]                                  :readingAge
  # @option opt [BsContentWarning,Array<BsContentWarning>] :excludedContentWarnings
  # @option opt [BsContentWarning,Array<BsContentWarning>] :includedContentWarnings
  # @option opt [String, Array<String>]                    :excludedCategories
  # @option opt [String, Array<String>]                    :includedCategories
  # @option opt [String, Array<String>]                    :excludedAuthors
  # @option opt [String, Array<String>]                    :includedAuthors
  #
  # @return [Bs::Message::RecommendationProfile]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_put-recommendation-profile
  #
  def update_recommendation_profile(user: nil, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:put, 'accounts', userId, 'recommendationProfile', **opt)
    Bs::Message::RecommendationProfile.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:                    :userIdentifier,
        },
        required: {
          userIdentifier:          String,
        },
        optional: {
          includeGlobalCollection: Boolean,
          narratorType:            BsNarratorType,
          narratorGender:          BsGender,
          readingAge:              Integer,
          excludedContentWarnings: BsContentWarning,
          includedContentWarnings: BsContentWarning,
          excludedCategories:      String,
          includedCategories:      String,
          excludedAuthors:         String,
          includedAuthors:         String,
        },
        multi: %i[
          excludedContentWarnings  includedContentWarnings
          excludedCategories       includedCategories
          excludedAuthors          includedAuthors
        ],
        reference_page: 'membership',
        reference_id:   '_put-recommendation-profile'
      }
    end

  # ===========================================================================
  # :section: Preferences
  # ===========================================================================

  public

  # == GET /v2/accounts/(userIdentifier)/preferences
  #
  # == 2.1.19. Get user account preferences
  # Get the account preferences associated with the given user.
  #
  # @param [User, String, nil] user   Default: `@user`.
  # @param [Hash]              opt    Passed to #api.
  #
  # @return [Bs::Message::MyAccountPreferences]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_get-user-account-preferences
  #
  def get_preferences(user: nil, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:get, 'accounts', userId, 'preferences', **opt)
    Bs::Message::MyAccountPreferences.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
        },
        reference_page:   'membership',
        reference_id:     '_get-user-account-preferences'
      }
    end

  # == PUT /v2/accounts/(userIdentifier)/preferences
  #
  # == 2.1.20. Update user account preferences
  # Update the account preferences associated with the given user.
  #
  # @param [User, String, nil] user   Default: `@user`.
  # @param [Hash]              opt    Passed to #api.
  #
  # @option opt [Boolean]        :allowAdultContent
  # @option opt [Boolean]        :showAllBooks          Default: *false*
  # @option opt [IsoLanguage]    :language
  # @option opt [BsFormatType]   :format
  # @option opt [BsBrailleGrade] :brailleGrade
  # @option opt [BsBrailleFmt]   :brailleFormat
  # @option opt [Integer]        :brailleCellLineWidth
  # @option opt [Boolean]        :useUeb                Default: *false*
  #
  # @return [Bs::Message::MyAccountPreferences]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_put-user-account-preferences
  #
  def update_preferences(user: nil, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:put, 'accounts', userId, 'preferences', **opt)
    Bs::Message::MyAccountPreferences.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          fmt:                  :format,
          user:                 :userIdentifier,
        },
        required: {
          userIdentifier:       String,
        },
        optional: {
          allowAdultContent:    Boolean,
          showAllBooks:         Boolean,
          language:             IsoLanguage,
          format:               BsFormatType,
          brailleGrade:         BsBrailleGrade,
          brailleFormat:        BsBrailleFmt,
          brailleCellLineWidth: Integer,
          useUeb:               Boolean,
        },
        reference_page:         'membership',
        reference_id:           '_put-user-account-preferences'
      }
    end

  # ===========================================================================
  # :section: Periodical subscriptions
  # ===========================================================================

  public

  # == GET /v2/accounts/(userIdentifier)/periodicals
  #
  # == 2.1.21. Get periodical subscriptions of a user
  # Get the list of periodical subscriptions for an existing user.
  #
  # @param [User, String, nil] user   Default: `@user`.
  # @param [Hash]              opt    Passed to #api.
  #
  # @return [Bs::Message::PeriodicalSubscriptionList]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_get-periodicals-user
  #
  def get_periodical_subscriptions(user: nil, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:get, 'accounts', userId, 'periodicals', **opt)
    Bs::Message::PeriodicalSubscriptionList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
        },
        reference_page:   'membership',
        reference_id:     '_get-periodicals-user'
      }
    end

  # == POST /v2/accounts/(userIdentifier)/periodicals
  #
  # == 2.1.22. Subscribe to a periodical series for a user
  # Subscribe to a periodical series for an existing user.
  #
  # @param [User, String, nil] user   Default: `@user`.
  # @param [Hash]              opt    Passed to #api.
  #
  # @option opt [String]             :seriesId                      *REQUIRED*
  # @option opt [BsPeriodicalFormat] :format                        *REQUIRED*
  #
  # @return [Bs::Message::PeriodicalSubscriptionList]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_subscribe-periodical-series
  #
  def subscribe_periodical(user: nil, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:post, 'accounts', userId, 'periodicals', **opt)
    Bs::Message::PeriodicalSubscriptionList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          seriesId:       String,
          format:         BsPeriodicalFormat,
        },
        reference_page:   'membership',
        reference_id:     '_subscribe-periodical-series'
      }
    end

  # == DELETE /v2/accounts/(userIdentifier)/periodicals/(seriesId)
  #
  # == 2.1.23. Unsubscribe from a periodical series for a user
  # Unsubscribe from a periodical series for an existing user.
  #
  # @param [User, String, nil] user       Default: `@user`.
  # @param [String]            seriesId
  # @param [Hash]              opt        Passed to #api.
  #
  # @return [Bs::Message::PeriodicalSubscriptionList]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_unsubscribe-periodical-series
  #
  def unsubscribe_periodical(user: nil, seriesId:, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:delete, 'accounts', userId, 'periodicals', seriesId, **opt)
    Bs::Message::PeriodicalSubscriptionList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          seriesId:       String,
        },
        reference_page:   'membership',
        reference_id:     '_unsubscribe-periodical-series'
      }
    end

  # ===========================================================================
  # :section: Reading lists
  # ===========================================================================

  public

  # == GET /v2/accounts/(userIdentifier)/lists
  #
  # == 2.1.24. Get reading lists for a given user
  # Request the list of reading lists that a given user is able to see. These
  # could be private lists, shared lists, or organization lists that the user
  # is subscribed to.
  #
  # @param [User, String, nil] user   Default: `@user`.
  # @param [Hash]              opt    Passed to #api.
  #
  # @option opt [String]                   :start
  # @option opt [Integer]                  :limit       Default: 10
  # @option opt [BsMyReadingListSortOrder] :sortOrder   Default: 'name'
  # @option opt [BsSortDirection]          :direction   Default: 'asc'
  #
  # @return [Bs::Message::ReadingListList]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_get-member-readinglists-list
  #
  def get_reading_lists(user: nil, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:get, 'accounts', userId, 'lists', **opt)
    Bs::Message::ReadingListList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
        },
        optional: {
          start:     String,
          limit:     Integer,
          sortOrder: BsMyReadingListSortOrder,
          direction: BsSortDirection,
        },
        reference_page:   'membership',
        reference_id:     '_get-member-readinglists-list'
      }
    end

  # == POST /v2/accounts/(userIdentifier)/lists
  #
  # == 2.1.25. Create a reading list for a given user
  # Create an empty reading list that will be owned by the given user, with the
  # properties provided.
  #
  # @param [User, String, nil] user   Default: `@user`.
  # @param [Hash]              opt    Passed to #api.
  #
  # @option opt [String]   :name                                     *REQUIRED*
  # @option opt [BsAccess] :access                                   *REQUIRED*
  # @option opt [String]   :description
  #
  # @return [Bs::Message::ReadingList]
  #
  # @see https://apidocs.bookshare.org/membership/index.html#_post-member-readinglist-create
  #
  def create_reading_list(user: nil, **opt)
    opt    = get_parameters(__method__, **opt)
    userId = opt.delete(:userIdentifier) || name_of(user || @user)
    api(:post, 'accounts', userId, 'lists', **opt)
    Bs::Message::ReadingList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          name:           String,
          access:         BsAccess,
        },
        optional: {
          description:    String,
        },
        reference_page:   'membership',
        reference_id:     '_post-member-readinglist-create'
      }
    end

end

__loading_end(__FILE__)
