// app/assets/javascripts/shared/time.js


import { compact } from './objects'


// ============================================================================
// Constants
// ============================================================================

/**
 * Milliseconds per second.
 *
 * @readonly
 * @type {number}
 */
export const SECOND = 1000;

/**
 * Alias for SECOND.
 *
 * @readonly
 * @type {number}
 */
export const SECONDS = 1 * SECOND;

/**
 * Milliseconds per minute.
 *
 * @readonly
 * @type {number}
 */
export const MINUTE = 60 * SECONDS;

/**
 * Alias for MINUTE.
 *
 * @readonly
 * @type {number}
 */
export const MINUTES = 1 * MINUTE;

// ============================================================================
// Functions
// ============================================================================

/**
 * Interpret *value* as a time and return milliseconds into the epoch.  If
 * *value* is missing or invalid, the current time value is returned.
 *
 * @param {Date|number} [value]
 *
 * @returns {number}
 */
export function timeOf(value) {
    let result;
    switch (typeof value) {
        case 'object': result = value.getTime(); break;
        case 'number': result = value;           break;
        default:       result = Date.now();      break;
    }
    return result;
}

/**
 * The number of seconds since the given timestamp was created.
 *
 * @param {Date|number} start_time     Original `Date.now()` value.
 * @param {Date|number} [time_now]     Default: `Date.now()`.
 *
 * @returns {number}
 */
export function secondsSince(start_time, time_now) {
    const start = timeOf(start_time);
    const now   = timeOf(time_now);
    return (now - start) / SECOND;
}

/**
 * Show the given date value as "YYYY-MM-DD hh:mm:ss".
 *
 * @param {string|number|Date} value
 * @param {object}             [opt]
 *
 * @param {string}  [opt.separator]  Default: ' '.
 * @param {boolean} [opt.dateOnly]   If *true* do not show time.
 * @param {boolean} [opt.timeOnly]   If *true* do not show date.
 *
 * @returns {string}                        Blank if *value* is not a date.
 *
 * @see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat/DateTimeFormat
 */
export function asDateTime(value, opt = {}) {
    const separator  = opt.separator || ' ';
    const date_value = (value instanceof Date) ? value : new Date(value);
    let date, time;
    if (date_value.getFullYear()) {
        if (opt.dateOnly || !opt.timeOnly) {
            const parts = date_value.toLocaleDateString('en-GB').split('/');
            date = [parts.pop(), ...parts].join('-');
        }
        if (opt.timeOnly || !opt.dateOnly) {
            time = date_value.toLocaleTimeString([], { hour12: false });
        }
    }
    return compact([date, time]).join(separator);
}
