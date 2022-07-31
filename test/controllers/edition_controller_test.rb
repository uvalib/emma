# test/controllers/edition_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class EditionControllerTest < ActionDispatch::IntegrationTest

  MODEL         = Edition
  CONTROLLER    = :edition
  PARAMS        = { controller: CONTROLLER }.freeze
  OPTIONS       = { controller: CONTROLLER, expect: :success }.freeze

  TEST_USERS    = %i[anonymous emmadso].freeze
  TEST_READERS  = TEST_USERS
  TEST_WRITERS  = %i[anonymous].freeze # TODO: edition write tests

  READ_FORMATS  = :all
  WRITE_FORMATS = :all

  # noinspection RbsMissingTypeSignature
  setup do
    @readers = find_users(*TEST_READERS)
    @writers = find_users(*TEST_WRITERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'edition index - list all editions for a periodical' do
    action  = :index
    series  = sample_periodical.seriesId
    edition = sample_edition.editionId
    params  = PARAMS.merge(action: action, seriesId: series, editionId: edition)
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      u_opt = options
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end
  end

  test 'edition show - details of an existing edition' do
    action  = :show
    series  = sample_periodical.seriesId
    edition = sample_edition.editionId
    params  = PARAMS.merge(action: action, id: series, editionId: edition)
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      u_opt = options
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end unless not_applicable 'No periodicals available from Bookshare API'
    # NOTE: No periodicals are currently in the EMMA collection; until that
    #   changes this test will not succeed if logged in.
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'edition new - add metadata for a new edition' do
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

  test 'edition create - a new edition' do
    action  = :create
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)
    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        post_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'edition edit - metadata for an existing edition' do
    action  = :edit
    series  = sample_periodical.seriesId
    params  = PARAMS.merge(action: action, id: series)
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

  test 'edition update - modify an existing edition' do
    action  = :update
    series  = sample_periodical.seriesId
    params  = PARAMS.merge(action: action, id: series)
    options = OPTIONS.merge(action: action, test: __method__)
    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        put_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'edition destroy - remove an existing edition' do
    action  = :destroy
    series  = sample_periodical.seriesId
    params  = PARAMS.merge(action: action, id: series)
    options = OPTIONS.merge(action: action, test: __method__)
    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        delete_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  # ===========================================================================
  # :section: Download tests
  # ===========================================================================

  test 'edition download - get an edition artifact' do
    action  = :download
    series  = sample_periodical.seriesId
    edition = sample_edition.editionId
    format  = sample_artifact.format
    params  = { seriesId: series, editionId: edition, fmt: format }
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      able  = can?(user, :download, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = edition_download_url(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] = (able || (fmt == :html)) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: WRITE_FORMATS) do
          if fmt == :html
            redirect_to = able ? /bookshare/ : Regexp.new(BASE_URL)
            assert_select "a:match('href', ?)", redirect_to, text: 'redirected'
          end
        end
      end
    end unless not_applicable 'TODO: edition download test'
  end

end
