# app/models/concerns/record/sti.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common methods for ActiveRecord classes that are part of a Single Table
# Inheritance (STI) hierarchy.  ActiveRecord applies STI to classes whose
# database schema contains a :type column.
#
# @!attribute [rw] type
#   Database :type column.
#   @return [String]
#
module Record::Sti

  extend ActiveSupport::Concern

  include Record
  include Record::Identification

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The default name for the column which holds the record type.
  #
  # @type [Symbol]
  #
  TYPE_COLUMN = :type

  # If *true* the :type column will hold the full name of the subclass.
  # If *false* the :type column will hold only the final portion of the name.
  #
  # @type [Boolean]
  #
  FULL_TYPE_NAME = false

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The name of the column which holds the record type.
  #
  # @return [Symbol]
  #
  def type_column
    TYPE_COLUMN
  end

  # The STI variant of the current record.
  #
  # @return [Symbol, nil]
  #
  def type_value
    self[type_column]&.underscore&.to_sym
  end

  # The base variant of the current record.
  #
  # @return [Symbol, nil]
  #
  def base_type_value
    type_value
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the :type column holds the full name of the subclass.
  #
  def full_type_name?
    FULL_TYPE_NAME
  end

  # Indicate whether the current record is associated with a non-leaf class.
  #
  def sti_base?
    # noinspection RubyMismatchedArgumentType
    self.class.send(__method__)
  end

  # Indicate whether the current record is associated with a leaf class.
  #
  def sti_child?
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

    include Record::Sti

    # =========================================================================
    # :section: Record::Sti overrides
    # =========================================================================

    public

    def type_value
      record_name.underscore.to_sym
    end

    def base_type_value
      type_value
    end

    # =========================================================================
    # :section: Record::Sti overrides
    # =========================================================================

    public

    def sti_base?
      false
    end

    def sti_child?
      false
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
  end

end

# To be included in a record class which is a Single Table Inheritance child.
#
module Record::Sti::Leaf

  extend ActiveSupport::Concern

  include Record

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)

    include Record::Sti

    # =========================================================================
    # :section: Record::Sti::ClassMethods overrides
    # =========================================================================

    public

    def self.sti_child?
      true
    end

  end

end

# To be included in a record class which is a parent of a Single Table
# Inheritance child other than the Root.
#
module Record::Sti::Branch

  extend ActiveSupport::Concern

  include Record

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)

    include Record::Sti

  end

end

# To be included in a record class which is a Single Table Inheritance base.
#
# == Implementation Notes
# Using `validates :type, presence: true` allows instances of the base class
# to be created but prevents them from being persisted to the database.
#
module Record::Sti::Root

  include Record

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  extend ActiveSupport::Concern

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)

    include Record::Sti

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include ActiveRecord::Inheritance
      # :nocov:
    end

    # =========================================================================
    # :section:
    # =========================================================================

    raise "#{self}: not STI" unless has_column?(type_column)

    self.store_full_sti_class = full_type_name?

    # =========================================================================
    # :section: ActiveRecord validations
    # =========================================================================

    validates type_column, presence: true

    # =========================================================================
    # :section: Record::Sti::ClassMethods overrides
    # =========================================================================

    public

    def self.sti_base?
      true
    end

    # =========================================================================
    # :section: Class methods
    # =========================================================================

    public

    # Name of the STI child for records of this type.
    #
    # @param [Symbol, String, Class, Record::Sti, nil] t
    # @param [Boolean]                                 no_raise
    #
    # @return [String]
    # @return [nil]                   Only if *no_raise* is set to *true*.
    #
    # @note (record.type == record.class.type) should always be true.
    #
    def self.type(t = nil, no_raise: false)
      t ||= self
      # noinspection RubyNilAnalysis
      if t.is_a?(Symbol) || t.is_a?(String)
        t.to_s
      elsif t.is_a?((base = base_class))
        t[type_column]
      elsif t.is_a?(Class) && (t < base)
        t.record_name
      else
        raise "#{t}: not a subclass of #{base}" unless no_raise
      end
    end

  end

end

__loading_end(__FILE__)
