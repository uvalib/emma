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
  # @return [Symbol]
  #
  def route_helper(controller, action = nil)
    ctr  = controller.to_s.underscore
    url  = (ctr.delete_suffix!('_url')  unless action)
    path = (ctr.delete_suffix!('_path') unless action || url)
    ctr  = ctr.split('/').map(&:singularize).join('_') if ctr.include?('/')
    return :"#{ctr}_url"  if url
    return :"#{ctr}_path" if path
    case action&.to_sym
      when nil, :index then :"#{ctr}_index_path"
      when :show       then :"#{ctr}_path"
      else                  :"#{action}_#{ctr}_path"
    end
  end

  # get_path_for
  #
  # @param [Symbol, String]      controller
  # @param [Symbol, String, nil] action
  #
  # @return [String, nil]
  #
  def get_path_for(controller, action = nil, **opt)
    meth = route_helper(controller, action)
    if respond_to?(meth)
      send(meth, **opt)
    else
      Log.warn { "#{__method__}: invalid route helper #{meth.inspect}" }
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.send(:extend, self)
  end

end

__loading_end(__FILE__)
