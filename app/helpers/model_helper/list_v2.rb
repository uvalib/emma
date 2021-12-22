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

    # noinspection RubyMismatchedArgumentType, RubyMismatchedReturnType
    field_pairs(item, **fp_opt, &block).sort_by { |field_properties|
      field_sort_order_v2(field_properties.first)
    }.map! { |field, prop|
      opt[:row] += 1
      value  = render_value(item, prop[:value], **value_opt)
      levels = field_scopes_v2(field).presence
      rp_opt = levels ? append_classes(opt, levels) : opt
      render_pair(prop[:label], value, prop: prop, **rp_opt)
    }.unshift(nil).join(separator).html_safe
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # field_sort_order
  #
  # @param [Symbol, nil] field
  #
  # @return [Array<Integer, Symbol>]
  #
  def field_sort_order_v2(field)
    pri, sec, rest = search_field_level_v2[field]
    pri = primary_levels_v2.index(pri)   || primary_levels_v2.size
    sec = secondary_levels_v2.index(sec) || secondary_levels_v2.size
    [pri, sec, *rest]
  end

  # Return with the CSS classes associated with the items field scope(s).
  #
  # @param [Array, Symbol, String, nil] value
  #
  # @return [Array<String>]
  #
  #--
  # == Variations
  #++
  #
  # @overload field_scopes_v2(single)
  #   Interpret the argument as a field name used to lookup the scope values.
  #   @param [Symbol, String, nil] single
  #   @return [Array<String>]
  #
  # @overload field_scopes_v2(array)
  #   Extract the scopes from *array*.
  #   @param [Array<Symbol>]       array
  #   @return [Array<String>]
  #
  def field_scopes_v2(value)
    levels = value.is_a?(Array) ? value : search_field_level_v2[value&.to_sym]
    levels = levels&.select { |s| s.is_a?(Symbol) || s.is_a?(String) } || []
    levels.map! { |s| "scope-#{s}" }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  def search_field_level_v2
    @search_field_level_v2 ||=
      Search::Record::TitleRecord.hierarchy_paths(
        field_hierarchy_config_v2
      ).to_h
  end

  def primary_levels_v2
    @primary_levels_v2 ||= field_hierarchy_config_v2.keys
  end

  def secondary_levels_v2
    @secondary_levels_v2 ||= field_hierarchy_config_v2[:files].keys
  end

  def field_hierarchy_config_v2
    # noinspection RailsI18nInspection
    @field_hierarchy_config_v2 ||=
      Search::Record::TitleRecord.symbolize_values(
        I18n.t('emma.search.field_hierarchy_v2')
      )
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
