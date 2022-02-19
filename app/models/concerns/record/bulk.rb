# app/models/concerns/record/bulk.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

#require_relative 'sti' # NOTE: commented-out

# Methods for ActiveRecord that involve bulk operations.
#
module Record::Bulk

  extend ActiveSupport::Concern

  include Emma::Common

  include Record

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include Model
    include Record::Sti
    # :nocov:
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Fallback URL base. TODO: ?                                                  # NOTE: from Upload::BulkMethods
  #
  # @type [String]
  #
  BULK_BASE_URL = PRODUCTION_BASE_URL

  # Default user for bulk uploads. # TODO: ?                                    # NOTE: from Upload::BulkMethods
  #
  # @type [String]
  #
  BULK_USER = 'emmadso@bookshare.org'

  # Fields that used within the instance but are not persisted to the database. # NOTE: from Upload::BulkMethods
  #
  # @type [Array<Symbol>]
  #
  LOCAL_FIELDS = [
    :file_path,     # IA Bulk # TODO: remove after upload -> entry (?)
    :manifest_path  # NOTE: new native bulk upload (?)
  ]

  # Fields that are expected to be included in :emma_data.                      # NOTE: from Upload::BulkMethods
  #
  # @type [Array<Symbol>]
  #
  INDEX_FIELDS = Search::Record::MetadataRecord.field_names.freeze

  # The default name for the column which holds the record type.
  #
  # @type [Symbol]
  #
  TYPE_COLUMN = Record::Sti::TYPE_COLUMN

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the current record is not involved in bulk operations.
  #
  def single?
    !bulk?
  end

  # Indicate whether the current record is involved in bulk operations.
  #
  def bulk?
    false
  end

  # The bulk operation of the current record ('Create', 'Edit', 'Remove').
  #
  # @return [String, nil]
  #
  def bulk_type
  end

  # Name of the class referenced by the :bulk relation.
  #
  # @return [String]
  #
  def bulk_operation_class
    # noinspection RubyMismatchedArgumentType
    self.class.send(__method__)
  end

  # Name of the class referenced by the :parts relation.
  #
  # @return [String]
  #
  def bulk_part_class
    # noinspection RubyMismatchedArgumentType
    self.class.send(__method__)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Use the importer module to translate imported fields into Entry columns
  # and/or EMMA metadata fields.
  #
  # @param [Hash]           fields
  # @param [Module, String] importer_name
  #
  # @return [Hash]
  #
  def import_transform(fields, importer_name)                                   # NOTE: from Upload::BulkMethods
    importer = Import.get_importer(importer_name)
    Log.error { "#{__method__}: #{importer_name}: invalid" } if importer.blank?
    return fields if fields.blank? || importer.blank?

    known_names = field_names + INDEX_FIELDS + LOCAL_FIELDS
    known_fields, added_fields = partition_hash(fields, *known_names)
      .tap { |k, a| __debug_items { { known_fields: k, added_fields: a } } } # TODO: remove - debugging
    importer.translate_fields(added_fields).merge!(known_fields)
      .tap { |f| __debug_items { { fields: f } } } # TODO: remove - debugging
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Class methods automatically added to the including record class.
  #
  module ClassMethods

    include Record::Bulk

    # =========================================================================
    # :section: Record::Bulk overrides
    # =========================================================================

    public

    # Name of the class referenced by the :bulk relation.
    #
    # @return [String]
    #
    def bulk_operation_class
      "#{base_class}::BulkOperation"
    end

    # Name of the class referenced by the :parts relation.
    #
    # @return [String]
    #
    def bulk_part_class
      "#{base_class}::BulkPart"
    end

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

# Definitions to be included in a record class which can be a part of a bulk
# operation.
#
# @!attribute [rw] :bulk_id
#   The bulk workflow phase of which is record is a part.
#   (NULL indicates a single-workflow record.)
#
module Record::Bulk::Part

  extend ActiveSupport::Concern

  include Record
  include Record::Bulk
  include Record::Identification

  # ===========================================================================
  # :section: Record::Bulk overrides
  # ===========================================================================

  public

  def bulk?
    bulk.present?
  end

  def bulk_type
    self[type_column]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Class methods automatically added to the including record class.
  #
  module ClassMethods

    include Record::Bulk::ClassMethods

    # =========================================================================
    # :section: Record::Bulk::ClassMethods overrides
    # =========================================================================

    public

    def bulk_type
      record_name
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)

    include Record::Sti::Branch

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include ActiveRecord::Associations::ClassMethods
      # :nocov:
    end

    # =========================================================================
    # :section: ActiveRecord associations
    # =========================================================================

    belongs_to :bulk, class_name: bulk_operation_class, optional: true

  end

end

# Definitions to be included in a record class which represents a bulk
# operation.
#
module Record::Bulk::Operation

  extend ActiveSupport::Concern

  include Record
  include Record::Bulk
  include Record::Identification

  # ===========================================================================
  # :section: Record::Bulk overrides
  # ===========================================================================

  public

  def bulk?
    true
  end

  def bulk_type
    # noinspection RubyMismatchedArgumentType
    self.class.send(__method__)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Class methods automatically added to the including record class.
  #
  module ClassMethods

    include Record::Bulk::ClassMethods

    # =========================================================================
    # :section: Record::Bulk::ClassMethods overrides
    # =========================================================================

    public

    def bulk?
      true
    end

    def bulk_type
      record_name.remove('Bulk')
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  # noinspection RailsParamDefResolve
  included do |base|

    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)

    include Record::Sti::Branch

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include ActiveRecord::Associations::ClassMethods
      # :nocov:
    end

    # =========================================================================
    # :section: ActiveRecord associations
    # =========================================================================

    has_many :parts, class_name: bulk_part_class, foreign_key: :bulk_id
    has_many :part_actions, through: :parts, source: :actions

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Source of the bulk upload manifest.                                       # NOTE: from Upload::BulkMethods#file_path
    #
    # @return [String, nil]
    #
    attr_reader :manifest_path

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether all of the parts of the bulk operation are done.
    #
    def parts_completed?
      parts.all?(&:final_state?)
    end

    # Indicate whether all of the actions associated with the bulk operation
    # have succeeded.
    #
    def actions_succeeded?
      part_actions.all?(&:succeeded?)
    end

  end

end

# Definitions to be included in the base record class for bulk parts or bulk
# operations.
#
module Record::Bulk::Root

  extend ActiveSupport::Concern

  include Record
  include Record::Bulk

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
