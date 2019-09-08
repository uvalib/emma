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

end
