# lib/ext/sprockets/lib/sprockets/_debug.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Debugging for Sprockets gem extensions.

__loading_begin(__FILE__)

require 'sprockets'

module Sprockets

  module ExtensionDebugging

    if DEBUG_SPROCKETS
      include Emma::Extension::Debugging
    else
      include Emma::Extension::NoDebugging
    end

    # =========================================================================
    # :section: Emma::Extension::Debugging overrides
    # =========================================================================

    public

    def __ext_log_leader
      super('SPROCKETS')
    end

  end

end

if DEBUG_SPROCKETS

  # TODO: Work into Emma::Extension::Debugging
  class DebugTiming

    extend Emma::TimeMethods

    def self.start
      @start ||= 0.0
    end

    def self.now
      timestamp.tap { |t| @start ||= t }
    end

    def self.offset(time = nil)
      time ||= now
      time_span(start, time)
    end

    def self.duration(start_time = nil, end_time = nil)
      start_time ||= start
      end_time   ||= now
      time_span(start_time, end_time)
    end

    def self.level
      @level ||= 0
    end

    def self.push_level
      @level = level + 1
    end

    def self.pop_level
      @level = level.positive? ? (level - 1) : 0
    end

    def self.thread_name
      Thread.current.name || Thread.current.to_s
    end

    def self.indent(depth = level)
      '   ' * depth
    end

    def self.aggregate?(processor)
      return false if processor.blank? || processor.is_a?(String)
      [
        :load_from_unloaded,
        Sprockets::Bundle,
        Sprockets::ProcessorUtils::CompositeProcessor
      ].any? do |c|
        (processor == c) ||
          (c.is_a?(Class) && processor.is_a?(c)) ||
          processor.to_s.include?(c.to_s)
      end
    end

    def self.enter(processor, input, time = nil)
      time ||= now
      stamp  = '%-15s' % offset(time)
      delta  = '%-15s' % ''

      tid    = thread_name
      file   = input[:filename]
      name   = processor.inspect.truncate(256)
      label  = ["SPROCKETS #{tid} [#{level}] #{indent}#{file}", name]
      label += Array.wrap(yield) if block_given?
      label  = label.join(' | ')

      pushed = (push_level if aggregate?(processor))

      $stderr.puts ">>> #{stamp} #{delta} #{label}"
      $stderr.puts if pushed
      time
    end

    def self.leave(processor, input, start, time = nil)
      time ||= now
      stamp  = '%-15s' % offset(time)
      delta  = '%-15s' % duration(start, time)

      # noinspection RubyUnusedLocalVariable
      popped = (pop_level if aggregate?(processor))

      tid    = thread_name
      file   = input[:filename]
      name   = processor.inspect.truncate(256)
      label  = ["SPROCKETS #{tid} [#{level}] #{indent}#{file}", name]
      label += Array.wrap(yield) if block_given?
      label  = label.join(' | ')

      $stderr.puts "<<< #{stamp} #{delta} #{label}"
      $stderr.puts
      time
    end

  end

end

__loading_end(__FILE__)
