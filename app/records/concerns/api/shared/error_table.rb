# app/records/concerns/api/shared/error_table.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Add an error table to a message class that contains a :messages attribute.
#
module Api::Shared::ErrorTable

  extend ActiveSupport::Concern

  included do

    # @return [Hash{String,Integer=>String}]
    attr_reader :errors

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  GENERAL_ERROR_TAG = 'ERROR'
  GENERAL_ERROR_KEY = "#{GENERAL_ERROR_TAG}[%d]"

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate the error table.
  #
  # (To be run from the initializer.)
  #
  # @param [Array<Exception, String, Array>] entries
  #
  # @return [Hash{String,Integer=>String}]
  #
  # == Usage Notes
  # Intended to be executed in the initializer.
  #
  def initialize_error_table(*entries)
    entries =
      entries.flatten.flat_map { |item|
        if item.respond_to?(:messages)
          item.messages
        elsif item.respond_to?(:message)
          item.message
        else
          item
        end
      }.map { |item| item.to_s.strip.presence }.compact.uniq
    @errors = make_error_table(*entries)
  end

  # make_error_table
  #
  # @param [Array<String>] entries
  #
  # @return [Hash{String,Integer=>String}]
  #
  def make_error_table(*entries)
    i = 0
    result = {}
    entries.each do |entry|
      item_index, item_error = entry.split(/^\s*-+\s*/, 2)
      item_index = item_index.to_i
      unless item_index.positive? && item_error.present?
        item_index = 'ERROR[%d]' % (i += 1)
        item_error = entry
      end
      result[item_index] ||= []
      result[item_index] << item_error
    end
    result.transform_values! { |v| v.join('; ') }
  end

end

__loading_end(__FILE__)
