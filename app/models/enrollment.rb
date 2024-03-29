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
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Record::Rendering
    extend  Record::Rendering
    # :nocov:
  end

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
    opt.delete(:id) # Just to be safe.
    opt[:updated_at] ||= DateTime.now
    opt[:created_at] ||= opt[:updated_at]

    org = nil
    usr = Array.wrap(self[:org_users]).compact
    Org.transaction do
      org = Org.create(fields.except(:id).merge!(opt))
      User.transaction(requires_new: true) do
        usr.map! { |u| u.merge(opt, org_id: org.id) }
        usr.each { |u| u[:role] ||= 'member' }
        usr.first[:role] = 'manager' if usr.none? { |u| u[:role] == 'manager' }
        usr.map! { |u| User.create(u) }
      end
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
    send(__method__, **opt, retry_opt => true)
  end

end

__loading_end(__FILE__)
