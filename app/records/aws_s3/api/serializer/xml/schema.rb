# app/records/aws_s3/api/serializer/xml/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# XML-specific definition overrides for serialization.
#
# @see Api::Serializer::Xml::Schema
#
module AwsS3::Api::Serializer::Xml::Schema

  include AwsS3::Api::Serializer::Schema
  include Api::Serializer::Xml::Schema

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # If this value is *false* then #attribute schema values are serialized
  # (rendered) as XML attributes; if *true* then they are serialized as XML
  # elements (removing the distinction between #attribute and #has_one).
  #
  # @see Api::Serializer::Xml::Schema#attributes_as_elements?
  #
  def attributes_as_elements?
    false
  end

end

__loading_end(__FILE__)
