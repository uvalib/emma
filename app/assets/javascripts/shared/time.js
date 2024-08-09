// app/assets/javascripts/shared/time.js


import { AppDebug } from "../application/debug";
import { compact }  from "./objects";


AppDebug.file("shared/time");

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
 * Interpret **value** as a time and return milliseconds into the epoch or 0 if
 * **value** does not express a time value.
 *
 * @param {*} value
 *
 * @returns {number}
 */
export function timestamp(value) {
    let date;
    if (!value) {
        // No date value given.
    } else if (value instanceof Date) {
        date = value;
    } else if (typeof value === "number") {
        date = new Date(value);
    } else if (typeof value === "string") {
        date = new Date(value.trim().replace(/\s*UTC\s*/, ""));
    }
    return date?.getTime() || 0;
}

/**
 * Interpret **value** as a time and return milliseconds into the epoch.  If
 * **value** is missing or invalid, the current time value is returned.
 *
 * @param {Date|number} [value]
 *
 * @returns {number}
 */
export function timeOf(value) {
    return value && timestamp(value) || Date.now();
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
 * @param {string}  [opt.separator]   Default: " ".
 * @param {boolean} [opt.dateOnly]    If *true*, do not show time.
 * @param {boolean} [opt.timeOnly]    If *true*, do not show date.
 *
 * @returns {string}                  Blank if **value** is not a date.
 *
 * @see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat/DateTimeFormat
 */
export function asDateTime(value, opt = {}) {
    const separator  = opt.separator || " ";
    const date_value = (value instanceof Date) ? value : new Date(value);
    let date, time;
    if (date_value.getFullYear()) {
        if (opt.dateOnly || !opt.timeOnly) {
            const parts = date_value.toLocaleDateString("en-GB").split("/");
            date = [parts.pop(), ...parts].join("-");
        }
        if (opt.timeOnly || !opt.dateOnly) {
            time = date_value.toLocaleTimeString([], { hour12: false });
        }
    }
    return compact([date, time]).join(separator);
}
