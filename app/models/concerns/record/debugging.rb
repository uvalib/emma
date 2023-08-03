# app/models/concerns/record/debugging.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Add debugging support.
#
# === Usage Notes
# Must be included last so that #initialize can be overridden.
#
module Record::Debugging

  extend ActiveSupport::Concern

  if DEBUG_RECORD

    include Emma::Debug

    include Record

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include Kernel
      # :nocov:
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Show instance output.
    #
    # @param [Array<*>] parts
    # @param [Hash]     opt           Passed to ShowMethods#output.
    #
    def show(*parts, **opt)
      opt[:tag] ||= "#{self.class.name}[#{id}]"
      output(':', **opt) { self }
      parts.each do |part|
        output(part, ':', **opt) { eval("#{part}") }
      end
      nil
    end

    # Console output.
    #
    # @param [Array<*>]    parts
    # @param [String, nil] tag
    # @param [String, nil] ldr
    # @param [Integer]     width
    #
    # @return [nil]
    #
    def output(*parts, tag: nil, ldr: '***', width: 72, **)
      line = [ldr, tag, *parts].compact.join(' ').strip
      trailer = '*' * (width - line.size - 1)
      __output "#{line} #{trailer}"
      pp yield if block_given?
      nil
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    def __debug_step(*args, **opt, &block)
      __output "\n\n###################################################"
      __debug_items(*args, **opt, &block)
    end

  else

    neutralize(:show)
    neutralize(:output)
    neutralize(:__debug_step)

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Class methods automatically added to the including record class.
  #
  module ClassMethods

    include Record::Debugging

    if DEBUG_RECORD

      # Non-functional hints for RubyMine type checking.
      unless ONLY_FOR_DOCUMENTATION
        # :nocov:
        include ActiveRecord::Scoping::Named::ClassMethods
        # :nocov:
      end

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # Show class output.
      #
      # @param [Array<*>] parts
      # @param [Hash]     opt         Passed to ShowMethods#output.
      #
      # @return [nil]
      #
      def show(*parts, **opt)
        opt[:tag] ||= "#{name} |"
        all_label = "all = #{all.count}"
        output(all_label, **opt)
        pp all
        output(all_label, **opt)
        parts.each do |part|
          count = eval("#{part}.count rescue 0")
          output("#{part} = #{count}", **opt)
        end
        nil
      end

    end

  end

  # Methods which are only appropriate if the including class is an
  # ApplicationRecord.
  #
  module InstanceMethods

    include Record::Debugging

    if DEBUG_RECORD

      # Non-functional hints for RubyMine type checking.
      unless ONLY_FOR_DOCUMENTATION
        # :nocov:
        include ActiveRecord::Core
        # :nocov:
      end

      # =======================================================================
      # :section: ActiveRecord overrides
      # =======================================================================

      public

      # Create a new instance.
      #
      # @param [Model, Hash, nil] attr
      #
      def initialize(attr = nil, &block)
        ldr = "new #{self.class.base_class.name.underscore.upcase} RECORD"
        __debug_items(binding, leader: ldr)
        super(attr, &block)
        __debug_items(self.class.name, self, leader: ldr)
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
