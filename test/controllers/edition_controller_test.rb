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
  # :section:
  # ===========================================================================

  test 'edition index - list all editions for a periodical' do
    periodical = sample_periodical.seriesId
    edition    = sample_edition.editionId
    endpoint   = edition_index_path(seriesId: periodical, editionId: edition)
    options    = OPTIONS.merge(test: __method__, action: 'index')
    options[:expect] = :success
    TEST_READERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

  test 'edition show - details of an existing edition' do
    periodical = sample_periodical.seriesId
    edition    = sample_edition.editionId
    endpoint   = edition_path(id: periodical, editionId: edition)
    options    = OPTIONS.merge(test: __method__, action: 'show')
    options[:expect] = :success
    TEST_READERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

  test 'edition new - add metadata for a new edition' do
    endpoint = new_edition_path
    options  = OPTIONS.merge(test: __method__, action: 'new')
    TEST_WRITERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

  test 'edition create - a new edition' do
    endpoint = edition_index_path
    options  = OPTIONS.merge(test: __method__, action: 'create')
    TEST_WRITERS.each do |user|
      post_as(user, endpoint, options)
    end
  end

  test 'edition edit - metadata for an existing edition' do
    periodical = sample_periodical.seriesId
    endpoint   = edit_edition_path(id: periodical)
    options    = OPTIONS.merge(test: __method__, action: 'edit')
    TEST_WRITERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

  test 'edition update - modify an existing edition' do
    periodical = sample_periodical.seriesId
    endpoint   = edition_path(id: periodical)
    options    = OPTIONS.merge(test: __method__, action: 'update')
    TEST_WRITERS.each do |user|
      put_as(user, endpoint, options)
    end
  end

  test 'edition destroy - remove an existing edition' do
    periodical = sample_periodical.seriesId
    endpoint   = edition_path(id: periodical)
    options    = OPTIONS.merge(test: __method__, action: 'destroy')
    TEST_WRITERS.each do |user|
      delete_as(user, endpoint, options)
    end
  end

end
