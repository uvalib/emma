# test/controllers/artifact_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class ArtifactControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = 'artifact'
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = [ANONYMOUS, EMMA_DSO].freeze
  TEST_READERS = TEST_USERS
  TEST_WRITERS = [ANONYMOUS].freeze # TODO: artifact write tests

  # ===========================================================================
  # :section:
  # ===========================================================================

=begin # TODO: all artifacts? Probably not...
  test 'artifact index - list all artifacts' do
    endpoint = artifact_index_path
    options  = OPTIONS.merge(test: __method__, action: 'index')
    TEST_READERS.each do |user|
      get_as(user, endpoint, options)
    end
  end
=end

  test 'artifact show - details of an existing artifact' do
    title    = sample_title.bookshareId
    endpoint = artifact_path(id: title)
    options  = OPTIONS.merge(test: __method__, action: 'show')
    TEST_READERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

  test 'artifact new - add metadata for a new artifact' do
    endpoint = new_artifact_path
    options  = OPTIONS.merge(test: __method__, action: 'new')
    TEST_WRITERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

  test 'artifact create - upload a new artifact' do
    endpoint = artifact_index_path
    options  = OPTIONS.merge(test: __method__, action: 'create')
    TEST_WRITERS.each do |user|
      post_as(user, endpoint, options)
    end
  end

  test 'artifact edit - metadata for an existing artifact' do
    title    = sample_title.bookshareId
    endpoint = edit_artifact_path(id: title)
    options  = OPTIONS.merge(test: __method__, action: 'edit')
    TEST_WRITERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

  test 'artifact update - replace an existing artifact' do
    title    = sample_title.bookshareId
    endpoint = artifact_path(id: title)
    options  = OPTIONS.merge(test: __method__, action: 'update')
    TEST_WRITERS.each do |user|
      put_as(user, endpoint, options)
    end
  end

  test 'artifact destroy - remove an existing artifact' do
    title    = sample_title.bookshareId
    endpoint = artifact_path(id: title)
    options  = OPTIONS.merge(test: __method__, action: 'destroy')
    TEST_WRITERS.each do |user|
      delete_as(user, endpoint, options)
    end
  end

  test 'artifact download - get an artifact' do
    title    = sample_title.bookshareId
    format   = sample_artifact.format
    endpoint = artifact_path(id: title, fmt: format)
    options  = OPTIONS.merge(test: __method__, action: 'download')
    TEST_READERS.each do |user|
      get_as(user, endpoint, options)
    end
  end

end
