// app/assets/javascripts/shared/definitions.js

// ============================================================================
// JSDoc type definitions
// ============================================================================

/**
 * @typedef {string|jQuery|HTMLElement|EventTarget} Selector
 */

// ============================================================================
// Basic values and enumerations
// ============================================================================

/**
 * Milliseconds per second.
 *
 * @constant
 * @type {number}
 */
const SECOND = 1000;

/**
 * Alias for SECOND.
 *
 * @constant
 * @type {number}
 */
const SECONDS = SECOND;

// ============================================================================
// Functions - Math
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
// Functions - Enumerables
// ============================================================================

/**
 * Create an array to hold the item if it is not already one.
 *
 * @param {*} item
 *
 * @returns {array}
 */
function arrayWrap(item) {
    return Array.isArray(item) ? item : [item];
}

/**
 * Render an item as a string (used in place of `JSON.stringify`).
 *
 * @param {*}      item
 * @param {number} [limit]            Maximum length of result.
 *
 * @return {string}
 */
function asString(item, limit) {
    let result = '';
    let left   = '';
    let right  = '';
    let space  = '';

    if (typeof item === 'string') {
        // A string value.
        result += item;
        left   = '"';
        right  = '"';

    } else if (!item || (typeof item !== 'object')) {
        // A numeric, boolean, undefined, or null value.
        result += item;

    } else if (Array.isArray(item)) {
        // An array object.
        result = item.map(function(v) { return asString(v) }).join(', ');
        left   = '[';
        right  = ']';

    } else if (item.hasOwnProperty('originalEvent')) {
        // JSON.stringify fails with "cyclic object value" for jQuery events.
        result = asString(item.originalEvent);

    } else {
        // A generic object.
        let pairs = function(v, k) { return `"${k}": ${asString(v)}`; };
        result = $.map(item, pairs).join(', ');
        left   = '{';
        right  = '}';
        if (result) { space = ' '; }
    }

    left  = `${left}${space}`;
    right = `${space}${right}`;
    if (limit && (limit < (result.length + left.length + right.length))) {
        const omit = '...';
        const max  = limit - omit.length - left.length - right.length;
        result = (max > 0) ? result.substr(0, max) : '';
        result += omit;
    }
    return left + result + right;
}

// noinspection FunctionWithMultipleReturnPointsJS
/**
 * Generate a copy of the item without blank elements.
 *
 * @param {Array|object|string|*} item
 *
 * @return {Array|object|string|*}
 */
function compact(item) {
    if (typeof item === 'string') {
        return item.trim();

    } else if (Array.isArray(item)) {
        let arr = [];
        item.forEach(function(v) {
            const value = compact(v);
            if (isPresent(value)) { arr.push(...arrayWrap(value)); }
        });
        return arr;

    } else if (typeof item === 'object') {
        let obj = {};
        $.each(item, function(k, v) {
            const value = compact(v);
            if (isPresent(value)) { obj[k] = value; }
        });
        return obj;

    } else {
        return item;
    }
}

/**
 * Flatten one or more nested arrays.
 *
 * @param {Array|*} item...
 *
 * @return {Array}
 */
function flatten(item) {
    let result = [];
    if (arguments.length > 1) {
        const args = Array.from(arguments);
        args.forEach(function(v) { result.push(...flatten(v)); });
    } else if (Array.isArray(item)) {
        item.forEach(function(v) { result.push(...flatten(v)); });
    } else {
        const value = (typeof item === 'string') ? item.trim() : item;
        if (value) { result.push(value); }
    }
    return result;
}

// ============================================================================
// Functions - Time and date
// ============================================================================

/**
 * Interpret *value* as a time and return milliseconds into the epoch.  If
 * *value* is missing or invalid, the current time value is returned.
 *
 * @param {Date|number} [value]
 *
 * @return {number}
 */
function timeOf(value) {
    let result;
    switch (typeof value) {
        case 'object': result = value.getTime(); break;
        case 'number': result = value;           break;
        default:       result = Date.now();      break;
    }
    return result;
}

/**
 * The number of seconds since the given timestamp was created.
 *
 * @param {Date|number} start_time     Original `Date.now()` value.
 * @param {Date|number} [time_now]     Default: `Date.now()`.
 *
 * @return {number}
 */
