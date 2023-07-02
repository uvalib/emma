// app/assets/javascripts/shared/math.js


import { AppDebug } from '../application/debug';


AppDebug.file('shared/math');

// ============================================================================
// Constants
// ============================================================================

/**
 * Kilobyte multiplier.
 *
 * @readonly
 * @type {number}
 */
export const K = 1024;

/**
 * Kilobyte multiplier.
 *
 * @readonly
 * @type {number}
 */
export const KB = K;

/**
 * Megabyte multiplier.
 *
 * @readonly
 * @type {number}
 */
export const MB = KB * KB;

// ============================================================================
// Functions
// ============================================================================

/**
 * Return the percentage of part in total.
 *
 * @param {number} part
 * @param {number} total
 *
 * @returns {number}
 */
export function percent(part, total) {
    return total ? ((part / total) * 100) : 0;
}

/**
 * Show the given value as a multiple of 1024.
 *
 * @param {number|string} value
 * @param {boolean}       [full]      If **true**, show full unit name.
 *
 * @returns {string}                  Blank if *value* is not a number.
 */
export function asSize(value, full) {
    const n = Number.parseFloat(value);
    if (!n && (n !== 0)) {
        return '';
    }
    let i = 0;
    // noinspection OverlyComplexBooleanExpressionJS
    let magnitude =
        ((n < Math.pow(K, ++i)) && i) || // B
        ((n < Math.pow(K, ++i)) && i) || // KB
        ((n < Math.pow(K, ++i)) && i) || // MB
        ++i;                             // GB
    magnitude--;
    const size_name = ['Bytes', 'Kilobytes', 'Megabytes', 'Gigabytes'];
    const size_abbr = ['B', 'KB', 'MB', 'GB'];
    const units     = full ? size_name[magnitude] : size_abbr[magnitude];
    const precision = Math.min(magnitude, 2);
    const result    = (n / Math.pow(K, magnitude)).toFixed(precision);
    return `${result} ${units}`;
}
