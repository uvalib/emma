# test/controllers/upload_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class UploadControllerTest < ActionDispatch::IntegrationTest

  MODEL         = Upload
  CONTROLLER    = :upload
  PARAMS        = { controller: CONTROLLER }.freeze
  OPTIONS       = { controller: CONTROLLER }.freeze

  TEST_USERS    = ALL_TEST_USERS
  TEST_READERS  = TEST_USERS
  TEST_WRITERS  = TEST_USERS

  READ_FORMATS  = :all
  WRITE_FORMATS = :html

  setup do
    @readers = find_users(*TEST_READERS)
    @writers = find_users(*TEST_WRITERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'upload index - list all uploads' do
    action  = :index
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        case opt[:expect]
          when :success then opt[:redir] = index_redirect(user: user, **opt)
        end
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'upload show - details of an existing upload' do
    action  = :show
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        rec = uploads(:example)
        url = url_for(id: rec.id, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'upload new - data for a new upload' do
    action  = :new
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'upload create - a new upload' do
    action  = :create
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        rec = sample_for_create
        url = url_for(**rec.fields, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        post_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'upload edit - data for an existing upload' do
    action  = :edit
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        rec = sample_for_edit
        url = url_for(id: rec.id, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'upload update - replace an existing upload' do
    action  = :update
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        rec = sample_for_edit
        rec.set_state(:validating)
        url = url_for(**rec.fields, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        put_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'upload delete - select an existing upload for removal' do
    action  = :delete
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)

    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        rec = sample_for_delete
        url = url_for(id: rec.id, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'upload destroy - remove an existing upload' do
    action  = :destroy
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        rec = sample_for_delete
        url = url_for(id: rec.id, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        delete_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  public

  # @private
  # @type [Integer,nil]
  attr_accessor :create_id

  # @private
  # @type [Integer,nil]
  attr_accessor :edit_id

  # @private
  # @type [Integer,nil]
  attr_accessor :delete_id

  # Push a dummy item into the database for creating.
  #
  # @param [Symbol, String, Hash] src
  #
  # @return [Upload]
  #
  def sample_for_create(src = :example)
    current = create_id && Upload.find_by(id: create_id)
    current&.delete
    new_record(src).tap do |record|
      self.create_id = record.save!
      record.set_state('validating')
    end
  end

  # Push a dummy item into the database for editing.
  #
  # @param [Symbol, String, Hash] src
  #
  # @return [Upload]
  #
  def sample_for_edit(src = :edit_example)
    current = edit_id && Upload.find_by(id: edit_id)
    current&.delete
    new_record(src).tap do |record|
      self.edit_id = record.id if record.save!
    end
  end

  # Push a dummy item into the database for deletion.
  #
  # @param [Symbol, String, Hash] src
  #
  # @return [Upload]
  #
  def sample_for_delete(src = :delete_example)
    current = delete_id && Upload.find_by(id: delete_id)
    return current if current && (src == :delete_example)
    current&.delete
    new_record(src).tap do |record|
      self.delete_id = record.id if record.save!
    end
  end

  # Generate a new non-persisted item to support new item creation.
  #
  # @param [Symbol, String, Hash] src
  #
  # @return [Upload]
  #
  def new_record(src = :example)
    fields = src.is_a?(Hash) ? src : uploads(src.to_sym).fields.except(:id)
    Upload.new(fields)
  end

  # ===========================================================================
  # :section: TestHelper::Utility overrides
  # ===========================================================================

  public

  # The default :index action redirects to :list_own.
  #
  # @param [Hash] opt
  #
  # @return [String, nil]
  #
  def index_redirect(**opt)
    opt[:dst] ||= :list_own
    super
  end

end
