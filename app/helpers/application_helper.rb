# app/helpers/application_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Common helper methods.
#
module ApplicationHelper

  # The name of this application for display purposes.
  #
  # @type [String]
  #
  APP_NAME = I18n.t('emma.application.name')

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The name of this application for display purposes.
  #
  # @return [String]
  #
  def app_name
    APP_NAME
  end

end
