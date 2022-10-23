# app/models/concerns/record/uploadable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common methods to support Shrine-based file objects uploaded from the client.
#
# @!attribute [r] file
#   A de-serialized representation of the :file_data column for this model.
#   @return [FileUploader::UploadedFile]
#
# @!attribute [r] file_attacher
#   Inserted by Shrine::Plugins:Activerecord.
#   @return [FileUploader::Attacher]
#
module Record::Uploadable

  extend ActiveSupport::Concern

  include Record
  include Record::FileData

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ActiveRecord::Validations
    include Record::Testing
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The maximum age (in seconds) allowed for download links which are meant to  # NOTE: from Upload::FileMethods
  # be valid only for a single time.
  #
  # This should be generous to allow for network delays.
  #
  # @type [Integer]
  #
  ONE_TIME_USE_EXPIRATION = 10

  # The maximum age (in seconds) allowed for download links.                    # NOTE: from Upload::FileMethods
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
  include FileUploader::Attachment(:file)                                       # NOTE: from Upload::FileMethods

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:

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

    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Full name of the file.
  #
  # @return [String]
  # @return [nil]                     If :file_data is blank.
  #
  def filename                                                                  # NOTE: from Upload::FileMethods
    @filename ||= attached_file&.original_filename&.dup
  end

  # Return the attached file, loading it if necessary (and possible).
  #
  # @return [FileUploader::UploadedFile]
  # @return [nil]                     If :file_data is blank.
  #
  def attached_file                                                             # NOTE: from Upload::FileMethods
=begin # TODO: remove when :json resolved
    file || (file_attacher.load_data(file_data) if file_data.present?)
=end
    file || file_attacher_load
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Return the cached file, attaching it if necessary (and possible).
  #
  # @return [FileUploader::UploadedFile]
  # @return [nil]
  #
  def attach_cached                                                             # NOTE: from Upload::FileMethods
    return file_attacher.file if file_attacher.cached?
    return if file_attacher.stored? || file_data.blank?
=begin # TODO: remove when :json resolved
    file_attacher.load_data(file_data)
