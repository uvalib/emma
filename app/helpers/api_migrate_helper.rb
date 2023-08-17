# app/helpers/api_migrate_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# View helper methods for rendering API data migration results.
#
module ApiMigrateHelper

  include PanelHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render an API data migration report.
  #
  # @param [Hash]    report
  # @param [Integer] level            Heading level (default: 2 [:h2]).
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_api_migration(report, level = 2)
    change_summary =
      html_div(class: 'summary') do
        count = report[:count] || 0
        table = report[:table] || '???'
        "#{count} records in '#{table}' table" # TODO: I18n
      end
    record_changes =
      html_tag(:ul, class: 'record-list') do
        report[:record]&.map { |id, rec| api_record_changes(id, rec, level) }
      end
    change_summary << record_changes
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Render details of the EMMA data migration for a specific database record.
  #
  # @param [Integer] rid              Record number.
  # @param [Hash]    entry            Migration data for this record.
  # @param [Integer] level            Heading level.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def api_record_changes(rid, entry, level)
    html_tag(:li, class: 'record-results', id: rid) do
      heading = "Record #{rid}" # TODO: I18n
      heading = html_tag(level, heading, class: 'record-id')
      changes = api_field_section(rid, entry, :changes, (level + 1))
      results = api_field_section(rid, entry, :results, (level + 1))
      heading << changes << results
    end
  end

  # Render a labelled section for `entry[part]` values.
  #
  # @param [Integer]        rid       Record number.
  # @param [Hash]           entry     Migration data for this record.
  # @param [Symbol, String] part      Section of *entry*.
  # @param [Integer]        level     Heading level.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #api_field_changes
  # @see #api_field_results
  #
  def api_field_section(rid, entry, part, level)
    css   = part.to_s
    id    = unique_id(css, unique: rid)
    label = html_tag(level, css.capitalize, id: id, class: "#{css}-label")
    info  =
      html_div(class: css, 'aria-describedby': id) do
        entry[part.to_sym].presence&.map do |column, field|
          send("api_field_#{part}", column, field, (level + 1))
        end || html_div('NO DATA', class: 'field') # TODO: I18n
      end
    label << info
  end

  # Render changes to EMMA data field contents as a table of fields with before
  # and after values.
  #
  # @param [String, Symbol] column    Database column (e.g. :emma_data).
  # @param [Hash]           fields    Each changed EMMA field and its values.
  # @param [Integer]        level     Heading level.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def api_field_changes(column, fields, level = nil)
    f_css  = 'fields'
    column = html_tag(level, column, class: 'column')
    fields =
      html_div(class: f_css) do
        if fields.present?
          change_table_head +
            fields.flat_map.with_index(1) do |field_values, row|
              change_table_line(*field_values, row: row)
            end
        else
          html_div('NO CHANGES', class: 'field') # TODO: I18n
        end
      end
    # noinspection RubyMismatchedReturnType, RubyMismatchedArgumentType
    column << fields
  end

  # Render the resulting value of a modified EMMA data field as a collapsible
  # panel.
  #
  # @param [String, Symbol] column    Database column (e.g. :emma_data).
  # @param [Hash]           fields    Database column contents.
  # @param [Integer]        level     Heading level.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def api_field_results(column, fields, level = nil)
    f_css = 'fields'
    if fields.present?
      f_id   = unique_id(f_css)
      column = html_span(column) << toggle_button(id: f_id)
      f_opt  = { class: "#{f_css} toggle-panel", id: f_id }
      fields = UploadDecorator.new.render_json_data(fields)
    else
      f_opt  = { class: "#{f_css} empty open" }
      fields = html_div('EMPTY DATABASE COLUMN', class: 'field') # TODO: I18n
    end
    column = html_tag(level, column, class: 'column')
    fields = html_div(fields, f_opt)
    # noinspection RubyMismatchedReturnType, RubyMismatchedArgumentType
    column << fields
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Template for a change table line.
  #
  # @type [Hash]
  #
  ROW_PARTS = { field: 'FIELD', now: 'NOW', was: 'WAS' }.freeze

  # Change table heading row elements.
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def change_table_head
    # noinspection RubyMismatchedArgumentType
    @change_table_head ||=
      ROW_PARTS.map.with_index { |kv, col| change_table_cell(*kv, 0, col) }
  end

  # Change table data row elements.
  #
  # @param [Symbol, String] field     EMMA data field.
  # @param [Hash]           values    Old and new field values.
  # @param [Integer]        row       Table line row number.
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def change_table_line(field, values, row:)
    values = values.transform_values(&:inspect)
    parts  = ROW_PARTS.merge(values, field: field)
    # noinspection RubyMismatchedArgumentType
    parts.map.with_index { |kv, col| change_table_cell(*kv, row, col) }
  end

  # Change table row element.
  #
  # @param [Symbol, String] name      Element CSS class.
  # @param [String]         value     Element content.
  # @param [Integer]        row       Table row number.
  # @param [Integer]        col       Table column number.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def change_table_cell(name, value, row, col)
    html_div(value, class: "row-#{row} col-#{col} #{name}")
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
