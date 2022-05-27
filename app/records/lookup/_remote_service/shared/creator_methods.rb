# app/records/lookup/_remote_service/shared/creator_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to authors, editors, etc.
#
module Lookup::RemoteService::Shared::CreatorMethods

  include Api::Shared::CreatorMethods
  include Lookup::RemoteService::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Return a list of cleaned proper names from the given field(s).
  #
  # @param [Array<Symbol>] fields
  # @param [Hash]          opt    Passed to #find_record_items and #clean_name.
  #
  # @return [Array<String>]
  #
  #--
  # noinspection RubyMismatchedReturnType, RubyMismatchedArgumentType
  #++
  def name_list(*fields, **opt)
    clean = !opt.key?(:clean) || opt.delete(:clean)
    fields.flat_map { |field| find_record_items(field, **opt) }.tap do |result|
      result.compact_blank!
      result.uniq!
      result.map! { |item| clean_name(item, **opt) } if clean
    end
  end

end

__loading_end(__FILE__)
