# app/models/member.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Model for the representation of a DSO member.
#
# == Usage Notes
# @see https://www.bookshare.org/orgAccountMembers:
# Members are students or clients who have a qualifying reading barrier.
#
# @see https://www.bookshare.org/cms/help-center/what-individual-membership-account
# An Individual Membership (IM) is a qualified adult or student's personal
# Bookshare account with Bookshare. IM's can freely search for and download
# books in any of the Bookshare accessible formats, unlike Organizational
# Members who only have limited access to books shared with them on Reading
# Lists. IM's can be linked with an Organizational Membership if desired to
# allow a sponsor or a teacher to share books with them on Reading Lists.
#
# @see https://www.bookshare.org/cms/help-center/what-organizational-membership-account
# Organizational Members (OM's) are qualified Bookshare users that are
# registered on an Organization's Bookshare account. Sponsors, generally
# teachers or other school staff, add students to their school's roster as
# Organizational Members.
#
# Organizational Members can log in to their own Bookshare account once a
# Sponsor creates a username and password for them. However, Organizational
# Members have limited access to our books as they can only download books that
# have been shared with them via a Reading List through a Bookshare integrated
# application.
#
# @see https://www.bookshare.org/cms/help-center/what-linked-account
# Linked accounts (OM+IM's) are combined Individual and Organizational
# accounts. With a Linked account students can access books that have been
# assigned to them by a sponsor as well as search and download books
# themselves.
#
class Member < ApplicationRecord

  belongs_to :user, optional: true

  has_and_belongs_to_many :reading_lists

  # ===========================================================================
  # :section: Authorization
  # ===========================================================================

  resourcify

  # ===========================================================================
  # :section: Validations
  # ===========================================================================

  validate on: :create do
    if linked_account? && User.find_by(email: emailAddress).nil?
      errors.add(:base, 'An institutional member must also be a User')
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the member is both an Organizational Member and an
  # Institutional Member.
  #
  def linked_account?
    institutional.present?
  end

end

__loading_end(__FILE__)
