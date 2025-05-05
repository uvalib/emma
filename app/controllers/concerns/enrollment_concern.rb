# app/controllers/concerns/enrollment_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/enrollment" controller.
#
module EnrollmentConcern

  extend ActiveSupport::Concern

  include RecaptchaHelper

  include ModelConcern
  include MailConcern

  # ===========================================================================
  # :section: ModelConcern overrides
  # ===========================================================================

  public

  # Add a new Enrollment record to the database.
  #
  # @param [Hash, nil] prm            Field values (def: `#current_params`).
  # @param [Boolean]   fatal          If *false*, use #save not #save!.
  # @param [Hash]      opt            Added field values.
  #
  # @option opt [Boolean] force       If *true* allow setting of :id.
  #
  # @return [Enrollment]              The new Enrollment record.
  #
  # @yield [attr] Adjust attributes and/or raise an exception.
  # @yieldparam [Hash] attr           Supplied attributes for the new record.
  # @yieldreturn [void]
  #
  def create_record(prm = nil, fatal: true, **opt, &blk)
    opt.reverse_merge!(recaptcha: true) if recaptcha_active?
    return super if blk
    super do |attr|
      raise_failure('No contact information given') if attr[:org_users].blank?
      Org.normalize_names!(attr, fatal: Record::SubmitError)
      check_unique(attr)
    end
  end

  # Start editing an existing Enrollment record.
  #
  # @param [any, nil] item            Default: the record for #identifier.
  # @param [Hash]     opt             Passed to #find_record.
  #
  # @raise [Record::StatementInvalid] If :id not given.
  # @raise [Record::NotFound]         If *item* was not found.
  #
  # @return [Enrollment, nil] A fresh instance unless *item* is an Enrollment.
  #
  # @yield [record] Raise an exception if the record is not acceptable.
  # @yieldparam [Enrollment] record May be altered by the block.
  # @yieldreturn [void]                 Block not called if *record* is *nil*.
  #
  def edit_record(item = nil, **opt, &blk)
    return super if blk
    unauthorized unless administrator?
    super
  end

  # Update the indicated Enrollment record.
  #
  # @param [any, nil] item            Default: the record for #identifier.
  # @param [Boolean]  fatal           If *false* use #update not #update!.
  # @param [Hash]     opt             Field values (default: `#current_params`)
  #
  # @raise [Record::NotFound]               Record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Record update halted.
  #
  # @return [Enrollment, nil]                The updated Enrollment record.
  #
  # @yield [record, attr] Raise an exception if the record is not acceptable.
  # @yieldparam [Enrollment] record May be altered by the block
  # @yieldparam [Hash] attr             New field(s) to be assigned to *record*
  # @yieldreturn [void]                 Block not called if *record* is *nil*
  #
  def update_record(item = nil, fatal: true, **opt, &blk)
    return super if blk
    super do |record, attr|
      check_unique(attr, current: record)
    end
  end

  # Retrieve the indicated Enrollment record(s) for the '/delete' page.
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

  # Remove the indicated Enrollment record(s).
  #
  # @param [any, nil] items
  # @param [Boolean]  fatal           If *false* do not #raise_failure.
  # @param [Hash]     opt             Default: `#current_params`
  #
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array]                   Destroyed Enrollment records.
  #
  # @yield [record] Called for each record before deleting.
  # @yieldparam [Enrollment] record
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
  # result in a non-unique Enrollment or, ultimately, Organization.
  #
  # @param [Hash]          attrs      Enrollment fields/values.
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
      next if Org.where(k => v).blank? && Enrollment.where(k => v).blank?
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
  def default_fallback_location = enrollment_index_path

  # ===========================================================================
  # :section: OptionsConcern overrides
  # ===========================================================================

  protected

  # Create an Options instance from the current parameters.
  #
  # @return [Enrollment::Options]
  #
  def get_model_options
    Enrollment::Options.new(request_parameters)
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
  # @return [Enrollment::Paginator]
  #
  def pagination_setup(paginator: Enrollment::Paginator, **opt)
    opt[:id] ||= identifier
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The organization created by #finalize_enrollment.
  #
  # @return [Org, nil]
  #
  attr_reader :new_org

  # The users created by #finalize_enrollment.
  #
  # @return [Array<User>, nil]
  #
  attr_reader :new_users

  # Finalize an EMMA enrollment request by creating a new Org and User, and
  # removing the Enrollment record.
  #
  # @param [any, nil] item            Default: the record for #identifier.
  # @param [Hash]     opt             Passed to #find_record.
  #
  # @return [Enrollment, nil]
  #
  def finalize_enrollment(item = nil, **opt)
    item, _prm = model_request_params(item)
    __debug_items("WF #{self.class} #{__method__}") {{ opt: _prm, item: item }}
    time = opt.delete(:time) || DateTime.now
    find_record(item, **opt).tap do |record|
      @new_org, @new_users = record.complete_enrollment(updated_at: time)
      record.destroy
    end
  end

  # Indicate whether #generate_new_users_emails should be run for users of a
  # new organization.
  #
  def new_users_email?
    new_users.present? && send_welcome_email?
  end

  # Send a welcome email to all new users created along with the organization.
  # In addition, manager users will receive #new_org_email.
  #
  # @param [Hash] opt                 To MailConcern#generate_new_org_emails
  #
  # @return [void]
  #
  def generate_new_users_emails(**opt)
    generate_new_org_emails(new_users, **opt)
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
