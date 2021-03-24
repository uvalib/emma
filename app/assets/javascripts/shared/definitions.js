// app/assets/javascripts/shared/definitions.js

// ============================================================================
// JSDoc type definitions
// ============================================================================

/**
 * @typedef {string|jQuery|HTMLElement|EventTarget} Selector
 */

/**
 * @typedef {Selector|Event|jQuery.Event} SelectorOrEvent
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

/**
 * Kilobyte multiplier.
 *
 * @constant
 * @type {number}
 */
const K = 1024;

/**
 * HTTP response codes.
 *
 * @constant
 * @type {object}
 */
const HTTP = Object.freeze({
    ok:                     200,
    created:                201,
    accepted:               202,
    non_authoritative:      203,
    no_content:             204,
    multiple_choices:       300,
    moved_permanently:      301,
    found:                  302,
    not_modified:           304,
    temporary_redirect:     307,
    permanent_redirect:     308,
    bad_request:            400,
    unauthorized:           401,
    forbidden:              403,
    request_timeout:        408,
    conflict:               409,
    internal_server_error:  500,
    not_implemented:        501,
    bad_gateway:            502,
    service_unavailable:    503,
    gateway_timeout:        504,
});

// ============================================================================
// Functions - Math
// ============================================================================

/**
 * Return the percentage of part in total.
 *
 * @param {number} part
 * @param {number} total
 *
 * @returns {number}
 */
function percent(part, total) {
    // noinspection MagicNumberJS
    return total ? ((part / total) * 100) : 0;
}

/**
 * Show the given value as a multiple of 1024.
 *
 * @param {number|string} value
 * @param {boolean}       [full]      If *true*, show full unit name.
 *
 * @returns {string}                  Blank if *value* is not a number.
 */
