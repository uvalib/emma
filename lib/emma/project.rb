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
  PROJECT_SITE = config_item(:project, :site).freeze

  # The email address for project information.
  #
  # @type [String]
  #
  PROJECT_EMAIL = config_item(:project, :email).freeze

  # The web site for the "emma-users" mailing list.
  #
  # @type [String]
  #
  MAILING_LIST_SITE = config_item(:mailing_list, :site).freeze

  # The email address for the "emma-users" mailing list.
  #
  # @type [String]
  #
  MAILING_LIST_EMAIL = config_item(:mailing_list, :email).freeze

  # The email address for general information.
  #
  # @type [String]
  #
  CONTACT_EMAIL = config_item(:contact, :email).freeze

  # The email address for support.
  #
  # @type [String]
  #
  HELP_EMAIL = CONTACT_EMAIL

  # The email address for requesting EMMA enrollment.
  #
  # @type [String]
  #
  ENROLL_EMAIL = config_item(:enroll, :email).freeze

end

__loading_end(__FILE__)
