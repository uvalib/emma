# test/controllers/artifact_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class ArtifactControllerTest < ActionDispatch::IntegrationTest

  CONTROLLER   = :artifact
  OPTIONS      = { controller: CONTROLLER }.freeze

  TEST_USERS   = %i[anonymous emmadso].freeze
  TEST_READERS = TEST_USERS
  TEST_WRITERS = %i[anonymous].freeze # TODO: artifact write tests

  # noinspection RbsMissingTypeSignature
  setup do
    @readers = find_users(*TEST_READERS)
    @writers = find_users(*TEST_WRITERS)
  end

  # ===========================================================================
  # :section: Read tests
  # ===========================================================================

  test 'artifact index - list all artifacts' do
    action  = :index
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      able  = can?(user, action, Artifact)
      u_opt =
        if able
          options.merge(expect: :success)
        else
          options.except(:controller, :action)
        end
      TEST_FORMATS.each do |fmt|
        url = artifact_index_url(format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt)
      end
    end unless not_applicable
  end

  test 'artifact show - details of an existing artifact' do
    action  = :show
    options = OPTIONS.merge(action: action, test: __method__)
    title   = sample_title.bookshareId
    format  = sample_artifact.format
    params  = OPTIONS.merge(action: action, id: title, fmt: format)
    @readers.each do |user|
      able  = can?(user, action, Artifact)
      u_opt =
        if able
          options.merge(expect: :success)
        else
          options.except(:controller, :action)
        end
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt)
      end
    end unless not_applicable "Bookshare API doesn't support this"
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'artifact new - add metadata for a new artifact' do
    action  = :new
    options = OPTIONS.merge(action: action, test: __method__)
    params  = options.except(:test)
    url     = url_for(**params)
    @writers.each do |user|
      able  = can?(user, action, Artifact)
      u_opt =
        if able
          options.merge(expect: :success)
        else
          options.merge(expect: :redirect).except(:controller, :action)
        end
      get_as(user, url, **u_opt)
    end if allowed_format(only: :html)
  end

  test 'artifact create - upload a new artifact' do
    action  = :create
    options = OPTIONS.merge(action: action, test: __method__)
    params  = options.except(:test)
    url     = url_for(**params)
    @writers.each do |user|
      able  = can?(user, action, Artifact)
      u_opt =
        if able
          options.merge(expect: :no_content, media_type: nil)
        else
          options.merge(expect: :redirect).except(:controller, :action)
        end
      post_as(user, url, **u_opt)
    end if allowed_format(only: :html)
  end

  test 'artifact edit - metadata for an existing artifact' do
    action  = :edit
    options = OPTIONS.merge(action: action, test: __method__)
    title   = sample_title.bookshareId
    url     = edit_artifact_url(id: title)
    @writers.each do |user|
      able  = can?(user, action, Artifact)
      u_opt =
        if able
          options.merge(expect: :success)
        else
          options.merge(expect: :redirect).except(:controller, :action)
        end
      get_as(user, url, **u_opt)
    end if allowed_format(only: :html)
  end

  test 'artifact update - replace an existing artifact' do
    action  = :update
    options = OPTIONS.merge(action: action, test: __method__)
    title   = sample_title.bookshareId
    url     = artifact_url(id: title)
    @writers.each do |user|
      able  = can?(user, action, Artifact)
      u_opt =
        if able
          options.merge(expect: :no_content, media_type: nil)
        else
          options.merge(expect: :redirect).except(:controller, :action)
        end
      put_as(user, url, **u_opt)
    end if allowed_format(only: :html)
  end

  test 'artifact destroy - remove an existing artifact' do
    action  = :destroy
    options = OPTIONS.merge(action: action, test: __method__)
    title   = sample_title.bookshareId
    url     = artifact_url(id: title)
    @writers.each do |user|
      able  = can?(user, action, Artifact)
      u_opt =
        if able
          options.merge(expect: :no_content, media_type: nil)
        else
          options.merge(expect: :redirect).except(:controller, :action)
        end
      delete_as(user, url, **u_opt)
    end if allowed_format(only: :html)
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
    @readers.each do |user|
      able  = can?(user, :download, Artifact)
      u_opt = options
      TEST_FORMATS.each do |fmt|

        opt = u_opt.merge(format: fmt)

        if fmt == :html
          url = bs_download_url(url_opt)
          if able
            opt[:xhr]    = true
            opt[:format] = nil  # Defer format check until after the send.
            opt[:expect] = :any # Defer status check until after the send.
          else
            opt[:expect] = :redirect
          end
        else
          url = bs_download_url(url_opt.merge(format: fmt))
          opt[:expect] = able ? :success : :unauthorized
        end

        get_as(user, url, **opt) do

          # Additional post-send assertions.
          case response.status

            when 401 # Unauthorized
              assert fmt != :html
              assert response.body.match?(AUTH_FAILURE)

            when 302 # Redirect
              assert fmt == :html
              link = able ? DOWNLOAD_LINK : INTERNAL_LINK
              assert_select 'a:match("href", ?)', link, text: 'redirected'

            when 200 # Success
              unless fmt == :html
                valid = {
                  submitted: 'SUBMITTED',   # Fresh request for artifact.
                  download:  DOWNLOAD_LINK  # Artifact already generated.
                }
                ok = valid.values.any? { |v| response.body.match?(v) }
                assert ok, "response is none of #{valid.keys}"
              end

            else
              assert false, "Unexpected status #{response.status}"
          end

        end

      end
    end
  end

end
