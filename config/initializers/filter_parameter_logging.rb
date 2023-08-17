# config/initializers/filter_parameter_logging.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Be sure to restart your server when you modify this file.

# Configure parameters to be filtered from the log file. Use this to limit
# dissemination of sensitive information. See ActiveSupport::ParameterFilter
# documentation for supported notations and behaviors.
# noinspection SpellCheckingInspection
Rails.application.config.filter_parameters +=
  %i[passw secret token _key crypt salt certificate otp ssn]
Rails.application.config.filter_parameters = [] if not_deployed?
