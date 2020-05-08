# app/records/ingest/shared/title_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods mixed in to record elements related to catalog titles.
#
module Ingest::Shared::TitleMethods

  include ::TitleMethods

  # ===========================================================================
  # :section: ::TitleMethods overrides
  # ===========================================================================

  public

=begin
  # A unique identifier for this catalog title.
  #
  # @return [String]
  #
  # This method overrides:
  # @see ::TitleMethods#identifier
  #
  def identifier
    emma_titleId.to_s
  end
=end

  # ===========================================================================
  # :section: ::TitleMethods overrides
  # ===========================================================================

  public

=begin
  # All contributor(s) to this catalog title, stripping terminal punctuation
  # from each name where appropriate.
  #
  # @return [Array<String>]
  #
  # This method overrides:
  # @see ::TitleMethods#contributor_list
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
=end

  # ===========================================================================
  # :section: ::TitleMethods overrides
  # ===========================================================================

  public

=begin
  # The ISBN.
  #
  # @return [String]
  # @return [nil]                     If the value cannot be determined.
  #
  # This method overrides:
  # @see ::TitleMethods#isbn
  #
  def isbn
    @isbn ||= extract_isbns(:dc_identifier).first
  end
=end

=begin
  # Related ISBNs omitting the main ISBN if part of the data array.
  #
  # @return [Array<String>]
  #
  # This method overrides:
  # @see ::TitleMethods#related_isbns
  #
  def related_isbns
    @related_isbns ||= all_isbns - [isbn]
  end
=end

=begin
  # The main and related ISBNs.
  #
  # @return [Array<String>]
  #
  # This method overrides:
  # @see ::TitleMethods#all_isbns
  #
  def all_isbns
    @all_isbns ||= extract_isbns(:dc_identifier, :dc_relation)
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

=begin
  # Get only ISBN identifiers.
  #
  # @param [Array<Symbol>] fields
  #
  # @return [Array<String>]
  #
  def extract_isbns(*fields)
    vals = fields.flat_map { |field| get_values(field) }
    vals.map { |v| v.to_s.gsub(/\s/, '').sub!(/^isbn[^\d]*/, '') }.compact.uniq
  end
=end

  # ===========================================================================
  # :section: ::TitleMethods overrides
  # ===========================================================================

  public

=begin
  # Field(s) that may hold date information about the title.
  #
  # @return [Array<Symbol>]
  #
  # This method overrides:
  # @see ::TitleMethods#title_fields
  #
  def title_fields
    %i[dc_title]
  end
=end

=begin
  # Field(s) that may hold date information about the title.
  #
  # @return [Array<Symbol>]
  #
  # This method overrides:
  # @see ::TitleMethods#date_fields
  #
  def date_fields
    %i[dcterms_dateCopyright emma_lastRemediationDate]
  end
=end

=begin
  # Field(s) that may hold content information about the title.
  #
  # @return [Array<Symbol>]
  #
  # This method overrides:
  # @see ::TitleMethods#contents_fields
  #
  def contents_fields
    %i[dc_description]
  end
=end

end

__loading_end(__FILE__)
