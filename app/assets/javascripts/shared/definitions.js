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
 * @returns {number}
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
 * @returns {boolean}
 */
function isDefined(item) {
    return typeof item !== 'undefined';
}

/**
 * Indicate whether the item is not defined.
 *
 * @param {*} item
 *
 * @returns {boolean}
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
 * @returns {boolean}
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

// noinspection JSUnusedGlobalSymbols
/**
 * Indicate whether the item contains a value.
 *
 * @param {*} item
 *
 * @returns {boolean}
 */
function notEmpty(item) {
    return !isEmpty(item);
}

/**
 * Indicate whether the item does not contain a value.
 *
 * @param {*} item
 *
 * @returns {boolean}
 */
function isMissing(item) {
    return isEmpty(item);
}

/**
 * Indicate whether the item contains a value.
 *
 * @param {*} item
 *
 * @returns {boolean}
 */
function isPresent(item) {
    return !isMissing(item);
}

/**
 * Make a selector out of an array of attributes.
 *
 * @param {string[]} attributes
 *
 * @returns {string}
 */
function attributeSelector(attributes) {
    return '[' + attributes.join('], [') + ']';
}

// ============================================================================
// Function definitions - URL
// ============================================================================

/**
 * Extract the URL present in *arg*.
 *
 * @param {Event|Location|object|string} arg
 *
 * @returns {string}
 */
function extractUrl(arg) {
    var path;
    if (arg instanceof Event) {
        // If *arg* is a HashChangeEvent then newURL will be present.
        // (Checking for "instanceof" is avoided because of MS IE.)
        // noinspection JSUnresolvedVariable
        path = arg.target ? arg.target.href : arg.newURL;

    } else if (arg instanceof Location) {
        // The full path including hash.
        path = arg.href;

    } else if (typeof arg === 'object') {
        // Microsoft Edge seems to return location as a simple Object.
        path = arg.href;

    } else if (typeof arg === 'string') {
        // Assumedly the caller is expecting a URL.
        path = arg;
    }
    return path || '';
}

// ============================================================================
// Function definitions - Accessibility
// ============================================================================

/**
 * @constant {string[]}
 */
var FOCUS_ELEMENTS =
    ['a', 'area', 'button', 'input', 'select', 'textarea'];

/**
 * @constant {string}
 */
var FOCUS_ELEMENTS_SELECTOR = FOCUS_ELEMENTS.join(', ');

/**
 * @constant {string[]}
 */
var FOCUS_ATTRIBUTES =
    ['href', 'controls', 'data-path', 'draggable', 'tabindex'];

/**
 * @constant {string}
 */
var FOCUS_ATTRIBUTES_SELECTOR = attributeSelector(FOCUS_ATTRIBUTES);

/**
 * @constant {string}
 */
var FOCUS_SELECTOR =
    FOCUS_ELEMENTS_SELECTOR + ', ' + FOCUS_ATTRIBUTES_SELECTOR;

/**
 * @constant {string[]}
 */
var NO_FOCUS_ATTRIBUTES = ['tabindex="-1"'];

/**
 * @constant {string}
 */
var NO_FOCUS_SELECTOR = attributeSelector(NO_FOCUS_ATTRIBUTES);

/**
 * Indicate whether the element referenced by the selector can have tab focus.
 *
 * @param {Selector} element
 *
 * @returns {boolean}
 */
function focusable(element) {
    return isPresent($(element).filter(FOCUS_SELECTOR).not(NO_FOCUS_SELECTOR));
}