function secondsSince(start_time, time_now) {
    const start = timeOf(start_time);
    const now   = timeOf(time_now);
    return (now - start) / SECOND;
}

// ============================================================================
// Functions - Element values
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
    return typeof item === 'undefined';
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
        for (let property in item) {
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
    return notEmpty(item);
}

/**
 * Make a selector out of an array of attributes.
 *
 * @param {string[]} attributes
 *
 * @return {string}
 */
function attributeSelector(attributes) {
    const list = attributes.join('], [');
    return `[${list}]`;
}

// ============================================================================
// Functions - CSS
// ============================================================================

/**
 * Multiplier for Math.random().
 *
 * @constant
 * @type {number}
 */
const SIX_DIGITS = 1000000;

/**
 * Create a unique CSS class name by appending a random hex number.
 *
 * @param {string} css_class
 *
 * @return {string}
 */
function randomizeClass(css_class) {
    const random = Math.floor(Math.random() * SIX_DIGITS);
    return css_class + '-' + random.toString(16);
}

/**
 * Toggle the presence of a CSS class for one or more disjoint elements.
 *
 * @param {Selector|Selector[]} sel
 * @param {string}              cls
 * @param {boolean}             [setting]
 */
function toggleClass(sel, cls, setting) {
    arrayWrap(sel).forEach(function(e) { $(e).toggleClass(cls, setting); });
}

/**
 * Join one or more CSS class names or arrays of class names.
 *
 * @param {...string|Array} args
 *
 * @return {string}
 */
function cssClasses(...args) {
    let result = [];
    args.forEach(function(arg) {
        let values = undefined;
        if (typeof arg === 'string') {
            values = arg.trim().replace(/\s+/, ' ').split(' ');
        } else if (Array.isArray(arg)) {
            values = cssClasses(...arg);
        } else if (typeof arg === 'object') {
            values = cssClasses(...arg['class']);
        }
        if (isPresent(values)) {
            result.push(...values);
        }
    });
    return result.join(' ');
}

/**
 * Form a selector from one or more selectors or class names.
 *
 * @param {...string|Array} args
 *
 * @return {string}
 */
function selector(...args) {
    let result = [];
    cssClasses(...args).split(' ').forEach(function(v) {
        if (v === ',') {
            result.push(', ');
        } else if (v.includes(',')) {
            const parts  = v.split(',');
            const values = cssClasses(...parts).join(', ');
            result.push(values);
        } else if (v[0] === '#') {    // ID selector
            result.unshift(v);
        } else if (v[0] === '.') {    // CSS class selector
            result.push(v);
        } else {                      // CSS class
            result.push('.' + v);
        }
    });
    return result.join('').trim();
}

// ============================================================================
// Functions - HTML
// ============================================================================

/**
 * Safely transform HTML-encoded text.
 *
 * @param {string} text
 *
 * @return {string}
 */
function htmlDecode(text) {
    let str = text.toString().trim();
    let doc = str && new DOMParser().parseFromString(str, 'text/html');
    return doc && doc.documentElement.textContent;
}

/**
 * If necessary scroll the indicated element so that it is within the viewport.
 *
 * @param {Selector} element
 *
 * @return {jQuery}
 */
function scrollIntoView(element) {
    let $element = $(element);
    const rect   = $element[0].getBoundingClientRect();
    const top    = 0;
    const bottom = window.innerHeight || document.documentElement.clientHeight;
    if (rect.top < top) {
        $element[0].scrollIntoView(true);
    } else if (rect.bottom > bottom) {
        $element[0].scrollIntoView(false);
    }
    return $element;
}

/**
 * Create an HTML element.
 *
 * @param {string|ElementProperties} element
 * @param {ElementProperties}        [properties]
 *
 * @returns {jQuery}
 */
function create(element, properties) {
    const obj  = (typeof element === 'object');
    const prop = (obj ? element     : properties) || {};
    const tag  = (obj ? element.tag : element)    || 'div';

    // noinspection HtmlUnknownTag
    let $element = (tag[0] === '<') ? $(tag) : $(`<${tag}>`);
    prop.class   && $element.addClass(prop.class);
    prop.type    && $element.attr('type',  prop.type);
    prop.tooltip && $element.attr('title', prop.tooltip);

    if      (typeof prop.html  === 'string') { $element.html(prop.html);  }
    else if (typeof prop.label === 'string') { $element.text(prop.label); }
    else if (typeof prop.text  === 'string') { $element.text(prop.text);  }
    return $element;
}

