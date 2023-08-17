# test/controllers/manifest_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class ManifestControllerTest < ActionDispatch::IntegrationTest

  MODEL         = Manifest
  CONTROLLER    = :manifest
  PARAMS        = { controller: CONTROLLER }.freeze
  OPTIONS       = { controller: CONTROLLER, expect: :success }.freeze

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

  test 'manifest index - list all manifests' do
    action  = :index
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        case (opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized)
          when :success then opt[:redir] = index_redirect(user: user, **opt)
        end
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'manifest show - details of an existing manifest' do
    action  = :show
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        rec = manifests(:example)
        url = url_for(id: rec.id, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'manifest new - import data for a new manifest' do
    action  = :new
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'manifest create - a new manifest' do
    action  = :create
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_opt[:expect] = :redirect

      TEST_FORMATS.each do |fmt|
        rec = new_record.tap { |r| r.user = user }
        url = url_for(**rec.fields, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] = :unauthorized unless fmt == :html
        post_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'manifest edit - data for an existing manifest' do
    action  = :edit
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        rec = sample_for_edit
        url = url_for(id: rec.id, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'manifest update - replace an existing manifest' do
    action  = :update
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_opt[:expect] = :redirect

      TEST_FORMATS.each do |fmt|
        rec = sample_for_edit
        url = url_for(**rec.fields, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] = :unauthorized unless fmt == :html
        put_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'manifest delete - select an existing manifest for removal' do
    action  = :delete
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)

      TEST_FORMATS.each do |fmt|
        rec = sample_for_delete
        url = url_for(id: rec.id, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'manifest destroy - remove an existing manifest' do
    action  = :destroy
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)

    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_opt[:expect] = :redirect

      TEST_FORMATS.each do |fmt|
        rec = sample_for_delete
        url = url_for(id: rec.id, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] = :unauthorized unless fmt == :html
        delete_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  # ===========================================================================
  # :section: Methods
  # ===========================================================================

  public

  # @private
  # @type [String,nil]
  attr_accessor :edit_id

  # @private
  # @type [String,nil]
  attr_accessor :delete_id

  # Push a dummy item into the database for editing.
  #
  # @param [Symbol, String, Hash] src
  #
  # @return [Manifest]
  #
  def sample_for_edit(src = :edit_example)
    current = edit_id && Manifest.find_by(id: edit_id)
    current&.delete
    new_record(src).tap do |record|
      self.edit_id = record.id if record.save!
    end
  end

  # Push a dummy item into the database for deletion.
  #
  # @param [Symbol, String, Hash] src
  #
  # @return [Manifest]
  #
  def sample_for_delete(src = :delete_example)
    current = delete_id && Manifest.find_by(id: delete_id)
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
  # @return [Manifest]
  #
  def new_record(src = :example)
    fields = src.is_a?(Hash) ? src : manifests(src.to_sym).fields.except(:id)
    Manifest.new(fields)
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
  def index_redirect(**opt, &blk)
    opt[:dst] ||= :list_own
    super(**opt, &blk)
  end

end
