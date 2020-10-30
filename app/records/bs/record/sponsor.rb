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
    has_one   :allowAdultContent, Boolean
    has_one   :canDownload,       Boolean
    has_one   :deleted,           Boolean
    has_one   :emailAddress
    has_one   :hasAgreement,      Boolean
    has_one   :language
    has_many  :links,             Bs::Record::Link
    has_one   :locked,            Boolean
    has_one   :name,              Bs::Record::Name
    has_one   :phoneNumber
    has_one   :site,              SiteType
    has_one   :title
  end

end

__loading_end(__FILE__)
