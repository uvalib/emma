# app/services/aws_s3_service/definition.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Interface to the shared data structure which holds the definition of the API
# requests and parameters.
#
module AwsS3Service::Definition

  # @private
  def self.included(base)
    base.send(:include, ApiService::Definition)
  end

end

__loading_end(__FILE__)
