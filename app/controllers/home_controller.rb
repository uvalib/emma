# app/controllers/home_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Home pages.
#
# @see app/views/home
#
class HomeController < ApplicationController

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /home
  # The main application page.
  #
  def index
  end

  # == GET /home/welcome
  # The main application page for anonymous users.
  #
  def welcome
  end

  # == GET /home/dashboard
  # The main application page for authenticated users.
  #
  def dashboard
  end

end

__loading_end(__FILE__)
