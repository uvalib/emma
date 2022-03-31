# app/decorators/members_decorator.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Collection presenter for "/member" pages.
#
# @!attribute [r] object
#   Set in Draper#initialize
#   @return [Array<Bs::Record::UserAccount>]
#
class MembersDecorator < BaseCollectionDecorator

  # ===========================================================================
  # :section: Draper
  # ===========================================================================

  collection_of MemberDecorator

end

__loading_end(__FILE__)
