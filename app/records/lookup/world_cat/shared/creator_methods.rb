# app/records/lookup/world_cat/shared/creator_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to authors, editors, etc.
#
module Lookup::WorldCat::Shared::CreatorMethods

  include Lookup::RemoteService::Shared::CreatorMethods
  include Lookup::WorldCat::Shared::CommonMethods

  # ===========================================================================
  # :section: Api::Shared::CreatorMethods overrides
  # ===========================================================================

  public

  # The author(s)/creator(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #find_record_items.
  #
  # @return [Array<String>]
  #
  def creator_list(**opt)
    name_list(:dc_creator, :dc_contributor, **opt)
  end

  # All contributor(s) to this catalog title, stripping terminal punctuation
  # from each name where appropriate.
  #
  # @param [Hash] opt                 Passed to #find_record_items.
  #
  # @return [Array<String>]
  #
  def contributor_list(**opt)
    name_list(:dc_contributor, **opt)
  end

end

__loading_end(__FILE__)
