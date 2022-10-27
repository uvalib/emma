# config/initializers/aws.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Setup and initialization for 'aws-sdk-core', 'aws-sdk-s3' and other AWS gems.

Aws.config[:log_level]    = DEBUG_AWS ? :debug : :info
Aws.config[:logger]       = Log.new(progname: 'AWS')
Aws.config[:logger].level = Log.log_level(Aws.config[:log_level])
