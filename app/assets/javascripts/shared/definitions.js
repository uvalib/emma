// app/assets/javascripts/shared/definitions.js

// ============================================================================
// Basic values and enumerations
// ============================================================================

/** @constant {number} */
var SECOND = 1000; // milliseconds

/** @constant {number} */
var SECONDS = SECOND;

/**
 * Key codes.
 *
 * @readonly
 * @enum {number}
 */
var CHAR = {
    Backspace:  8,
    Tab:        9,
    Enter:      13,
    Shift:      16,
    Ctrl:       17,
    Alt:        18,
    CapsLock:   20,
    Escape:     27,
    Space:      32,
    PageUp:     33,
    PageDown:   34,
    End:        35,
    Home:       36,
    ArrowLeft:  37,
    ArrowUp:    38,
    ArrowRight: 39,
    ArrowDown:  40,
    Insert:     45,
    Delete:     46
};

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
// Function definitions - Enumerables
// ============================================================================

//noinspection FunctionWithMultipleReturnPointsJS
/**
 * Generate a copy of the array without blank elements.
 *
 * @param {Array|object|string|*} item
 *
 * @return {Array|object|string|*}
 */
function compact(item) {
    if (item instanceof Array) {
        return compactArray(item);
    } else if (typeof item === 'object') {
        return compactObject(item);
    } else if (typeof item === 'string') {
        return item.trim();
    } else {
        return item;
    }
}

/**
 * Generate a copy of the array without blank elements.
 *
 * @param {Array} item
 *
 * @return {Array}
 */
function compactArray(item) {
    var result = [];
    item.forEach(function(v) {
        var value = compact(v);
        if (isPresent(value)) { result.push(value); }
    });
    return result;
}

/**
 * Generate a copy of the array without blank elements.
 *
 * @param {object} item
 *
 * @return {object}
 */
function compactObject(item) {
    var result = {};
    $.each(item, function(k, v) {
        var value = compact(v);
        if (isPresent(value)) { result[k] = value; }
    });
    return result;
}

// ============================================================================
// Function definitions - Math
// ============================================================================

/**
 * Return the percentage of part in total.
 *
 * @param {number} part
 * @param {number} total
 *
 * @return {number}
 */
function percent(part, total) {
    // noinspection MagicNumberJS
    return total ? ((part / total) * 100) : 0;
}

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

// noinspection JSUnusedGlobalSymbols
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

/**
 * Make a selector out of an array of attributes.
 *
 * @param {string[]} attributes
 *
 * @return {string}
 */
function attributeSelector(attributes) {
    return '[' + attributes.join('], [') + ']';
}

// ============================================================================
// Function definitions - HTML
// ============================================================================

/**
 * Safely transform HTML-encoded text.
 *
 * @param {string} text
 *
 * @return {string}
 */
function htmlDecode(text) {
    var res = '';
    var str = text.toString().trim();
    if (str) {
        var doc = new DOMParser().parseFromString(str, 'text/html');
        res = doc.documentElement.textContent;
    }
    return res;
}

// ============================================================================
// Function definitions - URL
// ============================================================================

/**
 * Extract the URL present in *arg*.
 *
 * @param {Event|Location|object|string} arg
 *
 * @return {string}
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

// noinspection JSUnusedGlobalSymbols
/**
 * Provide an action for a cancel button, redirecting to the value of the
 * 'data-path' attribute if present or redirecting back otherwise.
 *
 * @param {string|Selector|Event} arg
 */
function cancelAction(arg) {
    var $button, url;
    if (typeof arg === 'object') {
        arg.stopPropagation();
        $button = $(arg.target);
    } else if (isMissing(arg)) {
        $button = $(this);
    } else if (arg.indexOf('http') === 0) {
        url     = arg;
    } else if (arg.indexOf('/') === 0) {
        url     = arg;
    } else {
        $button = $(arg);
    }
    if (!url && isPresent($button)) {
        url = $button.attr('data-path');
    }
    if (!url && window.location.search && !window.history.length) {
        url = window.location.pathname;
    }
    if (url === window.location.href) {
        window.location.reload();
    } else if (url) {
        window.location.href = url;
    } else {
        window.history.back();
    }
}

// ============================================================================
// Function definitions - Events
// ============================================================================

/**
 * Set an event handler without concern that it may already set.
 *
 * @param {jQuery}   $element
 * @param {string}   name             Event name.
 * @param {function} func             Event handler.
 *
 * @return {jQuery}
 */
function handleEvent($element, name, func) {
    return $element.off(name, func).on(name, func);
}

