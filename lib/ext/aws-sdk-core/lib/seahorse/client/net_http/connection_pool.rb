# lib/ext/aws-sdk-core/lib/seahorse/client/net_http/connection_pool.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for 'aws-sdk-s3'.

__loading_begin(__FILE__)

require 'seahorse/client/net_http/connection_pool'

module Seahorse
  module Client
    module NetHttp
      class ConnectionPool
        @default_logger =
          if (logger = Aws.config[:logger])
            Log.new(logger)
          else
            Log.new(progname: 'AWS', level: (Aws.config[:log_level] || :info))
          end
      end
    end
  end
end

__loading_end(__FILE__)
