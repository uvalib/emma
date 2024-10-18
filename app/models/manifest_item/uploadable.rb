# app/models/manifest_item/uploadable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ManifestItem::Uploadable

  include ManifestItem::FileData

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include Record::Uploadable
  end
  # :nocov:

  # ===========================================================================
  # :section: Record::Uploadable overrides
  # ===========================================================================

  public

  # Full name of the file.
  #
  # @return [String]
  # @return [nil]                     If :file_data is blank.
  #
  def filename
    @filename ||= file_reference || super
  end

  # ===========================================================================
  # :section: Record::Uploadable overrides
  # ===========================================================================

  protected

  # Return the cached file unless :file_data contains an indirect reference to
  # the actual file.
  #
  # @return [FileUploader::UploadedFile]
  # @return [nil]
  #
  def attach_cached
    super unless file_reference.present?
  end

  # Indicate whether the attached file is valid.
  #
  # If the :file_data field does not contain uploader information then this
  # just returns *true* so that Shrine-related validations do not fail.
  #
  def attached_file_valid?
    make_file_record(file_data).blank? || super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

__loading_end(__FILE__)
