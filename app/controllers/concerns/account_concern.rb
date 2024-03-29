# app/controllers/concerns/account_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support methods for the "/account" controller.
#
# @!method model_options
#   @return [User::Options]
#
# @!method paginator
#   @return [User::Paginator]
#
module AccountConcern

  extend ActiveSupport::Concern

  include Emma::Common

  include SerializationConcern
  include ModelConcern

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Columns searched for generic (:like) matches.
  #
  # @type [Array<Symbol>]
  #
  ACCT_MATCH_KEYS = %i[email last_name first_name].freeze

  # Parameter keys related to password management.
  #
  # @type [Array<Symbol>]
  #
  PASSWORD_KEYS = %i[password password_confirmation current_password].freeze

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
    id ||= identifier.presence&.to_s
    super || (id == current_id.to_s)
  end

  # The identifier of the current model instance which #CURRENT_ID represents
  # in the context of AccountController actions.
  #
  # @return [Integer, nil]
  #
  def current_id
    current_user&.id
  end

  # URL parameters associated with model record(s).
  #
  # @return [Array<Symbol>]
  #
  def id_param_keys
    [*super, :email].uniq
  end

  # ===========================================================================
  # :section: ModelConcern overrides
  # ===========================================================================

  public

  def find_or_match_keys
    super(*User.field_names, *PASSWORD_KEYS)
  end

  # ===========================================================================
  # :section: ModelConcern overrides
  # ===========================================================================

  public

  # Return with the specified User record.
  #
  # @param [any, nil] item      String, Integer, Hash, Model; def: #identifier.
  # @param [Hash]     opt       Passed to Record::Identification#find_record.
  #
  # @raise [Record::StatementInvalid] If :id not given.
  # @raise [Record::NotFound]         If *item* was not found.
  #
  # @return [User, nil]         A fresh record unless *item* is a #model_class.
  #
  # @yield [record] Raise an exception if the record is not acceptable.
  # @yieldparam [User] record
  # @yieldreturn [void]
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def find_record(item = nil, **opt, &blk)
    return super if blk
    authorized_session
    super do |record|
      authorized_org_member(record)
    end
  end

  # Start a new User.
  #
  # @param [Hash, nil] prm            Field values (def: `#current_params`).
  # @param [Hash]      opt            Added field values.
  #
  # @option opt [Boolean] force       If *true* allow setting of :id.
  #
  # @return [User]                    An un-persisted User instance.
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
      if administrator?
        # Allow :org_id to be nil so that it can be selected on the form.
      else
        attr[:org_id] = current_org_id
      end
    end
  end

  # Add a new User record to the database.
  #
  # @param [Hash, nil] prm            Field values (def: `#current_params`).
  # @param [Boolean]   fatal          If *false*, use #save not #save!.
  # @param [Hash]      opt            Added field values.
  #
  # @option opt [Boolean] force       If *true* allow setting of :id.
  #
  # @return [User]                    The new User record.
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
    super do |attr|
      if administrator?
        attr[:org_id] = Org.none.id if attr[:org_id].nil?
      else
        attr[:org_id] = current_org_id
      end
    end
  end

  # Start editing an existing User record.
  #
  # @param [any, nil] item            Default: the record for #identifier.
  # @param [Hash]     opt             Passed to #find_record.
  #
  # @raise [Record::StatementInvalid] If :id not given.
  # @raise [Record::NotFound]         If *item* was not found.
  #
  # @return [User, nil]               A fresh instance unless *item* is a User.
  #
  # @yield [record] Raise an exception if the record is not acceptable.
  # @yieldparam [User] record         May be altered by the block.
  # @yieldreturn [void]               Block not called if *record* is *nil*.
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def edit_record(item = nil, **opt, &blk)
    return super if blk
    super do |record|
      authorized_self_or_org_manager(record)
    end
  end

  # Update the indicated User record, ensuring that :email and :org_id are not
  # changed unless authorized.
  #
  # @param [any, nil] item            Def.: record for ModelConcern#identifier.
  # @param [Boolean]  fatal           If *false* use #update not #update!.
  # @param [Hash]     opt             Field values (default: `#current_params`)
  #
  # @raise [Record::NotFound]               Record could not be found.
  # @raise [ActiveRecord::RecordInvalid]    Record update failed.
  # @raise [ActiveRecord::RecordNotSaved]   Record update halted.
  #
  # @return [User, nil]               The updated User record.
  #
  # @yield [record, attr] Raise an exception if the record is not acceptable.
  # @yieldparam [User] record         May be altered by the block.
  # @yieldparam [Hash] attr           New field(s) to be assigned to *record*.
  # @yieldreturn [void]               Block not called if *record* is *nil*.
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def update_record(item = nil, fatal: true, **opt, &blk)
    return super if blk
    super do |record, attr|
      if administrator?
        attr[:org_id] = Org.none.id if attr[:org_id].nil?
      else
        discard = []
        if attr.key?((k = :org_id)) && (attr[k] != current_org_id)
          discard << k
        end
        if attr.key?((k = :email)) && ((acct = attr[k]) != record.account)
          if acct.blank? || !manager? || (User.find_by(k => acct)&.oid != org)
            discard << k
          end
        end
        if discard.present?
          attr.except!(*discard)
          Log.info do
            # noinspection RubyScope
            list = discard.map { |k, v| "#{k}=#{v.inspect}" }.join(', ')
            "#{__method__}: discarded: #{list} for #{current_user}"
          end
        end
      end
    end
  end

  # Retrieve the indicated User record(s) for the '/delete' page.
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
    unauthorized unless administrator? || manager?
    super
  end

  # Remove the indicated User record(s).
  #
  # @param [any, nil] items
  # @param [Boolean]  fatal           If *false* do not #raise_failure.
  # @param [Hash]     opt             Default: `#current_params`
  #
  # @raise [Record::SubmitError]      If there were failure(s).
  #
  # @return [Array]                   Destroyed User records.
  #
  # @yield [record] Called for each record before deleting.
  # @yieldparam [User] record
  # @yieldreturn [String,nil]         Error message if *record* unacceptable.
  #
  #--
  # noinspection RubyMismatchedReturnType
  #++
  def destroy_records(items = nil, fatal: true, **opt, &blk)
    return super if blk
    unauthorized unless administrator? || manager?
    super do |record|
      unless authorized_org_manager(record, fatal: false)
        "no authorization to remove #{record}"
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get matching User account records or all records if no terms are given.
  #
  # @param [Array<String,Hash,Array,nil>] terms
  # @param [Array<Symbol>]                columns
  # @param [Hash]                         hash_terms  Added to *terms* except
  #                                                     #MAKE_RELATION_OPT
  #
  # @return [ActiveRecord::Relation<User>]
  #
  def get_accounts(*terms, columns: ACCT_MATCH_KEYS, **hash_terms)
    keys  = Record::Searchable::MAKE_RELATION_OPT
    opt   = normalize_sort_order!(hash_terms.extract!(*keys))
    terms = terms.push(hash_terms).flatten.compact_blank!
    terms.map! { |t| t.is_a?(Hash) ? normalize_predicates!(t) : t }
    case
      when terms.present?           then opt[:columns] = columns
      when administrator?           then # continue
      when (org = current_org&.id)  then opt[:org_id]  = org
      when (usr = current_user&.id) then opt[:id]      = usr
      else                               return User.none
    end
    User.make_relation(*terms, **opt)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Configured account record fields.
  #
  # @return [ActionConfig]            Frozen result.
  #
  def account_fields(...)
    Model.configuration_fields(:account)[:all]
  end

  # Get the appropriate message to display.
  #
  # @param [Symbol]       action
  # @param [Symbol]       outcome
  # @param [ActionConfig] config
  #
  # @return [String, nil]
  #
  def message_for(action, outcome, config = account_fields)
    # noinspection RubyMismatchedReturnType
    [action, :generic, :messages].find do |k|
      (v = config.dig(k, outcome)) and (break v)
    end
  end

  # Get the appropriate terms for message interpolations.
  #
  # @param [Symbol]       action
  # @param [ActionConfig] config
  #
  # @return [Hash]
  #
  def interpolation_terms(action, config = account_fields)
    result = config.dig(action, :terms) || config.dig(action, :term) || {}
    action = result[:action] ||= action.to_s
    result[:actioned] ||= (action + (action.end_with?('e') ? 'd' : 'ed'))
    result
  end

  # ===========================================================================
  # :section: ResponseConcern overrides
  # ===========================================================================

  public

  def default_fallback_location = account_index_path

  # Display the failure on the screen -- immediately if modal, or after a
  # redirect otherwise.
  #
  # @param [Exception, User, String] error
  # @param [String]                  fallback
  # @param [Symbol]                  meth
  #
  # @return [void]
  #
  def error_response(error, fallback = nil, meth: nil)
    fallback ||=
      case params[:action]&.to_sym
        when :new,    :create  then { action: :new }
        when :edit,   :update  then { action: :edit }
        when :delete, :destroy then { action: :index }
      end
    super
  end

  # ===========================================================================
  # :section: OptionsConcern overrides
  # ===========================================================================

  protected

  # Create an Options instance from the current parameters.
  #
  # @return [User::Options]
  #
  def get_model_options
    User::Options.new(request_parameters)
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
  # @return [User::Paginator]
  #
  def pagination_setup(paginator: User::Paginator, **opt)
    # noinspection RubyMismatchedReturnType
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module DeviseMethods

    # devise_mapping
    #
    # @return [Devise::Mapping]
    #
    # @see DeviseController#devise_mapping
    #
    def devise_mapping
      @devise_mapping ||=
        request.env['devise.mapping'] ||= Devise.mappings[:user]
    end

    # resource_class
    #
    # @return [Class]
    #
    # @see DeviseController#resource_class
    # @see Devise::Mapping#to
    #
    def resource_class
      devise_mapping.to
    end

    # resource_name
    #
    # @return [String]
    #
    # @see DeviseController#resource_name
    # @see Devise::Mapping#name
    #
    def resource_name
      devise_mapping.name
    end
    alias :scope_name :resource_name

    # resource
    #
    # @return [User, nil]
    #
    # @see DeviseController#resource
    #
    def resource
      instance_variable_get(:"@#{resource_name}")
    end

    # resource=
    #
    # @param [User, nil] new_resource
    #
    # @return [User, nil]
    #
    # @see DeviseController#resource=
    #
    def resource=(new_resource)
      instance_variable_set(:"@#{resource_name}", new_resource)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.helper(self) if base.respond_to?(:helper)
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)

    include DeviseMethods

  end

end

__loading_end(__FILE__)
