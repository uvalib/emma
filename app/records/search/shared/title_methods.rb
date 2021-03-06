# app/records/search/shared/title_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to catalog titles.
#
# Attributes supplied by the including module:
#
# @attr [String] emma_titleId
#
module Search::Shared::TitleMethods

  include Api::Shared::TitleMethods
  include Search::Shared::LinkMethods

  # ===========================================================================
  # :section: ::TitleMethods overrides
  # ===========================================================================

  public

  # A unique identifier for this catalog title.
  #
  # @return [String]
  #
  def identifier
    emma_titleId.to_s
  end

  # ===========================================================================
  # :section: ::TitleMethods overrides
  # ===========================================================================

  public

  # All contributor(s) to this catalog title, stripping terminal punctuation
  # from each name where appropriate.
  #
  # @return [Array<String>]
  #
  def contributor_list
    get_values(:dc_creator).uniq.map do |v|
      parts = v.split(/[[:space:]]+/)
      parts.shift if parts.first.blank?
      parts.pop   if parts.last.blank?
      parts <<
        case (last = parts.pop)
          when /^[^.]\.$/ then last       # Assumed to be an initial
          when /^[A-Z]$/  then last + '.' # An initial missing a period.
          else                 last.sub(/[.,;]+$/, '')
        end
      parts.join(' ')
    end
  end

  # ===========================================================================
  # :section: ::TitleMethods overrides
  # ===========================================================================

  public

  # The ISBN.
  #
  # @return [String]
  # @return [nil]                     If the value cannot be determined.
  #
  def isbn
    @isbn ||= extract_isbns(:dc_identifier).first
  end

  # Related ISBNs omitting the main ISBN if part of the data array.
  #
  # @return [Array<String>]
  #
  def related_isbns
    @related_isbns ||= all_isbns - [isbn]
  end

  # The main and related ISBNs.
  #
  # @return [Array<String>]
  #
  def all_isbns
    @all_isbns ||= extract_isbns(:dc_identifier, :dc_relation)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Get only ISBN identifiers.
  #
  # @param [Array<Symbol>] fields
  #
  # @return [Array<String>]
  #
  def extract_isbns(*fields)
    vals = fields.flat_map { |field| get_values(field) }
    vals.map { |v| v.to_s.remove(/\s/).sub!(/^isbn[^\d]*/, '') }.compact.uniq
  end

  # ===========================================================================
  # :section: ::TitleMethods overrides
  # ===========================================================================

  public

  # Field(s) that may hold date information about the title.
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
    %i[dcterms_dateCopyright emma_lastRemediationDate]
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
