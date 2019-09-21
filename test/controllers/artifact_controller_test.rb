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
  # :section: Read tests
  # ===========================================================================

=begin # TODO: all artifacts? Probably not...
  test 'artifact index - list all artifacts' do
    options = OPTIONS.merge(test: __method__, action: 'index')
    TEST_READERS.each do |user|
      TEST_FORMATS.each do |fmt|
        url = artifact_index_url(format: fmt)
        opt = options.merge(format: fmt)
        get_as(user, url, opt)
      end
    end
  end
=end

  test 'artifact show - details of an existing artifact' do
    title   = sample_title.bookshareId
    format  = sample_artifact.format
    url_opt = { id: title, fmt: format }
    options = OPTIONS.merge(test: __method__, action: 'show')
    TEST_READERS.each do |user|
      TEST_FORMATS.each do |fmt|
        url = artifact_url(url_opt.merge(format: fmt))
        opt = options.merge(format: fmt)
        get_as(user, url, opt)
      end
    end
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  if TESTING_HTML

    test 'artifact new - add metadata for a new artifact' do
      url     = new_artifact_url
      options = OPTIONS.merge(test: __method__, action: 'new')
      TEST_WRITERS.each do |user|
        able = can?(user, :new, Artifact)
        opt =
          if able
            options.merge(expect: :success)
          else
            options.merge(expect: :redirect).except(:controller, :action)
          end
        get_as(user, url, opt)
      end
    end

    test 'artifact create - upload a new artifact' do
      url     = artifact_index_url
      options = OPTIONS.merge(test: __method__, action: 'create')
      TEST_WRITERS.each do |user|
        able = can?(user, :create, Artifact)
        opt =
          if able
            options.merge(expect: :no_content, media_type: nil)
          else
            options.merge(expect: :redirect).except(:controller, :action)
          end
        post_as(user, url, opt)
      end
    end

    test 'artifact edit - metadata for an existing artifact' do
      title   = sample_title.bookshareId
      url     = edit_artifact_url(id: title)
      options = OPTIONS.merge(test: __method__, action: 'edit')
      TEST_WRITERS.each do |user|
        able = can?(user, :edit, Artifact)
        opt =
          if able
            options.merge(expect: :success)
          else
            options.merge(expect: :redirect).except(:controller, :action)
          end
        get_as(user, url, opt)
      end
    end

    test 'artifact update - replace an existing artifact' do
      title   = sample_title.bookshareId
      url     = artifact_url(id: title)
      options = OPTIONS.merge(test: __method__, action: 'update')
      TEST_WRITERS.each do |user|
        able = can?(user, :update, Artifact)
        opt =
          if able
            options.merge(expect: :no_content, media_type: nil)
          else
            options.merge(expect: :redirect).except(:controller, :action)
          end
        put_as(user, url, opt)
      end
    end

    test 'artifact destroy - remove an existing artifact' do
      title   = sample_title.bookshareId
      url     = artifact_url(id: title)
      options = OPTIONS.merge(test: __method__, action: 'destroy')
      TEST_WRITERS.each do |user|
        able = can?(user, :destroy, Artifact)
        opt =
          if able
            options.merge(expect: :no_content, media_type: nil)
          else
            options.merge(expect: :redirect).except(:controller, :action)
          end
        delete_as(user, url, opt)
      end
    end

  end

  # ===========================================================================
  # :section: Download tests
  # ===========================================================================

  DOWNLOAD_LINK = %r{https://bookshare}
  INTERNAL_LINK = Regexp.new(BASE_URL)

  test 'artifact download - get an artifact' do
    title   = sample_title.bookshareId
    format  = sample_artifact.format
    url_opt = { bookshareId: title, fmt: format }
    options = { test: __method__ }
    TEST_READERS.each do |user|
      able = can?(user, :download, Artifact)
      TEST_FORMATS.each do |fmt|

        opt = options.merge(format: fmt)

        if fmt == :html
          url = download_url(url_opt)
          if able
            opt[:xhr]    = true
            opt[:format] = nil  # Defer format check until after the send.
            opt[:expect] = :any # Defer status check until after the send.
          else
            opt[:expect] = :redirect
          end
        else
          url = download_url(url_opt.merge(format: fmt))
          opt[:expect] = able ? :success : :unauthorized
        end

        get_as(user, url, opt) do

          # Additional post-send assertions.
          case response.status

            when 401 # Unauthorized
              assert fmt != :html
              assert response.body.match?('sign in')

            when 302 # Redirect
              assert fmt == :html
              link = able ? DOWNLOAD_LINK : INTERNAL_LINK
              assert_select 'a:match("href", ?)', link, text: 'redirected'

            when 200 # Success
              unless fmt == :html
                assert \
                  response.body.match?('SUBMITTED') ||  # Fresh request
                  response.body.match?(DOWNLOAD_LINK)   # Already generated
              end

            else
              assert false, "Unexpected status #{response.status}"
          end

        end

      end
    end
  end

end