// ============================================================================
// Functions - URL
// ============================================================================

/**
 * Extract the URL value associated with *arg*.
 *
 * @param {string|HashChangeEvent|Event|Location|{url: string}} arg
 *
 * @return {string}
 */
function urlFrom(arg) {
    let result = undefined;
    // noinspection IfStatementWithTooManyBranchesJS
    if (typeof arg === 'string') {      // Assumedly the caller expecting a URL
        result = arg;
    } else if ((typeof arg !== 'object') || Array.isArray(arg)) {
        // Skipping invalid argument.
    } else if (isDefined(arg.newURL)) { // HashChangeEvent
        result = arg.newURL;
    } else if (isDefined(arg.target) && isDefined(arg.target.href)) { // Event
        result = arg.target.href;
    } else if (isDefined(arg.href)) {   // Location, HTMLBaseElement
        result = arg.href;
    } else if (isDefined(arg.url)) {    // object
        result = arg.url;
    }
    return result || '';
}

/**
 * Make an object out of a URL parameter string.
 *
 * @param {string} str
 *
 * @return {object}
 */
function asParams(str) {
    let result = {};
    if (typeof str === 'string') {
        str.trim().replace(/^[?&]+/, '').split('&').forEach(function(pair) {
            let parts = pair.split('=');
            const k   = parts.shift();
            if (k) {
                result[k] = parts.join('=');
            }
        });
    } else if (typeof str === 'object') {
        result = str;
    } else {
        console.error(`asParams: cannot handle ${typeof str}: ${str}`);
    }
    return result;
}

/**
 * Return the parameters of a URL as an object.
 *
 * @param {string} [path]             Default: `window.location`.
 *
 * @return {object}
 */
function urlParameters(path) {
    const prms = path ? path.replace(/^[^?]*\?/, '') : window.location.search;
    return asParams(prms);
}

/**
 * Assemble strings and/or objects to create an absolute URL.
 *
 * @param {string|object|string[]|object[]} parts
 *
 * @return {string}
 */
function makeUrl(...parts) {
    let path   = [];
    let params = {};

    // Accumulate path parts and param parts.
    flatten(parts).forEach(function(arg) {
        if (typeof arg === 'object') {
            $.extend(params, arg);
        } else if (arg.match(/^[?&]/)) {
            $.extend(params, asParams(arg));
        } else if (arg.includes('?')) {
            let half = arg.split('?');
            path.push(half.shift());
            $.extend(params, asParams(half.join('&')));
        } else if (arg.includes('=')) {
            $.extend(params, asParams(arg));
        } else {
            path.push(arg);
        }
    });

    // Assemble the parts of the path.  If the start of the path does not
    // happen to be the first argument it will be brought to the beginning.
    let path_starter  = undefined;
    let starter_index = path.findIndex(function(v) {
        if (v.match(/^https?:/)) {
            path_starter = v;
        } else if (v.startsWith('//')) {
            path_starter = window.location.protocol + v;
        }
        return isPresent(path_starter);
    });
    if (isEmpty(path)) {
        path.push(window.location.origin + window.location.pathname);
    } else if (isMissing(path_starter)) {
        path.unshift(window.location.origin);
    } else {
        let tmp_path = [path_starter];
        tmp_path.push(...path.slice(0, starter_index));
        tmp_path.push(...path.slice(starter_index + 1));
        path = tmp_path;
    }
    let url = path.join('/');

    // Assemble the parts of the parameters.
    if (isPresent(params)) {
        url += '?';
        url += $.map(params, function(v, k) { return `${k}=${v}`; }).join('&');
    }

    return url;
}

// noinspection JSUnusedGlobalSymbols
/**
 * Provide an action for a cancel button, redirecting to the value of the
 * 'data-path' attribute if present or redirecting back otherwise.
 *
 * @param {string|Selector|Event} arg
 */
