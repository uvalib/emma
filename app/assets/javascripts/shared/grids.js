// app/assets/javascripts/shared/grids.js
//
// Support for generic grid accessibility.


import { AppDebug }                           from '../application/debug';
import { BaseClass }                          from './base-class';
import { selector }                           from './css';
import { keyCombo, keyFormat, modifiersOnly } from './keyboard';
import { NavGroup }                           from './nav-group';
import { isObject }                           from './objects';
import {
    ensureFocusable,
    maybeFocusable,
    neutralizeFocusables,
    restoreFocusables,
    setFocusable,
} from './accessibility';
import {
    isDefined,
    isMissing,
    isPresent,
    notDefined,
    presence,
} from './definitions';
import {
    delayedBy,
    handleCapture,
    handleEvent,
    phase,
} from './events';
import {
    containedBy,
    contains,
    sameElements,
    selfOrParent,
} from './html';


const MODULE = 'Grids';
const DEBUG  = true;

AppDebug.file('shared/grids', MODULE, DEBUG);

/**
 * Console output functions for this module.
 */
const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

// ============================================================================
// Constants
// ============================================================================

const ACTIVE     = 'grid';
const PASSIVE    = 'table';
const GRID_ROLES = [ACTIVE, PASSIVE];
const GRIDS      = GRID_ROLES.map(type => `[role="${type}"]`).join(',');
const GRID       = GRIDS;

const ROW_ROLES  = ['row'];
const ROWS       = ROW_ROLES.map(type => `[role="${type}"]`).join(',');
const ROW        = ROWS;

const CELL_ROLES = ['cell', 'gridcell', 'rowheader', 'columnheader'];
const CELLS      = CELL_ROLES.map(type => `[role="${type}"]`).join(',');
const CELL       = CELLS;

const HIDDEN     = selector(['hidden', 'undisplayed', '[aria-hidden="true"]']);

const LOC_DATA   = 'gridLocation';
const FOCUS_DATA = 'gridFocus';
const DIM_DATA   = 'gridDimensions';

const ROW_CURR   = 0;
const ROW_FIRST  = 1;
const ROW_LAST   = -1;
const ROW_UP     = -1;
const ROW_DOWN   = 1;
const ROW_PAGE   = 10; // TODO: dynamic?

const COL_CURR   = 0;
const COL_FIRST  = 1;
const COL_LAST   = -1;
const COL_LEFT   = -1;
const COL_RIGHT  = 1;
const COL_PAGE   = 10; // TODO: dynamic?

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {object} RowCol
 *
 * @property {number} row
 * @property {number} col
 */

/**
 * @typedef {RowCol} RowColDelta
 *
 * @property {number} row_delta
 * @property {number} col_delta
 */

/**
 * @typedef {object} MinMax
 *
 * @property {number} [row_min]
 * @property {number} [row_max]
 * @property {number} [col_min]
 * @property {number} [col_max]
 */

/**
 * @typedef {object} MoveLimit
 *
 * @property {boolean} [row_min]
 * @property {boolean} [row_max]
 * @property {boolean} [col_min]
 * @property {boolean} [col_max]
 */

/**
 * @typedef {function(n?:number): (GridMoveTo|GridMoveBy)} GridMoverFunc
 */

/**
 * @typedef {GridMoveTo|GridMoveBy|GridMoverFunc} GridMover
 */

// ============================================================================
// Classes
// ============================================================================

/**
 * Coordinates for a grid cell. <p/>
 *
 * The default is (ROW_FIRST, COL_FIRST) -- the top-left cell location.
 *
 * @extends BaseClass
 * @extends RowCol
 */
class GridLocation extends BaseClass {

    static CLASS_NAME = 'GridLocation';
    static DEBUGGING  = DEBUG;
    static DEBUG_CTOR = false;

    // ========================================================================
    // Variables
    // ========================================================================

    /** @type {number} */ _row;
    /** @type {number} */ _col;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {number|RowCol|GridLocation} [row]
     * @param {number}                     [col]
     *
     * @overload constructor()
     *  Set to (ROW_FIRST, COL_FIRST).
     *
     * @overload constructor(row)
     *  @param {RowCol|GridLocation} row
     *
     * @overload constructor(row, col)
     *  @param {number} row
     *  @param {number} col
     */
    constructor(row, col) {
        super();
        this.set_current(row, col);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get def_row()   { return ROW_FIRST }
    get def_col()   { return COL_FIRST }

    // ========================================================================
    // Properties
    // ========================================================================

    get row()       { return isDefined(this._row) ? this._row : this.def_row }
    get col()       { return isDefined(this._col) ? this._col : this.def_col }

    set row(v)      { if (isDefined(v)) { this._row = Number(v) || this.row } }
    set col(v)      { if (isDefined(v)) { this._col = Number(v) || this.col } }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * A clone of the instance.
     *
     * @returns {GridLocation}
     */
    dup() {
        return new this.constructor(this);
    }

    /**
     * A copy of the values.
     *
     * @returns {RowCol}
     */
    toObject() {
        return this.get_current();
    }

    /**
     * Get row/col values.
     *
     * @returns {RowCol}
     */
    get_current() {
        return { row: this.row, col: this.col };
    }

    /**
     * Set row/col values.
     *
     * @param {number|RowCol|GridLocation} [row]
     * @param {number}                     [col]
     *
     * @overload set_current()
     *  Set to default.
     *
     * @overload set_current(row)
     *  @param {RowCol|GridLocation} row
     *
     * @overload set_current(row, col)
     *  @param {number} row
     *  @param {number} col
     */
    set_current(row, col) {
        let row_col;
        if (row instanceof GridLocation) {
            row_col = { ...row.get_current() };
        } else if (typeof row === 'object') {
            row_col = { ...row };
        } else {
            row_col = { row, col };
        }
        this.row = row_col.row || this.def_row;
        this.col = row_col.col || this.def_col;
    }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Return the item if it is an instance or create one if not.
     *
     * @param {RowCol|GridLocation} item
     *
     * @returns {this}
     */
    static wrap(item) {
        return (item instanceof this) ? item : new this(item);
    }

}

// noinspection FunctionNamingConventionJS
/**
 * Specification of a change to a new specific grid location. <p/>
 *
 * The default is (ROW_CURR, COL_CURR) -- _i.e._, no change.
 *
 * @extends GridLocation
 */
class GridMoveTo extends GridLocation {

    static CLASS_NAME = 'GridMoveTo';

    // ========================================================================
    // Variables
    // ========================================================================

    /** @type {number} */ _row_min;
    /** @type {number} */ _row_max;
    /** @type {number} */ _col_min;
    /** @type {number} */ _col_max;

    // ========================================================================
    // Properties - internal
    // ========================================================================

    get def_row()   { return ROW_CURR }
    get def_col()   { return COL_CURR }

    // ========================================================================
    // Properties
    // ========================================================================

    get row_min()   { return this._row_min || ROW_FIRST }
    get row_max()   { return this._row_max }
    get col_min()   { return this._col_min || COL_FIRST }
    get col_max()   { return this._col_max }

