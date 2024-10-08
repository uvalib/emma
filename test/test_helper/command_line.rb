# test/test_helper/command_line.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support for command-line processing via Rake and the RubyMine IDE.
#
module TestHelper::CommandLine

  extend self

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get command-line argument "TEST_FORMATS=..." or ENV['TEST_FORMATS'].
  #
  # @param [Array<Symbol>] default
  #
  # @return [Array<Symbol>]
  #
  def cli_env_test_formats(default: %i[html])
    cli_env_value(var: 'TEST_FORMATS', default: default)
  end

  # Get a setting from command-line arguments or environment variable.
  #
  # @param [Array, String, Symbol, nil] value
  # @param [String]                     var
  # @param [Array<Symbol>, nil]         default
  #
  # @return [Array<Symbol>, nil]
  #
  def cli_env_value(value = nil, var:, default:)
    val = value || $*.find { _1.dup.sub!(/#{var}=/i, '') } || ENV[var]
    return default unless val
    val = val.to_s.gsub(/\W/, ' ').squish.split(' ') unless val.is_a?(Array)
    val.compact_blank.map! { _1.to_s.downcase.to_sym }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    base.extend(self)
  end

end

__loading_end(__FILE__)
