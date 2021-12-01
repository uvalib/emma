# app/helpers/model_helper/list_v2.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting the display and creation of Model instances
# (both database items and API messages).
#
module ModelHelper::ListV2

  include ModelHelper::List

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @private
  SEARCH_FIELD_LEVEL =
    Search::Record::TitleRecord::FIELD_HIERARCHY.flat_map { |primary, section|
      next if primary.start_with?('_') || !section.is_a?(Hash)
      section.flat_map do |secondary, fields|
        next if secondary.start_with?('_') || !fields.is_a?(Array)
        fields.each_with_index.map do |field, position|
          [field, [primary, secondary, position]]
        end
      end
    }.compact.to_h.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render grouped field/value pairs.
  #
  # @param [Model, Hash, nil]    item
  # @param [String, Symbol, nil] model        Default: `params[:controller]`.
  # @param [String, Symbol, nil] action       Default: `params[:action]`.
  # @param [Hash, nil]           pairs        Except for #render_pair options.
  # @param [Integer, nil]        row_offset   Def: 0.
  # @param [String, nil]         separator    Def: #DEFAULT_ELEMENT_SEPARATOR.
  # @param [Hash]                opt
  # @param [Proc]                block        Passed to #field_pairs.
  #
  # @option opt [Integer] :index              Offset to make unique element IDs
  #                                             passed to #render_pair.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_grouped_fields(
    item,
    model:      nil,
    action:     nil,
    pairs:      nil,
    row_offset: nil,
    separator:  DEFAULT_ELEMENT_SEPARATOR,
    **opt,
    &block
  )
    return ''.html_safe unless item

    opt[:row]   = row_offset || 0
    opt[:model] = Model.for(model || item) || params[:controller]&.to_sym

    value_opt = opt.slice(:model, :index, :min_index, :max_index, :no_format)
    fp_opt    = opt.slice(:model).merge!(action: action, pairs: pairs)

    field_pairs(item, **fp_opt, &block).sort_by { |field_properties|
      # noinspection RubyMismatchedParameterType
      field_sort_order(field_properties.first)
    }.map! { |field, prop|
      opt[:row] += 1
      value  = render_value(item, prop[:value], **value_opt)
      levels = field_scopes(field).presence
      rp_opt = levels ? append_classes(opt, levels) : opt
      render_pair(prop[:label], value, prop: prop, **rp_opt)
    }.unshift(nil).join(separator).html_safe
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # @private
  PRIMARY_LEVELS =
    Search::Record::TitleRecord::FIELD_HIERARCHY.keys.freeze

  # @private
  SECONDARY_LEVELS =
    Search::Record::TitleRecord::FIELD_HIERARCHY[:file].keys.freeze

  # field_sort_order
  #
  # @param [Symbol, nil] field
  #
  # @return [Array<Integer, Symbol>]
  #
  def field_sort_order(field)
    pri, sec, rest = SEARCH_FIELD_LEVEL[field]
    pri = PRIMARY_LEVELS.index(pri)   || PRIMARY_LEVELS.size
    sec = SECONDARY_LEVELS.index(sec) || SECONDARY_LEVELS.size
    [pri, sec, *rest]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return with the CSS classes associated with the items field scope(s).
  #
  # @param [ Array, Symbol,nil] value
  #
  # @return [Array<String>]
  #
  def field_scopes(value)
    #ModelHelper::ListV2.field_scopes(value)
    levels = value.is_a?(Array) ? value : SEARCH_FIELD_LEVEL[value&.to_sym]
    levels = levels&.select { |s| s.is_a?(Symbol) || s.is_a?(String) } || []
    levels.map! { |s| "scope-#{s}" }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

=begin
  # Return with the CSS classes associated with the items field scope(s).
  #
  # @param [ Array, Symbol,nil] value
  #
  # @return [Array<String>]
  #
  def self.field_scopes(value)
    levels = value.is_a?(Array) ? value : SEARCH_FIELD_LEVEL[value&.to_sym]
    levels = levels&.select { |s| s.is_a?(Symbol) || s.is_a?(String) } || []
    levels.map! { |s| "scope-#{s}" }
  end
=end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
