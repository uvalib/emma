# test/controllers/org_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class OrgControllerTest < ActionDispatch::IntegrationTest

  MODEL         = Org
  CONTROLLER    = :org
  PARAMS        = { controller: CONTROLLER }.freeze
  OPTIONS       = { controller: CONTROLLER, expect: :success }.freeze

  TEST_USERS    = %i[anonymous test_guest_1 test_dso_1 test_man_1 test_adm].freeze
  TEST_READERS  = TEST_USERS
=begin # TODO: test_man_1's org doesn't match artificially generated fixture org
  TEST_WRITERS  = TEST_USERS
=end # TODO: Skip until able to dynamically create test users to match generated orgs:
  TEST_WRITERS  = TEST_USERS.excluding(:test_man_1).freeze

  READ_FORMATS  = :all
  WRITE_FORMATS = :html

  setup do
    @readers = find_users(*TEST_READERS)
    @writers = find_users(*TEST_WRITERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'org index - list all orgs' do
    action  = :index
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      admin = user&.administrator?
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      assert able, 'Administrator unable to list orgs' if admin
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect]   = :redirect unless admin
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        opt[:format]   = :any if opt[:expect] == :redirect
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'org show - details of an existing org' do
    action  = :show
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        rec = sample_org
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

  test 'org new - import data for a new org' do
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

  test 'org create - a new org' do
    action  = :create
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)
    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      u_opt[:expect] = :redirect
      TEST_FORMATS.each do |fmt|
        rec = new_record
        url = url_for(**rec.fields, **params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] = :unauthorized unless fmt == :html
        post_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'org edit - data for an existing org' do
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

  test 'org update - replace an existing org' do
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

  test 'org delete - select an existing org for removal' do
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

  test 'org destroy - remove an existing org' do
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
  attr_accessor :create_id

  # @private
  # @type [String,nil]
  attr_accessor :edit_id

  # @private
  # @type [String,nil]
  attr_accessor :delete_id

  # Push a dummy item into the database for creating.
  #
  # @param [Symbol, String, Hash] src
  #
  # @return [Org]
  #
  def sample_for_create(src = :example)
    current = create_id && Org.find_by(id: create_id)
    current&.delete
    new_record(src).tap do |record|
      self.create_id = record.save!
    end
  end

  # Push a dummy item into the database for editing.
  #
  # @param [Symbol, String, Hash] src
  #
  # @return [Org]
  #
  def sample_for_edit(src = :edit_example)
    current = edit_id && Org.find_by(id: edit_id)
    current&.delete
    new_record(src).tap do |record|
      self.edit_id = record.id if record.save!
    end
  end

  # Push a dummy item into the database for deletion.
  #
  # @param [Symbol, String, Hash] src
  #
  # @return [Org]
  #
  def sample_for_delete(src = :delete_example)
    current = delete_id && Org.find_by(id: delete_id)
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
  # @return [Org]
  #
  def new_record(src = :example)
    fields = src.is_a?(Hash) ? src : orgs(src.to_sym).fields.except(:id)
    Org.new(fields)
  end

end
