# app/models/app_global.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A singleton object for providing global settings to all workers/threads via
# Rails.cache.
#
class AppGlobal

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The Rails.cache namespace for items managed by this class.
  #
  # @type [Symbol]
  #
  NAMESPACE = ApplicationHelper::APP_CONFIG[:name]&.downcase&.to_sym || :app

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module Methods

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Rails.cache namespace for key/value pairs.
    #
    # @return [Symbol]
    #
    def namespace
      NAMESPACE
    end

    # The value returned if the value was not present.
    #
    # @return [any]
    #
    def default
      nil
    end

    # Get a global value.
    #
    # @param [Hash] opt               Passed to #cache_read.
    #
    # @return [any]
    #
    def get_item(**opt)
      cache_read(**opt) || default
    end

    # Set a global value.
    #
    # @param [any, nil] value         Default: `#default`.
    # @param [Hash]     opt           Passed to #cache_write.
    #
    # @return [any]                   The new current value.
    # @return [nil]                   If the write failed.
    #
    def set_item(value = nil, **opt)
      value ||= default
      cache_write(value, **opt) && value if value
    end

    # Initialize a global value.
    #
    # @param [any, nil] value         Replacement value (if given).
    # @param [Hash]     opt           Passed to #cache_write.
    #
    # @return [any]                   The new current value.
    # @return [nil]                   If the write failed.
    #
    def reset_item(value = nil, **opt)
      set_item(value, **opt).presence
    end

    # Remove a global value.
    #
    # @param [Hash] opt               Passed to #cache_delete.
    #
    # @return [Boolean]
    # @return [nil]                   If the write failed.
    #
    def clear_item(**opt)
      cache_delete(**opt)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # The key defined by the subclass.
    #
    # @return [Symbol, nil]
    #
    def cache_key
    end

    # Get a Rails.cache value.
    #
    # @param [Symbol, String] key
    #
    # @return [any, nil]
    # @return [nil]                   If *key* is missing.
    #
    def cache_read(key: cache_key, **)
      Rails.cache.read(key, namespace: namespace) if validate_key(key)
    end

    # Set a Rails.cache value.
    #
    # @param [any, nil]       value
    # @param [Symbol, String] key
    #
    # @return [Boolean]
    # @return [nil]                   If *key* is missing.
    #
    def cache_write(value, key: cache_key, **)
      Rails.cache.write(key, value, namespace: namespace) if validate_key(key)
    end

    # Remove a Rails.cache value.
    #
    # @param [Symbol, String] key
    #
    # @return [Boolean]
    # @return [nil]                   If *key* is missing.
    #
    def cache_delete(key: cache_key, **)
      Rails.cache.delete(key, namespace: namespace) if validate_key(key)
    end

    # validate_key
    #
    # @param [any, nil] key
    #
    # @raise [RuntimeError]             If key is missing/blank.
    #
    # @return [true]
    #
    def validate_key(key)
      key.present? or raise 'No cache key given'
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    def self.included(base)
      base.extend(self)
    end

  end

  include Methods

end

__loading_end(__FILE__)
