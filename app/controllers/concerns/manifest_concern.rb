# app/controllers/concerns/manifest_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/manifest" controller.
#
# @!method model_options
#   @return [Manifest::Options]
#
# @!method paginator
#   @return [Manifest::Paginator]
#
module ManifestConcern

  extend ActiveSupport::Concern

  include Emma::Common

  include SerializationConcern
  include SubmissionConcern
  include ModelConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return with the specified Manifest record.
  #
  # @param [Manifest, Hash, String, nil] item  Def `ModelConcern#identifier`
  # @param [Hash]                        opt   To ModelConcern#find_record.
  #
  # @return [Manifest]              A fresh record unless *item* is a Manifest.
  #
  def find_manifest(item = nil, **opt)
    # noinspection RubyMismatchedReturnType
    find_record(item, **opt)
  end

  # Locate related ManifestItem records.
  #
  # @param [Manifest, nil] item
  # @param [Hash]          opt
  #
  # @raise [Record::SubmitError]        If :page is not valid.
  #
  # @return [Paginator::Result]
  #
  def find_or_match_manifest_items(item = nil, **opt)
    # An :id is only valid in this context if it's a ManifestItem ID.
    opt[:id] &&= positive(opt[:id]) or opt.delete(:id)
    opt[:limit]       ||= paginator.page_size
    opt[:page]        ||= paginator.page_number
    opt[:manifest_id] ||= item&.id || identifier
    ManifestItem.search_records(**opt)
  end

  # ===========================================================================
  # :section: ModelConcern overrides
  # ===========================================================================

  public

  # Start a new (un-persisted) manifest.
  #
  # @param [Hash, nil]       prm        Field values (def: `#current_params`).
  # @param [Boolean, String] force_id   If *true*, allow setting of :id.
  #
  # @return [Manifest]                  Un-persisted Manifest instance.
  #
  def new_record(prm = nil, force_id: false, **)
    # noinspection RubyMismatchedReturnType
    super do |attr|
      attr[:name]  ||= Manifest.default_name
      attr[:user_id] = current_user.id unless manager? && attr[:user_id]
    end
  end

  # Update the indicated User, ensuring that :email is not changed unless
  # authorized.
  #
  # @param [*]       item             Def.: record for ModelConcern#identifier.
  # @param [Boolean] fatal            If *false* use #update not #update!.
  # @param [Hash]    prm              Field values (default: `#current_params`)
  #
  # @raise [Record::NotFound]               Record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Record update halted.
  #
  # @return [Manifest, nil]           The updated Manifest instance.
  #
  def update_record(item = nil, fatal: true, **prm)
    # noinspection RubyMismatchedReturnType
    super do |_record, attr|
      attr[:user_id] = current_user.id unless manager? && attr[:user_id]
    end
  end

  # ===========================================================================
  # :section: Workflow
  # ===========================================================================

  public

  # Persist changes to an existing manifest and update the saved state of all
  # associated rows.
  #
  # @param [Manifest, Hash, nil] item
  # @param [Hash, nil]           attr       Default: `#current_params`
  #
  # @raise [Record::NotFound]               If the Manifest could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Manifest record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Manifest record update halted.
  #
  # @return [Manifest]              A fresh record unless *item* is a Manifest.
  #
  # @see file:assets/javascripts/controllers/manifest-edit.js *saveUpdates()*
  #
  def save_changes(item = nil, attr = nil)
    item, attr = model_request_params(item, attr)
    find_manifest(item).tap do |manifest|
      manifest.save_changes!(**attr)
    end
  end

  # Back out of provisional changes to associated rows.
  #
  # @param [Manifest, Hash, nil] item
  # @param [Hash, nil]           attr       Default: `#current_params`
  #
  # @raise [Record::NotFound]               If the Manifest could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Manifest record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Manifest record update halted.
  #
  # @return [Manifest]              A fresh record unless *item* is a Manifest.
  #
  # @see file:assets/javascripts/controllers/manifest-edit.js *cancelUpdates()*
  #
  def cancel_changes(item = nil, attr = nil)
    item, attr = model_request_params(item, attr)
    find_manifest(item).tap do |manifest|
      manifest.cancel_changes!(**attr)
    end
  end

  # ===========================================================================
  # :section: Workflow
  # ===========================================================================

  public

  # Validate readiness of a manifest to start transmission.
  #
  # @param [Manifest, Hash, nil] item
  # @param [Hash, nil]           opt        Default: `#current_params`
  #
  # @raise [Record::NotFound]               If the Manifest could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Manifest record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Manifest record update halted.
  #
  # @return [Manifest]              A fresh record unless *item* is a Manifest.
  #
  def remit_manifest(item = nil, opt = nil)
    item, _ = model_request_params(item, opt)
    find_manifest(item)
  end

