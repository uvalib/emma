# lib/ext/active_support/core_ext/string.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class String

  # By-passes the built-in definition to avoid problems encountered during
  # tests under ruby-2.6.3.
  #
  # @param [String] prefix
  #
  # @return [String]
  #
  def delete_prefix(prefix)
    start_with?(prefix) ? self[prefix.size..-1] : self.dup
  end if RUBY_VERSION < '2.7' # TODO: Determine if this is needed for >= 2.7.

  # By-passes the built-in definition to avoid problems encountered during
  # tests under ruby-2.6.3.
  #
  # @param [String] prefix
  #
  # @return [String]
  # @return [nil]
  #
  def delete_prefix!(prefix)
    self.slice!(0..(prefix.size-1)) and self if start_with?(prefix)
  end if RUBY_VERSION < '2.7' # TODO: Determine if this is needed for >= 2.7.

end

__loading_end(__FILE__)
