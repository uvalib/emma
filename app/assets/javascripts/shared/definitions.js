// app/assets/javascripts/shared/definitions.js

// ============================================================================
// Basic values and enumerations
// ============================================================================

/**
 * @type {number}
 */
const SECOND = 1000; // milliseconds

// ============================================================================
// JSDoc typedefs
// ============================================================================

//noinspection LocalVariableNamingConventionJS
/**
 * Indicates a function parameter that expects a {@link jQuery} object or
 * something that can be used to generate a {@link jQuery} object.
 *
 * @typedef Selector
 * @type {string|HTMLElement|jQuery}
 */
let Selector;

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
        for (let property in item) {
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
 */
function consoleLog(...args) {
    console.log(logJoin(args));
}

/**
 * Emit a console warning message.
 */
function consoleWarn(...args) {
    console.warn(logJoin(args));
}

/**
 * Emit a console warning message.
 */
function consoleError(...args) {
    console.error(logJoin(args));
}

/**
 * Join strings into a single message.
 *
 * @param {Arguments, Array} args
 *
 * @return {string}
 */
function logJoin(args) {
    let message = [];
    for (let i = 0; i < args.length; i++) {
        let arg = args[i];
        if (typeof arg === 'object') {
            for (let j = 0; j < arg.length; j++) {
                message.push(arg[j].toString().trim());
            }
        } else {
            message.push(arg.toString().trim());
        }
    }
    return message.join(' ');
}
