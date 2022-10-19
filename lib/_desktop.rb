# lib/_desktop.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Additions/modifications that will only be defined on the desktop.

# =============================================================================
# Inheritance
# =============================================================================

public

class Object

  # All ancestors which define a given method.
  #
  # @param [Symbol] meth
  #
  # @return [Hash{Symbol=>Array<Module>}]
  #
  def self.ancestors_with(meth)
    { class: [], instance: [] }.tap do |result|
      ancestors.each do |mod|
        result[:class]    << mod if mod.methods(false).include?(meth)
        result[:instance] << mod if mod.instance_methods(false).include?(meth)
      end
    end
  end

  # Display all ancestors which define a given method.
  #
  # @param [Symbol] meth
  #
  # @return [Integer]
  #
  def self.show_ancestors_with(meth)
    lines =
      ancestors_with(meth).flat_map { |type, mods|
        next if mods.empty?
        type = type.to_s
        gap = ' ' * (positive(10 - type.size) || 1)
        mods.map { |mod| "#{type}#{gap}#{mod}" }
      }.compact_blank!
    $stdout.puts(lines.presence&.join("\n") || 'NONE')
    lines.size
  end

end
