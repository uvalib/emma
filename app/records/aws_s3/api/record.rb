# app/records/aws_s3/api/record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for objects that are deposited into AWS S3.
#
class AwsS3::Api::Record < Api::Record

  include AwsS3::Api::Common
  include AwsS3::Api::Schema
  include AwsS3::Api::Record::Schema
  include AwsS3::Api::Record::Associations

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Recursively remove empty values from the object.  Unlike #compact_blank:
  #
  # - Preserves instance of explicit *false* values.
  # - Converts to *nil* instances of #EMPTY_VALUE.
  # - Returns *nil* if the entire object was empty.
  #
  # @param [Any] item
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def remove_empty_values(item)
    case item
      when BaseDecorator::EMPTY_VALUE
        nil
      when TrueClass, FalseClass
        item
      when Hash
        item.map { |k, v| [k, send(__method__, v)] }.to_h.compact.presence
      when Array
        item.map { |v| send(__method__, v) }.compact.presence
      else
        item.presence
    end
  end

end

__loading_end(__FILE__)
