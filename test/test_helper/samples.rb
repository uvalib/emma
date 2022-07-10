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
    artifact:       :brf,
    edition:        :New_Yorker_1,
    job_result:     :example,
    member:         :organization,
    periodical:     :New_Yorker,
    reading_list:   :A_Member_List,
    role:           :example,
    search_call:    :Mansfield_Park,
    search_result:  :Mansfield_Park_1,
    title:          :Investigación,
    user:           :developer,
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Define methods which generate model instances from the appropriate
  # text/fixtures/*.yml data.
  #
  # @!method sample_artifact
  # @!method sample_edition
  # @!method sample_job_result
  # @!method sample_member
  # @!method sample_periodical
  # @!method sample_reading_list
  # @!method sample_role
  # @!method sample_search_call
  # @!method sample_search_result
  # @!method sample_title
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

    # Generate a sample instance from text/fixtures/artifacts.yml.
    # @return [Artifact]
    def sample_artifact; end

    # Generate a sample instance from text/fixtures/editions.yml.
    # @return [Edition]
    def sample_edition; end

    # Generate a sample instance from text/fixtures/jobs_results.yml.
    # @return [JobResult]
    def sample_job_result; end

    # Generate a sample instance from text/fixtures/members.yml.
    # @return [Member]
    def sample_member; end

    # Generate a sample instance from text/fixtures/artifacts.yml.
    # @return [Periodical]
    def sample_periodical; end

    # Generate a sample instance from text/fixtures/reading_lists.yml.
    # @return [ReadingList]
    def sample_reading_list; end

    # Generate a sample instance from text/fixtures/roles.yml.
    # @return [Role]
    def sample_role; end

    # Generate a sample instance from text/fixtures/search_calls.yml.
    # @return [SearchCall]
    def sample_search_call; end

    # Generate a sample instance from text/fixtures/search_results.yml.
    # @return [SearchResult]
    def sample_search_result; end

    # Generate a sample instance from text/fixtures/titles.yml.
    # @return [Title]
    def sample_title; end

    # Generate a sample instance from text/fixtures/users.yml.
    # @return [User]
    def sample_user; end

    # :nocov:
  end

end
