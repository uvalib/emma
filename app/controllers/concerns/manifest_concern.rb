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
  # @param [Manifest, Hash, String, nil] item  Default: `#identifier`.
  # @param [Hash]                        opt   Passed to #find_record.
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

  # Return with the specified Manifest record.
  #
  # @param [any, nil] item      String, Integer, Hash, Model; def: #identifier.
  # @param [Hash]     opt       Passed to Record::Identification#find_record.
  #
  # @raise [Record::StatementInvalid] If :id not given.
  # @raise [Record::NotFound]         If *item* was not found.
  #
  # @return [Manifest, nil]     A fresh record unless *item* is a Manifest.
  #
  # @yield [record] Raise an exception if the record is not acceptable.
  # @yieldparam [Manifest] record
  # @yieldreturn [void]
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def find_record(item = nil, **opt, &blk)
    return super if blk
    authorized_session
    super do |record|
      authorized_self_or_org_member(record)
    end
  end

  # Start a new Manifest.
  #
  # @param [Hash, nil] prm            Field values (def: `#current_params`).
  # @param [Hash]      opt            Added field values.
  #
  # @option opt [Boolean] force       If *true* allow setting of :id.
  #
  # @return [Manifest]                An un-persisted Manifest instance.
  #
  # @yield [attr] Adjust attributes and/or raise an exception.
  # @yieldparam [Hash] attr           Supplied attributes for the new record.
  # @yieldreturn [void]
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def new_record(prm = nil, **opt, &blk)
    return super if blk
    authorized_session
    super do |attr|
      attr[:name]    ||= Manifest.default_name
      attr[:user_id] ||= current_user.id
      authorized_org_manager(attr) unless attr[:user_id] == current_user.id
    end
  end

  # Add a new Manifest record to the database.
  #
  # @param [Hash, nil] prm            Field values (def: `#current_params`).
  # @param [Boolean]   fatal          If *false*, use #save not #save!.
  # @param [Hash]      opt            Added field values.
  #
  # @option opt [Boolean] force       If *true* allow setting of :id.
  #
  # @return [Manifest]                The new Manifest record.
  #
  # @yield [attr] Adjust attributes and/or raise an exception.
  # @yieldparam [Hash] attr           Supplied attributes for the new record.
  # @yieldreturn [void]
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def create_record(prm = nil, fatal: true, **opt, &blk)
    return super if blk
    authorized_session
    super
  end

  # Start editing an existing Manifest record.
  #
  # @param [any, nil] item            Default: the record for #identifier.
  # @param [Hash]     opt             Passed to #find_record.
  #
  # @raise [Record::StatementInvalid]   If :id not given.
  # @raise [Record::NotFound]           If *item* was not found.
  #
  # @return [Manifest, nil]   A fresh instance unless *item* is a #model_class.
  #
  # @yield [record] Raise an exception if the record is not acceptable.
  # @yieldparam [Manifest] record     May be altered by the block.
  # @yieldreturn [void]               Block not called if *record* is *nil*.
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def edit_record(item = nil, **opt, &blk)
    return super if blk
    super do |record|
      authorized_self_or_org_member(record)
    end
  end

  # Update the indicated Manifest record, ensuring that the associated user is
  # not changed unless authorized.
  #
  # @param [any, nil] item            Def.: record for ModelConcern#identifier.
  # @param [Boolean]  fatal           If *false* use #update not #update!.
  # @param [Hash]     opt             Field values (default: `#current_params`)
  #
  # @raise [Record::NotFound]               Record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Record update halted.
  #
  # @return [Manifest, nil]           The updated Manifest record.
  #
  # @yield [record, attr] Raise an exception if the record is not acceptable.
  # @yieldparam [Manifest] record     May be altered by the block.
  # @yieldparam [Hash]     attr       New field(s) to be assigned to *record*.
  # @yieldreturn [void]               Block not called if *record* is *nil*.
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def update_record(item = nil, fatal: true, **opt, &blk)
    return super if blk
    super do |_record, attr|
      attr[:user_id] ||= current_user.id
      unless attr[:user_id] == current_user.id
        user = User.find_by(id: attr[:user_id])
        authorized_org_member(user)
      end
    end
  end

  # Retrieve the indicated Manifest record(s) for the '/delete' page.
  #
  # @param [any, nil] items           To #search_records
  # @param [Hash]     opt             Default: `#current_params`
  #
  # @raise [RangeError]               If :page is not valid.
  #
  # @return [Paginator::Result]
  #
  # @yield [items, opt] Raise an exception unless the `*items*` are acceptable.
  # @yieldparam [Array] items         Identifiers of items to be deleted.
  # @yieldparam [Hash]  options       Options to #search_records.
  # @yieldreturn [void]               Block not called if *record* is *nil*.
  #
  def delete_records(items = nil, **opt, &blk)
    return super if blk
    authorized_session
    super
  end

  # Remove the indicated Manifest record(s).
  #
  # @param [any, nil] items
  # @param [Boolean]  fatal           If *false* do not #raise_failure.
  # @param [Hash]     opt             Default: `#current_params`
  #
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array]                   Destroyed Manifest records.
  #
  # @yield [record] Called for each record before deleting.
  # @yieldparam [Manifest] record
  # @yieldreturn [String,nil]         Error message if *record* unacceptable.
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def destroy_records(items = nil, fatal: true, **opt, &blk)
    return super if blk
    authorized_session
    super do |record|
      unless authorized_self_or_org_manager(record, fatal: false)
        "no authorization to remove #{record}"
      end
    end
  end

  # ===========================================================================
  # :section: Workflow
  # ===========================================================================

  public

  # Persist changes to an existing manifest and update the saved state of all
  # associated rows.
  #
  # @param [Manifest, Hash, nil] item       Default: `#identifier`.
  # @param [Hash, nil]           attr       Default: `#current_params`.
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
  # @param [Manifest, Hash, nil] item       Default: `#identifier`.
  # @param [Hash, nil]           attr       Default: `#current_params`.
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
  # @param [Manifest, Hash, nil] item       Default: `#identifier`.
  # @param [Hash, nil]           opt        Ignored.
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

  # The default redirect path for #redirect_back_or_to.
  #
  # @return [String]
  #
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
