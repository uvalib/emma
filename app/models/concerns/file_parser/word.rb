# app/models/concerns/file_parser/word.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Microsoft Word (.docx) file format metadata extractor.
#
# @see FileFormat::Xml
# @see FileFormat::Zip
#
class FileParser::Word < FileParser

  include FileFormat::Word
  include FileFormat::Xml
  include FileFormat::Zip

  # ===========================================================================
  # :section: FileFormat::Xml overrides
  # ===========================================================================

  public

  # Gather all metadata values.
  #
  # @return [Hash{Symbol=>Array<String>}]
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
    doc    = get_archive_entry('docProps/core.xml', file_handle)
    doc  &&= Nokogiri.XML(doc)
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