/**
 * Set click and keypress event handlers without concern that it may already
 * set.
 *
 * @param {jQuery}   $element
 * @param {function} func             Event handler.
 *
 * @return {jQuery}
 */
function handleClickAndKeypress($element, func) {
    return handleEvent($element, 'click', func).each(handleKeypressAsClick);
}

// ============================================================================
// Function definitions - Accessibility
// ============================================================================

/** @constant {string[]} */
var FOCUS_ELEMENTS = ['a', 'area', 'button', 'input', 'select', 'textarea'];

/** @constant {string} */
var FOCUS_ELEMENTS_SELECTOR = FOCUS_ELEMENTS.join(', ');

/** @constant {string[]} */
var FOCUS_ATTRIBUTES =
    ['href', 'controls', 'data-path', 'draggable', 'tabindex'];

/** @constant {string} */
var FOCUS_ATTRIBUTES_SELECTOR = attributeSelector(FOCUS_ATTRIBUTES);

/** @constant {string} */
var FOCUS_SELECTOR =
    FOCUS_ELEMENTS_SELECTOR + ', ' + FOCUS_ATTRIBUTES_SELECTOR;

/** @constant {string[]} */
var NO_FOCUS_ATTRIBUTES = ['tabindex="-1"'];

/** @constant {string} */
var NO_FOCUS_SELECTOR = attributeSelector(NO_FOCUS_ATTRIBUTES);

/** @constant {string} */
var KEYPRESS_PROP = 'keypress-click';

/**
 * For "buttons" or "links" which are not <a> tags (or otherwise don't
 * respond by default to a carriage return as an equivalent to a click).
 *
 * @param {Selector}       selector  Specification of node(s) containing
 *                                     elements which must respond to a
 *                                     carriage return like a mouse click.
 *
 * @param {boolean}        [direct]  If *true* then the target is the nodes
 *                                     indicated by *selector* and not the
 *                                     descendents of those nodes.
 *
 * @param {string|boolean} [match]   If *false* then $(selector) specifies
 *                                     the target elements directly; if
 *                                     *true* or missing then all focusable
 *                                     elements at or below $(selector) are
 *                                     chosen; if a string then it is used
 *                                     instead of FOCUS_ATTRIBUTES_SELECTOR
 *
 * @param {string|boolean} [except]  If *false* then all matches are
 *                                     chosen; otherwise elements matching
 *                                     FOCUS_ELEMENTS_SELECTOR are
 *                                     eliminated.  In either case,
 *                                     elements with tabindex == -1 are
 *                                     skipped. Default: elements like <a>.
 *
 * @return {jQuery}
 *
 * @see {@link nodeHandleKeypressAsClick}
 * @see {@link treeHandleKeypressAsClick}
 */
function handleKeypressAsClick(selector, direct, match, except) {

    /**
     * Determine the target(s) based on the *direct* argument.
     *
     * @type {jQuery}
     */
    var $elements = (typeof selector === 'number') ? $(this) : $(selector);

    // Apply match criteria to select all elements that would be expected to
    // receive a keypress based on their attributes.
    var criteria = [];
    if (match && (typeof match === 'string')) {
        criteria.push(match);
    } else if (direct || (match === true) || notDefined(match)) {
        criteria.push(FOCUS_ATTRIBUTES_SELECTOR);
    }
    if (isPresent(criteria)) {
        var sel = criteria.join(', ');
        $elements = direct ? $elements.filter(sel) : $elements.find(sel);
    }

    // Ignore elements that won't be reached by tabbing to them.
    var exceptions = [NO_FOCUS_SELECTOR];
    if (except && (typeof except === 'string')) {
        exceptions.push(except);
    }
    if (isPresent(exceptions)) {
        $elements = $elements.not(exceptions.join(', '));
    }

    // Attach the handler to any remaining elements, ensuring that the
    // handler is not added twice.

    function handler(event) {
        var key = event.keyCode || event.which;
        if (key === CHAR.Enter) {
            var $target  = $(event.target || this);
            var href     = $target.attr('href');
            if (!href || (href === '#')) {
                $target.prop(KEYPRESS_PROP, key).click().focusin();
                return false;
            }
        }
    }

    return handleEvent($elements, 'keydown', handler);
}

/**
 * Indicate whether the element referenced by the selector can have tab focus.
 *
 * @param {Selector} element
 *
 * @return {boolean}
 */
function focusable(element) {
    return isPresent($(element).filter(FOCUS_SELECTOR).not(NO_FOCUS_SELECTOR));
}
