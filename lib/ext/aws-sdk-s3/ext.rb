# lib/ext/aws-sdk-s3/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for 'aws-sdk-s3' which is only activated by ENV['DEBUG_AWS'].

__loading_begin(__FILE__)

require 'aws-sdk-s3'
require_subdirs(__FILE__)

__loading_end(__FILE__)
