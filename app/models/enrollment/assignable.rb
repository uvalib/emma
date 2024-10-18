# app/models/enrollment/assignable.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Enrollment::Assignable

  include Emma::Json

  # Non-functional hints for RubyMine type checking.
  # :nocov:
  unless ONLY_FOR_DOCUMENTATION
    include Record::Assignable
  end
  # :nocov:

  # ===========================================================================
  # :section: Record::Assignable overrides
  # ===========================================================================

  public

  # Ensure that blanks are allowed and that input values are normalized.
  #
  # @param [Model, Hash, ActionController::Parameters, nil] attr
  # @param [Hash]                                           opt
  #
  # @return [Hash]
  #
  def normalize_attributes(attr, **opt)
    opt.reverse_merge!(key_norm: true, compact: false)
    super
  end

  # Normalize a specific field value.
  #
  # @param [Symbol]        key
  # @param [any, nil]      value
  # @param [String, Class] type
  # @param [Hash, nil]     errors
  #
  # @return [any, nil]
  #
  def normalize_field(key, value, type, errors = nil)
    case key
      when :org_users     then value = normalize_users(value)
      when :admin_notes   then value = normalize_notes(value)
      when :request_notes then value = normalize_notes(value)
    end
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Normalize a value for the :org_users attribute.
  #
  # @param [String, Array, Hash, nil] arg
  # @param [Hash]                     opt   To #json_parse.
  #
  # @return [Array<Hash>]
  #
  def normalize_users(arg, **opt)
    return [] if arg.nil?
    return arg.flat_map { normalize_users(_1, **opt) } if arg.is_a?(Array)
    arg = json_parse(arg, **opt) || arg
    if arg.is_a?(String)
      case arg
        when /\n/ then arg = arg.split("\n")
        when /;/  then arg = arg.split(';')
        else           arg = [arg]
      end
      arg.map! do |v|
        e = l = f = nil
        case (v = v.squish.presence)
          when nil  then next
          when /@/  then e = v
          when /, / then l, f = v.split(', ', 2)
          when / /  then v.split(' ').tap { |n| l, f = n.pop, n.join(' ') }
          else           l = v
        end
        { email: e, last_name: l, first_name: f }.compact
      end
    elsif arg.is_a?(Hash)
      arg = arg.transform_values { _1.is_a?(String) ? _1.squish : _1 }
    elsif !arg.is_a?(Array)
      Log.warn { "#{__method__}: bad: #{arg.inspect}" }
    end
    Array.wrap(arg).compact_blank
  end

  # Normalize a value for the :request_notes or :admin_notes attributes.
  #
  # @param [String, Array, nil] arg
  #
  # @return [String, nil]
  #
  def normalize_notes(arg)
    case arg
      when String then arg = arg.strip.split("\n")
      when Array  then arg = arg.compact
      when nil    then return
      else             return Log.warn { "#{__method__}: bad: #{arg.inspect}" }
    end
    arg.map!(&:squish).compact_blank.presence&.join("\n")
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

__loading_end(__FILE__)
