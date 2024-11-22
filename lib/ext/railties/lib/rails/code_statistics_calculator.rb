# lib/ext/railties/lib/rails/code_statistics_calculator.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Add CSS/SCSS to CodeStatisticsCalculator

__loading_begin(__FILE__)

require 'rails/code_statistics_calculator'

module CodeStatisticsCalculatorExt

  # Replacement for Rails::CodeStatisticsCalculator#PATTERNS to include CSS.
  #
  # @type [Hash{Symbol=>Hash{Symbol=>Regexp}}]
  #
  PATTERNS =
    Rails::CodeStatisticsCalculator::PATTERNS.dup.tap { |pat|
      pat[:yml] = pat[:yaml] = { line_comment: /^\s*#/ }
      pat[:css] = pat[:scss] = pat[:sass] = pat[:js].except(:method)
      pat[:js]  = pat[:js].merge(begin_block_comment: %r{(^|\s+)/\*})
    }.deep_freeze

  # This replacement addresses several issues:
  #
  # * Handles inline block comments for JavaScript.
  #
  # @param [File] io
  # @param [Symbol] file_type
  #
  # @return [void]
  #
  def add_by_io(io, file_type)
    pattern      = PATTERNS[file_type] || {}
    block_begin  = pattern[:begin_block_comment]
    block_end    = pattern[:end_block_comment]
    inline_block = (block_begin != block_end)
    inline_block &&= /#{block_begin}.*?#{block_end}/

    comment_started = false

    while (line = io.gets)
      @lines += 1

      comment_start = block_begin&.match?(line)
      comment_end   = block_end&.match?(line)

      if comment_started && comment_end && inline_block
        comment_started = false
        line.sub!(inline_block, '')
      elsif comment_started && comment_end
        comment_started = false
        next
      elsif comment_started
        # Ignore lines inside a block comment.
        next
      elsif comment_start && comment_end && inline_block
        # Delete commented-out portion of the line.
        line.gsub!(inline_block, '')
      elsif comment_start && inline_block
        comment_started = true
        line.sub!(/#{block_begin}.*$/, '')
      elsif comment_start
        comment_started = true
        next
      end

      next if line.match?(/^\s*$/)
      next if pattern[:line_comment]&.match?(line)

      @classes    += 1 if pattern[:class]&.match?(line)
      @methods    += 1 if pattern[:method]&.match?(line)
      @code_lines += 1
    end
  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Rails::CodeStatisticsCalculator => CodeStatisticsCalculatorExt

__loading_end(__FILE__)
