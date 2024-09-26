# lib/_system.rb
#
# frozen_string_literal: true
# warn_indent:           true

require '_trace'

__loading_begin(__FILE__)

# =============================================================================
# System extension support
# =============================================================================

# Included in modules which extend/override system definitions.
#
module SystemExtension

  # This method checks that the methods defined in *ext* are not already
  # defined in *mod*.
  #
  # If there is ever a time when Rails or the standard Ruby library defines
  # one of these extension methods, any current uses of the method needs to be
  # evaluated and the local definition should be removed.
  #
  # @param [Module]  mod            The module or class that is being extended.
  # @param [Module]  ext            The module with new or override methods.
  # @param [Array]   except         The names of overridden methods.
  # @param [Boolean] fatal          If *false* then just log errors.
  # @param [Symbol]  ref            Defined in './at_start.rb'
  #
  def check_extension(mod, ext, except: [], fatal: true, ref: :NATIVE_METHODS)
    return if mod.included_modules.include?(ext)
    native = nil
    if !const_defined?(ref)
      __output("WARNING: #{ref} not defined")
    elsif !(native = const_get(ref))
      __output("WARNING: #{ref} is nil")
    elsif !(native = native[mod])
      __output("WARNING: #{ref} does not contain #{mod}")
    end
    native ||= (mod.methods + mod.instance_methods).sort.uniq
    added    = ext.instance_methods.excluding(*except)
    errors   = added.intersection(native).presence or return
    errors   = "#{mod} already defines %s" % errors.join(', ')
    fatal ? fail(errors) : __output("ERROR: #{errors}")
  end

  # Inject extension methods into *mod*.
  #
  # @param [Module] mod
  # @param [Module] ext               Default: the including module.
  #
  # @return [Module]                  The *ext* module.
  #
  def include_in(mod, ext = nil)
    ext ||= self
    check_extension(mod, ext) if sanity_check?
    mod.include(ext)
  end

  # Inject extension methods into *mod*.
  #
  # @param [Module] mod
  # @param [Module] ext               Default: the including module.
  #
  # @return [Module]                  The *ext* module.
  #
  def include_and_extend(mod, ext = nil)
    ext ||= self
    check_extension(mod, ext) if sanity_check?
    mod.include(ext)
    mod.extend(ext)
  end

  # ===========================================================================
  # :section: Module methods
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

__loading_end(__FILE__)
