# app/records/lookup/_remote_service/shared/title_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to catalog titles.
#
module Lookup::RemoteService::Shared::TitleMethods

  include Api::Shared::TitleMethods
  include Lookup::RemoteService::Shared::IdentifierMethods

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

  # The title and subtitle of this catalog title.
  #
  # @param [Symbol] field
  #
  # @return [String]
  #
  def full_title(field = nil)
    field && find_record_value(field) || super()
  end

  # ===========================================================================
  # :section: Api::Shared::TitleMethods overrides
  # ===========================================================================

  public

  # Name of publisher.
  #
  # @param [Symbol] field
  #
  # @return [String, nil]
  #
  def publisher_name(field = nil)
    find_record_value(field) if field
  end

  # The place of publication.
  #
  # @param [Symbol] field
  #
  # @return [String, nil]
  #
  def publication_place(field = nil)
    find_record_value(field) if field
  end

  # The date of publication.
  #
  # @param [Symbol] field
  #
  # @return [String, nil]
  #
  def publication_date(field = nil)
    IsoDay.cast(find_record_items(field).first)&.to_s if field
  end

  # The year of publication.
  #
  # @param [Symbol] field
  #
  # @return [String, nil]
  #
  def publication_year(field = nil)
    IsoYear.cast(find_record_items(field).first)&.to_s if field
  end

  # ===========================================================================
  # :section: Api::Shared::TitleMethods overrides
  # ===========================================================================

  public

  # The type of work containing an article (if relevant).
  #
  # @param [Symbol] field
  #
  # @return [String, nil]
  #
  def series_type(field = nil)
    find_record_value(field) if field
  end

  # The volume of the journal containing an article (if relevant).
  #
  # @param [Symbol] field
  #
  # @return [String, nil]
  #
  def series_volume(field = nil)
    find_record_value(field, clean: false) if field
  end

  # The issue of the journal containing an article (if relevant).
  #
  # @param [Symbol] field
  #
  # @return [String, nil]
  #
  def series_issue(field = nil)
    find_record_value(field, clean: false) if field
  end

  # ===========================================================================
  # :section: Api::Shared::TitleMethods overrides
  # ===========================================================================

  public

  # language_list
  #
  # @param [Symbol] field
  #
  # @return [Array<String>]
  #
  def language_list(field = nil)
    return [] unless field
    find_record_values(field).map { |v| IsoLanguage.find(v)&.alpha3 || v }
  end

  # subject_list
  #
  # @param [Symbol] field
  #
  # @return [Array<String>]
  #
  def subject_list(field = nil)
    return [] unless field
    find_record_values(field).map(&:upcase_first)
  end

  # description_list
  #
  # @param [Symbol] field
  #
  # @return [Array<String>]
  #
  def description_list(field = nil)
    return [] unless field
    find_record_items(field).compact_blank
  end
end

__loading_end(__FILE__)
