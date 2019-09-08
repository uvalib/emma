# app/models/api/sponsor.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Api::Sponsor
#
# @attr [Boolean]            allowAdultContent
# @attr [Boolean]            canDownload
# @attr [Boolean]            deleted
# @attr [String]             emailAddress
# @attr [Boolean]            hasAgreement
# @attr [String]             language
# @attr [Array<Api::Link>]   links
# @attr [Boolean]            locked
# @attr [Api::Name]          name
# @attr [String]             phoneNumber
# @attr [SiteType]           site
# @attr [SubscriptionStatus] subscriptionStatus
# @attr [String]             title
#
# @see https://apidocs.bookshare.org/reference/index.html#_sponsor
#
class Api::Sponsor < Api::Record::Base

  include Api::Common::AccountMethods
  include Api::Common::LinkMethods

  schema do
    attribute :allowAdultContent,   Boolean
    attribute :canDownload,         Boolean
    attribute :deleted,             Boolean
    attribute :emailAddress,        String
    attribute :hasAgreement,        Boolean
    attribute :language,            String
    has_many  :links,               Api::Link
    attribute :locked,              Boolean
    has_one   :name,                Api::Name
    attribute :phoneNumber,         String
    attribute :site,                SiteType
    attribute :subscriptionStatus,  SubscriptionStatus
    attribute :title,               String
  end

end

__loading_end(__FILE__)
