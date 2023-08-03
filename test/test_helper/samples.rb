# test/test_helper/samples.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Access to sample models.
#
module TestHelper::Samples

  # A table of models and the selected entry from test/fixtures/*.yml.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  #--
  # noinspection NonAsciiCharacters
  #++
  SAMPLE_FIXTURE = {
    job_result:     :example,
    manifest:       :example,
    manifest_item:  :example,
    org:            :one,
    role:           :example,
    search_call:    :Mansfield_Park,
    search_result:  :Mansfield_Park_1,
    upload:         :emma_completed,
    user:           :test_dev,
  }.freeze

  # A string added to the start of each title created on a non-production
  # instance to help distinguish it from other index results.
  #
  # @type [String]
  #
  TITLE_PREFIX = UploadWorkflow::Properties::DEV_TITLE_PREFIX

  # File fixture for Uploads.
  #
  # @type [String]
  #
  UPLOAD_FILE = 'pg2148.epub'

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Define methods which generate model instances from the appropriate
  # text/fixtures/*.yml data.
  #
  # @!method sample_job_result
  # @!method sample_manifest
  # @!method sample_manifest_item
  # @!method sample_org
  # @!method sample_role
  # @!method sample_search_call
  # @!method sample_search_result
  # @!method sample_upload
  # @!method sample_user
  #
  SAMPLE_FIXTURE.each_pair do |model, fixture|
    define_method(:"sample_#{model}") do
      @sample ||= {}
      @sample[model] ||= send(model.to_s.pluralize.to_sym, fixture)
    end
  end

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:

    # Generate a sample instance from text/fixtures/jobs_results.yml.
    # @return [JobResult]
    def sample_job_result; end

    # Generate a sample instance from text/fixtures/manifests.yml.
    # @return [Manifest]
    def sample_manifest; end

    # Generate a sample instance from text/fixtures/manifest_items.yml.
    # @return [ManifestItem]
    def sample_manifest_item; end

    # Generate a sample instance from text/fixtures/orgs.yml.
    # @return [Org]
    def sample_org; end

    # Generate a sample instance from text/fixtures/roles.yml.
    # @return [Role]
    def sample_role; end

    # Generate a sample instance from text/fixtures/search_calls.yml.
    # @return [SearchCall]
    def sample_search_call; end

    # Generate a sample instance from text/fixtures/search_results.yml.
    # @return [SearchResult]
    def sample_search_result; end

    # Generate a sample instance from text/fixtures/uploads.yml.
    # @return [Upload]
    def sample_upload; end

    # Generate a sample instance from text/fixtures/users.yml.
    # @return [User]
    def sample_user; end

    # :nocov:
  end

end
