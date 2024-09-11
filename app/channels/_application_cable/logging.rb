# app/channels/_application_cable/logging.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Definitions for ActionCable logging.
#
module ApplicationCable::Logging

  extend ActiveSupport::Concern

  include Emma::Common
  include Emma::Debug
  include Emma::ThreadMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  TAG_LEADER = 'CABLE'

  def cable_tag(arg = nil, tag: nil, tid: nil, **)
    arg ||= self
    name  = arg.is_a?(Class) ? arg : arg.class
    tag ||= ('CLASS' if arg.is_a?(Class))
    # noinspection RailsParamDefResolve
    tag ||= arg.try(:connection_identifier) || arg.try(:stream_id)
    tid ||= thread_name
    "#{TAG_LEADER} #{name} [#{tid}] [#{tag}]"
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Send debugging output to the console.
  #
  # @param [Array<*>] args
  # @param [Hash]     opt
  # @param [Proc]     blk             Passed to #__debug_items
  #
  # @return [nil]
  #
  def __debug_cable(*args, **opt, &blk)
    args.compact!
    case args.first
      when ActionCable::Connection::Base then obj = args.shift
      when ActionCable::Channel::Base    then obj = args.shift
      when Class, /^#{TAG_LEADER} /      then obj = args.shift
      else                                    obj = self
    end
    # noinspection RubyMismatchedArgumentType
    opt[:leader]    = "#{cable_tag(obj)}:" unless opt.key?(:leader)
    opt[:compact]   = true                 unless opt.key?(:compact)
    opt[:separator] = "\n\t"               unless opt.key?(:separator)
    __debug_items(args.join(DEBUG_SEPARATOR), **opt, &blk)
  end
    .tap { neutralize(_1) unless DEBUG_CABLE }

  # Send sent/received WebSocket data to the console.
  #
  # @param [Symbol]   meth
  # @param [any, nil] data
  #
  # @return [nil]
  #
  def __debug_cable_data(meth, data)
    __debug_cable(meth) do
      "#{data.class} = #{data.inspect.truncate(512)}"
    end
  end
    .tap { neutralize(_1) unless DEBUG_CABLE }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module ClassMethods
    include ApplicationCable::Logging
  end

end

__loading_end(__FILE__)
