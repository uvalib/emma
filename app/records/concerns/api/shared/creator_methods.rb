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
  # @note Currently unused.
  # :nocov:
  def author_list(**opt)
    creator_list(**opt)
  end
  # :nocov:

  # The editor(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  # @note Currently unused.
  # :nocov:
  def editor_list(**)
    []
  end
  # :nocov:

  # The composer(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  # @note Currently unused.
  # :nocov:
  def composer_list(**)
    []
  end
  # :nocov:

  # The lyricist(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  # @note Currently unused.
  # :nocov:
  def lyricist_list(**)
    []
  end
  # :nocov:

  # The arranger(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  # @note Currently unused.
  # :nocov:
  def arranger_list(**)
    []
  end
  # :nocov:

  # The translator(s) of this catalog title.
  #
  # @return [Array<String>]
  #
  # @note Currently unused.
  # :nocov:
  def translator_list(**)
    []
  end
  # :nocov:

  # The creator(s) of this catalog title.
  #
  # @param [Hash] opt                 Passed to #creator_list.
  #
  # @return [Array<String>]
  #
  # @note Currently unused.
  # :nocov:
  def creators(**opt)
    creator_list(**opt)
  end
  # :nocov:

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
    get_values(field, **opt).map { clean_name(_1) }.uniq
  end

end

__loading_end(__FILE__)
