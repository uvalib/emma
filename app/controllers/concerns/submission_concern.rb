# app/controllers/concerns/submission_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for bulk submissions.
#
module SubmissionConcern

  extend ActiveSupport::Concern

  include ApiConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Access the bulk submission service.
  #
  # @return [SubmissionService]
  #
  def submission_api
    # noinspection RubyMismatchedReturnType
    api_service(SubmissionService)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # start_submission
  #
  # @param [Manifest] manifest
  # @param [Hash]     opt             To SubmissionService#make_request
  #
  # @return [void]
  #
  def start_submission(manifest, **opt)
    submission_api.make_request(:start, manifest: manifest, **opt)
  end

  # stop_submission
  #
  # @param [Manifest] manifest
  # @param [Hash]     opt             To SubmissionService#make_request
  #
  # @return [void]
  #
  def stop_submission(manifest, **opt)
    submission_api.make_request(:cancel, manifest: manifest, **opt)
  end

  # pause_submission
  #
  # @param [Manifest] manifest
  # @param [Hash]     opt             To SubmissionService#make_request
  #
  # @return [void]
  #
  def pause_submission(manifest, **opt)
    submission_api.make_request(:pause, manifest: manifest, **opt)
  end

  # resume_submission
  #
  # @param [Manifest] manifest
  # @param [Hash]     opt             To SubmissionService#make_request
  #
  # @return [void]
  #
  def resume_submission(manifest, **opt)
    submission_api.make_request(:resume, manifest: manifest, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
