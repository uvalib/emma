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
  include MailConcern

  # ===========================================================================
  # :section: ParamsConcern overrides
  # ===========================================================================

  public

  # Indicate whether request parameters (explicitly or implicitly) reference
  # the current user's organization.
  #
  # @param [any, nil] id              Default: `#identifier`.
  #
  def current_id?(id = nil)
    id ||= identifier.presence&.to_s or return current_org.present?
    super || (id == current_id.to_s)
  end

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
  # @return [Hash]
  #
  def current_get_params
    super do |prm|
      prm[:id] ||= current_id
    end
  end

  # Extract POST parameters that are usable for creating/updating a Manifest
  # instance.
  #
  # @return [Hash]
  #
  def current_post_params
    super do |prm|
      prm[:id] ||= current_id
    end
  end

  # ===========================================================================
  # :section: ModelConcern overrides
  # ===========================================================================

  public

  # Return with the specified Org record.
  #
  # @param [any, nil] item      String, Integer, Hash, Model; def: #identifier.
  # @param [Hash]     opt       Passed to Record::Identification#find_record.
  #
  # @raise [Record::StatementInvalid] If :id not given.
  # @raise [Record::NotFound]         If *item* was not found.
  #
  # @return [Org, nil]          A fresh record unless *item* is a #model_class.
  #
  # @yield [record] Raise an exception if the record is not acceptable.
  # @yieldparam [Org] record
  # @yieldreturn [void]
  #
  def find_record(item = nil, **opt, &blk)
    return super if blk
    unauthorized unless administrator? || manager?
    super do |record|
      authorized_org_manager(record)
    end
  end

  # Start a new Org.
  #
  # @param [Hash, nil] prm            Field values (def: `#current_params`).
  # @param [Hash]      opt            Added field values.
  #
  # @option opt [Boolean] force       If *true* allow setting of :id.
  #
  # @return [Org]                     An un-persisted Org instance.
  #
  # @yield [attr] Adjust attributes and/or raise an exception.
  # @yieldparam [Hash] attr           Supplied attributes for the new record.
  # @yieldreturn [void]
  #
  def new_record(prm = nil, **opt, &blk)
    return super if blk
    unauthorized unless administrator?
    super
  end

  # Add a new Org record to the database.
  #
  # @param [Hash, nil] prm            Field values (def: `#current_params`).
  # @param [Boolean]   fatal          If *false*, use #save not #save!.
  # @param [Hash]      opt            Added field values.
  #
  # @option opt [Boolean] force       If *true* allow setting of :id.
  #
  # @return [Org]                     The new Org record.
  #
  # @yield [attr] Adjust attributes and/or raise an exception.
  # @yieldparam [Hash] attr           Supplied attributes for the new record.
  # @yieldreturn [void]
  #
  def create_record(prm = nil, fatal: true, **opt, &blk)
    return super if blk
    unauthorized unless administrator?
    super do |attr|
      Org.normalize_names!(attr, fatal: Record::SubmitError)
      check_unique(attr)
      @new_org_man = attr[:contact].present?
    end
  end

  # Start editing an existing Org record.
  #
  # @param [any, nil] item            Default: the record for #identifier.
  # @param [Hash]     opt             Passed to #find_record.
  #
  # @raise [Record::StatementInvalid] If :id not given.
  # @raise [Record::NotFound]         If *item* was not found.
  #
  # @return [Org, nil]                A fresh instance unless *item* is an Org.
  #
  # @yield [record] Raise an exception if the record is not acceptable.
  # @yieldparam [Org] record          May be altered by the block.
  # @yieldreturn [void]               Block not called if *record* is *nil*.
  #
  def edit_record(item = nil, **opt, &blk)
    return super if blk
    unauthorized unless administrator? || manager?
    super do |record|
      authorized_org_manager(record)
    end
  end

  # Update the indicated Org record.
  #
  # @param [any, nil] item            Default: the record for #identifier.
  # @param [Boolean]  fatal           If *false* use #update not #update!.
  # @param [Hash]     opt             Field values (default: `#current_params`)
  #
  # @raise [Record::NotFound]               Record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Record update halted.
  #
  # @return [Org, nil]                The updated Org record.
  #
  # @yield [record, attr] Raise an exception if the record is not acceptable.
  # @yieldparam [Org]  record         May be altered by the block.
  # @yieldparam [Hash] attr           New field(s) to be assigned to *record*.
  # @yieldreturn [void]               Block not called if *record* is *nil*.
  #
  def update_record(item = nil, fatal: true, **opt, &blk)
    return super if blk
    unauthorized unless administrator? || manager?
    super do |record, attr|
      ln, sn = attr.values_at(:long_name, :short_name)
      norm   = ln && !ln.casecmp?(record[:long_name])
      norm ||= sn && !sn.casecmp?(record[:short_name])
      Org.normalize_names!(attr, fatal: Record::SubmitError) if norm
      check_unique(attr, current: record)
      @new_org_man = attr[:contact].present? && record[:contact].blank?
    end
  end

  # Retrieve the indicated Org record(s) for the '/delete' page.
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
    unauthorized unless administrator?
    super
  end

  # Remove the indicated Org record(s).
  #
  # @param [any, nil] items
  # @param [Boolean]  fatal           If *false* do not #raise_failure.
  # @param [Hash]     opt             Default: `#current_params`
  #
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array]                   Destroyed Org records.
  #
  # @yield [record] Called for each record before deleting.
  # @yieldparam [Org] record
  # @yieldreturn [String,nil]         Error message if *record* unacceptable.
  #
  def destroy_records(items = nil, fatal: true, **opt, &blk)
    return super if blk
    unauthorized unless administrator?
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Return with an error message value if any of the fields of *attr* would
  # result in a non-unique Organization.
  #
  # @param [Hash]          attrs      Org fields/values.
  # @param [Model, nil]    current    Existing record if *attr* is an update.
  # @param [Array<Symbol>] keys       Only check these fields.
  #
  # @raise [Record::SubmitError]      If uniqueness would be violated.
  #
  # @return [void]
  #
  def check_unique(attrs, current: nil, keys: %i[long_name short_name])
    attrs = attrs.dup   if keys || current
    attrs.slice!(*keys) if keys
    attrs.reject! do |k, v|
      v.is_a?(String) ? v.casecmp?(current[k]) : (v == current[k])
    end if current
    attrs.each_pair do |k, v|
      next if Org.where(k => v).blank?
      raise_failure("There is already an organization with #{k} #{v.inspect}")
    end
  end

  # ===========================================================================
  # :section: ResponseConcern overrides
  # ===========================================================================

  public

  # The default redirect path for #redirect_back_or_to.
  #
  # @return [String]
  #
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
