# lib/ext/railties/lib/rails/code_statistics.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Add CSS/SCSS to CodeStatistics

__loading_begin(__FILE__)

require 'rails/code_statistics'

module CodeStatisticsExt

  EXTENSIONS  = %w(rb js ts coffee rake css scss sass)
  EXT_PATTERN = '(%s)' % EXTENSIONS.join('|')
  FILE_REGEX  = /^(?!\.).*?\.#{EXT_PATTERN}$/

  def calculate_directory_statistics(directory, pattern = FILE_REGEX)
    super
  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override CodeStatistics => CodeStatisticsExt

__loading_end(__FILE__)
