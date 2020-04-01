# app/models/concerns/zip_archive.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'archive/zip'

# Manipulate file formats based on ZIP.
#
module ZipArchive

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # get_archive_entry
  #
  # @param [String]             zip_path
  # @param [String, FileHandle] file      Physical archive file.
  # @param [Boolean]            recurse
  #
  # @return [String]                      File contents
  # @return [nil]
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

  rescue => e
    Log.warn { "#{__method__}(#{zip_path}): #{e.message}" }
  end

  # Locate the indicated file in the given archive.
  #
  # @param [String]             ext   Target filename extension.
  # @param [String, FileHandle] file  Physical archive file.
  #
  # @return [String]                  Path to metadata archive entry.
  # @return [nil]
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

  rescue => e
    Log.warn { "#{__method__}(#{file}): #{e.message}" }
  end

end

__loading_end(__FILE__)
