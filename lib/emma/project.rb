# lib/emma/project.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Emma::Project
#
module Emma::Project

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The web site for project information.
  #
  # @type [String]
  #
  PROJECT_SITE = config_item('emma.project.site').freeze

  # The email address for project information.
  #
  # @type [String]
  #
  PROJECT_EMAIL = config_item('emma.project.email').freeze

  # The email address for support and general information.
  #
  # @type [String]
  #
  CONTACT_EMAIL = config_item('emma.contact.email').freeze

end

__loading_end(__FILE__)
