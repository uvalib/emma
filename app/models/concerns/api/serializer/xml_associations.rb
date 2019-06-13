# app/models/concerns/api/serializer/xml_associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'api/serializer/associations'

# Overrides to the class methods defined in Api::Serializer::Associations for
# XML serializers.
#
module Api::Serializer::XmlAssociations

  extend ActiveSupport::Concern

  # Collections of elements can be handled in one of two ways:
  #
  # 1. WRAP_COLLECTIONS == *true*
  #
  # The collection is contained within a "wrapper" element whose tag is the
  # plural of the element name; e.g., one or more "<copy>" elements wrapped
  # inside a "<copies>" element:
  #
  #   <holding>
  #     <copies>
  #       <copy>...</copy>
  #       <copy>...</copy>
  #       <copy>...</copy>
  #     </copies>
  #   </holding>
  #
  # 2. WRAP_COLLECTIONS == *false*
  #
  # The collection of elements are repeated directly; e.g.:
  #
  #   <holding>
  #     <copy>...</copy>
  #     <copy>...</copy>
  #     <copy>...</copy>
  #   </holding>
  #
  # @type [TrueClass, FalseClass]
  #
  WRAP_COLLECTIONS = false unless defined?(WRAP_COLLECTIONS)

  module ClassMethods

    include Api::Schema

    # =========================================================================
    # :section: Record field schema DSL
    # =========================================================================

    protected

    # XML-specific operations for #attribute data elements.
    #
    # @param [String, Symbol, Class] _element
    # @param [Hash]                  options
    #
    # @return [void]
    #
    # This method replaces:
    # @see Api::Serializer::Associations#prepare_attribute!
    #
    def prepare_attribute!(_element, options)
      if options[:attribute].is_a?(FalseClass)
        options.except!(:attribute)
      elsif !options.key?(:attribute)
        options[:attribute] = true
      end
    end

    # XML-specific operations for #has_many data elements.
    #
    # @param [String, Symbol]        wrapper
    # @param [String, Symbol, Class] element
    # @param [Hash]                  options
    #
    # @option options [TrueClass, FalseClass] :wrap
    #
    # If options[:wrap] is *true* then it will be replaced by the *wrapper*;
    # this forces a specific collection to be wrapped even when
    # #WRAP_COLLECTIONS is *false*.
    #
    # @return [void]
    #
    # This method replaces:
    # @see Api::Serializer::Associations#prepare_collection!
    #
    def prepare_collection!(wrapper, element, options)
      wrap =
        case options[:wrap]
          when false then options.delete(:wrap)
          when true  then true
          when nil   then WRAP_COLLECTIONS
        end
      options[:wrap] = wrapper.to_s.demodulize.downcase if wrap
      options[:as] ||= element.to_s.demodulize.downcase
    end

  end

end

__loading_end(__FILE__)
