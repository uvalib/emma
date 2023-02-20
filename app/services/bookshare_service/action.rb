# app/services/bookshare_service/action.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Namespace for API requests.
#
module BookshareService::Action
  include BookshareService::Action::ActiveTitles
  include BookshareService::Action::AssignedTitles
  include BookshareService::Action::Bookmarks
  include BookshareService::Action::CollectionPeriodicals
  include BookshareService::Action::CollectionTitles
  include BookshareService::Action::MembershipActiveTitles
  include BookshareService::Action::MembershipMessages
  include BookshareService::Action::MembershipOrganizations
  include BookshareService::Action::MembershipUserAccounts
  include BookshareService::Action::Messages
  include BookshareService::Action::Organization
  include BookshareService::Action::Periodicals
  include BookshareService::Action::PopularLists
  include BookshareService::Action::ReadingActivity
  include BookshareService::Action::ReadingLists
  include BookshareService::Action::Recommendations
  include BookshareService::Action::Titles
  include BookshareService::Action::UserAccount
end

__loading_end(__FILE__)