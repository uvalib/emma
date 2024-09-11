# app/models/concerns/record/updatable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common methods for ActiveRecord classes that contain columns with values
# constrained to an enumerable list and are intended to be updated dynamically.
#
module Record::Updatable

  extend ActiveSupport::Concern

  include Record

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Class methods automatically added to the including record class.
  #
  module ClassMethods

    include Record::Updatable

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Analogous to the instance methods generated by ActiveRecord::Enum#enum,
    # but for a column whose values are strings not integers.
    #
    # @param [Symbol, String, Hash]      cols
    # @param [Array<Symbol,String>, nil] vals
    #
    # @return [void]
    #
    #--
    # === Variations
    #++
    #
    # @overload enum_methods(columns_and_values)
    #   @param [Hash] columns_and_values
    #
    # @overload enum_methods(column, values)
    #   @param [Symbol, String]       column
    #   @param [Array<Symbol,String>] values
    #
    # === Usage Notes
    # This creates instance methods in the class which calls it.  E.g.:
    #
    #   `enum_methods command: %i[pause cancel]`
    #
    # creates:
    #
    #   * valid_command?(value = nil, **)   Is the value of :command legal?
    #   * command_values(...)               All legal :command values.
    #   * self.command_values(...)          All legal :command values.
    #   * set_command!(value, **)           Set :command to the given value.
    #   * clear_command?(...)               Is :command set to NULL ?
    #   * clear_command!(...)               Set :command to NULL.
    #   * pause?(...)                       Is :command set to :pause ?
    #   * pause!(...)                       Set :command to :pause.
    #   * cancel?(...)                      Is :command set to :cancel ?
    #   * cancel!(...)                      Set :command to :cancel.
    #
    # NOTE: The imperative methods update an entry that exists in the database
    # immediately without needing to use #save.
    #
    # @see #set_fields_direct
    #
    def enum_methods(cols, vals = nil)
      columns_and_values = cols.is_a?(Hash) ? cols : { cols => vals }
      columns_and_values.each_pair do |column, values|
        col_name = column.to_s.upcase
        values   = Array.wrap(values).compact_blank
        raise "#{__method__}: #{column}: no values given" if values.blank?
        values.map!(&:to_s)

        module_eval <<~HEREDOC

          include Record::Updatable::InstanceMethods

          #{col_name}_VALUES = #{values}.map(&:to_sym).freeze

          def valid_#{column}?(value = nil, **)
            value = (value || #{column})&.to_sym
            #{col_name}_VALUES.include?(value)
          end

          def #{column}_values(...)
            #{col_name}_VALUES
          end

          def self.#{column}_values(...)
            #{col_name}_VALUES
          end

          def set_#{column}!(value, **)
            set_fields_direct(#{column}: value).present?
          end

          def clear_#{column}?(...)
            #{column}.blank?
          end

          def clear_#{column}!(...)
            set_#{column}!(nil)
          end

          #{values}.each do |value|
            define_method("\#{value}?") { |*, **| #{column} == value }
            define_method("\#{value}!") { |*, **| set_#{column}!(value) }
          end

        HEREDOC
      end
    end

  end

  # Methods to be added to the including record class.
  #
  module InstanceMethods

    include Record::Updatable

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include ActiveRecord::Core
      include ActiveRecord::AttributeMethods
      # :nocov:
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Get the current value of a database column.
    #
    # @note This does not currently get the "real-time" value.  In the absence
    #   of a strategy for plucking the current column value a reload of the
    #   database record is required first.
    #
    # @param [Symbol, String] column  Database field name.
    #
    # @return [any, nil]
    #
    # @note From Upload::WorkflowMethods#get_field_direct
    #
    def get_field_direct(column)
      if new_record?
        self[column]
      else
        read_attribute(column)
      end
    end

    # Directly update a database column, by-passing validations and other
    # callbacks.
    #
    # @param [String, Symbol] column
    # @param [any, nil]       new_value
    #
    # @raise [ActiveRecord::ReadOnlyRecord]   If the record is not writable.
    #
    # @return [Boolean, nil]            Nil if the record has been deleted.
    #
    # @note From Upload::WorkflowMethods#set_field_direct
    #
    def set_field_direct(column, new_value)
      set_fields_direct(column => new_value)
    end

    # Directly update multiple database columns, by-passing validations and
    # other callbacks.
    #
    # If the record does not yet exist in the database, only the model object
    # is updated.  If the record does exist then it is updated dynamically in
    # the database as well.
    #
    # @param [Hash] pairs
    #
    # @raise [ActiveRecord::ReadOnlyRecord]   If the record is not writable.
    #
    # @return [Boolean, nil]            Nil if the record has been deleted.
    #
    # @note From Upload::WorkflowMethods#set_fields_direct
    #
    def set_fields_direct(pairs)
      # noinspection RailsParamDefResolve
      case
        when readonly?   then send(:_raise_readonly_record_error)
        when destroyed?  then nil
        when new_record? then pairs.each_pair { self[_1] = _2 }.present?
        else                  update_columns(pairs)
      end
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

    include InstanceMethods

  end

end

__loading_end(__FILE__)
