# app/models/manifest_item.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class ManifestItem < ApplicationRecord

  include Model

  include Record
  include Record::EmmaData
  include Record::FileData
  include Record::Assignable
  include Record::Describable
  include Record::Searchable
  include Record::Sortable
  include Record::Updatable
  include Record::Uploadable
  include Record::Validatable

  include Record::Testing
  include Record::Debugging

  include ManifestItem::Config
  include ManifestItem::Assignable
  include ManifestItem::EmmaData
  include ManifestItem::EmmaIdentification
  include ManifestItem::FieldMethods
  include ManifestItem::FileData
  include ManifestItem::Identification
  include ManifestItem::StatusMethods
  include ManifestItem::Uploadable
  include ManifestItem::Validatable

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    extend Record::Describable::ClassMethods
    # :nocov:
  end

  # ===========================================================================
  # :section: ActiveRecord ModelSchema
  # ===========================================================================

  self.implicit_order_column = :created_at

  # ===========================================================================
  # :section: ActiveRecord associations
  # ===========================================================================

  belongs_to :manifest

  has_one :user, through: :manifest

  has_one :org,  through: :user

  # ===========================================================================
  # :section: ActiveRecord scopes
  #
  # active:       Records not marked for deletion.
  # to_delete:    Records marked for deletion.
  #
  # completed:    Records which have not been changed since the last save.
  # unsaved:      Records which have been changed since the last save.
  # never_saved:  Records which have been created since the last save.
  # incomplete:   New or changed records.
  #
  # saved:        Valid records.
  # pending:      Records with unsaved change(s).
  #
  # data_valid:   Records with sufficient bibliographic and remediation data.
  # file_valid:   Records with resolved file data.
  #
  # could_submit: Records that can appear in "/manifest/remit".
  # submittable:  Records can be submitted en masse without human intervention.
  #
  # ===========================================================================

  scope :active,       -> { where('deleting IS NOT TRUE') }
  scope :to_delete,    -> { where(deleting: true) }

  scope :never_saved,  -> { where(last_saved: nil) }
  scope :unsaved,      -> { where('last_saved < updated_at') }
  scope :completed,    -> { where('last_saved >= updated_at') }
  scope :incomplete,   -> { never_saved.or(unsaved) }

  scope :pending,      -> { active.and(incomplete) }
  scope :saved,        -> { active.and(completed) }

  scope :data_valid,   -> { where(data_status: STATUS_VALID[:data_status]) }
  scope :file_valid,   -> { where(file_status: STATUS_VALID[:file_status]) }

  scope :data_ready,   -> { where(data_status: STATUS_READY[:data_status]) }
  scope :file_ready,   -> { where(file_status: STATUS_READY[:file_status]) }

  scope :could_submit, -> { saved.and(data_valid).and(file_valid) }
  scope :submittable,  -> { saved.and(data_ready).and(file_ready) }

  scope :in_row_order, -> { order(:row, :delta, :id) }

  # ===========================================================================
  # :section: ApplicationRecord overrides
  # ===========================================================================

  public

  # Create a new instance.
  #
  # @param [ManifestItem,Manifest,Hash] attr    To #assign_attributes via super
  #
  def initialize(attr = nil)
    attr = { manifest_id: attr.id } if attr.is_a?(Manifest)
    super
  end

  # The user associated with this record.
  #
  # @return [Integer, nil]
  #
  def user_id = user&.id

  # The organization associated with this record.
  #
  # @return [Integer, nil]
  #
  def org_id = org&.id

  # ===========================================================================
  # :section: IdMethods overrides
  # ===========================================================================

  public

  def uid(item = nil)
    item ? super : user_id
  end

  def oid(item = nil)
    item ? super : org_id
  end

  # Produce a relation for selecting records associated with the given user.
  #
  # @param [*]    user
  # @param [Hash] opt
  #
  # @return [ActiveRecord::Relation]
  #
  def self.for_user(user = nil, **opt)
    user = extract_value!(user, opt, :user, __method__)
    user = uid(user)
    joins(:manifest).where('manifests.user_id = ?', user, **opt)
  end

  # Produce a relation for selecting records associated with the given
  # organization.
  #
  # @param [Org, Hash, Symbol, String, Integer, nil] org
  # @param [Hash]                                    opt
  #
  # @return [ActiveRecord::Relation]
  #
  def self.for_org(org = nil, **opt)
    org = extract_value!(org, opt, :org, __method__)
    org = oid(org)
    joins(:user).where('users.org_id = ?', org, **opt)
  end

  # ===========================================================================
  # :section: Record::Assignable overrides
  # ===========================================================================

  public

  # Override to regenerate the :field_error field if indicated.
  #
  # @param [Model, Hash, ActionController::Parameters, nil] attr
  #
  # @option attr [Boolean] :re_validate
  #
  # @return [void]
  #
  def assign_attributes(attr)
    attr = normalize_attributes(attr)
    opt  = attr[:attr_opt] || {}
    super
    if opt[:re_validate]
      data_columns = fields.except(*NON_BACKUP_COLS)
      data_values  = normalize_attributes(data_columns)
      self.field_error = data_values[:field_error]
      update_status!(**opt.slice(*UPDATE_STATUS_OPTS))
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Mark the record as saved.
  #
  # The value of :updated_at is forced to be the same as :last_saved so that
  # the :unsaved scope can work.
  #
  # @note If this method is invoked on a record marked for deletion, that
  #   probably indicates a error somewhere.
  #
  # @param [DateTime, nil] timestamp  Default: time now.
  # @param [Hash]          opt        Field values to update.
  #
  # @return [self]
  #
  def save_changes!(timestamp = nil, **opt)
    Log.warn { "#{__method__}: marked for deletion: #{inspect}" }   if deleting
    opt[:last_saved] = timestamp        if timestamp
    opt[:last_saved] = DateTime.now     unless opt.key?(:last_saved)
    opt[:updated_at] = opt[:last_saved] unless opt.key?(:updated_at)
    opt[:deleting]   = false            unless opt.key?(:deleting)  if deleting
    opt[:editing]    = false            unless opt.key?(:editing)   if editing
    opt[:backup]     = nil              unless opt.key?(:backup)    if backup
    opt[:attr_opt]   = { re_validate: true }
    update!(opt)
    self
  end

  # Back out of provisional changes.
  #
  # @param [Hash] opt                 Field values to update.
  #
  # @return [self]
  #
  def cancel_changes!(**opt)
    Log.info { "#{__method__}: undeleting: #{inspect}" } if deleting
    opt[:deleting] = false unless opt.key?(:deleting)    if deleting
    opt[:editing]  = false unless opt.key?(:editing)     if editing
    opt[:backup]   = nil   unless opt.key?(:backup)      if backup
    opt = backup.symbolize_keys.merge!(opt)              if backup
    update!(opt)
    self
  end

end

__loading_end(__FILE__)
