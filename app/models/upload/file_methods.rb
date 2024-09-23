# app/models/upload/file_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Upload record methods to support Shrine-based file objects uploaded from the
# client.
#
# @!attribute [r] file
#   A de-serialized representation of the :file_data column for this model.
#   @return [FileUploader::UploadedFile]
#
# @!attribute [r] file_attacher
#   Inserted by Shrine::Plugins:Activerecord.
#   @return [FileUploader::Attacher]
#
# @!attribute [r] edit_file
#   A de-serialized representation of the :edit_file_data column.
#   @return [FileUploader::UploadedFile]
#
# @!attribute [r] edit_file_attacher
#   Inserted by Shrine::Plugins:Activerecord.
#   @return [FileUploader::Attacher]
#
module Upload::FileMethods

  include Upload::WorkflowMethods
  include FileNaming

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:

    include ActiveRecord::Validations

    # Represents a file that was uploaded to a storage.
    #
    # @return [FileUploader::UploadedFile]
    #
    # @see Shrine::ClassMethods#inherited (Created via Shrine)
    #
    attr_reader :file

    # Saves information about the uploaded file as an attachment to a record
    # (saving the file data to the :file_data database column).
    #
    # The attaching process requires a temporary and a permanent storage to be
    # registered (by default that's :cache and :store).
    #
    # @return [FileUploader::Attacher]
    #
    attr_reader :file_attacher

    # Represents a file that was uploaded to a storage as a replacement for the
    # originally-submitted file.
    #
    # @return [FileUploader::UploadedFile]
    #
    # @see #file
    #
    attr_reader :edit_file

    # Saves information about the uploaded replacement as an attachment to a
    # record (saving the file data to the :edit_file_data database column).
    #
    # The attaching process requires a temporary and a permanent storage to be
    # registered (by default that's :cache and :store).
    #
    # @return [FileUploader::Attacher]
    #
    # @see #file_attacher
    #
    attr_reader :edit_file_attacher

    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The maximum age (in seconds) allowed for download links which are meant to
  # be valid only for a single time.
  #
  # This should be generous to allow for network delays.
  #
  # @type [Integer]
  #
  ONE_TIME_USE_EXPIRATION = 10

  # The maximum age (in seconds) allowed for download links.
  #
  # This allows the link to be reused for a while, but not long enough to allow
  # sharing of content URLs for distribution.
  #
  # @type [Integer]
  #
  DOWNLOAD_EXPIRATION = 1800

  # ===========================================================================
  # :section: Fields
  # ===========================================================================

  public

  # Shrine attachment for :file_data.
  #
  # noinspection RubyResolve
  include FileUploader::Attachment(:file)

  # Shrine attachment for :edit_file_data, which is applicable only when
  # `#phase` is "edit".
  #
  # noinspection RubyResolve
  include FileUploader::Attachment(:edit_file)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Full name of the file.
  #
  # @return [String]
  # @return [nil]                     If :file_data is blank.
  #
  def filename
    @filename ||= attached_file&.original_filename&.dup
  end

  # Return the attached file, loading it if necessary (and possible).
  #
  # @return [FileUploader::UploadedFile]
  # @return [nil]                     If :file_data is blank.
  #
  def attached_file
    file || (file_attacher.load_data(file_data) if file_data.present?)
  end

  # Full name of the file when editing an existing entry.
  #
  # @return [String]
  # @return [nil]                     If :file_data is blank.
  #
  def edit_filename
    edit_attached_file&.original_filename&.dup
  end

  # Return the attached file, loading it if necessary (and possible).
  #
  # @return [FileUploader::UploadedFile]
  # @return [nil]                     If :file_data is blank.
  #
  def edit_attached_file
    edit_file ||
      (edit_file_attacher.load_data(edit_file_data) if edit_file_data.present?)
  end

  # Full name of the file currently associated with the record.
  #
  # @return [String]
  # @return [nil]                     If :file_data is blank.
  #
  def active_filename
    edit_phase && edit_filename || filename
  end

  # Return the attached file currently associated with the record.
  #
  # @return [FileUploader::UploadedFile]
  # @return [nil]                     If :file_data is blank.
  #
  def active_attached_file
    edit_phase && edit_attached_file || attached_file
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Return the cached file, attaching it if necessary (and possible).
  #
  # @return [FileUploader::UploadedFile, nil]
  #
  def attach_cached
    return file_attacher.file if file_attacher.cached?
    return if file_attacher.stored? || file_data.blank?
    file_attacher.load_data(file_data)
    file_attacher.set(nil) unless file_attacher.cached?
    file_attacher.file
  end

  # Return the cached file, attaching it if necessary (and possible).
  #
  # @return [FileUploader::UploadedFile, nil]
  #
  def edit_attach_cached
    return edit_file_attacher.file if edit_file_attacher.cached?
    return if edit_file_attacher.stored? || edit_file_data.blank?
    edit_file_attacher.load_data(edit_file_data)
    edit_file_attacher.set(nil) unless edit_file_attacher.cached?
    edit_file_attacher.file
  end

  # Return the cached file currently associated with the record.
  #
  # @return [FileUploader::UploadedFile, nil]
  #
  def active_attach_cached
    edit_phase ? edit_attach_cached : attach_cached
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Move the uploaded file to its final destination.
  #
  # If the file is in :cache it will be moved to :store.  If it's already in
  # :store then this is a no-op.
  #
  # @param [Boolean] fatal            If *true*, re-raise exceptions.
  #
  # @return [FileUploader::UploadedFile, nil]
  #
  def promote_file(fatal: false)
    __debug_items(binding)
    promote_cached_file(fatal: fatal)
  end

  # Remove the uploaded file from storage (either :store or :cache).
  #
  # @param [Symbol]  field            Either :file_data or :edit_file_data;
  #                                     otherwise the field is determined by
  #                                     the phase.
  # @param [Boolean] fatal            If *true*, re-raise exceptions.
  #
  # @return [void]
  #
  def delete_file(field: nil, fatal: false)
    __debug_items(binding)
    return if destroyed?
    if field.nil? && active_attached_file
      active_file_attacher.destroy
      active_file_attacher.set(nil)
    elsif (field == :edit_file_data) && edit_attached_file
      edit_file_attacher.destroy
      edit_file_attacher.set(nil)
    elsif (field == :file_data) && attached_file
      file_attacher.destroy
      file_attacher.set(nil)
    end
  rescue => error
    log_exception(error, __method__)
    re_raise_if_internal_exception(error)
    raise error if fatal
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a URL to the uploaded file which can be used to download the file
  # to the client browser.
  #
  # @param [Hash] opt                 Passed to Shrine::UploadedFile#url.
  #
  # @return [String]
  # @return [nil]                     If :file_data is blank.
  #
  def download_url(**opt)
    opt[:expires_in] ||= DOWNLOAD_EXPIRATION
    attached_file&.url(**opt)
  end

  # The AWS S3 object for the file.
  #
  # @return [Aws::S3::Object, nil]
  #
  def s3_object
    attached_file&.storage&.object(file.id)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Acquire a file and upload it to storage.
  #
  # @param [String] file_path
  # @param [Hash]   opt               Passed to FileUploader::Attacher#attach
  #                                     except for:
  #
  # @option [Symbol] :meth            Calling method (for logging).
  #
  # @return [FileUploader::UploadedFile]
  #
  # === Usage Notes
  # This method is not necessary for an Upload instance which is persisted to
  # the database because Shrine adds event handlers which cause the file to be
  # copied to storage.  This method is allows this action for a "free-standing"
  # Upload instance (without needing to execute #save in order to engage Shrine
  # event handlers to copy the file to storage).
  #
  def fetch_and_upload_file(file_path, **opt)
    meth   = opt.delete(:meth) || __method__
    result =
      if file_path =~ /^https?:/
        upload_remote_file(file_path, **opt)
      else
        upload_local_file(file_path, **opt)
      end
    Log.info do
      name = result&.original_filename.inspect
      size = result&.size      || 0
      type = result&.mime_type || 'unknown MIME type'
      "#{meth}: #{name} (#{size} bytes) #{type}"
    end
    result
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Options for Down#open.
  #
  # @type [Hash]
  #
  # @see Down::NetHttp#initialize
  # @see Down::NetHttp#open
  # @see Down::NetHttp#create_net_http
  #
  DOWN_OPEN_OPTIONS = { read_timeout: 60 }.deep_freeze

  # Acquire a remote file and copy it to storage.
  #
  # @param [String] url
  # @param [Hash]   opt     Passed to FileUploader::Attacher#attach except for:
  #
  # @option opt [Integer] :read_retry
  #
  # @return [FileUploader::UploadedFile]
  #
  def upload_remote_file(url, **opt)
    # @type [Down::ChunkedIO] io
    io = Down.open(url, **DOWN_OPEN_OPTIONS)
    opt[:metadata] = opt[:metadata]&.dup || {}
    opt[:metadata]['filename'] ||= File.basename(url)
    file_attacher.attach(io, **opt)
  rescue => error
    __output "!!! #{__method__}: #{error.class}: #{error.message}"
    raise error
  ensure
    # noinspection RubyScope, RubyMismatchedReturnType
    io&.close
  end

  # Copy a local file to storage.
  #
  # @param [String] path
  # @param [Hash]   opt               Passed to FileUploader::Attacher#attach
  #
  # @return [FileUploader::UploadedFile]
  #
  def upload_local_file(path, **opt)
    File.open(path) do |io|
      file_attacher.attach(io, **opt)
    end
  rescue => error
    __output "!!! #{__method__}: #{error.class}: #{error.message}"
    raise error
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The database column currently associated with uploaded file information
  # used by Shrine.
  #
  # @return [Symbol]
  #
  def file_data_column
    edit_phase ? :edit_file_data : :file_data
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The uploaded file currently being used with Shrine.
  #
  # @return [FileUploader::UploadedFile, nil]
  #
  def active_file
    edit_phase ? edit_file : file
  end

  # The file attacher currently being used with Shrine.
  #
  # @return [FileUploader::Attacher]
  #
  def active_file_attacher
    edit_phase ? edit_file_attacher : file_attacher
  end

  # The file metadata currently being used with Shrine.
  #
  # @return [String, nil]
  #
  def active_file_data
    self[file_data_column]
  end

  # ===========================================================================
  # :section: ActiveRecord validations
  # ===========================================================================

  protected

  # Indicate whether the attached file is valid.
  #
  def attached_file_valid?
    return false unless active_file
    active_file_attacher.validate
    active_file_attacher.errors.each { |e|
      errors.add(:file, :invalid, message: e)
    }.empty?
  end

  # ===========================================================================
  # :section: ActiveRecord callbacks
  # ===========================================================================

  protected

  # Make a debug output note to mark when a callback has occurred.
  #
  # @param [Symbol] type
  #
  # @return [void]
  #
  # === Usage Notes
  #
  # :before_save # should trigger:
  # Shrine::Plugins::Activerecord::AttacherMethods#activerecord_before_save
  #   Shrine::Attacher::InstanceMethods#save
  #
  # :after_commit, on: %i[create update] # should trigger:
  # Shrine::Plugins::Activerecord::AttacherMethods#activerecord_after_save
  #   Shrine::Attacher::InstanceMethods#finalize
  #     Shrine::Attacher::InstanceMethods#destroy_previous
  #     Shrine::Attacher::InstanceMethods#promote_cached
  #       Shrine::Attacher::InstanceMethods#promote
  #   Shrine::Plugins::Activerecord::AttacherMethods#activerecord_persist
  #     ActiveRecord::Persistence#save
  #
  # :after_commit, on: %i[destroy] # should trigger:
  # Shrine::Plugins::Activerecord::AttacherMethods#activerecord_after_destroy
  #   Shrine::Attacher::InstanceMethods#destroy_attached
  #     Shrine::Attacher::InstanceMethods#destroy
  #
  def note_cb(type)
    __debug_line { "*** UPLOAD CALLBACK #{type} ***" }
  end

  # Finalize a file upload by promoting the :cache file to a :store file.
  #
  # @param [Boolean] keep_cached      If *true*, don't delete the original.
  # @param [Boolean] fatal            If *false*, don't re-raise exceptions.
  #
  # @return [FileUploader::UploadedFile, nil]
  #
  # @note From Upload::FileMethods#promote_cached_file
  #
  def promote_cached_file(keep_cached: false, fatal: true)
    __debug_items(binding)
    return unless active_attach_cached
    old_file   = (active_file&.data&.presence unless keep_cached)
    old_file &&= FileUploader::UploadedFile.new(old_file)
    active_file_attacher.promote.tap { old_file&.delete }
  rescue => error
    log_exception(error, __method__)
    re_raise_if_internal_exception(error)
    raise error if fatal
  end

  # Finalize a deletion by the removing the file from :cache and/or :store.
  #
  # @param [Boolean] fatal            If *false*, don't re-raise exceptions.
  #
  # @return [TrueClass, nil]
  #
  def delete_cached_file(fatal: true)
    __debug_items(binding)
    return unless active_attach_cached
    active_file_attacher.destroy
    active_file_attacher.set(nil)
    true
  rescue => error
    log_exception(error, __method__)
    re_raise_if_internal_exception(error)
    raise error if fatal
  end

  # ===========================================================================
  # :section: ActiveRecord callbacks
  # ===========================================================================

  private

  # Add a log message for an exception.
  #
  # @param [Exception] excp
  # @param [Symbol]    meth           Calling method.
  #
  # @return [nil]
  #
  def log_exception(excp, meth = nil)
    error = warning = nil
    case excp
      when Shrine::FileNotFound      then warning = 'FILE_NOT_FOUND'
      when Shrine::InvalidFile       then warning = 'INVALID_FILE'
      when Shrine::AttachmentChanged then warning = 'ATTACHMENT_CHANGED'
      when Shrine::Error             then error   = 'unexpected Shrine error'
      else                                error   = "#{excp.class} unexpected"
    end
    Log.add(error ? Log::ERROR : Log::WARN) do
      "#{meth || __method__}: #{excp.message} [#{error || warning}]"
    end
  end

end

__loading_end(__FILE__)
