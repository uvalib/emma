# app/models/manifest_item/uploadable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module ManifestItem::Uploadable

  include ManifestItem::FileData

  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Record::Uploadable
    # :nocov:
  end

  # ===========================================================================
  # :section: Record::Uploadable overrides
  # ===========================================================================

  protected

=begin
  # Possibly temporary method to ensure that :file_data is being fed back as a
  # Hash since Shrine is expected that because the associated column is :json.
  #
  # @param [Hash, String, nil] data   Default: `#file_data`.
  #
  # @return [FileUploader::UploadedFile]
  # @return [nil]
  #
  def file_attacher_load(data = nil)
    __debug "=== file_attacher_load ManifestItem === | data = #{data.inspect}"
    data = make_file_record(data)
    __debug "=== file_attacher_load ManifestItem === | data -> #{data.inspect} | call stack\n#{caller.join("\n")}"
    file_attacher.load_data(data) if data.present?
  end
=end

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
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
