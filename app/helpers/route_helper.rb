# app/helpers/route_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for dynamic references to local URLs.
#
module RouteHelper

  # @private
  def self.included(base)

    __included(base, 'RouteHelper')

    base.send(:extend, self)

  end

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
    controller = controller&.to_sym
    action     = action&.to_sym
    # noinspection RubyYardReturnMatch
    [action, controller].find { |path| path&.end_with?('_path', '_url') } ||
      case action
        when :index, nil then "#{controller}_index_path".to_sym
        when :show       then "#{controller}_path".to_sym
        else                  "#{action}_#{controller}_path".to_sym
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

end

__loading_end(__FILE__)
