// app/assets/javascripts/shared/definitions.js

// ============================================================================
// Basic values and enumerations
// ============================================================================

/** @constant {number} */
var SECOND = 1000; // milliseconds

// ============================================================================
// JSDoc typedefs
// ============================================================================

// noinspection LocalVariableNamingConventionJS
/**
 * Indicates a function parameter that expects a {@link jQuery} object or
 * something that can be used to generate a {@link jQuery} object.
 *
 * @typedef Selector
 * @type {string|HTMLElement|jQuery}
 */
var Selector;

// ============================================================================
// Function definitions - Time and date
// ============================================================================

/**
 * The number of seconds since the given timestamp was created.
 *
 * @param {number} timestamp      Original `Date.now()` value.
 *
 * @return {number}
 */
function secondsSince(timestamp) {
    return (Date.now() - timestamp) / SECOND;
}

// ============================================================================
// Function definitions - Element values
// ============================================================================

/**
 * Indicate whether the item is not undefined.
 *
 * @param {*} item
 *
 * @return {boolean}
 */
function isDefined(item) {
    return typeof item !== 'undefined';
}

/**
 * Indicate whether the item is not defined.
 *
 * @param {*} item
 *
 * @return {boolean}
 */
function notDefined(item) {
    return !isDefined(item);
}

/**
 * Indicate whether the item does not contain a value.
 *
 * @param {*} item
 *
 * @return {boolean}
 */
// noinspection FunctionWithMultipleReturnPointsJS
function isEmpty(item) {
    // noinspection NegatedIfStatementJS
    if (!item) {
        return true;
    } else if (isDefined(item.length)) {
        return !item.length;
    } else if (typeof item === 'object') {
        for (var property in item) {
            if (item.hasOwnProperty(property)) {
                return false;
            }
        }
        return true;
    }
    return false;
}

/**
 * Indicate whether the item contains a value.
 *
 * @param {*} item
 *
 * @return {boolean}
 */
function notEmpty(item) {
    return !isEmpty(item);
}

/**
 * Indicate whether the item does not contain a value.
 *
 * @param {*} item
 *
 * @return {boolean}
 */
function isMissing(item) {
    return isEmpty(item);
}

/**
 * Indicate whether the item contains a value.
 *
 * @param {*} item
 *
 * @return {boolean}
 */
function isPresent(item) {
    return !isMissing(item);
}

// ============================================================================
// Function definitions - Console output
// ============================================================================

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
