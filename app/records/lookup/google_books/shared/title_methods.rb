# app/records/lookup/google_books/shared/title_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to catalog titles.
#
module Lookup::GoogleBooks::Shared::TitleMethods

  include Lookup::RemoteService::Shared::TitleMethods
  include Lookup::GoogleBooks::Shared::IdentifierMethods

  # ===========================================================================
  # :section: Model overrides
  # ===========================================================================

  public

  # A unique identifier for this catalog title.
  #
  # @return [String, nil]
  #
  def identifier
    best_identifier
  end

  # ===========================================================================
  # :section: Api::Shared::TitleMethods overrides
  # ===========================================================================

  public

  # Field(s) that may hold the title string.
  #
  # @return [Array<Symbol>]
  #
  def title_fields
    %i[title]
  end

  # Field(s) that may hold the subtitle string.
  #
  # @return [Array<Symbol>]
  #
  def subtitle_fields
    %i[subtitle]
  end

  # ===========================================================================
  # :section: Api::Shared::TitleMethods overrides
  # ===========================================================================

  public

  # One or more title strings.
  #
  # @return [Array<String>]
  #
  def title_values
    find_record_values(:title)
  end

  # One or more subtitle strings.
  #
  # @return [Array<String>]
  #
  def subtitle_values
    find_record_values(:subtitle)
  end

  # ===========================================================================
  # :section: Lookup::RemoteService::Shared::TitleMethods overrides
  # ===========================================================================

  public

  # Name of publisher.
  #
  # @return [String, nil]
  #
  def publisher_name
    super(:publisher)
  end

  # The date of publication.
  #
  # @return [String, nil]
  #
  def publication_date
    super(:publishedDate)
  end

  # The year of publication.
  #
  # @return [String, nil]
  #
  def publication_year
    super(:publishedDate)
  end

  # ===========================================================================
  # :section: Lookup::RemoteService::Shared::TitleMethods overrides
  # ===========================================================================

  public

  # language_list
  #
  # @return [Array<String>]
  #
  def language_list
    super(:language)
  end

  # subject_list
  #
  # @return [Array<String>]
  #
  def subject_list
    super(:categories)
  end

  # description_list
  #
  # @return [Array<String>]
  #
  def description_list
    super(:description)
  end

end

__loading_end(__FILE__)
