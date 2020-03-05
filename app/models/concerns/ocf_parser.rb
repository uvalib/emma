# app/models/concerns/ocf_parser.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Open Container Format (OCF) document information.
#
# EPUB and DAISY both use Open Container Format.
#
# The logic here is generalized to suit either EPUB or DAISY layouts.
#
# @see XmlBased
# @see ZipArchive
#
class OcfParser < FileParser

  include OcfFormat
  include XmlBased
  include ZipArchive

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The location of the .opf file in the ZIP archive.
  #
  # @return [String]
  #
  def opf_zip_path
    @opf_zip_path ||= find_zip_path('.opf', file_handle)
  end

  # The location of the .ncx file in the ZIP archive.
  #
  # @return [String]
  #
  def ncx_zip_path
    @ncx_zip_path ||= find_zip_path('.ncx', file_handle)
  end

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
    [get_opf_metadata, get_ncx_metadata, get_image_metadata].reduce(&:rmerge!)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Extract metadata values from the .opf file.
  #
  # <dc-metadata>
  #   <dc:title>                    -> :title
  #   <dc:creator>                  -> :creator
  #   <dc:contributor>              -> :contributor
  #   <dc:contributor role="edt">   -> :editor
  #   <dc:language>                 -> :language
  #   <dc:date>                     -> :date
  #   <dc:date event="publication"> -> :publication_date
  #   <dc:date event="conversion">  -> :producedDate
  #   <dc:publisher>                -> :publisher
  #   <dc:subject>                  -> :subject
  #   <dc:type>                     -> :type
  #   <dc:rights>                   -> :rights
  #   <dc:format>                   -> :formats
  #   <dc:source>                   -> :source
  #   <dc:coverage>                 -> :coverage
  #   <dc:relation>                 -> :relation
  #   <dc:description>              -> :description
  #   <dc:identifier>               -> :identifier
  #
  # <x-metadata>
  #   <meta name="DCTERMS.date.dateCopyrighted" -> :dateCopyrighted
  #   <meta name="Synopsis"                     -> :synopsis
  #   <meta name="cover"                        -> :cover [*]
  #   <meta name="dtb:audioFormat"              -> :audioFormat
  #   <meta name="dtb:multimediaContent"        -> :multimediaContent
  #   <meta name="dtb:multimediaType"           -> :multimediaType
  #   <meta name="dtb:narrator"                 -> :narrator
  #   <meta name="dtb:producedDate"             -> :producedDate
  #   <meta name="dtb:producer"                 -> :producer
  #   <meta name="dtb:revision"                 -> :revision
  #   <meta name="dtb:revisionDate"             -> :revisionDate
  #   <meta name="dtb:revisionDescription"      -> :revisionDescription
  #   <meta name="dtb:sourceDate"               -> :sourceDate
  #   <meta name="dtb:sourceEdition"            -> :sourceEdition
  #   <meta name="dtb:sourcePublisher"          -> :sourcePublisher
  #   <meta name="dtb:sourceRights"             -> :sourceRights
  #   <meta name="dtb:sourceTitle"              -> :sourceTitle
  #   <meta name="dtb:totalTime"                -> :totalTime
  #
  # [*] If :cover is present, its value is the id for the <manifest> <item>
  # that indicates ZIP archive file associated with the cover image.
  #
  # @return [Hash{Symbol=>Array<String>}]
  #
  def get_opf_metadata
    result = {}
    doc = opf_zip_path
    doc &&= get_archive_entry(doc, file_handle)
    doc &&= Nokogiri.XML(doc)

    # Parse <package><metadata> for metadata values.
    cover_id = nil
    (doc&.xpath('//xmlns:metadata')&.children || []).each do |element|
      next unless element.element?
      if element.name.include?('metadata')
        __debug_parse(element)
        result.rmerge!(parse_metadata(element))
      else
        __debug_parse(element, element)
        key, value = parse_meta(element) || parse_element(element)
        next if value.blank?
        if key == :cover
          cover_id = value
        else
          (result[key] ||= []) << value
        end
      end
    end

    # Parse <package><manifest> for cover image reference.
    (doc&.xpath('//xmlns:manifest')&.children || []).each do |element|
      next unless element.element?
      next unless (cover = retrieve_cover_image(element, cover_id))
      @cover_image ||= []
      @cover_image << cover
    end

    result
  end

  # Extract metadata values from the .ncx file.
  #
  # <head>
  #   <meta name="dtb:depth"          -> :depth
  #   <meta name="dtb:generator"      -> :generator
  #   <meta name="dtb:maxPageNumber"  -> :synopsis
  #   <meta name="dtb:totalPageCount" -> :totalPageCount
  #   <meta name="dtb:uid"            -> :uid
  #
  # @return [Hash{Symbol=>Array<String>}]
  #
  def get_ncx_metadata
    xml = ncx_zip_path
    xml &&= get_archive_entry(xml, file_handle)
    xml &&= Nokogiri.XML(xml)
    xml &&= xml.xpath('//xmlns:meta')
    xml ? parse_metas(xml) : {}
  end

  # Extract cover image.
  #
  # @return [Hash{Symbol=>Array<String>}]
  #
  def get_image_metadata
    @cover_image ? { cover_image: Array.wrap(@cover_image) } : {}
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # retrieve_cover_image
  #
  # @param [Nokogiri::XML::Element] manifest_item
  # @param [String, nil]            cover_id
  #
  # @return [String, nil]
  #
  # NOTE: This definitely applies to EPUB but maybe not to DAISY.
  #
  def retrieve_cover_image(manifest_item, cover_id = nil)
    attrs = get_attributes(manifest_item)
    return unless cover_id.nil? || (attrs[:id] == cover_id)
    return unless cover_id || (attrs[:properties] == 'cover-image')
    media_type = attrs[:'media-type']
    zip_path   = attrs[:href]
    image_data = get_archive_entry(zip_path, file_handle, recurse: true)
    image_data &&= Base64.encode64(image_data)
    "data:#{media_type}; base64,#{image_data}" if image_data
  end

end

__loading_end(__FILE__)
