// app/assets/javascripts/shared/logging.js


import { flatten }  from '../shared/objects'
import { asString } from '../shared/strings'


// ============================================================================
// Functions - Logging
// ============================================================================

/**
 * Emit a console log message.
 *
 * @param {...*} args
 */
export function consoleLog(...args) {
    console.log(...consoleArgs(args));
}

/**
 * Emit a console warning message.
 *
 * @param {...*} args
 */
export function consoleWarn(...args) {
    console.warn(...consoleArgs(args));
}

/**
 * Emit a console warning message.
 *
 * @param {...*} args
 */
export function consoleError(...args) {
    console.error(...consoleArgs(args));
}

// ============================================================================
// Functions - internal
// ============================================================================

/**
 * Prepare for console output.
 *
 * Simple objects are rendered as formatted strings, however functions and
 * elements are passed through untouched.
 *
 * @param {Array|*} arg
 *
 * @returns {Array}
 */
function consoleArgs(arg) {
    if (Array.isArray(arg)) {
        return flatten(arg).map(v => consoleArgs(v)).flat();
    }
    if (arg instanceof jQuery)     { return [arg] }
    if (arg instanceof Element)    { return [arg] }
    if (typeof arg === 'function') { return [arg] }
    if (typeof arg === 'string')   { return [arg.trim()] }
    return [asString(arg)];
}
