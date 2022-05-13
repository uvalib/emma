# app/records/lookup/google_books/shared/creator_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to authors, editors, etc.
#
module Lookup::GoogleBooks::Shared::CreatorMethods

  include Lookup::RemoteService::Shared::CreatorMethods
  include Lookup::GoogleBooks::Shared::CommonMethods

  # ===========================================================================
  # :section: Api::Shared::CreatorMethods overrides
  # ===========================================================================

  public

  # All contributor(s) to this catalog title, stripping terminal punctuation
  # from each name where appropriate.
  #
  # @param [Api::Record] target       Default: `self`.
  #
  # @return [Array<String>]
  #
  def contributor_list(target: nil, **)
    target = find_item(:volumeInfo, target: target) || target
    result = super(field: :authors, target: target)
    reverse_names(result)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Reorder names as "last_name, first_name" to make them comparable to\
  # WorldCat results.
  #
  # @param [Array<String>] items
  #
  # @return [Array<String>]
  #
  def reverse_names(items)
    items.map do |item|
      if item.include?(',')
        item # TODO: need some use cases...
      else
        name_parts = item.split(' ')
        last_name  = name_parts.pop
        first_name = name_parts.join(' ')
        "#{last_name}, #{first_name}"
      end
    end
  end

end

__loading_end(__FILE__)
