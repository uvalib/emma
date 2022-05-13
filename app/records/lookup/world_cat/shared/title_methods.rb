# app/records/lookup/world_cat/shared/title_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to catalog titles.
#
module Lookup::WorldCat::Shared::TitleMethods

  include Lookup::RemoteService::Shared::TitleMethods
  include Lookup::WorldCat::Shared::IdentifierMethods

  # ===========================================================================
  # :section: Api::Shared::TitleMethods overrides
  # ===========================================================================

  public

  # Field(s) that may hold the title string.
  #
  # @return [Array<Symbol>]
  #
  def title_fields
    %i[dc_title]
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
    find_record_values(:dc_title)
  end

  # WorldCat does not have subtitle strings.
  #
  # @return [Array<String>]
  #
  def subtitle_values
    []
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
    super(:dc_publisher)
  end

  # The date of publication.
  #
  # @return [String, nil]
  #
  def publication_date
    super(:dc_date)
  end

  # The year of publication.
  #
  # @return [String, nil]
  #
  def publication_year
    super(:dc_date)
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
    super(:dc_language)
  end

  # subject_list
  #
  # @return [Array<String>]
  #
  def subject_list
    super(:dc_subject)
  end

  # description_list
  #
  # @return [Array<String>]
  #
  def description_list
    super(:dc_description)
  end

end

__loading_end(__FILE__)