=end
    $stderr.puts "++++++++++++++++++++++++ promote! | #{self.class} | attach_cached"
    $stderr.puts "++++++++++++++++++++++++ promote! | #{self.class} | attach_cached | action.file_data #{file_data.class} | BAD | at start" if file_data.is_a?(String)
    file_attacher_load
    $stderr.puts "++++++++++++++++++++++++ promote! | #{self.class} | attach_cached | action.file_data #{file_data.class} | BAD | after file_attacher_load" if file_data.is_a?(String)
    file_attacher.set(nil) unless file_attacher.cached?
    file_attacher.file
  end

  # Possibly temporary method to ensure that :file_data is being fed back as a
  # Hash since Shrine is expected that because the associated column is :json.
  #
  # @param [Hash, String, nil] data   Default: `#file_data`.
  #
  # @return [FileUploader::UploadedFile]
  # @return [nil]
  #
  def file_attacher_load(data = nil)                                          # NOTE: from Upload::FileMethods#attached_file
    data = make_file_record(data)
    file_attacher.load_data(data) if data.present?
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
  # @param [Boolean] no_raise         If *false*, re-raise exceptions.
  #
  # @return [void]
  #
  def promote_file(no_raise: true)                                              # NOTE: from Upload::FileMethods
    $stderr.puts "++++++++++++++++++++++++ promote! | #{self.class} | promote_file"
    $stderr.puts "++++++++++++++++++++++++ promote! | #{self.class} | promote_file | action.file_data #{file_data.class} | BAD | at start" if file_data.is_a?(String)
    __debug_items(binding)
    promote_cached_file(no_raise: no_raise)
  end

  # Remove the uploaded file from storage (either :store or :cache).
  #
  # @param [Boolean] no_raise         If *false*, re-raise exceptions.
  #
  # @return [void]
  #
  def delete_file(no_raise: true)                                               # NOTE: from Upload::FileMethods
    __debug_items(binding)
    return if destroyed? || attached_file.nil?
    file_attacher.destroy
    file_attacher.set(nil)
  rescue => error
    # noinspection RubyMismatchedArgumentType
    log_exception(error, __method__)
    re_raise_if_internal_exception(error)
    raise error unless no_raise
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
  def download_url(**opt)                                                       # NOTE: from Upload::FileMethods
    opt[:expires_in] ||= ONE_TIME_USE_EXPIRATION
    attached_file&.url(**opt)
  end

  # The AWS S3 object for the file.
  #
  # @return [Aws::S3::Object, nil]
  #
  def s3_object                                                                 # NOTE: from Upload::FileMethods
    attached_file&.storage&.object(file.id)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Upload file via Shrine.                                                     # NOTE: from UploadWorkflow::External
  #
  # @param [Hash] opt
  #
  # @option opt [Rack::Request::Env] :env
  #
  # @return [Array<(Integer, Hash{String=>Any}, Array<String>)>]
  #
  # @see Shrine::Plugins::UploadEndpoint::ClassMethods#upload_response
  #
  def upload_file(**opt)
    fault!(opt) # @see Record::Testing
    FileUploader.upload_response(:cache, opt[:env]).tap do |stat, _hdrs, body|
      # noinspection RubyScope, RubyCaseWithoutElseBlockInspection
      err =
        case
          when stat.nil?          then 'missing request env data'
          when stat != 200        then 'invalid file'
          when body&.first.blank? then 'invalid response body'
        end # TODO: I18n
      file_attacher.errors.add(:file, :invalid, message: err) if err
    end
  end

  # Acquire a file and upload it to storage.
  #
  # @param [String] file              Directory path or URI.
  # @param [Hash]   opt               Passed to FileUploader::Attacher#attach
  #                                     except for:
  #
  # @option [Symbol] :meth            Calling method (for logging).
  #
  # @return [FileUploader::UploadedFile]
  #
  # == Usage Notes
  # This method is not necessary for an Entry instance which is persisted to
  # the database because Shrine adds event handlers which cause the file to be
  # copied to storage.  This method is allows this action for a "free-standing"
  # Entry instance (without needing to execute #save in order to engage Shrine
  # event handlers to copy the file to storage).
  #
  def fetch_and_upload_file(file, **opt)                                        # NOTE: from Upload::FileMethods
    meth   = opt.delete(:meth) || __method__
    remote = file.match?(/^https?:/)
    result = remote ? upload_remote(file, **opt) : upload_local(file, **opt)
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

  # Options for Down#open.                                                      # NOTE: from Upload::FileMethods
  #
  # @type [Hash]
  #
  # @see Down::NetHttp#initialize
  # @see Down::NetHttp#open
  # @see Down::NetHttp#create_net_http
  #
  DOWN_OPEN_OPTIONS = { read_timeout: 60 }.deep_freeze

  # Acquire a remote file and copy it to storage.                               # NOTE: from Upload::FileMethods#upload_remote_file
  #
  # @param [String] url
  # @param [Hash]   opt     Passed to FileUploader::Attacher#attach except for:
  #
  # @option opt [Integer] :read_retry
  #
  # @return [FileUploader::UploadedFile]
  #
  def upload_remote(url, **opt)
    # @type [Down::ChunkedIO] io
    io = Down.open(url, **DOWN_OPEN_OPTIONS)
    opt[:metadata] = opt[:metadata]&.dup || {}
    opt[:metadata]['filename'] ||= File.basename(url)
    file_attacher.attach(io, **opt)
  rescue => error
    $stderr.puts "!!! #{__method__}: #{error.class}: #{error.message}"
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
  def upload_local(path, **opt)                                                 # NOTE: from Upload::FileMethods#upload_local_file
    File.open(path) do |io|
      file_attacher.attach(io, **opt)
    end
  rescue => error
    $stderr.puts "!!! #{__method__}: #{error.class}: #{error.message}"
    raise error
  end

  # ===========================================================================
  # :section: ActiveRecord validations
  # ===========================================================================

  protected

  # Indicate whether the attached file is valid.
  #
  def attached_file_valid?                                                      # NOTE: from Upload::FileMethods
    return false if file.nil?
    file_attacher.validate
    file_attacher.errors.each { |e|
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
  # == Usage Notes
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
  def note_cb(type)                                                             # NOTE: from Upload::FileMethods
    __debug_line("*** SHRINE CALLBACK #{type} ***")
  end

  # Finalize a file upload by promoting the :cache file to a :store file.
  #
  # @param [Boolean] no_raise         If *true*, don't re-raise exceptions.
  # @param [Boolean] keep_cached      If *true*, don't delete the original.
  #
  # @return [FileUploader::UploadedFile, nil]
  #
  def promote_cached_file(no_raise: false, keep_cached: false)                  # NOTE: from Upload::FileMethods
    __debug_items(binding)
    return unless attach_cached
    old_file   = !keep_cached
    old_file &&= file&.data
    old_file &&= FileUploader::UploadedFile.new(old_file)
    file_attacher.promote.tap { old_file&.delete }
  rescue => error
    # noinspection RubyMismatchedArgumentType
    log_exception(error, __method__)
    re_raise_if_internal_exception(error)
    raise error unless no_raise
  end

  # Finalize a deletion by the removing the file from :cache and/or :store.
  #
  # @param [Boolean] no_raise         If *true*, don't re-raise exceptions.
  #
  # @return [TrueClass, nil]
  #
  def delete_cached_file(no_raise: false)                                       # NOTE: from Upload::FileMethods
    __debug_items(binding)
    return unless attach_cached
    file_attacher.destroy
    file_attacher.set(nil)
    true
  rescue => error
    # noinspection RubyMismatchedArgumentType
    log_exception(error, __method__)
    re_raise_if_internal_exception(error)
    raise error unless no_raise
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
  def log_exception(excp, meth = nil)                                           # NOTE: from Upload::FileMethods
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)

    include Record::EmmaData

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include Record::Uploadable # TODO: remove after upload -> entry
      include ActiveRecord::Validations
      include ActiveRecord::Callbacks::ClassMethods
      # :nocov:
    end

    # =========================================================================
    # :section: ActiveRecord validations
    # =========================================================================

    validate(on: %i[create]) { attached_file_valid? }
    validate(on: %i[update]) { attached_file_valid? }

    # =========================================================================
    # :section: ActiveRecord callbacks
    # =========================================================================

    if DEBUG_SHRINE
      before_validation { note_cb(:before_validation) }
      after_validation  { note_cb(:after_validation) }
      before_save       { note_cb(:before_save) }
      before_create     { note_cb(:before_create) }
      after_create      { note_cb(:after_create) }
      before_update     { note_cb(:before_update) }
      after_update      { note_cb(:after_update) }
      before_destroy    { note_cb(:before_destroy) }
      after_destroy     { note_cb(:after_destroy) }
      after_save        { note_cb(:after_save) }
      before_commit     { note_cb(:before_commit) }
      after_commit      { note_cb(:after_commit) }
      after_rollback    { note_cb(:after_rollback) }
    end

    after_rollback :delete_cached_file, on: %i[create]

    after_destroy do
      delete_file
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # noinspection RailsParamDefResolve, RbsMissingTypeSignature
    if try(:base_class) == Action

      # Action subclasses that operate on AWS S3 member repository queues need
      # to be given the submission ID dynamically since it will not be included
      # in the data that they carry.
      #
      # @return [String]
      #
      attr_accessor :submission_id

    end

  end

end

__loading_end(__FILE__)
