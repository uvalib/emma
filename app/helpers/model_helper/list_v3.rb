# app/helpers/model_helper/list_v3.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods supporting the display and creation of Model instances
# (both database items and API messages).
#
module ModelHelper::ListV3

  include ModelHelper::List

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render field/value pairs of a title-level record.
  #
  # @param [Search::Record::TitleRecord, Hash, nil] item
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
  #--
  # noinspection RubyNilAnalysis, RubyMismatchedParameterType
  #++
  def render_field_hierarchy(
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

    title_level = file_level = {}
    if pairs.present?
      title_level = pairs.select { |_, v| v.is_a?(Hash) }
      file_level  = pairs.select { |_, v| v.is_a?(Array) }
      pairs = pairs.except(*title_level.keys, *file_level.keys)
      title_level.reverse_merge!(nil => { nil => pairs }) if pairs.present?
    end

    value_opt   = opt.slice(:model, :index, :min_index, :max_index, :no_format)
    fp_opt      = opt.slice(:model).merge!(action: action)

    # Start with the title-level metadata fields common to all file entries.
    lines =
      title_level.flat_map do |group, sub_groups|
        g_prop = { group: group, record: item }
        sub_groups.flat_map do |sub_group, fields|
          field_pairs(item, **fp_opt, pairs: fields).map do |_field, prop|
            prop.merge(g_prop, sub_group: sub_group, row: (opt[:row] += 1))
          end
        end
      end

    # For each file, insert a section divider and the file-level metadata
    # fields for that file.
    lines +=
      file_level.flat_map do |group, entries|
        entry_no = 0
        entries.flat_map do |entry|
          record  = item.records[entry_no]
          index   = [opt[:index], (entry_no += 1)].compact.join('-')
          g_prop  = { group: group, record: record, index: index }
          heading = new_field_section(entry_no, index, opt)
          entry.flat_map { |sub_group, fields|
            field_pairs(record, **fp_opt, pairs: fields).map do |_field, prop|
              prop.merge(g_prop, sub_group: sub_group, row: (opt[:row] += 1))
            end
          }.unshift(heading)
        end
      end

    # Render each metadata field/value pair.
    lines.map { |line|
      if line.is_a?(Hash)
        record, field = line.values_at(:record, :field)
        value  = render_value(record, line[:value], field: field, **value_opt)
        levels = field_scopes(line.values_at(:group, :sub_group))
        rp_opt = opt.merge(line.slice(:index, :row))
        append_classes!(rp_opt, levels) if levels.present?
        render_pair(line[:label], value, prop: line, **rp_opt)
      else
        ERB::Util.h(line)
      end
    }.unshift(nil).join(separator).html_safe
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Probably-temporary divider between metadata for individual files within
  # a compound search item.
  #
  # @param [*]      number            Unique file indicator.
  # @param [*]      index             Unique file indicator.
  # @param [Hash]   opt               Passed to #render_pair.
  # @param [Symbol] field             Pseudo field name.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def new_field_section(number, index, opt, field: :new_file)
    opt[:row] += 1
    opt   = opt.merge(index: index, field: field)
    label = "File #{number}" # TODO: I18n
    value = '&nbsp;'.html_safe
    # noinspection RubyMismatchedReturnType
    render_pair(label, value, **opt)
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
