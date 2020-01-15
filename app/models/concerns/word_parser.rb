# app/models/concerns/word_parser.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Microsoft Word (.docx) document information.
#
# @see XmlBased
# @see ZipArchive
#
class WordParser < FileParser

  include XmlBased
  include ZipArchive

  # ===========================================================================
  # :section: XmlBased overrides
  # ===========================================================================

  public

  # Gather all metadata values.
  #
  # @return [Hash{Symbol=>Array<String>}]
  #
  # This method overrides:
  # @see XmlBased#retrieve_metadata
  #
  def retrieve_metadata
    get_core_metadata
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Extract metadata values from the core.xml file.
  #
  # <cp:coreProperties>
  #   <dc:contributor>      -> :contributor
  #   <dc:coverage>         -> :coverage
  #   <dc:creator>          -> :creator
  #   <dc:date>             -> :created
  #   <dc:Description>      -> :description
  #   <dc:format>           -> :formats
  #   <dc:identifier>       -> :identifier
  #   <dc:language>         -> :language
  #   <dc:publisher>        -> :publisher
  #   <dc:relation>         -> :relation
  #   <dc:rights>           -> :rights
  #   <dc:source>           -> :source
  #   <dc:subject>          -> :subject
  #   <dc:type>             -> :type
  #   <cp:author>           -> :author
  #   <cp:category>         -> :category
  #   <cp:comments>         -> :comments
  #   <cp:content_status>   -> :content_status
  #   <cp:keywords>         -> :keywords
  #   <cp:last_modified_by> -> :last_modified_by
  #   <cp:last_printed>     -> :last_printed
  #   <cp:modified>         -> :modified
  #   <cp:revision>         -> :revision
  #   <cp:version>          -> :version
  #
  # @return [Hash{Symbol=>Array<String>}]
  #
  def get_core_metadata
    result = {}
    doc = get_archive_entry('docProps/core.xml', local_path)
    doc &&= Nokogiri.XML(doc)
    (doc&.xpath('.//cp:coreProperties')&.children || []).each do |element|
      next unless element.element?
      __debug_parse(element)
      key, value = parse_element(element)
      next if value.blank?
      result[key] ||= []
      result[key] << value
    end
    result
  end

end

__loading_end(__FILE__)
