# test/test_helper/utility.rb
#
# frozen_string_literal: true
# warn_indent:           true

# General utility methods.
#
module TestHelper::Utility

  CDN_URL = 'https://d1lp72kdku3ux1.cloudfront.net'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The URL for a catalog title thumbnail.
  #
  # @param [String] bookshare_id
  #
  # @return [String]
  #
  def cdn_thumbnail(bookshare_id)
    "#{CDN_URL}/title_instance/13e/small/%s.jpg" % bookshare_id
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return a User instance from the given identification.
  #
  # @param [String, Symbol, User, *] user
  #
  # @return [User]
  # @return [nil]                     If *user* could not be converted.
  #
  def find_user(user)
    user = user.sub(/@.*$/, '').to_sym if user.is_a?(String)
    user = users(user) if user.is_a?(Symbol)
    user if user.is_a?(User)
  end

end
