# app/records/bs/record/sponsor.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Bs::Record::Sponsor
#
# @attr [Boolean]                 allowAdultContent
# @attr [Boolean]                 canDownload
# @attr [Boolean]                 deleted
# @attr [String]                  emailAddress
# @attr [Boolean]                 hasAgreement
# @attr [String]                  language
# @attr [Array<Bs::Record::Link>] links
# @attr [Boolean]                 locked
# @attr [Bs::Record::Name]        name
# @attr [String]                  phoneNumber
# @attr [SiteType]                site
# @attr [String]                  title
#
# @see https://apidocs.bookshare.org/reference/index.html#_sponsor
#
class Bs::Record::Sponsor < Bs::Api::Record

  include Bs::Shared::AccountMethods
  include Bs::Shared::LinkMethods

  schema do
    attribute :allowAdultContent, Boolean
    attribute :canDownload,       Boolean
    attribute :deleted,           Boolean
    attribute :emailAddress,      String
    attribute :hasAgreement,      Boolean
    attribute :language,          String
    has_many  :links,             Bs::Record::Link
    attribute :locked,            Boolean
    has_one   :name,              Bs::Record::Name
    attribute :phoneNumber,       String
    attribute :site,              SiteType
    attribute :title,             String
  end

end

__loading_end(__FILE__)
