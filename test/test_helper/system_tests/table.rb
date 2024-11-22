# test/test_helper/system_tests/table.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Support for tables of items.
#
module TestHelper::SystemTests::Table

  include TestHelper::SystemTests::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Validate an item table, ensuring that:
  #
  # * The number of rows is reflected in "aria-rowcount".
  # * The number of columns indicated by the "columns-NN" class matches those
  #   in the header, the number of cells in the first row, and the value of
  #   "aria-colcount".
  #
  # @param [Capybara::Node::Element, String] table
  # @param [Boolean]                         section
  #
  # @return [void]
  #
  def check_item_table(table = '.model-table', section: false)
    name    = (table if table.is_a?(String))
    table   = find(table) if table.is_a?(String)
    show_item { "--- SECTION #{name || section[:class]}" } if section

    head_tr = table.all('thead tr[role="row"]')
    body_tr = table.all('tbody tr[role="row"]')
    classes = table[:class].to_s.split(' ')
    columns = classes.find { _1.start_with?('columns-') }.tr('^0-9', '').to_i
    headers = table.all('thead th').size
    cells   = body_tr.to_ary.first&.all('td')&.size || headers
    rows    = body_tr.size
    a_cols  = table[:'aria-colcount'].to_i
    a_rows  = table[:'aria-rowcount'].to_i - head_tr.size

    # Verify row count agreement.
    unless a_rows == rows
      flunk "#{rows} rows but 'aria-rowcount' indicates #{a_rows} rows"
    end

    # Verify column count agreement.
    errors  = {}
    errors[:headers]       = headers unless columns == headers
    errors[:cells]         = cells   unless columns == cells
    errors[:aria_colcount] = a_cols  unless columns == a_cols
    if DEBUG_TESTS
      show_item "       table rows     = #{rows.inspect}"
      show_item "       table classes  = #{classes.inspect}"
      show_item "       table columns  = #{columns.inspect}"
      show_item "       table headers  = #{headers.inspect}" if errors.present?
      show_item "       table cells    = #{cells.inspect}"   if errors.present?
      show_item "       table colcount = #{a_cols.inspect}"  if errors.present?
    end
    errors.each_pair do |items, count|
      flunk "class has #{columns} columns but #{count} #{items} columns found"
    end
  end

  # Validate a horizontal listing of record values, ensuring that:
  #
  # * The number of columns indicated by the "columns-NN" class matches the
  #   number of label/value pairs within the element.
  #
  # @param [Capybara::Node::Element, String] listing
  # @param [Array, String, nil]              prune
  #
  # @return [void]
  #
  def check_details_columns(listing, prune: nil)
    name    = (listing if listing.is_a?(String))
    listing = find(listing) if listing.is_a?(String)
    classes = listing[:class].to_s.split(' ')
    columns = classes.find { _1.start_with?('columns-') }.tr('^0-9', '').to_i

    prune &&= Array.wrap(prune).map { _1.delete_prefix('.') }
    filter  =
      ->(item) {
        (item.send(:parent) == listing) &&
          !(prune && item[:class].split(' ').intersect?(prune))
      }
    labels = listing.all('.label', &filter).size
    values = listing.all('.value', &filter).size

    errors  = {}
    errors[:labels] = labels unless columns == labels
    errors[:values] = values unless columns == values
    if DEBUG_TESTS
      show_item "--- SECTION #{name || listing[:class]}"
      show_item "       classes = #{classes.inspect}"
      show_item "       columns = #{columns.inspect}"
      show_item "       labels  = #{labels.inspect}" if errors.present?
      show_item "       values  = #{values.inspect}" if errors.present?
    end
    errors.each_pair do |items, count|
      flunk "#{columns} columns indicated but #{count} column #{items} found"
    end
  end

  # Validate a details section that has a heading containing an item count and
  # a toggle to reveal a table of items.
  #
  # @param [Capybara::Node::Element, String] section
  #
  # @return [void]
  #
  def check_details_section(section)
    name    = (section if section.is_a?(String))
    section = find(section) if section.is_a?(String)
    show_item { "--- SECTION #{name || section[:class]}" }

    # Verify the item total in the section heading.
    total = section.find('.total-count').text.to_i
    show_item { "       total         = #{total.inspect}" }
    return if total.zero?

    # If there is a non-zero total, click the toggle to reveal the item table.
    toggle = section.first('.toggle.for-panel', minimum: 0)&.click
    show_item { "       toggle        = #{toggle[:class].inspect}" }

    # Validate the item table.
    table = section.find('table')
    check_item_table(table)

    # Verify that a "See all records" link appears when required.
    max = ENV_VAR['ROW_PAGE_SIZE'].to_i
    if (max > 0) && (total > max)
      part = section.find('.full-table-link')
      link = part.find('a')
      assert link, 'Missing full-table-link anchor element'
      assert_match config_term(:table, :rows_here, rows: max), part.text
    end

    # Verify record count agreement.
    recs = table[:'data-record-total'].to_i
    unless total == recs
      flunk "title indicates #{total} records; table indicates #{recs} records"
    end
  end

  # Validate a page selection menu (e.g. from :show_select, :edit_select, etc).
  #
  # @param [Capybara::Node::Element, String] section
  # @param [Integer]                         count
  # @param [String]                          action
  #
  # @return [void]
  #
  def check_page_select_menu(section = '.select-menu', count:, action:, **)
    name    = (section if section.is_a?(String))
    section = find(section) if section.is_a?(String)
    show_item { "--- MENU #{name || section[:class]}" }

    # Open the menu to get a screenshot.
    DEBUG_TESTS and section.find('.select2-selection').click and screenshot

    # Ensure that menu selections will open to the right page.
    form = section.find('.select-entry')
    url  = url_without_port(form[:action])
    assert (url == action), -> {
      "#{name} action #{url.inspect} instead of #{action.inspect}"
    }

    # Compare the (hidden) menu items with the provided count.
    opts = section.find('select', visible: false).all('option')
    size = opts.reject { _1[:value].blank? }.size
    assert (size == count), -> {
      "#{name} has #{size} items instead of #{count}"
    }

  end

end
