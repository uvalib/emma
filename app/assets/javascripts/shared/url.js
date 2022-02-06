// app/assets/javascripts/shared/url.js


import { compact } from '../shared/objects'
import {
    isDefined,
    isEmpty,
    isPresent,
    notDefined,
} from '../shared/definitions'


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
export function urlFrom(arg) {
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
export function asParams(item) {
    const func = 'asParams';
    let result = {};
    if (typeof item === 'string') {
        item.trim().replace(/^[?&]+/, '').split('&').forEach(function(pair) {
            let kv = decodeURIComponent(pair.replace('+', ' ')).split('=');
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
 * @param {string} [path]             Default: `window.location.search`.
 *
 * @returns {object}
 */
export function urlParameters(path) {
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
export function makeUrl(...parts) {
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
        tmp_path.push(...path.slice(0, starter_index));
        tmp_path.push(...path.slice(starter_index + 1));
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

/**
 * Provide an action for a cancel button, redirecting to the value of the
 * 'data-path' attribute if present or redirecting back otherwise.
 *
 * @param {string|Selector|Event} arg
 */
export function cancelAction(arg) {
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
