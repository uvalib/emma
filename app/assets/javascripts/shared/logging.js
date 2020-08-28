// app/assets/javascripts/shared/logging.js

//= require shared/definitions

/**
 * Emit a console log message.
 *
 * @param {...*} args
 */
function consoleLog(...args) {
    console.log(...consoleArgs(args));
}

/**
 * Emit a console warning message.
 *
 * @param {...*} args
 */
function consoleWarn(...args) {
    console.warn(...consoleArgs(args));
}

/**
 * Emit a console warning message.
 *
 * @param {...*} args
 */
function consoleError(...args) {
    console.error(...consoleArgs(args));
}

/**
 * Prepare for console output.
 *
 * @param {Array|*} arg
 *
 * @return {Array}
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