function asSize(value, full) {
    const n = Number.parseFloat(value);
    if (!n && (n !== 0)) {
        return '';
    }
    let i = 0;
    // noinspection OverlyComplexBooleanExpressionJS, IncrementDecrementResultUsedJS
    let magnitude =
        ((n < Math.pow(K, ++i)) && i) || // B
        ((n < Math.pow(K, ++i)) && i) || // KB
        ((n < Math.pow(K, ++i)) && i) || // MB
        ++i;                             // GB
    magnitude--;
    const size_name = ['Bytes', 'Kilobytes', 'Megabytes', 'Gigabytes'];
    const size_abbr = ['B', 'KB', 'MB', 'GB'];
    const units     = full ? size_name[magnitude] : size_abbr[magnitude];
    const precision = Math.min(magnitude, 2);
    const result    = (n / Math.pow(K, magnitude)).toFixed(precision);
    return `${result} ${units}`;
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
 * Transform an object into an array of key-value pairs.
 *
 * @param {object} item
 *
 * @returns {[string, any][]}
 */
function objectEntries(item) {
    return Object.entries(item).filter(kv => item.hasOwnProperty(kv[0]));
}

/**
 * Render an item as a string (used in place of `JSON.stringify`).
 *
 * @param {*}      item
 * @param {number} [limit]            Maximum length of result.
 *
 * @returns {string}
 */
function asString(item, limit) {
    const s_quote = "'";
    const d_quote = '"';
    let result    = '';
    let left      = '';
    let right     = '';
    let space     = '';

    if (typeof item === 'string') {
        // A string value.
        result += item;
        if ((item[0] !== s_quote) && (item[0] !== d_quote)) {
            left = right = d_quote;
        }

    } else if (typeof item === 'boolean') {
        // A true/false value.
        result += item.toString();

    } else if (typeof item === 'number') {
        // A numeric, NaN, or Infinity value.
        result += (item || (item === 0)) ? item.toString() : 'null';

    } else if (item instanceof Date) {
        // A date value.
        result += asDateTime(item);
        left = right = d_quote;

    } else if (!item) {
        // Undefined or null value.
        result += 'null';

    } else if (Array.isArray(item)) {
        // An array object.
        result = item.map(v => asString(v)).join(', ');
        left   = '[';
        right  = ']';

    } else if (item.hasOwnProperty('originalEvent')) {
        // JSON.stringify fails with "cyclic object value" for jQuery events.
        result = asString(item.originalEvent);

    } else {
        // A generic object.
        let pr = objectEntries(item);
        result = pr.map(kv => `"${kv[0]}": ${asString(kv[1])}`).join(', ');
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

/**
 * Generate an object from JSON (used in place of `JSON.parse`).
 *
 * @param {*}      item
 * @param {string} [caller]           For log messages.
 *
 * @returns {object|undefined}
 */
function fromJSON(item, caller) {
    const func = caller || 'fromJSON';
    let result = undefined;
    if (typeof item == 'object') {
        result = item;
    } else if (typeof item === 'string') {
        try {
            result = JSON.parse(item);
        }
        catch (err) {
            console.warn(`${func}: ${err} - item:`, item);
        }
    }
    return result;
}

/**
 * Generate a copy of the item without blank elements.
 *
 * @param {Array|object|string|*} item
 * @param {boolean}               [trim]    If *false*, don't trim white space.
 *
 * @returns {Array|object|string|*}
 */
function compact(item, trim) {
    if (typeof item === 'string') {
        return (trim === false) ? item : item.trim();

    } else if (Array.isArray(item)) {
        return item.map(v => compact(v, trim)).filter(v => isPresent(v));

    } else if (typeof item === 'object') {
        let pr = objectEntries(item).map(kv => [kv[0], compact(kv[1], trim)]);
        return Object.fromEntries(pr.filter(kv => isPresent(kv[1])));

    } else {
        return item;
    }
}

/**
 * Flatten one or more nested arrays.
 *
 * @param {Array|*} item...
 *
 * @returns {Array}
 */
function flatten(item) {
    let result = [];
    if (arguments.length > 1) {
        Array.from(arguments).forEach(v => result.push(...flatten(v)));
    } else if (Array.isArray(item)) {
        item.forEach(v => result.push(...flatten(v)));
    } else {
        const value = (typeof item === 'string') ? item.trim() : item;
        if (value) { result.push(value); }
    }
    return result;
}

/**
 * Make a completely frozen copy of an item.
 *
 * @param {Array|object|*} item       Source item (which will be unaffected).
 *
 * @returns {Array|object|*}          An immutable copy of *item*.
 */
function deepFreeze(item) {
    let new_item;
    if (Array.isArray(item)) {
        new_item = item.map(v => deepFreeze(v));
    } else if (typeof item === 'object') {
        let prs  = objectEntries(item).map(kv => [kv[0], deepFreeze(kv[1])]);
        new_item = Object.fromEntries(prs);
    } else {
        new_item = item;
    }
    return Object.freeze(new_item);
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
 * @returns {number}
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
 * @returns {number}
 */
function secondsSince(start_time, time_now) {
    const start = timeOf(start_time);
    const now   = timeOf(time_now);
    return (now - start) / SECOND;
}

/**
 * Show the given date value as "YYYY-MM-DD hh:mm:ss".
 *
 * @param {string|number|Date} value
 * @param {object}             [opt]
 *
 * @param {string}  [opt.separator]  Default: ' '.
 * @param {boolean} [opt.dateOnly]   If *true* do not show time.
 * @param {boolean} [opt.timeOnly]   If *true* do not show date.
 *
 * @returns {string}                        Blank if *value* is not a date.
 *
 * @see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat/DateTimeFormat
 */
function asDateTime(value, opt = {}) {
    const separator  = opt.separator || ' ';
    const date_value = (value instanceof Date) ? value : new Date(value);
    let date, time;
    if (date_value.getFullYear()) {
        if (opt.dateOnly || !opt.timeOnly) {
            let parts = date_value.toLocaleDateString('en-GB').split('/');
            date = [parts.pop(), ...parts].join('-');
        }
        if (opt.timeOnly || !opt.dateOnly) {
            time = date_value.toLocaleTimeString([], { hour12: false });
        }
    }
    return compact([date, time]).join(separator);
}

// ============================================================================
// Functions - Element values
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
    return typeof item === 'undefined';
}

/**
 * Indicate whether the item does not contain a value.
 *
 * @param {*} item
 *
 * @returns {boolean}
 */
function isEmpty(item) {
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
    return notEmpty(item);
}

/**
 * Indicate whether the item is an Event or jQuery.Event.
 *
 * @param {*} item
 *
 * @returns {boolean}
 */
function isEvent(item) {
    return (item instanceof Event) || (item instanceof jQuery.Event);
}

/**
 * Make a selector out of an array of attributes.
 *
 * @param {string[]} attributes
 *
 * @returns {string}
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
 * @returns {string}
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
    arrayWrap(sel).forEach(element => $(element).toggleClass(cls, setting));
}

/**
 * Normalize singletons and/or arrays of CSS class names.
 *
 * @param {...string|Array} args
 *
 * @returns {string[]}
 */
function cssClasses(...args) {
    let result = [];
    args.forEach(function(arg) {
        let values = undefined;
        if (typeof arg === 'string') {
            values = arg.trim().replace(/\s+/g, ' ').split(' ');
        } else if (Array.isArray(arg)) {
            values = cssClasses(...arg);
        } else if (typeof arg === 'object') {
            values = cssClasses(arg['class']);
        }
        values = compact(values);
        if (isPresent(values)) {
            result.push(...values);
        }
    });
    return result;
}

/**
 * Join one or more CSS class names or arrays of class names with spaces.
 *
 * @param {...string|Array} args      Passed to {@link cssClasses}.
 *
 * @returns {string}
 */
function cssClass(...args) {
    return cssClasses(...args).join(' ');
}

/**
 * Form a selector from one or more selectors or class names.
 *
 * @param {...string|Array} args      Passed to {@link cssClasses}.
 *
 * @returns {string}
 */
function selector(...args) {
    const func = 'selector';
    let result = [];
    args.forEach(function(arg) {
        let entry;
        if (isEmpty(arg)) {
            console.warn(`${func}: skipping empty ${typeof arg} = ${arg}`);

        } else if (Array.isArray(arg)) {
            entry = arg.map(v => v.trim().replace(/\s*,$/, ''));
            entry = entry.map(v => v.startsWith('.') ? v : `.${v}`);
            entry = entry.join(', ');

        } else if (typeof arg === 'object') {
            entry = selector(arg['class']);

        } else if (typeof arg !== 'string') {
            console.warn(`${func}: ignored ${typeof arg} = ${arg}`);

        } else if (arg === ',') {
            entry = ', ';

        } else if (arg.includes(',')) {
            entry = arg.trim().replace(/\s*,\s*/g, ',').split(',');
            entry = cssClasses(...entry);
            entry = entry.map(v => v.startsWith('.') ? v : `.${v}`);
            entry = entry.join(', ');

        } else if (arg[0] === '#') {    // ID selector
            result.unshift(arg);

        } else if (arg[0] === '.') {    // CSS class selector
            entry = arg;

        } else {                        // CSS class
            entry = `.${arg}`;
        }
        entry = compact(entry);
        if (isPresent(entry)) {
            result.push(entry);
        }
    });
    return result.join('').trim();
}

/**
 * Return an identifying selector for an element -- based on the element ID if
 * it has one.
 *
 * @param {jQuery|HTMLElement} element
 *
 * @returns {string}
 */
function elementSelector(element) {
    let e = $(element)[0];
    if (e.id) {
        return `#${e.id}`;
    } else if (e.className) {
        return e.localName + '.' + e.className.replace(/\s+/g, '.');
    } else {
        return e.localName;
    }
}

// ============================================================================
// Functions - HTML
// ============================================================================

/**
 * Safely transform HTML-encoded text.
 *
 * @param {string} text
 *
 * @returns {string}
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
 * @returns {jQuery}
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
 * @param {string|Event|jQuery.Event|Location|{url: string}} arg
 *
 * @returns {string}
 */
function urlFrom(arg) {
    let result = undefined;
    if (typeof arg === 'string') {      // Assumedly the caller expecting a URL
        result = arg;
    } else if ((typeof arg !== 'object') || Array.isArray(arg)) {
        // Skipping invalid argument.
    } else if (isDefined(arg.target)) { // Event or jQuery.Event
        const event = isDefined(arg.originalEvent) && arg.originalEvent || arg;
        result = isDefined(event.newURL) ? event.newURL : event.target.href;
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
 * @param {string|object} item
 *
 * @returns {object}
 */
function asParams(item) {
    const func = 'asParams';
    let result = {};
    if (typeof item === 'string') {
        item.trim().replace(/^[?&]+/, '').split('&').forEach(function(pair) {
            let kv = decodeURIComponent(pair).split('=');
            let k  = kv.shift();
            let v  = kv.join('=');
            if (k && v) {
                const array = k.endsWith('[]');
                if (array) {
                    k = k.replace('[]', '');
                }
                if (notDefined(result[k])) {
                    result[k] = array ? [v] : v;
                } else if (Array.isArray(result[k])) {
                    result[k] = [...result[k], v];
                } else {
                    result[k] = [result[k], v];
                }
            }
        });
    } else if (typeof item !== 'object') {
        console.error(`${func}: cannot handle ${typeof item}: ${item}`);
    } else if (isDefined(item.search)) {
        result = item.search; // E.g., `window.location`.
    } else {
        result = item;
    }
    return result;
}

/**
 * Return the parameters of a URL as an object.
 *
 * @param {string} [path]             Default: `window.location`.
 *
 * @returns {object}
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
 * @returns {string}
 */
function makeUrl(...parts) {
    const func = 'makeUrl';
    let path   = [];
    let params = {};
    let path_starter;
    let starter_index = 0;

    // Accumulate path parts and param parts.
    parts.forEach(processPart);

    // noinspection FunctionWithInconsistentReturnsJS, OverlyComplexFunctionJS
    /**
     * @param {string|string[]|object} arg
     *
     * NOTE: Return value is ignored.
     */
    function processPart(arg) {
        let part, starter, preserve;
        if (typeof arg === 'string') {
            part = arg.trim();
        } else if (Array.isArray(arg)) {
            return arg.forEach(processPart);
        } else if (typeof arg === 'object') {
            return $.extend(params, arg);
        }
        if (!part) {
            return;

        } else if (part === '//') {
            // A token which distinctly denotes the beginning of a URL but is
            // without the leading protocol portion.
            starter = window.location.protocol + part;

        } else if (part.startsWith('//')) {
            // A URL fragment without the leading protocol portion.
            processPart(window.location.protocol);
            processPart(part.replace(/^../, ''));
            return;

        } else if (part.startsWith('javascript:')) {
            // Show this as-is (although it probably shouldn't be seen here).
            starter  = part;
            preserve = true;

        } else if ((part === 'https://') || (part === 'http://')) {
            starter = part;

        } else if ((part === 'https:') || (part === 'http:')) {
            starter = part + '//';

        } else if (part.startsWith('https:') || part.startsWith('http:')) {
            // Full URL with leading protocol ("https://host/path?params").
            let parts = part.split('//');
            processPart(parts.shift());    // Protocol portion.
            processPart(parts.join('//')); // Remainder of the argument.
            return;

        } else if (part.includes('?')) {
            let parts = part.split('?');
            parts.shift().split('/').forEach(processPart); // Path portion.
            $.extend(params, asParams(parts.join('&')));   // Params portion.
            return;

        } else if (part.includes('&') || part.includes('=')) {
            return $.extend(params, asParams(part));

        } else if (part.includes('/')) {
            return part.split('/').forEach(processPart);
        }

        if (starter && path_starter) {
            // Invalid arguments supplied.
            console.warn(`${func}: second URL starter "${arg}"`);

        } else if (starter) {
            // Prepare leading URL part (ending with "//") so that the right
            // number of slashes remain when joined below.
            if (preserve) {
                part = starter;
            } else {
                part = starter.replace(/\/\/$/, '/').trim();
            }
            path_starter  = part;
            starter_index = path.length;

        } else if (!preserve) {
            // Remove leading and trailing slash(es), if any.
            part = part.replace(/^\/+/, '').replace(/\/+$/, '').trim();
        }

        if (part) {
            path.push(part);
        }
    }

    // Assemble the parts of the path.  If the start of the path does not
    // happen to be the first argument it will be brought to the beginning.
    if (isEmpty(path)) {
        path.push(window.location.origin + window.location.pathname);
    } else if (!path_starter) {
        path.unshift(window.location.origin);
    } else {
        let tmp_path = [path_starter];
        tmp_path.push(path.slice(0, starter_index));
        tmp_path.push(path.slice(starter_index + 1));
        path = tmp_path;
    }

    // Assemble the parts of the parameters.
    let url = path.join('/');
    params = compact(params);
    if (isPresent(params)) {
        url += '?' + $.map(params, (v,k) => `${k}=${v}`).join('&');
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
    let button;
    if (notDefined(arg)) {
        button = this;
    } else if (typeof arg === 'object') {
        arg.stopPropagation();
        arg.preventDefault();
        button = arg.target;
    } else if (arg && !arg.match(/^back$|^\/|^https?:|^javascript:/i)) {
        button = arg;
    }
    let url = button ? $(button).attr('data-path') : arg;
    if ((url === 'back') || (url === 'BACK')) {
        url = '';                       // Previous page.
    } else if (!url && window.location.search && !window.history.length) {
        url = window.location.pathname; // Current page with no URL parameters.
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
 * The default delay for {@link debounce}.
 *
 * @constant
 * @type {number}
 */
const DEBOUNCE_DELAY = 250; // milliseconds

/**
 * Generate a wrapper function which executes the callback function only after
 * the indicated delay.
 *
 * @param {function} callback
 * @param {number}   [wait]           Default: {@link DEBOUNCE_DELAY}.
 *
 * @returns {function}
 */
function debounce(callback, wait) {
    let delay = wait || DEBOUNCE_DELAY; // milliseconds
    let timeout;
    return function() {
        let _this = this;
        let args  = arguments;
        clearTimeout(timeout);
        timeout = setTimeout(function() {
            timeout = null;
            callback.apply(_this, args);
        }, delay);
    }
}

/**
 * Set an event handler without concern that it may already set.
 *
 * @param {jQuery}                 $element
 * @param {string}                 name     Event name.
 * @param {function(jQuery.Event)} func     Event handler.
 *
 * @returns {jQuery}
 */
function handleEvent($element, name, func) {
    return $element.off(name, func).on(name, func);
}

/**
 * Set click and keypress event handlers without concern that it may already
 * set.
 *
 * @param {jQuery}                 $element
 * @param {function(jQuery.Event)} func     Event handler.
 *
 * @returns {jQuery}
 */
function handleClickAndKeypress($element, func) {
    return handleEvent($element, 'click', func).each(handleKeypressAsClick);
}

/**
 * Set hover and focus event handlers.
 *
 * @param {jQuery}                 $element
 * @param {function(jQuery.Event)} funcEnter    Event handler for 'enter'.
 * @param {function(jQuery.Event)} [funcLeave]  Event handler for 'leave'.
 */
function handleHoverAndFocus($element, funcEnter, funcLeave) {
    if (funcEnter) {
        handleEvent($element, 'mouseenter', funcEnter);
        handleEvent($element, 'focus',      funcEnter);
    }
    if (funcLeave) {
        handleEvent($element, 'mouseleave', funcLeave);
        handleEvent($element, 'blur',       funcLeave);
    }
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
const FOCUS_ELEMENTS =
    deepFreeze(['a', 'area', 'button', 'input', 'select', 'textarea']);

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
    deepFreeze(['href', 'controls', 'data-path', 'draggable', 'tabindex']);

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
const NO_FOCUS_ATTRIBUTES = deepFreeze(['tabindex="-1"']);

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
 * @returns {jQuery}
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

    // noinspection FunctionWithInconsistentReturnsJS
    /**
     * Translate a carriage return to a click, except for links (where the
     * key press will be handled by the browser itself).
     *
     * @param {jQuery.Event|KeyboardEvent} event
     *
     * @returns {boolean}
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
 * Allow a click anywhere within the element holding a label/button pair
 * to be delegated to the enclosed input.  This broadens the "click target"
 * and allows clicks in the "void" between the input and the label to be
 * associated with the input element that the user intended to click.
 *
 * @param {Selector} element
 */
function delegateInputClick(element) {

    const func   = 'delegateInputClick';
    let $element = $(element);
    let $input   = $element.find('[type="radio"],[type="checkbox"]');
    const count  = $input.length;

    if (count < 1) {
        console.error(`${func}: no targets within:`);
        console.log(element);
        return;
    } else if (count > 1) {
        console.warn(`${func}: ${count} targets`);
    }

    handleClickAndKeypress($element, function(event) {
        if (event.target !== $input[0]) {
            event.preventDefault();
            $input.click();
        }
    });
}

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

// noinspection JSUnusedGlobalSymbols
/**
 * The focusable elements contained within *element*.
 *
 * @param {Selector} element
 *
 * @returns {jQuery}
 */
function focusableIn(element) {
    return $(element).find(FOCUS_SELECTOR).not(NO_FOCUS_SELECTOR);
}

/**
 * Hide/show elements by adding/removing the CSS "invisible" class.
 *
 * If *visible* is not given then visibility is toggled to the opposite state.
 *
 * @param {Selector} element
 * @param {boolean}  [visible]
 *
 * @returns {boolean} If *true* then *element* is becoming visible.
 */
function toggleVisibility(element, visible) {
    const invisibility_marker = 'invisible';
    let $element = $(element);
    let make_visible, hidden, visibility;
    if (isDefined(visible)) {
        make_visible = visible;
    } else if (isDefined((hidden = $.attr('aria-hidden')))) {
        make_visible = hidden && (hidden !== 'false');
    } else if (isDefined((visibility = $element.css('visibility')))) {
        make_visible = (visibility === 'hidden');
    } else {
        make_visible = $element.hasClass(invisibility_marker);
    }
    $element.toggleClass(invisibility_marker, !make_visible);
    $element.attr('aria-hidden', !make_visible);
    return make_visible;
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

// ============================================================================
// Functions - Turbolinks
// ============================================================================

const DEBUG_TURBOLINKS = true;

// noinspection ES6ConvertVarToLetConst
/*var $document = $(document);*/

if (DEBUG_TURBOLINKS) {
    [
        'click',
        'before-visit',
        'visit',
        'request-start',
        'request-end',
        'before-cache',
        'before-render',
        'render',
        'load',
    ].forEach(function(name) {
        const event_name = `turbolinks:${name}`;
        handleEvent($(document), event_name, function() {
            console.warn(`========== ${event_name} ==========`);
        });
    });
}
