# app/models/concerns/_model.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common model methods.
#
module Model

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The fields defined by this model.
  #
  # @return [Array<Symbol>]
  #
  def field_names
    instance_variables.map { |v| v.to_s.delete_prefix('@').to_sym }.sort
  end

  # The fields and values for this model instance.
  #
  # @return [Hash{Symbol=>*}]
  #
  def fields
    field_names.map { |field|
      [field, send(field)] rescue nil
    }.compact.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Common storage for configured properties for each model/controller.
  #
  class << self

    # Get configured properties for a model and controller.
    #
    # @param [Symbol, String] type
    #
    # @return [Hash{Symbol=>String,Array,Hash}]
    #
    def configuration(type)
      type = type.to_s
      type = type.sub(/^emma\./, '') if type.start_with?('emma.')
      # configuration_table[type.to_sym] ||= I18n.t("emma.#{type}") # TODO: restore
      # TODO: remove after configuration is transitioned...
      configuration_table[type.to_sym] ||=
        I18n.t("emma.#{type}").deep_dup.tap { |h| invert_field_entries!(h) }
    end

    # Configured properties for each model/controller.
    #
    # @return [Hash{Symbol=>Hash}]
    #
    def configuration_table
      @configuration_table ||= {}
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # invert_field_entries! # TODO: remove when configuration is transitioned...
    #
    # @param [Hash] hash
    #
    # @return [Hash]
    #
    def invert_field_entries!(hash)
      hash[:fields] &&=
        hash[:fields].map { |field, label|
          if label.is_a?(Hash)
            [field, swap_entries(label)]
          else
            swap_entry(field, label)
          end
        }.to_h
      (hash.keys - %i[fields record]).each do |action|
        next unless (entry = hash[action]).is_a?(Hash)
        next unless (fields = entry[:fields]).is_a?(Hash)
        entry[:fields] = swap_entries(fields)
      end
      hash
    end

    # swap_entries # TODO: remove when configuration is transitioned...
    #
    # @param [Hash] hash
    #
    # @return [Hash]
    #
    def swap_entries(hash)
      # @type [String, Symbol] field
      # @type [String, Symbol] label
      hash.map { |field, label| swap_entry(field, label) }.to_h
    end

    # swap_entry # TODO: remove when configuration is transitioned...
    #
    # @param [String, Symbol] field
    # @param [String, Symbol] label
    #
    # @return [Array<(Symbol,Symbol)>]
    #
    def swap_entry(field, label)
      label = label.to_s.split(' ').map(&:camelize).join(' ')
      [label.to_sym, field.to_sym]
    end

  end

end

__loading_end(__FILE__)
