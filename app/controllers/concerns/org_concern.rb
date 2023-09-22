# app/controllers/concerns/org_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/org" controller.
#
module OrgConcern

  extend ActiveSupport::Concern

  include ModelConcern

  # ===========================================================================
  # :section: ParamsConcern overrides
  # ===========================================================================

  public

  # The identifier of the current model instance which #CURRENT_ID represents
  # in the context of OrgController actions.
  #
  # @return [Integer, nil]
  #
  def current_id
    current_org&.id
  end

  # ===========================================================================
  # :section: ModelConcern overrides
  # ===========================================================================

  public

  # Get URL parameters relevant to the current operation.
  #
  # @return [Hash{Symbol=>*}]
  #
  def current_get_params
    super do |prm|
      prm[:id] ||= current_id
    end
  end

  # Extract POST parameters that are usable for creating/updating a Manifest
  # instance.
  #
  # @return [Hash{Symbol=>*}]
  #
  def current_post_params
    super do |prm|
      prm[:id] ||= current_id
    end
  end

  # Create and persist a new Org.
  #
  # @param [Hash, nil]       attr       Default: `#current_params`.
  # @param [Boolean, String] force_id   If *true*, allow setting of :id.
  # @param [Boolean]         fatal      If *false*, use #save not #save!.
  #
  # @return [Org]                       A new Org instance.
  #
  def create_record(attr = nil, force_id: true, fatal: true, **)
    raise "unavailable to user '#{current_user}'" unless administrator?
    # noinspection RubyMismatchedReturnType
    super
  end

  # Update the indicated Org.
  #
  # @param [Org, nil] item            Def.: record for ModelConcern#identifier.
  # @param [Boolean]  fatal           If *false* use #update not #update!.
  # @param [Hash]     prm             Field values.
  #
  # @raise [Record::NotFound]               Record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Record update halted.
  #
  # @return [Org, nil]                The updated Org instance.
  #
  def update_record(item = nil, fatal: true, **prm)
    raise "unavailable to user '#{current_user}'" unless administrator?
    # noinspection RubyMismatchedReturnType
    super
  end

  # Remove the indicated record(s).
  #
  # @param [String, Org, Array, nil] items
  # @param [Hash, nil]               prm      Default: `#current_params`
  # @param [Boolean]                 fatal
  #
  # @raise [Record::SubmitError]              If there were failure(s).
  #
  # @return [Array]                           Destroyed entries.
  #
  def destroy_records(items = nil, prm = nil, fatal: true, **)
    raise "unavailable to user '#{current_user}'" unless administrator?
    super
  end

  # ===========================================================================
  # :section: ResponseConcern overrides
  # ===========================================================================

  public

  def default_fallback_location = org_index_path

  # ===========================================================================
  # :section: OptionsConcern overrides
  # ===========================================================================

  protected

  # Create an Options instance from the current parameters.
  #
  # @return [Org::Options]
  #
  def get_model_options
    Org::Options.new(request_parameters)
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
  # @return [Org::Paginator]
  #
  def pagination_setup(paginator: Org::Paginator, **opt)
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
