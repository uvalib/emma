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
 * @param {Array|*} arg
 *
 * @returns {Array}
 */
function consoleArgs(arg) {
    let result = [];
    if (Array.isArray(arg)) {
        flatten(arg).forEach(function(v) { result.push(...consoleArgs(v)); });
    } else if (typeof arg === 'string') {
        result.push(arg.trim());
    } else {
        result.push(asString(arg));
    }
    return result;
}
