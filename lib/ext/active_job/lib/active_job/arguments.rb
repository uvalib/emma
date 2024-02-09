# lib/ext/active_job/lib/active_job/arguments.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# ActiveJob overrides.

__loading_begin(__FILE__)

require 'active_job/arguments'

module ActiveJob

  module ArgumentsExt

    # Non-functional hints for RubyMine type checking.
    unless ONLY_FOR_DOCUMENTATION
      # :nocov:
      include ActiveJob::Arguments
      # :nocov:
    end

    # =========================================================================
    # :section: ActiveJob::Arguments overrides
    # =========================================================================

    private

    # The default implementation makes it impossible to have nested
    # serializable objects because the result of serializing a nested object
    # will be a hash containing an '_aj_serialized' entry, which is flagged as
    # an error.
    #
    # @param [any, nil] key
    #
    # @return [String]
    #
    def serialize_hash_key(key)
      return key      if key.is_a?(String)
      return key.to_s if key.is_a?(Symbol)
      super
    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override ActiveJob::Arguments => ActiveJob::ArgumentsExt

__loading_end(__FILE__)
