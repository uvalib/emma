# test/test_helper/system_tests/ingest.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for working directly with the EMMA Unified Index.
#
module TestHelper::SystemTests::Ingest

  include TestHelper::SystemTests::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Cause the identified items to be updated in the EMMA Unified Index.
  #
  # @param [Array<Upload,String>] entries
  #
  # @return [Boolean]
  #
  def reindex(*entries)
    _, failures = UploadConcernShim.instance.reindex_submissions(*entries)
    failures.each { |msg| show_item(msg) }.blank?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # This is an object that is used to access UploadConcern functionality that
  # is not dependent on the context of operating within an ActionController.
  #
  class UploadConcernShim

    include Singleton
    include UploadConcern

    # Required to satisfy #ingest_api.
    def session = @session ||= {}

    # Required to satisfy #api_service.
    def current_user = @current_user ||= User.new(role: :developer)

  end

end
