# lib/ext/faraday/lib/faraday/encoders/ia_params_encoder.rb
#
# frozen_string_literal: true
# warn_indent:           true

module Faraday

  # Required in order to pass parameters back to *.us.archive.org in the order
  # in which they were received.
  #
  module IaParamsEncoder

    class << self
      extend Forwardable
      def_delegators :'Faraday::Utils', :escape, :unescape
    end

    extend EncodeMethods
    extend DecodeMethods

    # =========================================================================
    # :section: Faraday::EncodeMethods overrides
    # =========================================================================

    public

    # Same as the overridden method but does not sort.
    #
    # @param params [Hash, Array, #to_hash, nil] Parameters to be encoded
    #
    # @raise [TypeError] If *params* can not be converted to a Hash.
    #
    # @return [String]
    #
    def self.encode(params)
      return if params.nil?

      unless params.is_a?(Array)
        unless params.respond_to?(:to_hash)
          raise TypeError, "Can't convert #{params.class} into Hash."
        end
        params = params.to_hash.map { |key, value| [key.to_s, value] }
      end

      # The params have form [['key1', 'value1'], ['key2', 'value2']].
      params.map { |parent, value|
        encode_pair(escape(parent), value)
      }.join('&').chop
    end

  end

end
