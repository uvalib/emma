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
  include Record::Authorizable
  include Record::Describable
  include Record::Searchable
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
    extend  Record::Describable::ClassMethods
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

  scope :active,       -> { where('NOT deleting IS TRUE') }
  scope :to_delete,    -> { where(deleting: true) }

  scope :completed,    -> { where('last_saved >= updated_at') }
  scope :unsaved,      -> { where('last_saved < updated_at') }
  scope :never_saved,  -> { where(last_saved: nil) }
  scope :incomplete,   -> { unsaved.or(never_saved) }

  scope :saved,        -> { active.and(completed) }
  scope :pending,      -> { active.and(incomplete) }

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
  def initialize(attr = nil, &block)
    __debug_items(binding)
    case attr
      when Manifest     then attr = { manifest_id: attr.id }
      when ManifestItem then attr = attr.fields
      else raise "#{attr.inspect} invalid" if attr && !attr.is_a?(Hash)
    end
    super(attr, &block)
    __debug_items(leader: 'new MANIFEST ITEM') { self }
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
