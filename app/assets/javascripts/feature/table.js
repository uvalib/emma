// app/assets/javascripts/feature/table.js


import { AppDebug }                        from "../application/debug";
import { appSetup }                        from "../application/setup";
import { handleClickAndKeypress }          from "../shared/accessibility";
import { arrayWrap }                       from "../shared/arrays";
import { Emma }                            from "../shared/assets";
import { selector }                        from "../shared/css";
import { selfOrParent }                    from "../shared/html";
import { fromJSON, toObject }              from "../shared/objects";
import { baseUrl, makeUrl, urlParameters } from "../shared/url";
import * as xhr                            from "../shared/xhr";
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
} from "../shared/definitions";


const MODULE = "Table";
const DEBUG  = true;

AppDebug.file("feature/table", MODULE, DEBUG);

appSetup(MODULE, function() {

    /** @type {jQuery} */
    const $tables = $('table.sortable');

    // Only perform these actions on the appropriate pages.
    if (isMissing($tables)) { return }

    // ========================================================================
    // Type definitions
    // ========================================================================

    /**
     * @typedef {"ascending"|"descending"|"none"} SortDirection
     *
     * Valid "aria-sort" values.
     */

    /**
     * @typedef {{(string|number): SortDirection}} SortParameters
     *
     * One or more field/order pairs.
     */

    /**
     * @typedef {
     *  "non_sortable"      |
     *  "local_in_place"    |
     *  "remote_in_place"   |
     *  "remote_new_page"
     * } SortMode
     *
     * Sorting strategies.
     */

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Controls whether sorting on multiple columns is active.
     *
     * @note This has not currently supported.
     *
     * @type {boolean}
     */
    const MULTI_SORT     = false;

    /**
     * The sort parameter is a string containing a comma-separated list of
     * field names (indicating an ascending sort) and/or field names with
     * "_rev" appended (indicating a descending sort).
     *
     * @type {string}
     */
    const SORT_PARAM     = "sort";

    const COMPLETE_CLASS = "complete";
    const PARTIAL_CLASS  = "partial";
    const PAGEABLE_CLASS = "pageable";
    const SORTABLE_CLASS = "sortable";

    const COMPLETE       = selector(COMPLETE_CLASS);
    const PARTIAL        = selector(PARTIAL_CLASS);
    const PAGEABLE       = selector(PAGEABLE_CLASS);
    const SORTABLE       = selector(SORTABLE_CLASS);
    const SORTED_ASC     = '[aria-sort="ascending"]';
    const SORTED_DESC    = '[aria-sort="descending"]';

    /**
     * Accessible names for sort column headers.
     *
     * @type {Object.<SortDirection,string>}
     */
    const SORT = Emma.Terms.table.sort;

    /**
     *  Sorting strategies.
     *
     * @type {Object.<SortMode,string>}
     */
    const SORT_MODE = {
        non_sortable:    "Unsortable table",
        local_in_place:  "Client-side in-place sorting",
        remote_in_place: "In-place sorting with server-side results",
        remote_new_page: "Server-side results in a new page",
    };

    /**
     * Column names (`data-field` values) which indicate columns that are
     * not intended to be sortable.
     *
     * @type {string[]}
     */
    const IGNORED_FIELDS = [
        "actions",
    ];

    /**
     * Default sort parameters to apply so that sorted values are consistent.
     *
     * @type {Object.<string,SortDirection>}
     */
    const SECONDARY_SORT = {
        updated_at: "descending",
        id:         "ascending",
    };

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Setup a table to support sorting.
     *
     * @param {Selector} table
     */
    function initializeTable(table) {
        const $table = $(table);

        // Initialize sort controls.
        const prm    = tableParameters($table);
        const sort   = getSortParameters(prm);
        const $cols  = headersFor($table);
        $cols.each((_, column) => {
            const $head = $(column);
            const field = $head.attr("data-field");
            if (field) {
                setSortControls($head, sort[field]);
            }
        });
        handleClickAndKeypress($cols, onToggleColumnSort);

        // Save initial order of the rows.
        const $rows  = rowsFor($table);
        const $first = $rows.first();
        const $cells = $first.children('td');
        const cls    = $cells.first().attr("class")?.split(" ");
        const row    = cls?.find(c => c.match(/^row-\d/));
        const n      = Number(row?.replace(/^row-/, ""))    || 1;
        const ri     = Number($first.attr("aria-rowindex")) || n;
        originalStartRowNumber($table, n);
        originalStartAriaRowIndex($table, ri);
        $rows.each((idx, row) => { originalRowPosition(row, (idx + n)) });
    }

    /**
     * Toggle sort order on the associated column.
     *
     * If MULTI_SORT is not true then the sort values of all other columns are
     * cleared so that the selected column is the only involved in the sort.
     *
     * @param {ElementEvt} event
     */
    function onToggleColumnSort(event) {
        const $head = headerFor(event.target);
        if (!MULTI_SORT) {
            headersFor($head).not($head).each((_, column) => {
                const $head = $(column);
                const field = $head.attr("data-field");
                if (field && !IGNORED_FIELDS.includes(field)) {
                    clearSortControls($head);
                }
            });
        }
        toggleColumnSort($head);
    }

    /**
     * Toggle sort order on the associated column.
     *
     * @param {Selector}      target
     * @param {SortDirection} [direction]
     */
    function toggleColumnSort(target, direction) {
        const $head = headerFor(target);
        let new_direction;
        switch (true) {
            case (!!direction):         new_direction = direction;    break;
            case $head.is(SORTED_DESC): new_direction = "none";       break;
            case $head.is(SORTED_ASC):  new_direction = "descending"; break;
            default:                    new_direction = "ascending";  break;
        }
        setColumnSort($head, new_direction);
    }

    /**
     * Set the sort order on the indicated column, updating controls and
     * performing a new request if necessary.
     *
     * @param {Selector}      target
     * @param {SortDirection} direction
     */
    function setColumnSort(target, direction) {
        const $head = headerFor(target);
        const mode  = getSortMode($head);
        setSortControls($head, direction);
        switch (mode) {
            case "local_in_place":  return localSort($head);
            case "remote_in_place": return inPlaceSort($head);
            case "remote_new_page": return remoteSort($head);
            default:                return nonSortable($head);
        }
    }

    /**
     * Determine the sorting strategy required for this table.
     *
     * @param {Selector} target
     *
     * @returns {SortMode}
     */
    function getSortMode(target) {
        const $table = tableFor(target);
        switch (true) {
            case $table.is(`:not(${SORTABLE})`): return "non_sortable";
            case $table.is(COMPLETE):            return "local_in_place";
            case $table.is(PARTIAL):             return "remote_in_place";
            case $table.is(PAGEABLE):            return "remote_new_page";
            default:                             return "local_in_place";
        }
    }

    /**
     * Set the state of a sortable column header control.
     *
     * @param {Selector}      header
     * @param {SortDirection} [direction]   "none" by default
     */
    function setSortControls(header, direction) {
        const $head = headerFor(header);
        const lbl   = SORT[direction];
        const dir   = lbl && direction;
        $head.attr("aria-label", (lbl || SORT["none"]));
        $head.attr("aria-sort",  (dir || "none"));
    }

    /**
     * Clear the state of a sortable column header control.
     *
     * @param {Selector}  header
     */
    function clearSortControls(header) {
        setSortControls(header, "none");
    }

    // ========================================================================
    // Functions - sort strategies
    // ========================================================================

    /**
     * Placeholder mirroring actual sorting strategy implementations.
     *
     * @param {Selector} header
     */
    function nonSortable(header) {
        clearSortControls(header);
        alert(SORT_MODE.non_sortable);
    }

    /**
     * Apply sorting parameters to formulate a new server request.
     *
     * This is appropriate for a table where the rows constitute only one page
     * of records from the underlying database table.
     *
     * @param {Selector} header
     */
    function remoteSort(header) {
        const $table = tableFor(header);
        const url    = baseUrl($table.attr("data-path"));
        const params = updateSortParameters($table);
        window.location.href = makeUrl(url, params);
    }

    /**
     * Fetch modified contents for the table from the server and reconstruct
     * the rows on the client side.
     *
     * Because row cell values are modified in-place there is no need to adjust
     * row or cell attributes.
     *
     * @param {Selector} header
     */
    function inPlaceSort(header) {
        const $tbl = tableFor(header);
        const path = baseUrl($tbl.attr("data-path"));
        const prm  = updateSortParameters($tbl);
        xhr.get(path, prm, (data) => {
            let list = data || [];
            if (!Array.isArray(list)) { list = list["entries"] || list }
            if (!Array.isArray(list)) { list = list["list"]    || list }
            if (!Array.isArray(list)) { list = [] }
            const literal = ["boolean", "number", "string"];
            rowsFor($tbl).each((idx, row) => {
                const item = list[idx] || {};
                $(row).children('td').each((_, cell) => {
                    const $cell = $(cell);
                    const field = $cell.attr("data-field");
                    if (field && !IGNORED_FIELDS.includes(field)) {
                        let value = item[field];
                        if (field === "org_id") {
                            value = item["org"] || value;
                            if (typeof value === "object") {
                                value = value["short_name"];
                            }
                        } else if (field === "user_id") {
                            value = item["user"] || value;
                            if (typeof value === "object") {
                                value = value["email"];
                            }
                        } else if (field.endsWith("emma_data")) {
                            value = fromJSON(value) || {};
                            value = value["dc_title"];
                        } else if (field.endsWith("file_data")) {
                            value = fromJSON(value)   || {};
                            value = value["metadata"] || {};
                            value = value["filename"];
                        }
                        if (isEmpty(value)) {
                            value = "";
                        } else if (Array.isArray(value)) {
                            value = value.join(", ");
                        } else if (typeof value === "object") {
                            value = JSON.stringify(value);
                        } else if (literal.includes(typeof value)) {
                            value = `${value}`;
                        }
                        const $value = $cell.children('.value');
                        if (isPresent($value)) {
                            $value.text(value);
                        } else {
                            $cell.text(value);
                        }
                    }
                });
            });
        });
    }

    /**
     * Apply all sorting parameters to sort table rows in place.
     *
     * This is appropriate for a table where all data for a given model is
     * present in the table.
     *
     * Because "aria-rowindex" and cell "row-N" classes are associated with the
     * position of the row, these are recalculated after repositioning.
     *
     * @note Current implementation requires `MULTI_SORT === false`.
     *
     * @param {Selector} header
     */
    function localSort(header) {
        const $head  = headerFor(header);
        const field  = $head.attr("data-field");
        const sort   = field && $head.attr("aria-sort") || "ascending";
        const column = $head.index();
        const $table = tableFor($head);
        const $tbody = $table.find('tbody');
        const $rows  = $tbody.find('tr');

        // Select the sort comparison function based on the sort type.
        let value_fn, secondary;
        if (sort === "none") {
            value_fn  = originalCellValue;
        } else {
            secondary = secondarySorts(field);
        }

        // If secondary sort(s) apply, perform them first so that they will
        // have their affect on the selected sort.
        let rows = $rows.toArray();
        if (isPresent(secondary)) {
            const $headers = headersFor($table);
            $.each(secondary, (fld, dir) => {
                const $hdr = $headers.filter(`[data-field="${fld}"]`);
                const col  = $hdr.index();
                if (col >= 0) {
                    rows = sortRows(rows, col, dir);
                }
            });
        }
        rows = sortRows(rows, column, sort, value_fn);

        // Fix row "aria-rowindex" and cell "row-N" class names for the new
        // distribution of the rows.
        const first_cls = "row-first";
        const last_cls  = "row-last";
        const base_ri   = originalStartAriaRowIndex($table);
        const base_n    = originalStartRowNumber($table);
        const min_idx   = 0;
        const max_idx   = rows.length - 1;
        rows.forEach((row, idx) => {
            const first = (idx === min_idx);
            const last  = (idx === max_idx);
            const ri    = idx + base_ri;
            const n     = idx + base_n;
            const $row  = $(row);
            $row.children('td').each((_, cell) => {
                // noinspection JSUnresolvedReference
                const cls = cell.className.split(" ").map(c => {
                    switch (true) {
                        case (c === first_cls):    return "";
                        case (c === last_cls):     return "";
                        case !!c.match(/^row-\d/): return `row-${n}`;
                        default:                   return c;
                    }
                });
                first && cls.push(first_cls);
                last  && cls.push(last_cls);
                cell.className = cls.filter(v => v).join(" ");
            });
            $row.attr("aria-rowindex", `${ri}`);
        });

        // Reorder the rows in the DOM.
        $rows.detach();
        $tbody.append(rows);
    }

    // ========================================================================
    // Functions - sort support
    // ========================================================================

    /**
     * Default sort parameters to apply so that sorted values are consistent.
     *
     * Any parameters indicated by the `except` parameter will not be included
     * in the returned object.
     *
     * @param {string|string[]|object} [except]
     *
     * @returns {Object.<string,SortDirection>}
     */
    function secondarySorts(except) {
        const secondary = { ...SECONDARY_SORT };
        const fields =
            (Array.isArray(except)        && except) ||
            ((typeof except === "object") && Object.keys(except)) ||
            (except                       && [except]);
        fields?.forEach(field => delete secondary[field]);
        return secondary;
    }

    /**
     * Sort the rows in-place based on the given column.
     *
     * @param {HTMLElement[]} rows
     * @param {number}        col_idx
     * @param {SortDirection} [direction]
     * @param {function}      [value_func]
     *
     * @returns {HTMLElement[]}  Rows in sorted order.
     */
    function sortRows(rows, col_idx, direction, value_func) {
        const desc  = (direction === "descending");
        const value = value_func || currentCellValue;
        return rows.sort((row_a, row_b) => {
            const val_a = value(row_a, col_idx);
            const val_b = value(row_b, col_idx);
            switch (true) {
                case (val_a < val_b): return desc ?  1 : -1;
                case (val_a > val_b): return desc ? -1 :  1;
                default:              return 0;
            }
        });
    }

    /**
     * Generate a comparison value for the indicated data cell.
     *
     * @param {Selector} row
     * @param {number}   idx
     *
     * @returns {string|number}
     */
    function currentCellValue(row, idx) {
        const $cell = $(row).children('td').eq(idx);
        const value = $cell.text().trim();
        if (!value) { return "" }
        const num   = Number(value);
        return Number.isNaN(num) ? value.toUpperCase() : num;
    }

    /**
     * Get the original comparison value of a data cell.
     *
     * @note Currently this returns the original ordinal position of the row
     *  since this alone is enough to cause a sort to restore the original
     *  order of the rows.
     *
     * @param {Selector} row
     * @param {number}   [_idx]
     *
     * @returns {string|number}
     */
    function originalCellValue(row, _idx) {
        return originalRowPosition(row);
    }

    // ========================================================================
    // Functions - URL parameters
    // ========================================================================

    /**
     * The URL parameters needed to reconstruct the given table.
     *
     * If the table does not have a `data-path` attribute then the current URL
     * parameters are assumed.
     *
     * @param {Selector} [target]     Default: {@link urlParameters}.
     * @param {boolean}  [no_sort]    If *true*, skip sort parameters.
     *
     * @returns {object}
     */
    function tableParameters(target, no_sort) {
        const $tbl = target && tableFor(target);
        const path = $tbl?.attr("data-path");
        const prm  = urlParameters(path);
        if (no_sort) { delete prm[SORT_PARAM] }
        return prm;
    }

    /**
     * Extract sort parameter value(s).
     *
     * @param {object} [params]       Default: {@link urlParameters}.
     *
     * @returns {SortParameters}
     */
    function getSortParameters(params) {
        const prm  = params || urlParameters();
        const sort = prm[SORT_PARAM];
        let keys;
        if (typeof sort === "string") {
            // @note This works around apparent over-encoding by #url_for.
            // noinspection JSCheckFunctionSignatures
            keys = decodeURIComponent(sort);
            keys = keys.trim().split(/\s*,\s*/);
        } else {
            keys = arrayWrap(sort);
        }
        return toObject(keys, (k) => {
            const name = k.toLowerCase();
            const key  = name.replace(/_rev$/, "");
            const dir  = (key === name) ? "ascending" : "descending";
            return [key, dir];
        }, true);
    }

    /**
     * Generate URL parameters with updated sort parameter value(s).
     *
     * @param {Selector} target
     * @param {boolean}  [user_only]  Use only user-selected sort parameters.
     *                                  If MULTI_SORT then *false* by default;
     *                                  otherwise, *true* by default.
     *
     * @returns {object}              Replacement URL parameters.
     */
    function updateSortParameters(target, user_only) {
        const func  = "updateSortParameters";
        const reset = isDefined(user_only) ? user_only : !MULTI_SORT;
        const $tbl  = tableFor(target);
        const prm   = tableParameters($tbl, reset);
        const sort  = getSortSettings($tbl);
        const keys  = [];
        const errs  = [];
        const add   = (terms) =>
            Object.entries(terms).forEach(([k,v]) => {
                switch (v) {
                    case "none":        /* not included */      break;
                    case "ascending":   keys.push(k);           break;
                    case "descending":  keys.push(`${k}_rev`);  break;
                    default:            v && errs.push(v);      break;
                }
            });

        // Accumulate sort parameter value(s).
        const primary = reset ? sort : { ...getSortParameters(prm), ...sort };
        add(primary);

        // Apply secondary sort if-and-only-if there is a primary sort.
        if (isEmpty(keys)) {
            delete prm[SORT_PARAM];
        } else {
            add(secondarySorts(primary));
            prm[SORT_PARAM] = keys.join(",");
        }
        errs.forEach(err => console.warn(`${func}: invalid sort`, err));
        return prm;
    }

    /**
     * Get the cumulative sorting parameters set by all column headers.
     *
     * @param {Selector} target
     * @param {boolean}  [none]       If true then "none" sorts are reported.
     *
     * @returns {SortParameters}
     */
    function getSortSettings(target, none) {
        const result = {};
        headersFor(target).each((_, column) => {
            const $head = headerFor(column);
            const field = $head.attr("data-field");
            if (field && !IGNORED_FIELDS.includes(field)) {
                const direction = $head.attr("aria-sort");
                if (direction && (none || (direction !== "none"))) {
                    result[field] = direction;
                }
            }
        });
        return result;
    }

    // ========================================================================
    // Functions - elements data
    // ========================================================================

    /**
     * Remember the starting row number for the given table.
     *
     * @param {Selector} table
     * @param {number}   [value]
     *
     * @returns {number}
     */
    function originalStartRowNumber(table, value) {
        return storedValue(tableFor(table), "sort_start_row", value);
    }

    /**
     * Remember the starting "aria-rowindex" value for the given table.
     *
     * @param {Selector} table
     * @param {number}   [value]
     *
     * @returns {number}
     */
    function originalStartAriaRowIndex(table, value) {
        return storedValue(tableFor(table), "sort_start_aria", value);
    }

    /**
     * Remember the original row position for the given row.
     *
     * @param {Selector} row
     * @param {number}   [value]
     *
     * @returns {number}
     */
    function originalRowPosition(row, value) {
        return storedValue(rowFor(row), "sort_original_position", value);
    }

    /**
     * Manage a stored value attached to an element.
     *
     * @param {Selector} element
     * @param {string}   name
     * @param {*}        [value]
     *
     * @returns {*}
     */
    function storedValue(element, name, value) {
        const $element = $(element);
        if (isDefined(value)) {
            $element.data(name, value);
        }
        return $element.data(name);
    }

    // ========================================================================
    // Functions - elements
    // ========================================================================

    /**
     * Get the table element for a target at or within a table.
     *
     * @param {Selector} target       Anywhere at or within a table.
     *
     * @returns {jQuery}
     */
    function tableFor(target) {
        return selfOrParent(target, 'table');
    }

    /**
     * Get the header element for a target at or within a table column header.
     *
     * @param {Selector} target       Anywhere at or within a `<th>` element.
     *
     * @returns {jQuery}
     */
    function headerFor(target) {
        return selfOrParent(target, `th${SORTABLE}`);
    }

    /**
     * Get all column headers for a table.
     *
     * @param {Selector} target       Anywhere at or within a table.
     *
     * @returns {jQuery}
     */
    function headersFor(target) {
        return tableFor(target).find(`thead tr th${SORTABLE}`);
    }

    /**
     * Get the row element for a target within a table.
     *
     * @param {Selector} target       Anywhere at or within a `<tr>` element.
     *
     * @returns {jQuery}
     */
    function rowFor(target) {
        return selfOrParent(target, 'tr');
    }

    /**
     * Get all data rows for a table.
     *
     * @param {Selector} target       Anywhere at or within a table.
     *
     * @returns {jQuery}
     */
    function rowsFor(target) {
        return tableFor(target).find('tbody tr');
    }

    // ========================================================================
    // Functions - other
    // ========================================================================

    /**
     * Indicate whether console debugging is active.
     *
     * @returns {boolean}
     */
    function _debugging() {
        return AppDebug.activeFor(MODULE, DEBUG);
    }

    // noinspection JSUnusedLocalSymbols
    /**
     * Emit a console message if debugging.
     *
     * @param {...*} args
     */
    function _debug(...args) {
        _debugging() && console.log(`${MODULE}:`, ...args);
    }

    // ========================================================================
    // Actions
    // ========================================================================

    $tables.each((_, table) => initializeTable(table));

});
