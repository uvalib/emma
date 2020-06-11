# lib/emma/config.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Emma::Config
#
module Emma::Config

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Load a YAML configuration file.
  #
  # @param [String, Pathname] path    Relative or absolute path to the file.
  # @param [Boolean, nil]     erb     If *false* don't attempt ERB translation.
  #
  # @return [Hash{Symbol=>Object}]    Contents of the YAML file.
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
    result

  rescue YAML::SyntaxError => e
    Log.error(e)

  rescue => e # Probable file read error.
    # noinspection RubyYardParamTypeMatch
    Log.error(e, path)
  end

end

__loading_end(__FILE__)
