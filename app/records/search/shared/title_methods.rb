# app/records/search/shared/title_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to catalog titles.
#
module Search::Shared::TitleMethods

  include Api::Shared::TitleMethods

  extend self

  # ===========================================================================
  # :section: Model overrides
  # ===========================================================================

  public

  # A unique identifier for this index entry.
  #
  # @return [String]
  #
  def identifier
    emma_recordId.to_s
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
    %i[dc_title]
  end

  # Field(s) that may hold date information about the title.
  #
  # @return [Array<Symbol>]
  #
  def date_fields
    %i[
      dcterms_dateCopyright
      emma_lastRemediationDate
      emma_publicationDate
      emma_sortDate
      rem_remediationDate
    ]
  end

  # Field(s) that may hold content information about the title.
  #
  # @return [Array<Symbol>]
  #
  def contents_fields
    %i[dc_description]
  end

end

__loading_end(__FILE__)
