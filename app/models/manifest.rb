# app/models/manifest.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class Manifest < ApplicationRecord

  include Model

  include Record
  include Record::Assignable
  include Record::Authorizable
  include Record::Describable
  include Record::Searchable

  include Record::Testing
  include Record::Debugging

  include Manifest::Config
  include Manifest::EmmaIdentification
  include Manifest::ItemMethods
  include Manifest::Searchable

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

  belongs_to :user, optional: true

  has_many :manifest_items, -> { in_row_order }, dependent: :destroy

  scope :for_user, ->(user) { where(user: user) }

  # ===========================================================================
  # :section: ApplicationRecord overrides
  # ===========================================================================

  public

  def user_id = user&.id

  # A textual label for the record instance.
  #
  # @param [Manifest, nil] item       Default: self.
  #
  # @return [String, nil]
  #
  def label(item = nil)
    (item || self).name.presence
  end

  # Create a new instance.
  #
  # @param [Manifest, Hash, nil] attr   Passed to #assign_attributes via super.
  #
  # @note - for dev traceability
  #
  def initialize(attr = nil, &block)
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Mark associated ManifestItem records as saved while renumbering their rows.
  #
  # @param [DateTime, nil] timestamp  Default: time now.
  # @param [Hash]          attr       Manifest field values to update.
  #
  # @return [self]
  #
  def save_changes!(timestamp = nil, **attr)
    timestamp ||= DateTime.now
    manifest_items.to_delete.destroy_all
    manifest_items.each.with_index(1) do |record, row|
      record.save_changes!(timestamp, row: row, delta: 0)
    end
    update!(attr)
    self
  end

  # Back out of provisional ManifestItem changes.
  #
  # If the Manifest has no items then it is destroyed (the assumption being
  # that this was a new Manifest that has been abandoned).
  #
  # @param [Hash] attr                Manifest field values to update.
  #
  # @return [self]
  #
  # === Implementation Notes
  # Items which were added and then deleted since the last save are in the
  # :never_saved scope but *not* the :incomplete scope.
  #
  def cancel_changes!(**attr)
    manifest_items.never_saved.destroy_all
    if manifest_items.empty?
      destroy!
    else
      manifest_items.each(&:cancel_changes!)
      update!(attr) if attr.present?
    end
    self
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  # Generate a default Manifest title name.
  #
  # @return [String]
  #
  def self.default_name
    DateTime.now.strftime('Started %B %d, %Y at %l:%M %P').squish # TODO: I18n
  end

end

__loading_end(__FILE__)
