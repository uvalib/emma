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

// noinspection FunctionWithMultipleReturnPointsJS
/**
 * Indicate whether the item does not contain a value.
 *
 * @param {*} item
 *
 * @return {boolean}
 */
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
