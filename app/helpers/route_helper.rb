# app/helpers/route_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for dynamic references to local URLs.
#
module RouteHelper

  include ParamsHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the appropriate route helper method.
  #
  # @param [Symbol, String]      controller
  # @param [Symbol, String, nil] action
  # @param [Boolean]             base       Strip "_select" from :action.
  #
  # @return [Symbol, String, Proc]
  #
  def route_helper(controller, action = nil, base: false)
    ctr = controller.to_s.underscore
    ctr = ctr.split('/').map(&:singularize).join('_') if ctr.include?('/')
    ctr = ctr.split('.').map(&:singularize).join('_') if ctr.include?('.')
    act = action&.to_sym
    act = base_action(act) if act && base
    if ctr.end_with?('_url', '_path')
      Log.warn("#{__method__}: #{controller}: ignoring action #{act}") if act
      return ctr
    end
    case act
      when :index, nil then :"#{ctr}_index_path"
      when :show       then :"#{ctr}_path"
      else                  :"#{act}_#{ctr}_path"
    end
  end

  # get_path_for
  #
  # @param [Array<Symbol,String,nil>] arg   Controller and optional action.
  # @param [Boolean]                  base  Strip "_select" from :action.
  # @param [Boolean]                  warn
  # @param [Hash]                     opt
  #
  # @return [String, nil]
  #
  def get_path_for(*arg, base: false, warn: true, **opt)
    ctr, act = arg
    ca  = opt.extract!(:controller, :ctrlr, :action)
    ctr = ca[:ctrlr]  || ca[:controller] || ctr
    act = ca[:action] || act
    case (path = route_helper(ctr, act, base: base))
      when Symbol then result = try(path, **opt)
      when Proc   then result = path.call(**opt)
      else             result = path.presence
    end and return result
    Log.warn("#{__method__}: invalid: #{ctr.inspect} #{act.inspect}") if warn
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
