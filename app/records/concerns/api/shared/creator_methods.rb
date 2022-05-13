# app/records/concerns/api/shared/creator_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to authors, editors, etc.
#
module Api::Shared::CreatorMethods

  include Api::Shared::CommonMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The author(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def author_list(**opt)
    creator_list(**opt)
  end

  # The editor(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  def editor_list(**)
    []
  end

  # The composer(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  def composer_list(**)
    []
  end

  # The lyricist(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  def lyricist_list(**)
    []
  end

  # The arranger(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  def arranger_list(**)
    []
  end

  # The translator(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  def translator_list(**)
    []
  end

  # The creator(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  def creators(**opt)
    creator_list(**opt)
  end

  # The author(s)/creator(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #contributor_list.
  #
  # @return [Array<String>]
  #
  def creator_list(**opt)
    contributor_list(**opt)
  end

  # All contributor(s) to this catalog title, stripping terminal punctuation
  # from each name where appropriate.
  #
  # @param [Symbol] field
  # @param [Hash]   opt               Passed to #get_values.
  #
  # @return [Array<String>]
  #
  def contributor_list(field: :dc_creator, **opt)
    get_values(field, **opt).map { |v| clean_name(v) }.uniq
  end

end

__loading_end(__FILE__)
