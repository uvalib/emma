# app/helpers/route_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for dynamic references to local URLs.
#
module RouteHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return the appropriate route helper method.
  #
  # @param [Symbol, String]      controller
  # @param [Symbol, String, nil] action
  #
  # @return [Symbol, String, Proc]
  #
  def route_helper(controller, action = nil)
    ctr = controller.to_s.underscore
    ctr = ctr.split('/').map(&:singularize).join('_') if ctr.include?('/')
    ctr = ctr.split('.').map(&:singularize).join('_') if ctr.include?('.')
    act = action&.to_sym
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
  # @param [Array<Symbol,String>] arg     Controller and optional action.
  # @param [Boolean]              warn
  # @param [Hash]                 opt
  #
  # @return [String, nil]
  #
  def get_path_for(*arg, warn: true, **opt)
    ctr, act = arg
    ctr = opt.delete(:controller) || ctr
    act = opt.delete(:action)     || act
    case (path = route_helper(ctr, act))
      when Symbol then result = try(path, **opt) and return result
      when Proc   then result = path.call(**opt) and return result
      else             result = path.presence    and return result
    end
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