=begin # TODO: submission start/stop ?
  # Start transmission of a manifest.
  #
  # @param [Manifest, Hash, nil] item
  # @param [Hash, nil]           opt        Default: `#model_request_params`
  #
  # @raise [Record::NotFound]               If the Manifest could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Manifest record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Manifest record update halted.
  #
  # @return [Manifest]              A fresh record unless *item* is a Manifest.
  #
  def start_manifest(item = nil, opt = nil)
    item, _  = model_request_params(item, opt)
    find_manifest(item).tap do |manifest|
      start_submission(manifest)
    end
  end

  # Terminate transmission of a manifest.
  #
  # @param [Manifest, Hash, nil] item
  # @param [Hash, nil]           opt        Default: `#model_request_params`
  #
  # @raise [Record::NotFound]               If the Manifest could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Manifest record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Manifest record update halted.
  #
  # @return [Manifest]              A fresh record unless *item* is a Manifest.
  #
  def stop_manifest(item = nil, opt = nil)
    item, _  = model_request_params(item, opt)
    find_manifest(item).tap do |manifest|
      stop_submission(manifest) if manifest
    end
  end

  # Pause transmission of a manifest.
  #
  # @param [Manifest, Hash, nil] item
  # @param [Hash, nil]           opt        Default: `#model_request_params`
  #
  # @raise [Record::NotFound]               If the Manifest could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Manifest record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Manifest record update halted.
  #
  # @return [Manifest]              A fresh record unless *item* is a Manifest.
  #
  def pause_manifest(item = nil, opt = nil)
    item, _  = model_request_params(item, opt)
    find_manifest(item).tap do |manifest|
      pause_submission(manifest)
    end
  end

  # Resume transmission of a paused manifest.
  #
  # @param [Manifest, Hash, nil] item
  # @param [Hash, nil]           opt        Default: `#model_request_params`
  #
  # @raise [Record::NotFound]               If the Manifest could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Manifest record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Manifest record update halted.
  #
  # @return [Manifest]              A fresh record unless *item* is a Manifest.
  #
  def resume_manifest(item = nil, opt = nil)
    item, _  = model_request_params(item, opt)
    find_manifest(item).tap do |manifest|
      resume_submission(manifest)
    end
  end
=end

  # ===========================================================================
  # :section: ResponseConcern overrides
  # ===========================================================================

  public

  def default_fallback_location = manifest_index_path

  # ===========================================================================
  # :section: OptionsConcern overrides
  # ===========================================================================

  protected

  # Create an Options instance from the current parameters.
  #
  # @return [Manifest::Options]
  #
  def get_model_options
    Manifest::Options.new(request_parameters)
  end

  # ===========================================================================
  # :section: PaginationConcern overrides
  # ===========================================================================

  public

  # Create a Paginator for the current controller action.
  #
  # @param [Class<Paginator>] paginator  Paginator class.
  # @param [Hash]             opt        Passed to super.
  #
  # @return [Manifest::Paginator]
  #
  def pagination_setup(paginator: Manifest::Paginator, **opt)
    opt[:id] ||= identifier
    # noinspection RubyMismatchedReturnType
    super
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