function cancelAction(arg) {
    let $button = undefined;
    let url     = undefined;
    if (typeof arg === 'object') {
        arg.stopPropagation();
        $button = $(arg.target);
    } else if (isMissing(arg)) {
        $button = $(this);
    } else if (arg.startsWith('http') || arg.startsWith('/')) {
        url     = arg;
    } else {
        $button = $(arg);
    }
    if (!url && isPresent($button)) {
        // noinspection JSObjectNullOrUndefined
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
// Functions - Events
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
// Functions - Accessibility
// ============================================================================

/**
 * Tags of elements that can receive focus.
 *
 * @constant
 * @type {string[]}
 */
const FOCUS_ELEMENTS = ['a', 'area', 'button', 'input', 'select', 'textarea'];

/**
 * Selector for FOCUS_ELEMENTS elements.
 *
 * @constant
 * @type {string}
 */
const FOCUS_ELEMENTS_SELECTOR = FOCUS_ELEMENTS.join(', ');

/**
 * Attributes indicating that an element should receive focus.
 *
 * @constant
 * @type {string[]}
 */
const FOCUS_ATTRIBUTES =
    ['href', 'controls', 'data-path', 'draggable', 'tabindex'];

/**
 * Selector for FOCUS_ATTRIBUTES elements.
 *
 * @constant
 * @type {string}
 */
const FOCUS_ATTRIBUTES_SELECTOR = attributeSelector(FOCUS_ATTRIBUTES);

/**
 * Selector for focusable elements.
 *
 * @constant
 * @type {string}
 */
const FOCUS_SELECTOR =
    FOCUS_ELEMENTS_SELECTOR + ', ' + FOCUS_ATTRIBUTES_SELECTOR;

/**
 * Attributes indicating that an element should NOT receive focus.
 *
 * @constant
 * @type {string[]}
 */
const NO_FOCUS_ATTRIBUTES = ['tabindex="-1"'];

/**
 * Selector for focusable elements that should not receive focus.
 *
 * @constant
 * @type {string}
 */
const NO_FOCUS_SELECTOR = attributeSelector(NO_FOCUS_ATTRIBUTES);

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
 */
function handleKeypressAsClick(selector, direct, match, except) {

    /**
     * Determine the target(s) based on the *direct* argument.
     *
     * @type {jQuery}
     */
    let $elements = (typeof selector === 'number') ? $(this) : $(selector);

    // Apply match criteria to select all elements that would be expected to
    // receive a keypress based on their attributes.
    let criteria = [];
    if (match && (typeof match === 'string')) {
        criteria.push(match);
    } else if (direct || (match === true) || notDefined(match)) {
        criteria.push(FOCUS_ATTRIBUTES_SELECTOR);
    }
    if (isPresent(criteria)) {
        const sel = criteria.join(', ');
        $elements = direct ? $elements.filter(sel) : $elements.find(sel);
    }

    // Ignore elements that won't be reached by tabbing to them.
    let exceptions = [NO_FOCUS_SELECTOR];
    if (except && (typeof except === 'string')) {
        exceptions.push(except);
    }
    if (isPresent(exceptions)) {
        $elements = $elements.not(exceptions.join(', '));
    }

    // Attach the handler to any remaining elements, ensuring that the
    // handler is not added twice.
    return handleEvent($elements, 'keydown', handleKeypress);

    // noinspection FunctionWithMultipleReturnPointsJS, FunctionWithInconsistentReturnsJS
    /**
     * Translate a carriage return to a click, except for links (where the
     * key press will be handled by the browser itself).
     *
     * @param {KeyboardEvent} event
     *
     * @return {boolean}
     */
    function handleKeypress(event) {
        const key = event && event.key;
        if (key === 'Enter') {
            let $target = $(event.target || this);
            const href  = $target.attr('href');
            if (!href || (href === '#')) {
                $target.click().focusin();
                return false;
            }
        }
    }
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

// noinspection JSUnusedGlobalSymbols
/**
 * The focusable elements contained within *element*.
 *
 * @param {Selector} element
 *
 * @return {jQuery}
 */
function focusableIn(element) {
    return $(element).find(FOCUS_SELECTOR).not(NO_FOCUS_SELECTOR);
}

// ============================================================================
// Functions - Browser
// ============================================================================

/**
 * Indicate whether the client browser is MS Internet Explorer.
 *
 * @returns {boolean}
 */
function isInternetExplorer() {
    // noinspection PlatformDetectionJS
    const ua = navigator.userAgent || '';
    return ua.includes('MSIE ') || ua.includes('Trident/');
}
