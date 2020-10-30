# app/services/bookshare_service/request/membership_user_accounts.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# BookshareService::Request::MembershipUserAccounts
#
# == Usage Notes
#
# === From API section 2.10 (Membership Assistant - User Accounts):
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

  # == GET /v2/accounts/{userIdentifier}
  #
  # == 2.10.1. Look up user account
  # Get details about the specified user account.  (Membership Assistants are
  # only allowed to search for users associated with the same Site as them.)
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    Passed to #api.
  #
  # @return [Bs::Message::UserAccount]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-useraccount-search
  #
  def get_account(user: @user, **opt)
    userIdentifier = name_of(user)
    api(:get, 'accounts', userIdentifier, **opt)
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
        reference_id:     '_get-useraccount-search'
      }
    end

  # == PUT /v2/accounts/{userIdentifier}
  #
  # == 2.10.2. Update a user account
  # Update an existing user account.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    Passed to #api.
  #
  # @option opt [String]      :firstName
  # @option opt [String]      :lastName
  # @option opt [String]      :phoneNumber
  # @option opt [String]      :emailAddress
  # @option opt [String]      :address1
  # @option opt [String]      :address2
  # @option opt [String]      :city
  # @option opt [String]      :state
  # @option opt [String]      :country
  # @option opt [String]      :postalCode
  # @option opt [String]      :guardianFirstName
  # @option opt [String]      :guardianLastName
  # @option opt [String]      :dateOfBirth
  # @option opt [IsoLanguage] :language
  # @option opt [Boolean]     :allowAdultContent
  # @option opt [SiteType]    :site
  # @option opt [RoleType]    :role
  # @option opt [String]      :password
  #
  # @return [Bs::Message::UserAccount]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_update-useraccount
  #
  def update_account(user: @user, **opt)
    userIdentifier = name_of(user)
    opt = get_parameters(__method__, **opt)
    api(:put, 'accounts', userIdentifier, **opt)
    Bs::Message::UserAccount.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:              :userIdentifier,
        },
        required: {
          userIdentifier:    String,
        },
        optional: {
          firstName:         String,
          lastName:          String,
          phoneNumber:       String,
          emailAddress:      String,
          address1:          String,
          address2:          String,
          city:              String,
          state:             String,
          country:           String,
          postalCode:        String,
          guardianFirstName: String,
          guardianLastName:  String,
          dateOfBirth:       String,
          language:          IsoLanguage,
          allowAdultContent: Boolean,
          site:              SiteType,
          role:              RoleType,
          password:          String,
        },
        reference_id:        '_update-useraccount'
      }
    end

  # == POST /v2/accounts
  #
  # == 2.10.3. Create a user account
  # Create a new user account.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @option opt [String]      :firstName          *REQUIRED*
  # @option opt [String]      :lastName           *REQUIRED*
  # @option opt [String]      :phoneNumber
  # @option opt [String]      :emailAddress       *REQUIRED*
  # @option opt [String]      :address1           *REQUIRED*
  # @option opt [String]      :address2
  # @option opt [String]      :city               *REQUIRED*
  # @option opt [String]      :state
  # @option opt [String]      :country            *REQUIRED*
  # @option opt [String]      :postalCode         *REQUIRED*
  # @option opt [String]      :guardianFirstName
  # @option opt [String]      :guardianLastName
  # @option opt [String]      :dateOfBirth
  # @option opt [IsoLanguage] :language
  # @option opt [Boolean]     :allowAdultContent
  # @option opt [SiteType]    :site
  # @option opt [RoleType]    :role
  # @option opt [String]      :password
  #
  # @return [Bs::Message::UserAccount]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_create-useraccount
  #
  def create_account(**opt)
    opt = get_parameters(__method__, **opt)
    api(:post, 'accounts', **opt)
    Bs::Message::UserAccount.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        required: {
          firstName:         String,
          lastName:          String,
          emailAddress:      String,
          address1:          String,
          city:              String,
          country:           String,
          postalCode:        String,
        },
        optional: {
          phoneNumber:       String,
          address2:          String,
          state:             String,
          guardianFirstName: String,
          guardianLastName:  String,
          dateOfBirth:       String,
          language:          IsoLanguage,
          allowAdultContent: Boolean,
          site:              SiteType,
          role:              RoleType,
          password:          String,
        },
        reference_id:        '_create-useraccount'
      }
    end

  # == PUT /v2/accounts/{userIdentifier}/password
  #
  # == 2.10.16. Update user password
  # Update the password for an existing user.
  #
  # @param [User, String, nil] user       Default: @user
  # @param [String]            password
  # @param [Hash]              opt        Passed to #api.
  #
  # @return [Bs::Message::StatusModel]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_update-membership-password
  #
  def update_account_password(user: @user, password:, **opt)
    userIdentifier = name_of(user)
    opt[:password] = password
    api(:put, 'accounts', userIdentifier, 'password', **opt)
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
        reference_id:     '_update-membership-password'
      }
    end

  # ===========================================================================
  # :section: Subscriptions
  # ===========================================================================

  public

  # == GET /v2/accounts/{userIdentifier}/subscriptions
  #
  # == 2.10.4. Get subscriptions
  # Get the list of membership subscriptions for an existing user.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    Passed to #api.
  #
  # @return [Bs::Message::UserSubscriptionList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-membership-subscriptions
  #
  def get_subscriptions(user: @user, **opt)
    userIdentifier = name_of(user)
    api(:get, 'accounts', userIdentifier, 'subscriptions', **opt)
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
        reference_id:     '_get-membership-subscriptions'
      }
    end

  # == POST /v2/accounts/{userIdentifier}/subscriptions
  #
  # == 2.10.5. Create a subscription
  # Create a new membership subscription for an existing user.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    Passed to #api.
  #
  # @option opt [IsoDay]    :startDate              *REQUIRED*
  # @option opt [IsoDay]    :endDate
  # @option opt [String]    :userSubscriptionType   *REQUIRED*
  # @option opt [Integer]   :numBooksAllowed
  # @option opt [Timeframe] :downloadTimeframe
  # @option opt [String]    :notes
  #
  # @return [Bs::Message::UserSubscription]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_create-membership-subscription
  #
  def create_subscription(user: @user, **opt)
    userIdentifier = name_of(user)
    opt = get_parameters(__method__, **opt)
    api(:post, 'accounts', userIdentifier, 'subscriptions', **opt)
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
          downloadTimeframe:    Timeframe,
          notes:                String,
        },
        reference_id:           '_create-membership-subscription'
      }
    end

  # == GET /v2/accounts/{userIdentifier}/subscriptions/{subscriptionId}
  #
  # == 2.10.6. Get single subscription
  # Get the specified membership subscription for an existing user.
  #
  # @param [User, String, nil] user             Default: @user
  # @param [String]            subscriptionId
  # @param [Hash]              opt              Passed to #api.
  #
  # @return [Bs::Message::UserSubscription]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-single-membership-subscription
  #
  def get_subscription(user: @user, subscriptionId:, **opt)
    userId = name_of(user)
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
        reference_id:     '_get-single-membership-subscription'
      }
    end

  # == PUT /v2/accounts/{userIdentifier}/subscriptions/{subscriptionId}
  #
  # == 2.10.7. Update a subscription
  # Update an existing membership subscription for an existing user.
  #
  # @param [User, String, nil] user             Default: @user
  # @param [String]            subscriptionId
  # @param [Hash]              opt              Passed to #api.
  #
  # @option opt [IsoDay]    :startDate              *REQUIRED*
  # @option opt [IsoDay]    :endDate
  # @option opt [String]    :userSubscriptionType   *REQUIRED*
  # @option opt [Integer]   :numBooksAllowed
  # @option opt [Timeframe] :downloadTimeframe
  # @option opt [String]    :notes
  #
  # @return [Bs::Message::UserSubscription]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_update-membership-subscription
  #
  def update_subscription(user: @user, subscriptionId:, **opt)
    userId = name_of(user)
    opt = get_parameters(__method__, **opt)
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
          downloadTimeframe:    Timeframe,
          notes:                String,
        },
        reference_id:           '_update-membership-subscription'
      }
    end

  # == GET /v2/subscriptiontypes
  #
  # == 2.10.8. Get subscription types
  # Get the list of subscription types available to users of the Membership
  # Assistant’s site.
  #
  # @param [Hash] opt                 Passed to #api.
  #
  # @return [Bs::Message::UserSubscriptionTypeList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-membership-subscription-types
  #
  def get_subscription_types(**opt)
    api(:get, 'subscriptiontypes', **opt)
    Bs::Message::UserSubscriptionTypeList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        reference_id: '_get-membership-subscription-types'
      }
    end

  # ===========================================================================
  # :section: Proof of disability
  # ===========================================================================

  public

  # == GET /v2/accounts/{userIdentifier}/pod
  #
  # == 2.10.9. Get proof of disability
  # Get the list of disabilities for an existing user.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    Passed to #api.
  #
  # @return [Bs::Message::UserPodList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-membership-pods
  #
  def get_user_pod(user: @user, **opt)
    userIdentifier = name_of(user)
    api(:post, 'accounts', userIdentifier, 'pod', **opt)
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
        reference_id:     '_get-membership-pods'
      }
    end

  # == POST /v2/accounts/{userIdentifier}/pod
  #
  # == 2.10.10. Create a proof of disability
  # Create a new record of a disability for an existing user.
  #
  # @param [User, String, nil]       user             Default: @user
  # @param [DisabilityType]          disabilityType
  # @param [ProofOfDisabilitySource] proofSource
  # @param [Hash]                    opt              Passed to #api.
  #
  # @return [Bs::Message::UserPodList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_create-membership-pod
  #
  def create_user_pod(user: @user, disabilityType:, proofSource:, **opt)
    userIdentifier       = name_of(user)
    opt[:disabilityType] = disabilityType
    opt[:proofSource]    = proofSource
    api(:post, 'accounts', userIdentifier, 'pod', **opt)
    Bs::Message::UserPodList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          disabilityType: DisabilityType,
          proofSource:    ProofOfDisabilitySource,
        },
        reference_id:     '_create-membership-pod'
      }
    end

  # == PUT /v2/accounts/{userIdentifier}/pod/{disabilityType}
  #
  # == 2.10.11. Update a proof of disability
  # Update the proof source for a disability for an existing user.
  #
  # @param [User, String, nil]       user             Default: @user
  # @param [DisabilityType]          disabilityType
  # @param [ProofOfDisabilitySource] proofSource
  # @param [Hash]                    opt              Passed to #api.
  #
  # @return [Bs::Message::UserPodList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_update-membership-pod
  #
  def update_user_pod(user: @user, disabilityType:, proofSource:, **opt)
    userIdentifier    = name_of(user)
    opt[:proofSource] = proofSource
    api(:put, 'accounts', userIdentifier, 'pod', disabilityType, **opt)
    Bs::Message::UserPodList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          disabilityType: DisabilityType,
          proofSource:    ProofOfDisabilitySource,
        },
        reference_id:     '_update-membership-pod'
      }
    end

  # == DELETE /v2/accounts/{userIdentifier}/pod/{disabilityType}
  #
  # == 2.10.12. Remove a proof of disability
  # Remove a proof of disability for an existing user.
  #
  # @param [User, String, nil] user             Default: @user
  # @param [DisabilityType]    disabilityType
  # @param [Hash]              opt              Passed to #api.
  #
  # @return [Bs::Message::UserPodList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_delete-membership-pod
  #
  def remove_user_pod(user: @user, disabilityType:, **opt)
    userIdentifier = name_of(user)
    api(:delete, 'accounts', userIdentifier, 'pod', disabilityType, **opt)
    Bs::Message::UserPodList.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:           :userIdentifier,
        },
        required: {
          userIdentifier: String,
          disabilityType: DisabilityType,
        },
        reference_id:     '_delete-membership-pod'
      }
    end

  # ===========================================================================
  # :section: Agreements
  # ===========================================================================

  public

  # == GET /v2/accounts/{userIdentifier}/agreements
  #
  # == 2.10.13. Get a list of signed agreements
  # Get the list of signed agreements for an existing user.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    Passed to #api.
  #
  # @return [Bs::Message::UserSignedAgreementList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-signed-agreements
  #
  def get_user_agreements(user: @user, **opt)
    userIdentifier = name_of(user)
    api(:post, 'accounts', userIdentifier, 'agreements', **opt)
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
        reference_id:     '_get-signed-agreements'
      }
    end

  # == POST /v2/accounts/{userIdentifier}/agreements
  #
  # == 2.10.14. Create a new signed agreement
  # Create a new signed agreement record for an existing user
  #
  # @param [User, String, nil] user           Default: @user
  # @param [AgreementType]     agreementType
  # @param [String]            dateSigned
  # @param [String]            printName
  # @param [Hash]              opt            Passed to #api.
  #
  # @option opt [String] :signedByLegalGuardian
  #
  # @return [Bs::Message::UserSignedAgreement]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_create-signed-agreement
  #
  def create_user_agreement(
    user: @user, agreementType:, dateSigned:, printName:, **opt
  )
    userIdentifier = name_of(user)
    opt = get_parameters(__method__, **opt)
    opt&.merge!(
      agreementType: agreementType,
      dateSigned:    dateSigned,
      printName:     printName
    )
    api(:post, 'accounts', userIdentifier, 'agreements', **opt)
    Bs::Message::UserSignedAgreement.new(response, error: exception)
  end
    .tap do |method|
      add_api method => {
        alias: {
          user:                  :userIdentifier,
        },
        required: {
          userIdentifier:        String,
          agreementType:         AgreementType,
          dateSigned:            String,
          printName:             String,
        },
        optional: {
          signedByLegalGuardian: String,
        },
        reference_id:            '_create-signed-agreement'
      }
    end

  # == POST /v2/accounts/{userIdentifier}/agreements/{id}/expired
  #
  # == 2.10.15. Expire a signed agreement
  # Expire a signed agreement.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [String]            id     Agreement ID
  # @param [Hash]              opt    Passed to #api.
  #
  # @return [Bs::Message::UserSignedAgreement]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_expire-signed-agreement
  #
  def remove_user_agreement(user: @user, id:, **opt)
    userIdentifier = name_of(user)
    api(:post, 'accounts', userIdentifier, 'agreements', id, 'expired', **opt)
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
        reference_id:     '_expire-signed-agreement'
      }
    end

  # ===========================================================================
  # :section: Recommendation profile
  # ===========================================================================

  public

  # == GET /v2/accounts/{userIdentifier}/recommendationProfile
  #
  # == 2.10.17. Get recommendation profile
  # Get property choices that guide title recommendations for the given user.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    Passed to #api.
  #
  # @return [Bs::Message::RecommendationProfile]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-recommendation-profile
  #
  def get_recommendation_profile(user: @user, **opt)
    userIdentifier = name_of(user)
    api(:get, 'accounts', userIdentifier, 'recommendationProfile', **opt)
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
        reference_id:     '_get-recommendation-profile'
      }
    end

  # == PUT /v2/accounts/{userIdentifier}/recommendationProfile
  #
  # == 2.10.18. Update recommendation profile
  # Update property choices that guide title recommendations for the given
  # user.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    Passed to #api.
  #
  # @option opt [Boolean]      :includeGlobalCollection   Default: *false*
  # @option opt [NarratorType] :narratorType
  # @option opt [Gender]       :narratorGender
  # @option opt [Integer]      :readingAge
  # @option opt [ContentWarning,Array<ContentWarning>] :excludedContentWarnings
  # @option opt [ContentWarning,Array<ContentWarning>] :includedContentWarnings
  # @option opt [String, Array<String>]                :excludedCategories
  # @option opt [String, Array<String>]                :includedCategories
  # @option opt [String, Array<String>]                :excludedAuthors
  # @option opt [String, Array<String>]                :includedAuthors
  #
  # @return [Bs::Message::RecommendationProfile]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_put-recommendation-profile
  #
  def update_recommendation_profile(user: @user, **opt)
    userIdentifier = name_of(user)
    opt = get_parameters(__method__, **opt)
    api(:put, 'accounts', userIdentifier, 'recommendationProfile', **opt)
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
          narratorType:            NarratorType,
          narratorGender:          Gender,
          readingAge:              Integer,
          excludedContentWarnings: ContentWarning,
          includedContentWarnings: ContentWarning,
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
        reference_id:              '_put-recommendation-profile'
      }
    end

  # ===========================================================================
  # :section: Preferences
  # ===========================================================================

  public

  # == GET /v2/accounts/{userIdentifier}/preferences
  #
  # == 2.10.19. Get user account preferences
  # Get the account preferences associated with the given user.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    Passed to #api.
  #
  # @return [Bs::Message::MyAccountPreferences]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-user-account-preferences
  #
  def get_preferences(user: @user, **opt)
    userIdentifier = name_of(user)
    api(:get, 'accounts', userIdentifier, 'preferences', **opt)
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
        reference_id:     '_get-user-account-preferences'
      }
    end

  # == PUT /v2/accounts/{userIdentifier}/preferences
  #
  # == 2.10.20. Update user account preferences
  # Update the account preferences associated with the given user.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    Passed to #api.
  #
  # @option opt [Boolean]       :allowAdultContent
  # @option opt [Boolean]       :showAllBooks           Default: *false*
  # @option opt [IsoLanguage]   :language
  # @option opt [FormatType]    :format
  # @option opt [BrailleGrade]  :brailleGrade
  # @option opt [BrailleFmt]    :brailleFormat
  # @option opt [Integer]       :brailleCellLineWidth
  # @option opt [Boolean]       :useUeb                 Default: *false*
  #
  # @return [Bs::Message::MyAccountPreferences]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_put-user-account-preferences
  #
  def update_preferences(user: @user, **opt)
    userIdentifier = name_of(user)
    opt = get_parameters(__method__, **opt)
    api(:put, 'accounts', userIdentifier, 'preferences', **opt)
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
          format:               FormatType,
          brailleGrade:         BrailleGrade,
          brailleFormat:        BrailleFmt,
          brailleCellLineWidth: Integer,
          useUeb:               Boolean,
        },
        reference_id:           '_put-user-account-preferences'
      }
    end

  # ===========================================================================
  # :section: Periodical subscriptions
  # ===========================================================================

  public

  # == GET /v2/accounts/{userIdentifier}/periodicals
  #
  # == 2.10.21. Get periodical subscriptions of a user
  # Get the list of periodical subscriptions for an existing user.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    Passed to #api.
  #
  # @return [Bs::Message::PeriodicalSubscriptionList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-periodicals-user
  #
  def get_periodical_subscriptions(user: @user, **opt)
    userIdentifier = name_of(user)
    api(:get, 'accounts', userIdentifier, 'periodicals', **opt)
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
        reference_id:     '_get-periodicals-user'
      }
    end

  # == POST /v2/accounts/{userIdentifier}/periodicals
  #
  # == 2.10.22. Subscribe to a periodical series for a user
  # Subscribe to a periodical series for an existing user.
  #
  # @param [User, String, nil]    user      Default: @user
  # @param [String]               seriesId
  # @param [PeriodicalFormatType] format
  # @param [Hash]                 opt       Passed to #api.
  #
  # @return [Bs::Message::PeriodicalSubscriptionList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_subscribe-periodical-series
  #
  def subscribe_periodical(user: @user, seriesId:, format:, **opt)
    userIdentifier = name_of(user)
    prm = encode_parameters(seriesId: seriesId, format: format)
    api(:post, 'accounts', userIdentifier, 'periodicals', **prm, **opt)
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
          format:         PeriodicalFormatType,
        },
        reference_id:     '_subscribe-periodical-series'
      }
    end

  # == DELETE /v2/accounts/{userIdentifier}/periodicals/{seriesId}
  #
  # == 2.10.23. Unsubscribe from a periodical series for a user
  # Unsubscribe from a periodical series for an existing user.
  #
  # @param [User, String, nil] user       Default: @user
  # @param [String]            seriesId
  # @param [Hash]              opt        Passed to #api.
  #
  # @return [Bs::Message::PeriodicalSubscriptionList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_unsubscribe-periodical-series
  #
  def unsubscribe_periodical(user: @user, seriesId:, **opt)
    userIdentifier = name_of(user)
    api(:delete, 'accounts', userIdentifier, 'periodicals', seriesId, **opt)
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
        reference_id:     '_unsubscribe-periodical-series'
      }
    end

  # ===========================================================================
  # :section: Reading lists
  # ===========================================================================

  public

  # == GET /v2/accounts/{userIdentifier}/lists
  #
  # == 2.10.24. Get reading lists for a given user
  # Get the list of periodical subscriptions for an existing user.
  #
  # @param [User, String, nil] user   Default: @user
  # @param [Hash]              opt    Passed to #api.
  #
  # @option opt [String]                 :start
  # @option opt [Integer]                :limit       Default: 10
  # @option opt [MyReadingListSortOrder] :sortOrder   Default: 'name'
  # @option opt [Direction]              :direction   Default: 'asc'
  #
  # @return [Bs::Message::ReadingListList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_get-member-readinglists-list
  #
  def get_reading_lists(user: @user, **opt)
    userIdentifier = name_of(user)
    opt = get_parameters(__method__, **opt)
    api(:get, 'accounts', userIdentifier, 'lists', **opt)
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
          start:          String,
          limit:          Integer,
          sortOrder:      MyReadingListSortOrder,
          direction:      Direction,
        },
        reference_id:     '_get-member-readinglists-list'
      }
    end

  # == POST /v2/accounts/{userIdentifier}/lists
  #
  # == 2.10.25. Create a reading list for a given user
  # Create an empty reading list that will be owned by the given user, with the
  # properties provided.
  #
  # @param [User, String, nil] user           Default: @user
  # @param [String]            name
  # @param [Access]            access
  # @param [Hash]              opt            Passed to #api.
  #
  # @option opt [String] :description
  #
  # @return [Bs::Message::ReadingList]
  #
  # @see https://apidocs.bookshare.org/reference/index.html#_post-member-readinglist-create
  #
  def create_reading_list(user: @user, name:, access:, **opt)
    userIdentifier = name_of(user)
    opt = get_parameters(__method__, **opt)
    opt&.merge!(name: name, access: access)
    api(:post, 'accounts', userIdentifier, 'lists', **opt)
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
          access:         Access,
        },
        optional: {
          description:    String,
        },
        reference_id:     '_post-member-readinglist-create'
      }
    end

end

__loading_end(__FILE__)
