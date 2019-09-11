# test/test_helper/samples.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Access to sample models.
#
module TestHelper::Samples

  ANONYMOUS       = nil
  EMMA_DSO        = 'emmadso@bookshare.org'
  EMMA_COLLECTION = 'emmacollection@bookshare.org'
  EMMA_MEMBERSHIP = 'emmamembership@bookshare.org'

  # A table of models and the selected entry from test/fixtures/*.yml.
  #
  # @type [Hash{Symbol=>Symbol}]
  #
  SAMPLE_FIXTURE = {
    artifact:     :example,
    edition:      :New_Yorker_1,
    member:       :organization,
    periodical:   :New_Yorker,
    reading_list: :A_Member_List,
    role:         :example,
    title:        :Investigación,
    user:         :example,
  }.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Define methods which generate model instances from the appropriate
  # text/fixtures/*.yml data.
  SAMPLE_FIXTURE.each_pair do |model, fixture|
    define_method(:"sample_#{model}") do
      @sample ||= {}
      @sample[model] ||= send(model.to_s.pluralize.to_sym, fixture)
    end
  end

  # Non-operative hints for RubyMine.
  unless ONLY_FOR_DOCUMENTATION

    # Generate a sample instance from text/fixtures/artifacts.yml.
    # @return [Artifact]
    def sample_artifact; end

    # Generate a sample instance from text/fixtures/editions.yml.
    # @return [Edition]
    def sample_edition; end

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

    # Generate a sample instance from text/fixtures/titles.yml.
    # @return [Title]
    def sample_title; end

    # Generate a sample instance from text/fixtures/users.yml.
    # @return [User]
    def sample_user; end

  end

end