    set row_min(v)  { this._row_min = Number(v) || ROW_FIRST }
    set row_max(v)  { this._row_max = Number(v) || undefined }
    set col_min(v)  { this._col_min = Number(v) || COL_FIRST }
    set col_max(v)  { this._col_max = Number(v) || undefined }

    get row_count() { return (this.row_max || 0) - this.row_min + 1 }
    get col_count() { return (this.col_max || 0) - this.col_min + 1 }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Return row/col minima and maxima.
     *
     * @returns {MinMax}
     */
    getBounds() {
        return {
            row_min: this.row_min,
            row_max: this.row_max,
            col_min: this.col_min,
            col_max: this.col_max,
        };
    }

    /**
     * Set row/col minima and maxima.
     *
     * @param {number|MinMax|GridMoveTo} [row_min]
     * @param {number}                   [row_max]
     * @param {number}                   [col_min]
     * @param {number}                   [col_max]
     */
    setBounds(row_min, row_max, col_min, col_max) {
        let bounds;
        if (row_min instanceof GridMoveTo) {
            bounds = row_min.getBounds();
        } else if (typeof row_min === 'object') {
            bounds = { ...row_min };
        } else {
            bounds = { row_min, row_max, col_min, col_max };
        }
        this.row_min = bounds.row_min;
        this.row_max = bounds.row_max;
        this.col_min = bounds.col_min;
        this.col_max = bounds.col_max;
    }

    /**
     * Update row and column.
     *
     * @param {GridLocation} location
     * @param {MinMax}       [bounds]
     *
     * @returns {GridLocation}
     */
    applyTo(location, bounds) {
        const func = 'applyTo'; this._debug(`${func}:`, location, bounds);
        if (typeof bounds === 'object') { this.setBounds(bounds) }
        let row = (this.row === ROW_LAST) ? this.row_max : this.row;
        let col = (this.col === COL_LAST) ? this.col_max : this.col;
        if (!(Number(row) > 0)) { row = location.row }
        if (!(Number(col) > 0)) { col = location.col }
        row = this._clamp(this.row_min, row, this.row_max);
        col = this._clamp(this.col_min, col, this.col_max);
        return new GridLocation(row, col);
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    _clamp(lbound, value, ubound) {
        let min, max, val = Number(value) || 0;
        if (val < (min = Number(lbound) || val)) { val = min }
        if (val > (max = Number(ubound) || val)) { val = max }
        return val;
    }

    // ========================================================================
    // Class methods
    // ========================================================================

    static ROW_START()      { return new this(ROW_CURR,  COL_FIRST) }
    static ROW_END()        { return new this(ROW_CURR,  COL_LAST)  }
    static COL_START()      { return new this(ROW_FIRST, COL_CURR)  }
    static COL_END()        { return new this(ROW_LAST,  COL_CURR)  }
    static TOP_LEFT()       { return new this(ROW_FIRST, COL_FIRST) }
    static BOTTOM_RIGHT()   { return new this(ROW_LAST,  COL_LAST)  }

}

// noinspection FunctionNamingConventionJS
/**
 * Specification of a relative change in grid location.
 *
 * - Positive row delta indicates a move down.
 * - Positive col delta indicates a move to the right.
 *
 * @extends GridMoveTo
 * @extends RowColDelta
 */
class GridMoveBy extends GridMoveTo {

    static CLASS_NAME = 'GridMoveBy';

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * If **true** then there is no default move limit and motion beyond the
     * bounds of the grid wraps to the neighboring row/column. <p/>
     * If **false** then motion is limited to {@link row_max} and
     * {@link col_max} by default.
     *
     * @type {boolean}
     */
    static WRAP = false;

    // ========================================================================
    // Variables
    // ========================================================================

