# app/records/aws_s3/api/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Values related to the details of serialization/de-serialization.
#
module AwsS3::Api::Schema

  include Api::Schema

  # ===========================================================================
  # :section: Api::Schema overrides
  # ===========================================================================

  public

  # The class name of the related service for logging.
  #
  # @return [String]
  #
  def service_name
    'AwsS3'
  end

end

__loading_end(__FILE__)
