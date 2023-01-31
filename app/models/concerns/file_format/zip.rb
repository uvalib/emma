# app/models/concerns/file_format/zip.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'archive/zip'

# Manipulate file formats which are based on the ZIP archive format.
#
module FileFormat::Zip

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # get_archive_entry
  #
  # @param [String, nil]             zip_path
  # @param [String, FileHandle, nil] file       Physical archive file.
  # @param [Boolean]                 recurse
  #
  # @return [String]  File contents
  # @return [nil]     If *zip_path* or *file* is blank, or could not be read.
  #
  def get_archive_entry(zip_path, file, recurse: false)
    return if zip_path.blank? || file.blank?
    zip_path = find_zip_path(zip_path, file) if zip_path.start_with?('.')
    Archive::Zip.open(file) do |archive|
      archive.each do |entry|
        found = (entry.zip_path == zip_path)
        found ||= recurse && entry.zip_path.end_with?("/#{zip_path}")
        return entry.file_data.read if found
      end
    end
    nil
  rescue => error
    Log.warn { "#{__method__}(#{zip_path}): #{error.message}" }
    re_raise_if_internal_exception(error)
  end

  # Locate the indicated file in the given archive.
  #
  # @param [String, nil]             ext        Target filename extension.
  # @param [String, FileHandle, nil] file       Physical archive file.
  #
  # @return [String]  Path to metadata archive entry.
  # @return [nil]     If *ext* or *file* is blank, or could not be read.
  #
  def find_zip_path(ext, file)
    return if ext.blank? || file.blank?
    ext = ".#{ext}" unless ext.start_with?('.')
    Archive::Zip.open(file) do |archive|
      archive.each do |entry|
        name = entry.zip_path.to_s
        return name if entry.file? && name.end_with?(ext)
      end
    end
    nil
  rescue => error
    Log.warn { "#{__method__}(#{file}): #{error.message}" }
    re_raise_if_internal_exception(error)
  end

end

__loading_end(__FILE__)