    /** @type {number}    */ _row_delta;
    /** @type {number}    */ _col_delta;
    /** @type {MoveLimit} */ _limit;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {number|RowColDelta}  row_delta
     * @param {number|MoveLimit}    [col_delta]
     * @param {MoveLimit}           [limit]
     *
     * @overload constructor(row_delta, limit)
     *  @param {RowColDelta}        row_delta
     *  @param {MoveLimit}          [limit]
     *
     * @overload constructor(row_delta, col_delta, limit)
     *  @param {number}             row_delta
     *  @param {number}             col_delta
     *  @param {MoveLimit}          [limit]
     */
    constructor(row_delta, col_delta, limit) {
        super();
        this.setDelta(row_delta, col_delta, limit);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get WRAP()       { return this.constructor.WRAP }

    get row_delta()  { return this._row_delta || ROW_CURR }
    get col_delta()  { return this._col_delta || COL_CURR }

    set row_delta(v) { this._row_delta = Number(v) || this.row_delta }
    set col_delta(v) { this._col_delta = Number(v) || this.col_delta }

    // ========================================================================
    // Methods - GridLocation overrides
    // ========================================================================

    /**
     * A copy of the values.
     *
     * @returns {RowColDelta}
     */
    toObject() {
        return { ...super.toObject(), ...this.getDelta() };
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Get row/col change values.
     *
     * @returns {RowColDelta}
     */
    getDelta() {
        // noinspection JSValidateTypes
        return { row_delta: this.row_delta, col_delta: this.col_delta };
    }

    /**
     * Set delta values.
     *
     * @param {number|RowColDelta}       [row_delta]
     * @param {number|MoveLimit|boolean} [col_delta]
     * @param {MoveLimit|boolean}        [limit]
     *
     * @returns {RowColDelta}
     *
     * @overload set_delta(row_delta, limit)
     *  @param {RowColDelta}        [row_delta]
     *  @param {MoveLimit|boolean}  [limit]
     *
     * @overload set_delta(row_delta, col_delta, limit)
     *  @param {number}             row_delta
     *  @param {number}             col_delta
     *  @param {MoveLimit|boolean}  [limit]
     */
    setDelta(row_delta, col_delta, limit) {
        let obj, lim;
        if (row_delta instanceof GridMoveBy) {
            obj = row_delta.getDelta();
            lim = col_delta;
        } else if (typeof row_delta === 'object') {
            obj = { ...row_delta };
            lim = col_delta;
        } else {
            obj = { row_delta, col_delta };
            lim = limit;
        }
        if (notDefined(lim)) { lim = !this.WRAP }
        switch (lim) {
            case false: this._limit = {};                       break;
            case true:  this._limit = { ...this.getBounds() };  break;
            default:    this._limit = { ...lim };               break;
        }
        this.row_delta = obj.row_delta;
        this.col_delta = obj.col_delta;
        return obj;
    }

    /**
     * Update row and column.
     *
     * @param {GridLocation}     location
     * @param {MinMax|undefined} [bounds]
     *
     * @returns {GridLocation}
     */
    applyTo(location, bounds) {
        const func = 'applyTo'; this._debug(`${func}:`, location, bounds);
        if (typeof bounds === 'object') { this.setBounds(bounds) }
        const limit = this._limit;
        let row = location.row + this.row_delta;
        let col = location.col + this.col_delta;

        const col_count = Number(this.col_count);
        if (limit.col_min && (col < this.col_min)) {
            col = this.col_min;
        } else if (limit.col_max && (col > this.col_max)) {
            col = this.col_max;
        } else if (col_count > 0) {
            // Normalize column, adding or subtracting rows as necessary.
            while (col < 1) {
                col += col_count;
                row -= 1;
            }
            while (col > col_count) {
                col -= col_count;
                row += 1;
            }
        }

        const row_count = Number(this.row_count);
        if (limit.row_min && (row < this.row_min)) {
            row = this.row_min;
        } else if (limit.row_max && (row > this.row_max)) {
            row = this.row_max;
        } else if (row_count > 0) {
            // Normalize row, adding or subtracting columns as necessary.
            while (row < 1) {
                row += row_count;
                col -= 1;
            }
            while (row > row_count) {
                row -= row_count;
                col += 1;
            }
        }

        row = this._clamp(this.row_min, row, this.row_max);
        col = this._clamp(this.col_min, col, this.col_max);
        return new GridLocation(row, col);
    }

    // ========================================================================
    // Class methods - internal
    // ========================================================================

    static _num(n)  { return Number(n) || 1 }

    // ========================================================================
    // Class methods
    // ========================================================================

    static LEFT(n)  { return new this(ROW_CURR, (COL_LEFT  * this._num(n))) }
    static RIGHT(n) { return new this(ROW_CURR, (COL_RIGHT * this._num(n))) }
    static UP(n)    { return new this((ROW_UP   * this._num(n)), COL_CURR) }
    static DOWN(n)  { return new this((ROW_DOWN * this._num(n)), COL_CURR) }

    static PAGE_UP(pages, size = ROW_PAGE) {
        const rows  = this._num(pages) * size * ROW_UP;
        const limit = { row_min: true, row_max: true };
        return new this(rows, COL_CURR, limit);
    }

    static PAGE_DOWN(pages, size = ROW_PAGE) {
        const rows  = this._num(pages) * size * ROW_DOWN;
        const limit = { row_min: true, row_max: true };
        return new this(rows, COL_CURR, limit);
    }

}

/**
 * A mapping of key combination to methods which generate a class instance for
 * affecting the indicated grid focus movement when applied.
 *
 * @type {Object.<string,GridMoverFunc>}
 */
const GRID_NAV = Object.freeze({
    ArrowLeft:              n => GridMoveBy.LEFT(n),
    ArrowRight:             n => GridMoveBy.RIGHT(n),
    ArrowUp:                n => GridMoveBy.UP(n),
    ArrowDown:              n => GridMoveBy.DOWN(n),
    PageUp:                 n => GridMoveBy.PAGE_UP(n),
    PageDown:               n => GridMoveBy.PAGE_DOWN(n),
    Home:                   _ => GridMoveTo.ROW_START(),
    End:                    _ => GridMoveTo.ROW_END(),
    'Control+ArrowLeft':    _ => GridMoveTo.ROW_START(),
    'Control+ArrowRight':   _ => GridMoveTo.ROW_END(),
    'Control+ArrowUp':      _ => GridMoveTo.COL_START(),
    'Control+ArrowDown':    _ => GridMoveTo.COL_END(),
    'Control+Home':         _ => GridMoveTo.TOP_LEFT(),
    'Control+End':          _ => GridMoveTo.BOTTOM_RIGHT(),
});

// ============================================================================
// Functions
// ============================================================================

/**
 * The function to be called to initialize static table navigation logic for
 * all non-grid tables on the page.
 */
export function initializeTables() {
    const $tables = $(`[role="${PASSIVE}"]`);
    $tables.each((_, table) => initializeTableNavigation(table));
}

/**
 * The function to be called to initialize static table navigation logic. <p/>
 *
 * This is appropriate for tables matching **`[role="table"]`** where only cell
 * navigation is required.
 *
 * If *table* does not have a role it will be set to {@link PASSIVE}, however
 * if it explicitly has the {@link ACTIVE} role it will be skipped.
 *
 * @param {Selector} table
 */
export function initializeTableNavigation(table) {
    const func = 'initializeTableNavigation'; OUT.debug(`${func}:`, table);
    let $table = gridFor(table);
    if (isMissing($table)) {
        OUT.debug(`${func}: setting role=${PASSIVE} for:`, table);
        $table = $(table).attr('role', PASSIVE);
    } else if ($table.attr('role') === ACTIVE) {
        OUT.warn(`${func}: skipping grid:`, table);
        return;
    }
    setupNavigation($table);
}

/**
 * The function to be called to initialize grid navigation logic. <p/>
 *
 * This is appropriate for tables matching **`[role="grid"]`** where both cell
 * and intra-cell navigation (within control nav groups) are required.
 *
 * If *grid* does not have a role it will be set to {@link ACTIVE}.
 *
 * @param {Selector} grid
 */
export function initializeGridNavigation(grid) {
    const func = 'initializeGridNavigation'; OUT.debug(`${func}:`, grid);
    let $grid  = gridFor(grid);
    if (isMissing($grid)) {
        OUT.debug(`${func}: setting role=${ACTIVE} for:`, grid);
        $grid = $(grid).attr('role', ACTIVE);
    } else if ($grid.attr('role') === PASSIVE) {
        OUT.warn(`${func}: skipping non-grid:`, grid);
        return;
    }
    setupNavigation($grid);
}

/**
 * The function to be called to renumber grid elements and initialize grid
 * cell navigation logic for any new cells.
 *
 * This should be called only on a grid which has been previously set up with
 * {@link initializeGridNavigation}.
 *
 * @param {Selector} grid
 */
export function updateGridNavigation(grid) {
    const func  = 'updateGridNavigation'; OUT.debug(`${func}:`, grid);
    const $grid = gridFor(grid);
    if ($grid.attr('role') === ACTIVE) {
        setupGridRows($grid);
    } else {
        OUT.warn(`${func}: skipping non-grid:`, grid);
    }
}

// ============================================================================
// Functions - grid setup
// ============================================================================

/**
 * Setup navigation for grids and tables.
 *
 * @param {jQuery} $grid
 */
function setupNavigation($grid) {
    //OUT.debug('setupNavigation: $grid =', $grid);
    ensureFocusable($grid);
    setupGridRows($grid);
    setupGridNavigation($grid);
}

/**
 * Assign grid location to each visible grid cell, and update $grid
 * *aria-rowcount* and *aria-colcount* if necessary. <p/>
 *
 * Any new cells (e.g. cells in rows inserted since this function was last run)
 * have additional setup applied to them.
 *
 * @param {jQuery} $grid
 */
function setupGridRows($grid) {
    const func  = 'setupGridRows'; OUT.debug(`${func}: $grid =`, $grid);
    const $rows = gridRows($grid);
    const $temp = $grid.find(ROW).filter(HIDDEN); // Hidden template rows.

    let $cols;
    $temp.each((_,   row) => { $cols = setupGridColumns(row) })
    $rows.each((idx, row) => { $cols = setupGridColumns(row, (idx + 1)) });

    const row_cnt = Number($grid.attr('aria-rowcount')) || 0;
    const row_min = ROW_FIRST;
    const row_max = $rows?.length || row_cnt;
    if (row_max > row_cnt) {
        $grid.attr('aria-rowcount', row_max);
        OUT.debug(`${func}: row_count was ${row_cnt}; now ${row_max}`);
    }

    const col_cnt = Number($grid.attr('aria-colcount')) || 0;
    const col_min = COL_FIRST;
    const col_max = $cols?.length || col_cnt;
    if (col_max !== col_cnt) {
        $grid.attr('aria-colcount', col_max);
        OUT.debug(`${func}: col_count was ${col_cnt}; now ${col_max}`);
    }

    setGridBounds($grid, row_min, row_max, col_min, col_max);
}

/**
 * Setup new cells and refresh existing cells.
 *
 * @param {Selector} row
 * @param {number}   [row_number]     One-based row number.
 *
 * @returns {jQuery}
 */
function setupGridColumns(row, row_number) {
    const num    = row_number || 0;
    const func   = 'setupGridColumns'; OUT.debug(`${func}: row ${num} =`, row);
    const $cells = gridCells(row);
    $cells.each((col_index, col_element) => {
        const col   = col_index + 1;
        const $cell = $(col_element);
        $cell.attr('aria-colindex', col);
        if (!$cell.attr('tabindex')) { $cell.attr('tabindex', 0) }
        if (!getGridLocation($cell)) { setupCellNavigation($cell) }
        setGridLocation($cell, num, col);
        neutralizeFocusables($cell); // NOTE: _not_ neutralizeCellFocusables
    });
    return $cells;
}

// ============================================================================
// Functions - grid events
// ============================================================================

/**
 * @typedef {object} GridEventProperties
 *
 * @property {jQuery}   $tgt
 * @property {jQuery}   $curr
 * @property {jQuery}   $grid
 * @property {jQuery}   $cell
 * @property {jQuery}   [$group]
 * @property {jQuery}   [$entry]
 * @property {jQuery}   [$control]
 * @property {jQuery}   [$target]
 * @property {boolean}  to_grid
 * @property {boolean}  to_cell
 * @property {boolean}  to_group
 * @property {boolean}  to_entry
 * @property {boolean}  to_ctrl
 * @property {boolean}  in_modal
 * @property {boolean}  in_cell
 * @property {NavGroup} [group]
 * @property {boolean}  [active]
 */

/** @type {GridEventProperties} */
const TEMPLATE = Object.freeze({
    $tgt:       undefined,
    $curr:      undefined,
    $grid:      undefined,
    $cell:      undefined,
    $group:     undefined,
    $entry:     undefined,
    $control:   undefined,
    $target:    undefined,
    to_grid:    undefined,
    to_cell:    undefined,
    to_group:   undefined,
    to_entry:   undefined,
    to_ctrl:    undefined,
    in_modal:   undefined,
    in_cell:    undefined,
    group:      undefined,
    active:     undefined,
});

/**
 * The {@link GridEventProperties} keys which represent mutually exclusive
 * identification properties.
 *
 * @type {Set<string>}
 */
const FLAGS = Object.freeze(
    new Set(Object.keys(TEMPLATE).filter(k => k.match(/^(to_|in_)/)))
);

/**
 * Derive values and logical properties from the event which express the
 * relationships between the event target and the grid components.
 *
 * @param {string}     func
 * @param {ElementEvt} event
 * @param {string}     [key]
 * @param {boolean}    [validate]
 *
 * @returns {GridEventProperties}
 */
function analyzeGridEvent(func, event, key, validate) {
    /** @type {jQuery} */
    const $tgt     = $(event.target),
          $curr    = $(event.currentTarget);

    const $grid    = gridFor($curr);
    const to_grid  = sameElements($tgt, $grid);
    const $cell    = !to_grid  && gridCell($tgt) || undefined;
    const to_cell  = !!$cell   && sameElements($tgt, $cell);
    const outside  = to_grid   || to_cell;
    const group    = $cell     && NavGroup.instanceFor($cell);

    const $group   = group?.group;
    const to_group = !outside  && !!$group && sameElements($tgt, $group);
    const inside   = !outside  && !to_group;

    const $control = group?.testControl($tgt);
    const to_ctrl  = !!$control;
    const $entry   = !to_ctrl  && group?.testEntry($tgt);
    const to_entry = !!$entry;
    const to_other = inside    && !to_ctrl && !to_entry;
    const $target  = to_other  && maybeFocusable($tgt) && $tgt || undefined;

    const in_modal = !!$target && !to_ctrl && !to_entry;
    const in_cell  = !in_modal && to_other && contains($cell, $tgt);
    const active   = group?.active;

    //noinspection JSValidateTypes
    /** @type {GridEventProperties} */
    const result = {
        $tgt,
        $curr,
        $grid,
        $cell,
        $group,
        $entry,
        $control,
        $target,
        to_grid,
        to_cell,
        to_group,
        to_entry,
        to_ctrl,
        in_modal,
        in_cell,
        group,
        active,
    };
    if (!in_modal && OUT.debugging()) {
        logGridEventAnalysis(result, event, key, func);
    }
    if (validate || OUT.debugging()) {
        validateGridEventAnalysis(result, func);
    }
    return result;
}

/**
 * Report on inconsistencies in the event analysis. <p/>
 *
 * (This should never need to be executed under normal circumstances since
 * it reports on programming errors that should be fixed before release.)
 *
 * @param {GridEventProperties} result
 * @param {string}              [caller]
 *
 * @returns {boolean}                 **true** if there were no problems.
 */
function validateGridEventAnalysis(result, caller) {
    const err = [];

    // Verify that exactly one condition flag is true.
    const flags = [];
    for (const [k, v] of Object.entries(result)) {
        if (v && FLAGS.has(k)) { flags.push(k) }
    }
    if (flags.length < 1) {
        err.push(['no condition flag was set']);
    } else if (flags.length > 1) {
        err.push(['only one should be true:', flags]);
    }

    // Verify that `in_modal` is appropriate.
    const { $tgt, in_modal, group } = result;
    const modal  = group?.MODAL_ROOT || NavGroup.MODAL_ROOT;
    const inside = containedBy($tgt, modal);
    if (in_modal && !inside) {
        err.push(['not in modal as expected:', $tgt]);
    } else if (inside && !in_modal) {
        err.push(['unexpectedly in modal:', $tgt]);
    }

    // Report error(s) to the console.
    if (isPresent(err)) {
        const func = caller || 'validateGridEventAnalysis';
        err.forEach(line => OUT.error(`${func}:`, ...line));
        return false;
    }
    return true;
}

/**
 * Detailed console output of an event analysis.
 *
 * @param {GridEventProperties} result
 * @param {ElementEvt}          event
 * @param {string}              [key]
 * @param {string}              [caller]
 */
function logGridEventAnalysis(result, event, key, caller) {
    const func = caller || 'logGridEventAnalysis';
    const msg  = key ? keyFormat(`${func}: key`, key) : [`${func}:`];
    const prop = {
        eventPhase:       phase(event),
        cancelable:       event.cancelable,
        defaultPrevented: event.defaultPrevented,
    };
    const log_values = (obj) => {
        const width = Math.max(...Object.keys(obj).map(k => k.length));
        for (const [k, v] of Object.entries(obj)) {
            OUT.debug(...msg, `${k.padEnd(width)} =`, v);
        }
    }
    OUT.debug(`*** ${''.padEnd(72,'v')} ***`);
    log_values(prop);
    log_values(result);
}

/**
 * Detailed console output for the end of handling of an event.
 *
 * @param {ElementEvt} event
 * @param {string}     [key]
 * @param {string}     [caller]
 */
function logGridEventEnd(event, key, caller) {
    const func = caller || 'logGridEventEnd';
    const msg  = key ? keyFormat(`${func}: key`, key) : [`${func}:`];
    OUT.debug(...msg, 'defaultPrevented ->', event.defaultPrevented);
    OUT.debug(`*** ${''.padEnd(72,'^')} ***`);
}

// ============================================================================
// Functions - grid navigation events
// ============================================================================

/**
 * Initialize grid cells and setup grid navigation event handlers.
 *
 * @param {jQuery} $grid
 */
function setupGridNavigation($grid) {
    OUT.debug('setupGridNavigation: $grid =', $grid);
    handleEvent(  $grid, 'focus',   onGridFocus);
    handleEvent(  $grid, 'blur',    onGridBlur);
    handleCapture($grid, 'keydown', onGridKeydownCapture);
}

/**
 * Start handling grid navigation keys for the indicated grid.
 *
 * @param {FocusEvt} event
 */
function onGridFocus(event) {
    const func  = 'onGridFocus';
    const leave = event.relatedTarget;
    const enter = event.currentTarget;
    const $grid = gridFor(enter);

    let entering_grid;
    if (!leave) {
        entering_grid = true; // Re-entering browser tab/window?
    } else if (!sameElements($grid, gridFor(leave))) {
        entering_grid = true;
    }

    if (OUT.debugging()) {
        const msg = [];
        switch (true) {
            case !leave:        msg.push('no previous focus before');   break;
            case entering_grid: msg.push('new outside focus:');         break;
            default:            msg.push('new inside focus:');          break;
        }
        leave && msg.push(leave);
        OUT.debug(`${func}:`, ...msg, '$grid = ', $grid, 'event =', event);
    }

    if (entering_grid) {
        moveGridCellFocus($grid);
    }
}

/**
 * Stop handling grid navigation keys for the indicated grid.
 *
 * @param {FocusEvt} event
 */
function onGridBlur(event) {
    const func  = 'onGridBlur';
    const enter = event.relatedTarget;
    const leave = event.currentTarget;
    const $grid = gridFor(leave);

    let leaving_grid;
    if (!enter) {
        leaving_grid = true; // Leaving browser tab/window?
    } else if (!sameElements($grid, gridFor(enter))) {
        leaving_grid = true;
    }

    if (OUT.debugging()) {
        const msg = [];
        switch (true) {
            case !enter:        msg.push('no new focus from');  break;
            case leaving_grid:  msg.push('new outside focus:'); break;
            default:            msg.push('new inside focus:');  break;
        }
        enter && msg.push(enter);
        OUT.debug(`${func}:`, ...msg, '$grid = ', $grid, 'event =', event);
    }

    if (leaving_grid) {
        // Currently no action defined.
    }
}

// noinspection FunctionTooLongJS
/**
 * Keyboard navigation between grid cells.
 *
 * @param {KeyboardEvt} event
 *
 * @returns {EventHandlerReturn}
 *
 * @see https://www.w3.org/WAI/ARIA/apg/patterns/grid/#gridNav_focus
 */
function onGridKeydownCapture(event) {
    const func = 'onGridKeydownCapture';
    const key  = keyCombo(event);
    if (!key) { return OUT.warn(`${func}: not a KeyboardEvent`, event) }
    if (modifiersOnly(key)) { return undefined } // Avoid excess logging.

    const {
        $tgt,
        $grid,
        $cell,
        $entry,
        $control,
        $target,
        to_cell,
        to_group,
        to_entry,
        to_ctrl,
        in_modal,
        group,
        active,
    } = analyzeGridEvent(func, event, key);

    let enter, leave, move, tab;
    if (in_modal) {
        // Event for an element which is inside the group element but is
        // not a group control (e.g. focusables in a popup modal dialog).
    } else if (active) {
        leave = (key === 'Escape');
    } else {
        switch (key) {
            case 'F2':        enter = !!group;       break;
            case 'Enter':     enter = !!group;       break;
            case 'Tab':       tab   = true;          break;
            case 'Shift+Tab': tab   = true;          break;
            default:          move  = GRID_NAV[key]; break;
        }
    }

    if (OUT.debugging()) {
        const msg = keyFormat(`${func}: key`, key);
        switch (true) {
            case !!move:    msg.push('GRID NAV');                        break;
            case tab:       msg.push('LEAVE GRID');                      break;
            case enter:     msg.push('ENTER CELL NAV');                  break;
            case leave:     msg.push('LEAVE CELL NAV');                  break;
            case in_modal:  msg.push('to modal under');                  break;
            case to_cell:                                                break;
            case to_group:  msg.push('to');                              break;
            case to_entry:  msg.push('to entry',      $entry,   "\nin"); break;
            case to_ctrl:   msg.push('to control',    $control, "\nin"); break;
            case !!$target: msg.push('to $target',    $target,  "\nin"); break;
            default:        msg.push('non-focusable', $tgt,     "\nin"); break;
        }
        if (group && !tab && !move) {
            msg.push(active ? 'active' : 'inactive');
            msg.push(`${group.CLASS_NAME} =`, group);
        }
        $cell && msg.push('in $cell =', $cell);
        OUT.debug(...msg, 'event =', event);
    }

    if (move) {
        moveGridCellFocus($grid, move);

    } else if (tab) {
        // Allow default, which will move focus to the prev/next element.
        setFocusable($grid, false, func);
        delayedBy(50, () => setFocusable($grid, true, func))();

    } else if (enter) {
        moveGridCellFocus($grid, undefined, false);

    } else if (!active && !$cell) {
        OUT.warn(`${func}: KEY "${key}" unexpected; event =`, event);
    }

    if (move || tab) { event.stopPropagation() }
    if (move)        { event.preventDefault()  }

    !in_modal && OUT.debugging() && logGridEventEnd(event, key, func);
}

// ============================================================================
// Functions - cell navigation events
// ============================================================================

/**
 * Set up event handlers to support navigation within a cell.
 *
 * @param {jQuery} $cell
 */
function setupCellNavigation($cell) {
    //OUT.debug('setupCellNavigation: $cell =', $cell);
    handleEvent(  $cell, 'focus',   onGridCellFocus);
    handleEvent(  $cell, 'blur',    onGridCellBlur);
    handleCapture($cell, 'click',   onGridCellClickCapture);
    handleCapture($cell, 'keydown', onGridCellKeydownCapture);
}

/**
 * Respond to a cell gaining focus.
 *
 * @param {FocusEvt} event
 */
function onGridCellFocus(event) {
    const func   = 'onGridCellFocus';
    const enter  = event.currentTarget;
    const leave  = event.relatedTarget;
    const $cell  = gridCell(enter);
    const $grid  = gridFor($cell);
    const group  = NavGroup.instanceFor($cell);
    const $group = group?.group;

    if (OUT.debugging()) {
        let entering_grid, entering_cell, leaving_group, leaving_ctrl;
        if (!leave) {
            // Current browser tab restored?
        } else if (!sameElements($grid, gridFor(leave))) {
            entering_grid = true;
        } else if (!sameElements($cell, gridCell(leave))) {
            entering_cell = true;
        } else if ($group && sameElements($group, leave)) {
            leaving_group = true;
        } else if (!sameElements($cell, leave)) {
            leaving_ctrl  = true;
        }
        let s;
        switch (true) {
            case !leave:        s = 'no previous focus for';            break;
            case entering_grid: s = 'old focus outside the grid:';      break;
            case entering_cell: s = 'old focus in grid outside cell:';  break;
            case leaving_group: s = 'old focus inside cell nav group:'; break;
            case leaving_ctrl:  s = 'old focus inside cell control:';   break;
            default:            s = 'old focus is same cell:';          break;
        }
        const msg = [s];
        leave && msg.push(leave);
        OUT.debug(`${func}:`, ...msg, '$cell =', $cell, 'event =', event);
    }

    if (!$group) {
        OUT.warn(`${func}: no NavGroup for $cell =`, $cell);
    }

    setGridCellFocus($grid, $cell, false);
    scrollToEdge($cell, $grid);
}

/**
 * Respond to a cell losing focus.
 *
 * @param {FocusEvt} event
 */
function onGridCellBlur(event) {
    const func   = 'onGridCellBlur';
    const enter  = event.relatedTarget;
    const leave  = event.currentTarget;
    const $cell  = gridCell(leave);
    const $grid  = gridFor($cell);
    const group  = NavGroup.instanceFor($cell);
    const $group = group?.group;

    let leaving_grid, leaving_cell, entering_group, entering_ctrl;
    if (!enter) {
        // Leaving current browser tab/window?
    } else if (!sameElements($grid, gridFor(enter))) {
        leaving_grid   = true;
    } else if (!sameElements($cell, gridCell(enter))) {
        leaving_cell   = true;
    } else if ($group && sameElements($group, enter)) {
        entering_group = true;
    } else if (!sameElements($cell, enter)) {
        entering_ctrl  = true;
    }

    if (OUT.debugging()) {
        let s;
        switch (true) {
            case !enter:         s = 'no new focus from';                break;
            case leaving_grid:   s = 'new focus outside the grid:';      break;
            case leaving_cell:   s = 'new focus in grid outside cell:';  break;
            case entering_group: s = 'new focus inside cell nav group:'; break;
            case entering_ctrl:  s = 'new focus inside cell control:';   break;
            default:             s = 'new focus is same cell:';          break;
        }
        const msg = [s];
        enter && msg.push(enter);
        OUT.debug(`${func}:`, ...msg, '$cell =', $cell, 'event =', event);
    }

    if (!$group) {
        OUT.warn(`${func}: no NavGroup for $cell =`, $cell);
    }

    if (group) {
        if (leaving_cell) { group.deactivate() }
    } else if (leaving_grid || leaving_cell) {
        neutralizeCellFocusables($cell);
    } else if (entering_ctrl) {
        restoreCellFocusables($cell);
    }

    if (leaving_grid) {
        setFocusable($cell, true, func);
    } else if (leaving_cell || entering_group || entering_ctrl) {
        setFocusable($cell, false, func);
    }
}

/**
 * Respond to a click within a cell. <p/>
 *
 * This will also fire in response to a click within a popup dialog that is
 * included within the cell, but that event does not have an impact on the
 * state of the cell or of the nav group within it.
 *
 * @param {MouseEvt|KeyboardEvt} event
 */
function onGridCellClickCapture(event) {
    const func = 'onGridCellClickCapture';
    const {
        $tgt,
        $grid,
        $cell,
        $entry,
        $control,
        $target,
        to_cell,
        to_group,
        to_entry,
        to_ctrl,
        in_modal,
        in_cell,
        group,
        active,
    } = analyzeGridEvent(func, event);

    if (OUT.debugging()) {
        const msg = [];
        switch (true) {
            case in_modal:  msg.push('to modal under');                  break;
            case to_cell:   msg.push('enter');                           break;
            case to_group:  msg.push('to');                              break;
            case to_entry:  msg.push('to entry',      $entry,   "\nin"); break;
            case to_ctrl:   msg.push('to control',    $control, "\nin"); break;
            case !!$target: msg.push('to $target',    $target,  "\nin"); break;
            default:        msg.push('non-focusable', $tgt,     "\nin"); break;
        }
        if (group) {
            msg.push(active ? 'active' : 'inactive');
            msg.push(`${group.CLASS_NAME} =`, group);
        }
        OUT.debug(`${func}:`, ...msg, '$cell =', $cell, 'event =', event);
    }

    //let handled;
    if (to_cell || in_cell || to_group || to_entry || to_ctrl) {
        const loc    = getGridLocation($cell);
        const motion = new GridMoveTo(loc);
        moveGridCellFocus($grid, motion, !active);
    }
    if (to_group || to_entry || to_ctrl) {
        group?.activate() && group?.clickedInside();
        setFocusable($cell, false, func);
    } else if (in_cell && group?.clickedInside()) {
        setFocusable($cell, false, func);
    }

    //if (handled) { event.stopPropagation() }
    //if (handled) { event.preventDefault()  }

    !in_modal && OUT.debugging() && logGridEventEnd(event, undefined, func);
}

// noinspection FunctionTooLongJS
/**
 * Navigation within a grid cell.
 *
 * @param {KeyboardEvt} event
 *
 * @returns {EventHandlerReturn}
 *
 * @see https://www.w3.org/WAI/ARIA/apg/patterns/grid/#gridNav_inside
 */
function onGridCellKeydownCapture(event) {
    const func = 'onGridCellKeydownCapture';
    const key  = keyCombo(event);
    if (!key) { return OUT.warn(`${func}: not a KeyboardEvent`, event) }
    if (modifiersOnly(key)) { return undefined } // Avoid excess logging.

    const {
        $tgt,
        $grid,
        $cell,
        $entry,
        $control,
        $target,
        to_cell,
        to_group,
        to_entry,
        to_ctrl,
        in_modal,
        group,
        active,
    } = analyzeGridEvent(func, event, key);

    let enter, leave;
    if (in_modal) {
        // Event for an element which is inside the group element but is
        // not a group control (e.g. focusables in a popup modal dialog).
    } else if (active) {
        leave = (key === 'Escape');
    } else if (group) {
        enter = (key === 'F2') || (key === 'Enter');
    }

    if (OUT.debugging()) {
        const msg = keyFormat(`${func}: key`, key);
        switch (true) {
            case enter:     msg.push('ENTERING');                        break;
            case leave:     msg.push('LEAVING');                         break;
            case in_modal:  msg.push('to modal under');                  break;
            case to_cell:                                                break;
            case to_group:  msg.push('to');                              break;
            case to_entry:  msg.push('to entry',      $entry,   "\nin"); break;
            case to_ctrl:   msg.push('to control',    $control, "\nin"); break;
            case !!$target: msg.push('to $target',    $target,  "\nin"); break;
            default:        msg.push('non-focusable', $tgt,     "\nin"); break;
        }
        if (group) {
            msg.push(active ? 'active' : 'inactive');
            msg.push(`${group.CLASS_NAME} =`, group);
        }
        OUT.debug(...msg, 'in $cell =', $cell, 'event =', event);
    }

    if (enter && (to_entry || to_ctrl)) {
        group.activate($entry ? group.control($entry) : $control);

    } else if (enter && group.activate()) {
        group.activeControls.first().trigger('focus');

    } else if (leave || enter) {
        group.deactivate();
        setGridCellFocus($grid, $cell);

    } else if (!in_modal && !group) {
        OUT.warn(`${func}: KEY "${key}" unexpected event =`, event);
    }

    if (enter || leave) { event.stopPropagation() }
    if (enter || leave) { event.preventDefault()  }

    !in_modal && OUT.debugging() && logGridEventEnd(event, key, func);
}

// ============================================================================
// Functions - grid navigation focus
// ============================================================================

/**
 * Move grid cell focus.
 *
 * @param {jQuery}    $grid
 * @param {GridMover} [motion]
 * @param {boolean}   [focus]         If **false** do not trigger focus.
 *
 * @returns {jQuery|undefined}
 */
function moveGridCellFocus($grid, motion, focus) {
    const func      = 'moveGridCellFocus'; OUT.debug(func);
    const $old_cell = getGridCellFocus($grid);
    const $cur_cell = moveGridCellCursor($grid, motion);
    const $new_cell = $cur_cell && setGridCellFocus($grid, $cur_cell, focus);
    const same_cell = $new_cell && sameElements($old_cell, $new_cell);

    if (OUT.debugging()) {
        const msg = [];
        switch (true) {
            case !!same_cell: msg.push('same:', $old_cell, $new_cell); break;
            case !!$old_cell: msg.push('leaving:', $old_cell); break;
            case !!$new_cell: msg.push('new cell'); break;
            default:          msg.push('invalid'); break;
        }
        OUT.debug(`${func}:`, ...msg, '*** motion =', motion);
    }

    if (!$new_cell) {
        return OUT.warn(`${func}: invalid motion =`, motion);
    }

    if ($old_cell && !same_cell) {
        neutralizeCellFocusables($old_cell);
    }
    scrollIntoView($new_cell, $grid);
    return $new_cell;
}

/**
 * Get the grid cell that has focus.
 *
 * @param {jQuery} $grid
 *
 * @returns {jQuery|undefined}
 */
function getGridCellFocus($grid) {
    //OUT.debug('getGridCellFocus: $grid =', $grid);
    return $grid.data(FOCUS_DATA);
}

/**
 * Set focus to the indicated grid cell.
 *
 * @param {jQuery}  $grid
 * @param {jQuery}  $cell             If missing, clear focus.
 * @param {boolean} [focus]           If **false** do not trigger focus.
 *
 * @returns {jQuery|undefined}
 */
function setGridCellFocus($grid, $cell, focus) {
    const func      = 'setGridCellFocus';
    const $new_cell = presence($cell);
    const same_grid = $new_cell && sameElements($grid, gridFor($new_cell));

    if (OUT.debugging()) {
        const msg = [];
        switch (true) {
            case !$new_cell: msg.push(`clear ${FOCUS_DATA} for`);       break;
            case !same_grid: msg.push('outside grid; $cell =', $cell);  break;
            default:         msg.push('$cell =', $cell);                break;
        }
        OUT.debug(`${func}:`, ...msg, '$grid =', $grid);
    }

    if (!$new_cell) {
        $grid.removeData(FOCUS_DATA);
    } else if (!same_grid) {
        OUT.warn(`${func}: not inside; $cell =`, $cell, '$grid =', $grid);
    } else {
        setFocusable($cell, true, func);
        $grid.data(FOCUS_DATA, $cell);
        return (focus === false) ? $cell : $cell.trigger('focus');
    }
}

// ============================================================================
// Functions - grid navigation cursor
// ============================================================================

/**
 * Update the grid coordinates cursor. <p/>
 *
 * If *motion* is missing, the cursor is not changed and the currently-focused
 * cell is returned.
 *
 * @param {jQuery}    $grid
 * @param {GridMover} [motion]
 *
 * @returns {jQuery|undefined}        Blank if *motion* is invalid.
 */
function moveGridCellCursor($grid, motion) {
    OUT.debug('moveGridCellCursor: motion =', motion);
    let location = getGridCellCursor($grid) || setGridCellCursor($grid);
    const move   = (typeof motion === 'function') ? motion() : motion;
    if (move) {
        location = move.applyTo(location, getGridBounds($grid));
        setGridCellCursor($grid, location);
    }
    const $row = gridRows($grid, location.row);
    return gridCells($row, location.col);
}

/**
 * Get the grid coordinates of the cell which has (or contains) focus.
 *
 * @param {jQuery} $grid
 *
 * @returns {GridLocation|undefined}
 */
function getGridCellCursor($grid) {
    const value = $grid.data(LOC_DATA);
    //OUT.debug('getGridCellCursor:', value, 'for $grid =', $grid);
    return value;
}

/**
 * Set the grid coordinates of the cell which has (or contains) focus.
 *
 * @param {jQuery}              $grid
 * @param {number|GridLocation} [r]
 * @param {number}              [c]
 *
 * @returns {GridLocation}
 *
 * @overload setGridCellCursor($grid)
 *  Set coordinates to (1,1) -- the top-left cell.
 *  @param {jQuery}       $grid
 *
 * @overload setGridCellCursor($grid, r)
 *  @param {jQuery}       $grid
 *  @param {GridLocation} r
 *
 * @overload setGridCellCursor($grid, r, c)
 *  @param {jQuery} $grid
 *  @param {number} r
 *  @param {number} c
 */
function setGridCellCursor($grid, r, c) {
    OUT.debug('setGridCellCursor:', r, c);
    const loc = new GridLocation(r, c);
    $grid.data(LOC_DATA, loc);
    return loc;
}

// ============================================================================
// Functions - grid coordinates
// ============================================================================

/**
 * Get the stored grid coordinates of the given cell.
 *
 * @param {Selector} cell
 *
 * @returns {GridLocation|undefined}
 */
function getGridLocation(cell) {
    const $cell = gridCell(cell);
    const value = $cell.data(LOC_DATA);
    //OUT.debug('getGridLocation:', value, 'for $cell =', $cell);
    return value;
}

/**
 * Set the stored grid coordinates of the given cell.
 *
 * @param {Selector}      cell
 * @param {number|RowCol} row
 * @param {number}        [col]
 *
 * @returns {GridLocation}
 */
function setGridLocation(cell, row, col) {
    const $cell = gridCell(cell);
    const value = new GridLocation(row, col);
    //OUT.debug('setGridLocation:', row, col, $cell);
    $cell.data(LOC_DATA, value);
    return value;
}

// ============================================================================
// Functions - grid dimensions
// ============================================================================

/**
 * Get grid dimensions.
 *
 * @param {jQuery} $grid
 *
 * @returns {MinMax|undefined}
 */
function getGridBounds($grid) {
    const value = $grid.data(DIM_DATA);
    //OUT.debug('getGridBounds:', value, 'for $grid =', $grid);
    return value;
}

/**
 * Set grid dimensions.
 *
 * @param {jQuery}        $grid
 * @param {number|MinMax} row_min
 * @param {number}        [row_max]
 * @param {number}        [col_min]
 * @param {number}        [col_max]
 *
 * @returns {MinMax}
 */
function setGridBounds($grid, row_min, row_max, col_min, col_max) {
    let value;
    if (isObject(row_min)) {
        value = { ...row_min };
    } else {
        value = { row_min, row_max, col_min, col_max };
    }
    OUT.debug('setGridBounds:', value, $grid);
    $grid.data(DIM_DATA, value);
    return value;
}

/**
 * If *cell* is at a corner or edge of *grid* then scroll the grid so that
 * movement to a sticky row or column header happens in an expected way.
 *
 * @param {Selector} cell
 * @param {Selector} [grid]           Derived from *cell* if missing.
 *
 * @returns {undefined}
 */
function scrollToEdge(cell, grid) {
    const func   = 'scrollToEdge';
    const $cell  = gridCell(cell);
    const $grid  = gridFor(grid || $cell);
    const bounds = getGridBounds($grid);
    const loc    = getGridLocation($cell);

    if (!bounds) {
        return OUT.warn(`${func}: no ${DIM_DATA} bounds for $grid =`, $grid);
    } else if (!loc) {
        return OUT.warn(`${func}: no ${LOC_DATA} location for $cell =`, $cell);
    }

    /** @type {ScrollToOptions} */
    const scroll = {};
    switch (loc.col) {
        case bounds.col_min: scroll.left = 0;                    break;
        case bounds.col_max: scroll.left = $grid[0].scrollWidth; break;
    }
    switch (loc.row) {
        case bounds.row_min: scroll.top = 0;                     break;
        case bounds.row_max: scroll.top = $grid[0].scrollHeight; break;
    }
    if (isMissing(scroll)) {
        OUT.debug(`${func}: not on edge: loc =`, loc, '$cell =', $cell);
    } else {
        $grid[0].scrollTo(scroll);
    }
}

/**
 * If *cell* partially out of the visible portion of *grid* then scroll the
 * grid so that the cell is fully visible.
 *
 * @param {Selector} cell
 * @param {Selector} [grid]           Derived from *cell* if missing.
 *
 * @returns {undefined}
 */
function scrollIntoView(cell, grid) {
    const $cell = gridCell(cell);
    const $grid = gridFor(grid || $cell);

    const css_val  = (v) => Number($grid.css(v)?.replaceAll(/[^\d]/g, ''));
    const x_offset = css_val('scroll-padding-left') || 0;
    const y_offset = css_val('scroll-padding-top')  || 0;

    const r_cell = $cell[0].getBoundingClientRect();
    const r_grid = $grid[0].getBoundingClientRect();
    const x_bar  = r_grid.width  - $grid[0].clientWidth;  // v. scroll bar
    const y_bar  = r_grid.height - $grid[0].clientHeight; // h. scroll bar

    const left  = r_cell.right  - r_grid.right  + x_bar;
    const right = r_grid.left   - r_cell.left   + x_offset;
    const up    = r_cell.bottom - r_grid.bottom + y_bar;
    const down  = r_grid.top    - r_cell.top    + y_offset;

    const x = ((left > 0) && left) || ((right > 0) && -right) || 0;
    const y = ((up   > 0) && up)   || ((down  > 0) && -down)  || 0;

    if (x || y) { $grid[0].scrollBy(x, y) }
}

// ============================================================================
// Functions - grid focusable elements
// ============================================================================

/**
 * Neutralize focusables within *$cell* by deactivating its nav group if it has
 * one, or directly if not.
 *
 * @param {jQuery}  $cell
 * @param {boolean} [plus_cell]
 */
function neutralizeCellFocusables($cell, plus_cell = true) {
    const func = 'neutralizeCellFocusables'; //OUT.debug(`${func}:`, $cell);
    if (isActiveGrid($cell)) {
        const group = NavGroup.instanceFor($cell);
        if (!group) {
            neutralizeFocusables($cell.children());
        } else if (group.active) {
            group.deactivate();
        }
    }
    if (plus_cell) {
        setFocusable($cell, false, func);
    }
}

/**
 * Restore focusables within *$cell* by activating its nav group if it has one,
 * or directly if not.
 *
 * @param {jQuery}  $cell
 * @param {boolean} [plus_cell]
 */
function restoreCellFocusables($cell, plus_cell = false) {
    const func = 'restoreCellFocusables'; //OUT.debug(`${func}:`, $cell);
    if (isActiveGrid($cell)) {
        const group = NavGroup.instanceFor($cell);
        if (!group) {
            restoreFocusables($cell.children());
        } else if (!group.active) {
            group.activate();
        }
    }
    if (plus_cell) {
        setFocusable($cell, true, func);
    }
}

// ============================================================================
// Functions - grid elements
// ============================================================================

/**
 * Indicate whether the `<table>` associated with the target has any cells with
 * interactive content -- as opposed to only cells with simple content (i.e.,
 * cells with no control groups).
 *
 * @param {Selector} target
 *
 * @returns {boolean}
 */
function isActiveGrid(target) {
    return gridFor(target).attr('role') === ACTIVE;
}

/**
 * The grid which is or contains the target.
 *
 * @param {Selector} target
 *
 * @returns {jQuery}
 */
function gridFor(target) {
    const func = 'gridFor'; //OUT.debug(`${func}: target =`, target);
    return selfOrParent(target, GRID, func);
}

/**
 * The grid cell which is or contains the target.
 *
 * @param {Selector} target
 *
 * @returns {jQuery}
 */
function gridCell(target) {
    const func = 'gridCell'; //OUT.debug(`${func}: target =`, target);
    return selfOrParent(target, CELL, func);
}

/**
 * The displayed row(s) of the indicated grid.
 *
 * @param {jQuery} $grid
 * @param {number} [row_number]       If given, limit to that ordinal row.
 *
 * @returns {jQuery}
 */
function gridRows($grid, row_number) {
    //OUT.debug(`gridRows(${row_number}): $grid =`, $grid);
    const $rows = $grid.find(ROW).not(HIDDEN);
    return row_number ? oneBasedIndex($rows, row_number) : $rows;
}

/**
 * The displayed column(s) of the indicated row.
 *
 * @param {Selector} row
 * @param {number}   [col_number]     If given, limit to that ordinal column.
 *
 * @returns {jQuery}
 */
function gridCells(row, col_number) {
    //OUT.debug(`gridCells(${row_number}): row =`, row);
    /** @type {jQuery} */
    const $row  = $(row);
    const $cols = $row.find(CELLS).not(HIDDEN);
    return col_number ? oneBasedIndex($cols, col_number) : $cols;
}

/**
 * The ordinal element of *$items* (or all elements if *number* is blank).
 *
 * @param {jQuery} $items
 * @param {number} [number]
 *
 * @returns {jQuery}
 */
function oneBasedIndex($items, number) {
    const n = Number(number) || 0;
    switch (true) {
        case (n > 0): return $items.eq(n-1);
        case (n < 0): return $items.last();
        default:      return $items;
    }
}
