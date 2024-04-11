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

  # ===========================================================================
  # :section: ModelConcern overrides
  # ===========================================================================

  public

  # @private
  # @type [Array<Symbol>]
  NAME_FIELD_KEYS = %i[long_name short_name].freeze

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
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def create_record(prm = nil, fatal: true, **opt, &blk)
    opt.reverse_merge!(recaptcha: true) if recaptcha_active?
    return super if blk
    super do |attr|
      # Ensure that an initial organization user is present.
      if attr[:org_users].blank?
        raise Record::SubmitError, 'No user information given'
      end

      # Ensure that :long_name is present and that :short_name is valid or can
      # be derived from :long_name.
      NAME_FIELD_KEYS.each do |k|
        v = attr[k]
        v ||= Enrollment.abbreviate_org(attr[:long_name]) if k == :short_name
        attr[k] = normalize_input(k, v)
      end

      # Ensure that :long_name and :short_name are unique.
      check_unique(attr, keys: NAME_FIELD_KEYS)
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
  #--
  # noinspection RubyMismatchedReturnType
  #++
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
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def update_record(item = nil, fatal: true, **opt, &blk)
    return super if blk
    super do |record, attr|
      # Ensure that :long_name and/or :short_name would not cause a conflict if
      # either is being changed.
      check_unique(attr, current: record, keys: NAME_FIELD_KEYS)
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
  # @yield [items, opt] Raise an exception unless the *items* are acceptable.
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
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def destroy_records(items = nil, fatal: true, **opt, &blk)
    return super if blk
    unauthorized unless administrator?
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Normalize a *field* value from input.
  #
  # @param [Symbol]   field
  # @param [any, nil] value
  #
  # @raise [Record::SubmitError]      If *value* is not acceptable for *field*.
  #
  # @return [String]                  Normalized value.
  #
  def normalize_input(field, value)
    case field
      when :long_name  then normalize_long_name(value)
      when :short_name then normalize_short_name(value)
      else                  Log.error("#{__method__}: #{field} unexpected")
    end
  end

  # Normalize a :long_name value.
  #
  # @param [any, nil] value
  #
  # @raise [Record::SubmitError]      If *value* is not acceptable for *field*.
  #
  # @return [String]                  Normalized value.
  #
  def normalize_long_name(value)
    value = value.to_s.squish
    error = ('Missing %{field}' if value.blank?)
    error &&= error % { field: 'organization name' } # TODO: I18n
    error and raise Record::SubmitError, error or value.upcase_first
  end

  # Normalize a :short_name value.
  #
  # @param [any, nil] value
  #
  # @raise [Record::SubmitError]      If *value* is not acceptable for *field*.
  #
  # @return [String]                  Normalized value.
  #
  def normalize_short_name(value)
    value = value.to_s.squish
    error =
      if value.blank?
        'Missing %{field}'
      elsif (value = value.gsub(/[^[:alnum:]]/, '')).blank?
        'Please use only letters or numbers for %{field}'
      elsif value.start_with?(/\d/)
        'Please begin %{field} with a letter'
      end
    error &&= error % { field: 'abbreviation' } # TODO: I18n
    error and raise Record::SubmitError, error or value
  end

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
  def check_unique(attrs, current: nil, keys: nil)
    attrs = attrs.slice(*keys)                      if keys
    attrs = attrs.reject { |k, v| current[k] == v } if current
    error =
      attrs.find do |k, v|
        next if Org.where(k => v).blank? && Enrollment.where(k => v).blank?
        break "There is already an organization with #{k} #{v.inspect}"
      end
    raise Record::SubmitError, error if error
  end

  # ===========================================================================
  # :section: ResponseConcern overrides
  # ===========================================================================

  public

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
    # noinspection RubyMismatchedReturnType
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
    # noinspection RubyMismatchedReturnType
    find_record(item, **opt).tap do |record|
      record.complete_enrollment(updated_at: time)
      record.destroy
    end
  end

  # Send a request email in order to generate a JIRA help ticket for a new
  # enrollment request.
  #
  # @param [Hash] opt
  #
  # @return [void]
  #
  # @see EnrollmentMailer#request_email
  #
  def generate_help_ticket(**opt)
    opt = params.slice(:format).merge!(opt)
    EnrollmentMailer.with(opt).request_email.deliver_later
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
