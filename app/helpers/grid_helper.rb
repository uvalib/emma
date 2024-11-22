# app/helpers/grid_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module GridHelper

  include HtmlHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Options consumed by internal methods which should not be passed on along to
  # the methods which generate HTML elements.
  #
  # @type [Array<Symbol>]
  #
  # @see #grid_cell_classes
  #
  GRID_OPT = %i[row col row_max col_max].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render a table of values.
  #
  # @param [Hash] pairs               Key-value pairs to display.
  # @param [Hash] opt                 Passed to outer #html_div except for:
  #                                     #GRID_OPT and :wrap to #grid_table_row
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def grid_table(pairs, **opt)
    opt[:col]     ||= 1
    opt[:row]     ||= 1
    opt[:col_max] ||= 2
    opt[:row_max] ||= pairs.size / opt[:col_max]
    outer_opt = opt.slice!(:wrap, :sr_only, *GRID_OPT)
    html_div(**outer_opt) do
      pairs.map do |key, value|
        grid_table_row(key, value, **opt).tap do
          if (opt[:col] % opt[:col_max]).zero?
            opt[:col] = 1
            opt[:row] += 1
          else
            opt[:col] += 1
          end
        end
      end
    end
  end

  # Render a key/value row.
  #
  # @param [any, nil] key
  # @param [any, nil] value
  # @param [Boolean]  wrap            If *true* then key/value pairs are joined
  #                                     within a wrapper element.
  # @param [Hash]     opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def grid_table_row(key, value, wrap: false, **opt)
    col = positive(opt[:col]) || 1
    key = opt[:'data-key'] = key.to_s
    unless key.is_a?(ActiveSupport::SafeBuffer)
      k_opt = opt.dup
      unless wrap
        k_opt[:col]   = col
        k_opt[:class] = grid_cell_classes('key', **k_opt)
      end
      k_opt.except!(*GRID_OPT)
      key = ERB::Util.h("#{key}:") if wrap && key.present?
      key = html_div(key, **k_opt)
    end
    unless value.is_a?(ActiveSupport::SafeBuffer)
      v_opt = opt.dup
      unless wrap
        v_opt[:col]   = col.succ
        v_opt[:class] = grid_cell_classes('value', **v_opt)
      end
      v_opt.except!(*GRID_OPT)
      value = html_div(value, **v_opt)
    end
    if wrap
      opt[:col]   = col
      opt[:class] = grid_cell_classes('entry', **opt)
      opt.except!(*GRID_OPT)
      html_div(**opt) { key << HTML_SPACE << value }
    else
      key << value
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Array<#to_s,Array>] classes
  # @param [Hash]               opt       Internal options:
  #
  # @option opt [String]  :class
  # @option opt [Integer] :row        Grid row (wide screen).
  # @option opt [Integer] :col        Grid column (wide screen).
  # @option opt [Integer] :row_max    Bottom grid row (wide screen).
  # @option opt [Integer] :col_max    Rightmost grid column (wide screen).
  # @option opt [Boolean] :sr_only    If *true*, include 'sr-only' CSS class.
  #
  # @return [Array<String>]
  #
  def grid_cell_classes(*classes, **opt)
    row = positive(opt[:row])
    col = positive(opt[:col])
    classes.concat(Array.wrap(opt[:class])) if opt[:class]
    classes << "row-#{row}" if row
    classes << "col-#{col}" if col
    classes << 'row-first'  if row == 1
    classes << 'col-first'  if col == 1
    classes << 'row-last'   if row == opt[:row_max].to_i
    classes << 'col-last'   if col == opt[:col_max].to_i
    classes << 'sr-only'    if opt[:sr_only]
    css_class_array(*classes)
  end

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   Additional CSS classes.
  # @param [Hash]               opt       To #append_grid_cell_classes!
  #
  # @return [Hash]                        A new hash.
  #
  # @note Currently unused.
  # :nocov:
  def append_grid_cell_classes(html_opt, *classes, **opt)
    unless html_opt
      Log.debug { "#{__method__}: nil html_opt from #{calling_method}" }
    end
    html_opt = html_opt&.deep_dup || {}
    append_grid_cell_classes!(html_opt, *classes, **opt)
  end
  # :nocov:

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   Additional CSS classes.
  # @param [Hash]               opt       Passed to #grid_cell_classes.
  #
  # @return [Hash]                        The modified *html_opt* hash.
  #
  def append_grid_cell_classes!(html_opt, *classes, **opt)
    classes = grid_cell_classes(*classes, **opt)
    append_css!(html_opt, *classes)
  end

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   Additional CSS classes.
  # @param [Hash]               opt       To #prepend_grid_cell_classes!.
  #
  # @return [Hash]                        A new hash.
  #
  # @note Currently unused.
  # :nocov:
  def prepend_grid_cell_classes(html_opt, *classes, **opt)
    unless html_opt
      Log.debug { "#{__method__}: nil html_opt from #{calling_method}" }
    end
    html_opt = html_opt&.deep_dup || {}
    prepend_grid_cell_classes!(html_opt, *classes, **opt)
  end
  # :nocov:

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   Additional CSS classes.
  # @param [Hash]               opt       Passed to #grid_cell_classes.
  #
  # @return [Hash]                        The modified *html_opt* hash.
  #
  def prepend_grid_cell_classes!(html_opt, *classes, **opt)
    classes = grid_cell_classes(*classes, **opt)
    prepend_css!(html_opt, *classes)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.extend(self)
  end

end

__loading_end(__FILE__)
