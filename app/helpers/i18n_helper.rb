# app/helpers/i18n_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting I18n lookup.
#
module I18nHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Parse ERB within the item found at the given config location.
  #
  # @param [String] path
  # @param [Hash]   opt               Passed to I18n#translate.
  #
  # @return [Any]
  #
  def i18n_erb(path, **opt)
    result = I18n.t(path, **opt)
    return result if !result.respond_to?(:empty?) || result.empty?
    erb_interpolate(result, caller_locations&.first)
  end

  # Interpret ERB.
  #
  # @param [Any]                              val
  # @param [Thread::Backtrace::Location, nil] loc
  #
  # @return [Any]
  #
  def erb_interpolate(val, loc = nil)
    case val
      when Hash   then val.transform_values { |v| erb_interpolate(v, loc) }
      when Array  then val.map { |v| erb_interpolate(v, loc) }
      when String then val.include?('<%=') ? erb_process(val, loc) : val
      else             val
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Interpret ERB within a string.
  #
  # @param [String]                           str
  # @param [Thread::Backtrace::Location, nil] loc
  #
  # @return [String]
  #
  def erb_process(str, loc = nil)
    erb = ERB.new(str)
    if loc
      erb.filename = loc.path
      erb.lineno   = loc.lineno
    end
    erb.result
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
