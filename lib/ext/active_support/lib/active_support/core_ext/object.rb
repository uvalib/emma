# lib/ext/active_support/lib/active_support/core_ext/object.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'active_support/core_ext/object'

module ObjectExt

  include SystemExtension

  # ===========================================================================
  # :section: Instance methods to add to Object
  # ===========================================================================

  public

  # Recursive freezing support.
  #
  # @see Hash#deep_freeze
  #
  def deep_freeze
    freeze
  end

  # Recursive duplication support.
  #
  # @see Hash#rdup
  #
  def rdup
    duplicable? ? dup : self
  end

  # A stand-in for #inspect for more limited output.
  #
  # @param [any, nil] item            Default: `self`.
  # @param [Integer]  max
  #
  # @return [String]
  #
  def summary(item = :self, max: 100)
    item = self if item.is_a?(Symbol) && (item === :self)
    case item
      when ActiveSupport::TimeWithZone then vars = item.to_s
      when ActiveRecord::Relation      then vars = {}
      when Model                       then vars = item.fields
    end
    vars ||= item.instance_variables.presence
    if vars.is_a?(Enumerable)
      h    = vars.is_a?(Hash)
      vars = vars.map { |k| [k, item.instance_variable_get(k)] }.to_h unless h
      vars = vars.map { |k, v| "#{k}: %s" % summary(v, max: max) }
      "#{item.class}<%s>" % vars.join(', ').truncate(max * 3)
    elsif (str = item.inspect).size < max
      str
    elsif item.is_a?(Enumerable)
      "#{item.class}(#{item.size})"
    else
      str.truncate(max, omission: "...#{str.last}")
    end
  end

end

class Object

  # Non-functional hints for RubyMine type checking.
  unless ONLY_FOR_DOCUMENTATION
    # :nocov:
    include ObjectExt
    # :nocov:
  end

  ObjectExt.include_in(self)

end

__loading_end(__FILE__)
