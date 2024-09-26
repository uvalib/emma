# test/test_helper/samples.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Access to sample models.
#
module TestHelper::Samples

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A string added to the start of each title created on a non-production
  # instance to help distinguish it from other index results.
  #
  # @type [String]
  #
  TITLE_PREFIX = UploadWorkflow::Properties::UPLOAD_DEV_TITLE_PREFIX

  # File fixture for Uploads.
  #
  # @type [String]
  #
  UPLOAD_FILE = 'pg2148.epub'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a unique user account email name.
  #
  # @param [User, String] original
  #
  # @return [String]
  #
  def unique_email(original)
    email = original.is_a?(User) ? original.email : original
    "#{hex_rand}_#{email}"
  end

end
