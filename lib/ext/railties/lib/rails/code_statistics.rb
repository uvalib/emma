# lib/ext/railties/lib/rails/code_statistics.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Add CSS/SCSS to CodeStatistics

__loading_begin(__FILE__)

require 'rails/code_statistics'

module CodeStatisticsExt

  require_relative './code_statistics_calculator'

  EXTENSIONS = CodeStatisticsCalculatorExt::PATTERNS.keys.freeze
  FILE_REGEX = Regexp.new('^(?!\.).*?\.(%s)$' % EXTENSIONS.join('|')).freeze
  NON_CODE   = [
    /^config/i,
    /script/i,
    /stylesheet/i,
    /^test /i,
    /tests?$/i,
    /views?$/i,
  ].deep_freeze

  def calculate_directory_statistics(directory, pattern = FILE_REGEX)
    super
  end

  def calculate_code
    @statistics.sum do |label, stats|
      NON_CODE.any? { label.match?(_1) } ? 0 : stats.code_lines
    end
  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override CodeStatistics => CodeStatisticsExt

__loading_end(__FILE__)
