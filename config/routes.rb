# config/routes.rb
#
# frozen_string_literal: true
# warn_indent:           true

Rails.application.routes.draw do

  # ===========================================================================
  # :section: API test routes
  # ===========================================================================

  get '/api', to: 'api#index'

  # ===========================================================================
  # :section: Home page
  # ===========================================================================

  root to: 'api#index'

end
