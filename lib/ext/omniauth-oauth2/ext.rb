# lib/ext/omniauth-oauth2/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the Omniauth-OAuth2 gem.

__loading_begin(__FILE__)

require 'ext/oauth2/ext'
require 'ext/omniauth/ext'
require 'omniauth-oauth2'
require_subdir(__FILE__)

__loading_end(__FILE__)

# TODO: debugging -- remove lib/ext/omniauth-oauth2/** when done
