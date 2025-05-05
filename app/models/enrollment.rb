# app/models/enrollment.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# An EMMA enrollment request contains fields needed to generate a new Org
# record and at least one new User record (the new organization's manager).
#
class Enrollment < ApplicationRecord

  include Model

  include Record
  include Record::Assignable
  include Record::Searchable
  include Record::Sortable

  include Record::Testing
  include Record::Debugging

  include Enrollment::Config
  include Enrollment::Assignable

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include Record::Rendering
    extend  Record::Rendering
  end
  # :nocov:

  # ===========================================================================
  # :section: ActiveRecord ModelSchema
  # ===========================================================================

  self.implicit_order_column = :created_at

  # ===========================================================================
  # :section: ApplicationRecord overrides
  # ===========================================================================

  public

  # A short textual representation for the record instance.
  #
  # @param [Enrollment, nil] item     Default: self.
  #
  # @return [String, nil]
  #
  def abbrev(item = nil)
    (item || self).short_name.presence
  end

  # A textual label for the record instance.
  #
  # @param [Enrollment, nil] item     Default: self.
  #
  # @return [String, nil]
  #
  def label(item = nil)
    (item || self).long_name.presence
  end

  # Create a new instance.
  #
  # @param [Enrollment, Hash, nil] attr   To #assign_attributes via super.
  #
  # @note - for dev traceability
  #
  def initialize(attr = nil)
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # User information based on :org_users.
  #
  # @return [Array<Hash>]
  #
  def user_list
    @user_list ||= prepare_user_list(org_users)
  end

  # User information for the requesting user (from :org_users).
  #
  # @return [Hash]
  #
  def requesting_user
    user_list.first
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Normalize a value from :org_users, supplying roles if missing.
  #
  # @param [Array<Hash>, Hash, nil] users
  #
  # @return [Array<Hash>]
  #
  def prepare_user_list(users)
    users = Array.wrap(users).compact_blank.presence or return [{}]
    users.map! { json_parse(_1, log: false).reverse_merge!(role: 'standard') }
    users.first[:role] = 'manager' if users.none? { _1[:role] == 'manager' }
    users
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Use the current Enrollment instance to create an Org record and one or more
  # User records.
  #
  # @param [Hash] opt                 Field values for Org and User records.
  #
  # @return [Array<(Org,Array<User>)]
  #
  # == Usage Notes
  # The caller should remove the record associated with the current instance
  # if the result of this method is satisfactory.
  #
  def complete_enrollment(**opt)
    retry_opt = :"#{__method__}_retry"
    retrying  = opt.delete(retry_opt)
    org = usr = nil

    # Initialize values that will be used to create Org and/or User records.
    opt[:status]      ||= :active
    opt[:created_at]  ||= DateTime.now
    opt[:updated_at]  ||= opt[:created_at]
    opt[:status_date] ||= opt[:updated_at]
    opt[:start_date]  ||= opt[:status_date]

    org_attr = fields.merge(opt).slice(*Org.field_names).except(:id)
    usr_attr = opt.slice(*User.field_names).except(:id)

    Org.transaction do
      org = Org.create(org_attr)
      usr = user_list.map { _1.merge(usr_attr, org_id: org.id) }
      User.transaction(requires_new: true) { usr.map! { User.create(_1) } }
      org.update_columns(contact: usr.select(&:manager?).map(&:id))
    end
    return org, usr

  rescue ActiveRecord::RecordNotUnique => error
    # Attributes for the Org and User do not specify an :id so if this
    # exception is raised, the likely problem is that one or more table
    # sequences needs to be reset.  If the exception is raised a second time
    # then there must be a problem that will need to be dealt with elsewhere.
    raise error if retrying
    Log.warn { "#{__method__}: resetting Org/User sequences and retrying" }
    conn = ActiveRecord::Base.connection
    conn.reset_pk_sequence!(Org.table_name)
    conn.reset_pk_sequence!(User.table_name)
    complete_enrollment(**opt, retry_opt => true)
  end

end

__loading_end(__FILE__)
