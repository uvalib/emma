# lib/emma/config.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'yaml'

# Emma::Config
#
module Emma::Config

  include Emma::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Load a YAML configuration file.
  #
  # @param [String, Pathname] path    Relative or absolute path to the file.
  # @param [Boolean, nil]     erb     If *false* don't attempt ERB translation.
  #
  # @return [Hash{Symbol=>Any}]       Contents of the YAML file.
  # @return [nil]                     If there was a problem.
  #
  def self.load(path, erb = true)
    original_path = path
    path = Pathname.new(path)    unless path.is_a?(Pathname)
    path = Rails.root.join(path) unless path.to_s.start_with?('/')
    text = File.read(path.to_s)
    text = ERB.new(text).result if erb
    result = YAML.load(text, original_path)
    result.deep_symbolize_keys! if result.is_a?(Hash)
    # noinspection RubyMismatchedReturnType
    result

  rescue YAML::SyntaxError => error
    Log.error(error)

  rescue => error # Probable file read error.
    # noinspection RubyMismatchedArgumentType
    Log.error(error, path)
    re_raise_if_internal_exception(error)
  end

end

__loading_end(__FILE__)
