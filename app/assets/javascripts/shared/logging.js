// app/assets/javascripts/shared/logging.js

//= require shared/definitions

/**
 * Emit a console log message.
 *
 * @param {*} arguments
 */
function consoleLog() {
    console.log(logJoin.apply(null, arguments));
}

/**
 * Emit a console warning message.
 *
 * @param {*} arguments
 */
function consoleWarn() {
    console.warn(logJoin.apply(null, arguments));
}

/**
 * Emit a console warning message.
 *
 * @param {*} arguments
 */
function consoleError() {
    console.error(logJoin.apply(null, arguments));
}

/**
 * Join strings into a single message.
 *
 * @param {*} arguments
 *
 * @return {string}
 */
function logJoin() {
    var args  = Array.prototype.slice.call(arguments);
    var parts = logFlatArray(args);
    return parts.join(' ');
}

/**
 * Flatten nested arrays to yield a single array of strings.
 *
 * @param {Array|*} arg
 *
 * @return {Array}
 */
function logFlatArray(arg) {
    var result = [];
    if (arg === false) {
        result.push('false');
    } else if (isEmpty(arg)) {
        // No change to result.
    } else if (arg instanceof Array) {
        for (var i = 0; i < arg.length; i++) {
            result = result.concat(logFlatArray(arg[i]));
        }
    } else if (typeof arg === 'object') {
        result.push(JSON.stringify(arg));
    } else {
        result.push(arg.toString().trim());
    }
    return result;
}
