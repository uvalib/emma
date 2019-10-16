# test/controllers/edition_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class EditionControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = 'edition'
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = [ANONYMOUS, EMMA_COLLECTION].freeze
  TEST_READERS = TEST_USERS
  TEST_WRITERS = [ANONYMOUS].freeze # TODO: edition write tests

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'edition index - list all editions for a periodical' do
    periodical = sample_periodical.seriesId
    edition    = sample_edition.editionId
    url_opt    = { seriesId: periodical, editionId: edition }
    options    = OPTIONS.merge(test: __method__, action: 'index')
    options[:expect] = :success
    TEST_READERS.each do |user|
      TEST_FORMATS.each do |fmt|
        url = edition_index_url(url_opt.merge(format: fmt))
        opt = options.merge(format: fmt)
        get_as(user, url, opt)
      end
    end
  end

  test 'edition show - details of an existing edition' do
    periodical = sample_periodical.seriesId
    edition    = sample_edition.editionId
    url_opt    = { id: periodical, editionId: edition }
    options    = OPTIONS.merge(test: __method__, action: 'show')
    options[:expect] = :success
    # NOTE: No periodicals are currently in the EMMA collection.
    # Until that changes this test will not succeed if logged in.
    # TEST_READERS.each do |user|
    [ANONYMOUS].each do |user|
      TEST_FORMATS.each do |fmt|
        url = edition_url(url_opt.merge(format: fmt))
        opt = options.merge(format: fmt)
        get_as(user, url, opt)
      end
    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  if TESTING_HTML

    test 'edition new - add metadata for a new edition' do
      url = new_edition_url
      opt = OPTIONS.merge(test: __method__, action: 'new')
      TEST_WRITERS.each do |user|
        get_as(user, url, opt)
      end
    end

    test 'edition create - a new edition' do
      url = edition_index_url
      opt = OPTIONS.merge(test: __method__, action: 'create')
      TEST_WRITERS.each do |user|
        post_as(user, url, opt)
      end
    end

    test 'edition edit - metadata for an existing edition' do
      periodical = sample_periodical.seriesId
      url        = edit_edition_url(id: periodical)
      opt        = OPTIONS.merge(test: __method__, action: 'edit')
      TEST_WRITERS.each do |user|
        get_as(user, url, opt)
      end
    end

    test 'edition update - modify an existing edition' do
      periodical = sample_periodical.seriesId
      url        = edition_url(id: periodical)
      opt        = OPTIONS.merge(test: __method__, action: 'update')
      TEST_WRITERS.each do |user|
        put_as(user, url, opt)
      end
    end

    test 'edition destroy - remove an existing edition' do
      periodical = sample_periodical.seriesId
      url        = edition_url(id: periodical)
      opt        = OPTIONS.merge(test: __method__, action: 'destroy')
      TEST_WRITERS.each do |user|
        delete_as(user, url, opt)
      end
    end

  end

  # ===========================================================================
  # :section: Download tests
  # ===========================================================================

=begin # TODO: edition download test
  test 'edition download - get an edition artifact' do
    periodical = sample_periodical.seriesId
    edition    = sample_edition.editionId
    format     = sample_artifact.format
    url_opt    = { seriesId: periodical, editionId: edition, fmt: format }
    options    = { test: __method__ }
    TEST_READERS.each do |user|
      able = can?(user, :download, Edition)
      TEST_FORMATS.each do |fmt|
        url = edition_download_url(url_opt.merge(format: fmt))
        opt = able ? options.dup : options.merge(format: fmt)
        opt[:expect] = (able || (fmt == :html)) ? :redirect : :unauthorized
        get_as(user, url, opt) do
          if fmt == :html
            redirect_to = able ? /bookshare/ : Regexp.new(BASE_URL)
            assert_select "a:match('href', ?)", redirect_to, text: 'redirected'
          end
        end
      end
    end
  end
=end

end
