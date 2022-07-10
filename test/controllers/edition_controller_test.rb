# test/controllers/edition_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class EditionControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = :edition
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = %i[anonymous emmadso].freeze
  TEST_READERS = TEST_USERS
  TEST_WRITERS = %i[anonymous].freeze # TODO: edition write tests

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
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)
    periodical = sample_periodical.seriesId
    edition    = sample_edition.editionId
    url_opt    = { seriesId: periodical, editionId: edition }
    @readers.each do |user|
      TEST_FORMATS.each do |fmt|
        url = edition_index_url(url_opt.merge(format: fmt))
        opt = options.merge(format: fmt)
        get_as(user, url, **opt)
      end
    end
  end

  test 'edition show - details of an existing edition' do
    action  = :show
    options = OPTIONS.merge(action: action, test: __method__, expect: :success)
    periodical = sample_periodical.seriesId
    edition    = sample_edition.editionId
    url_opt    = { id: periodical, editionId: edition }
    @readers.each do |user|
      TEST_FORMATS.each do |fmt|
        url = edition_url(url_opt.merge(format: fmt))
        opt = options.merge(format: fmt)
        get_as(user, url, **opt)
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
    options = OPTIONS.merge(action: action, test: __method__)
    url     = new_edition_url
    @writers.each do |user|
      get_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'edition create - a new edition' do
    action  = :create
    options = OPTIONS.merge(action: action, test: __method__)
    url     = edition_index_url
    @writers.each do |user|
      post_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'edition edit - metadata for an existing edition' do
    action     = :edit
    options    = OPTIONS.merge(action: action, test: __method__)
    periodical = sample_periodical.seriesId
    url        = edit_edition_url(id: periodical)
    @writers.each do |user|
      get_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'edition update - modify an existing edition' do
    action     = :update
    options    = OPTIONS.merge(action: action, test: __method__)
    periodical = sample_periodical.seriesId
    url        = edition_url(id: periodical)
    @writers.each do |user|
      put_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  test 'edition destroy - remove an existing edition' do
    action     = :destroy
    options    = OPTIONS.merge(action: action, test: __method__)
    periodical = sample_periodical.seriesId
    url        = edition_url(id: periodical)
    @writers.each do |user|
      delete_as(user, url, **options)
    end if allowed_format(only: :html)
  end

  # ===========================================================================
  # :section: Download tests
  # ===========================================================================

  test 'edition download - get an edition artifact' do
    options    = { test: __method__ }
    periodical = sample_periodical.seriesId
    edition    = sample_edition.editionId
    format     = sample_artifact.format
    url_opt    = { seriesId: periodical, editionId: edition, fmt: format }
    @readers.each do |user|
      able = can?(user, :download, Edition)
      TEST_FORMATS.each do |fmt|
        url = edition_download_url(url_opt.merge(format: fmt))
        opt = able ? options.dup : options.merge(format: fmt)
        opt[:expect] = (able || (fmt == :html)) ? :redirect : :unauthorized
        get_as(user, url, **opt) do
          if fmt == :html
            redirect_to = able ? /bookshare/ : Regexp.new(BASE_URL)
            assert_select "a:match('href', ?)", redirect_to, text: 'redirected'
          end
        end
      end
    end unless not_applicable 'TODO: edition download test'
  end

end
