# test/controllers/artifact_controller_test.rb
#
# frozen_string_literal: true
# warn_indent:           true

require 'test_helper'

class ArtifactControllerTest < ActionDispatch::IntegrationTest

  MODEL         = Artifact
  CONTROLLER    = :artifact
  PARAMS        = { controller: CONTROLLER }.freeze
  OPTIONS       = { controller: CONTROLLER, expect: :success }.freeze

  TEST_USERS    = %i[anonymous emmadso].freeze
  TEST_READERS  = TEST_USERS
  TEST_WRITERS  = %i[anonymous].freeze # TODO: artifact write tests

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

  test 'artifact index - list all artifacts' do
    action  = :index
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end unless not_applicable
  end

  test 'artifact show - details of an existing artifact' do
    action  = :show
    title   = sample_title.bookshareId
    format  = sample_artifact.format
    params  = PARAMS.merge(action: action, id: title, fmt: format)
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        get_as(user, url, **opt, only: READ_FORMATS)
      end
    end unless not_applicable "Bookshare API doesn't support this"
  end

  # ===========================================================================
  # :section: Write tests
  # ===========================================================================

  test 'artifact new - add metadata for a new artifact' do
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

  test 'artifact create - upload a new artifact' do
    action  = :create
    params  = PARAMS.merge(action: action)
    options = OPTIONS.merge(action: action, test: __method__)
    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt =
        if able
          options.merge(media_type: nil, expect: :no_content)
        else
          options.except(:controller, :action, :expect)
        end
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        post_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'artifact edit - metadata for an existing artifact' do
    action  = :edit
    title   = sample_title.bookshareId
    params  = PARAMS.merge(action: action, id: title)
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

  test 'artifact update - replace an existing artifact' do
    action  = :update
    title   = sample_title.bookshareId
    params  = PARAMS.merge(action: action, id: title)
    options = OPTIONS.merge(action: action, test: __method__)
    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt =
        if able
          options.merge(media_type: nil, expect: :no_content)
        else
          options.except(:controller, :action, :expect)
        end
      TEST_FORMATS.each do |fmt|
        url = url_for(**params, format: fmt)
        opt = u_opt.merge(format: fmt)
        opt[:expect] ||= (fmt == :html) ? :redirect : :unauthorized
        put_as(user, url, **opt, only: WRITE_FORMATS)
      end
    end
  end

  test 'artifact destroy - remove an existing artifact' do
    action  = :destroy
    title   = sample_title.bookshareId
    params  = PARAMS.merge(action: action, id: title)
    options = OPTIONS.merge(action: action, test: __method__)
    @writers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt =
        if able
          options.merge(media_type: nil, expect: :no_content)
        else
          options.except(:controller, :action, :expect)
        end
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

  DOWNLOAD_LINK = %r{https://bookshare}
  INTERNAL_LINK = Regexp.new(BASE_URL)

  test 'artifact download - get an artifact' do
    action  = :download
    title   = sample_title.bookshareId
    format  = sample_artifact.format
    params  = { bookshareId: title, fmt: format }
    options = OPTIONS.merge(action: action, test: __method__)
    @readers.each do |user|
      able  = can?(user, action, MODEL)
      u_opt = able ? options : options.except(:controller, :action, :expect)
      TEST_FORMATS.each do |fmt|

        url = bs_download_url(**params, format: fmt)
        opt = u_opt.merge(format: fmt)

        if fmt != :html
          opt[:expect] = able ? :success : :unauthorized
        elsif able
          opt[:xhr]    = true
          opt[:format] = nil  # Defer format check until after the send.
          opt[:expect] = :any # Defer status check until after the send.
        else
          opt[:expect] = :redirect
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
              flunk "Unexpected status #{response.status}"

          end
        end
      end
    end
  end

end
