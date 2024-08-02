// app/assets/javascripts/shared/url.js


import { AppDebug }          from "../application/debug";
import { compact, isObject } from "./objects";
import {
    isDefined,
    isEmpty,
    isPresent,
    notDefined,
} from "./definitions";


AppDebug.file("shared/url");

// ============================================================================
// Functions
// ============================================================================

/**
 * Return the non-parameter portion of a URL (with no trailing slash).
 *
 * @param {string} [path]             Default: from `window.location`.
 *
 * @returns {string}
 */
export function baseUrl(path) {
    if (path) {
        return path.replace(/\?.*$/, "").replace(/\/+$/, "");
    } else {
        return window.location.origin + window.location.pathname;
    }
}

/**
 * Extract the URL value associated with *arg*.
 *
 * @param {string|jQuery.Event|Event|Location|{url: string}} arg
 *
 * @returns {string}
 */
export function urlFrom(arg) {
    let result;
    if (typeof arg === "string") {      // Assumedly the caller expecting a URL
        result = arg;
    } else if (!arg || (typeof arg !== "object")) {
        // Skipping invalid argument.
    } else if (isDefined(arg.target)) { // Event or jQuery.Event
        // noinspection JSValidateTypes
        /** @type {HashChangeEvent|AnchorEvt} */
        const event = arg.originalEvent || arg;
        result = event.newURL || event.target.href;
    } else if (isDefined(arg.href)) {   // Location, HTMLBaseElement
        result = arg.href;
    } else if (isDefined(arg.url)) {    // object
        result = arg.url;
    }
    return result || "";
}

/**
 * Make an object out of a URL parameter string.
 *
 * @param {string|object} item
 *
 * @returns {object}
 */
export function asParams(item) {
    const func = "asParams";
    let result = {};
    if (typeof item === "string") {
        item.trim().replace(/^[?&]+/, "").split("&").forEach(pair => {
            const kv    = decodeURIComponent(pair.replaceAll("+", " "));
            const parts = kv.split("=");
            let [k, v]  = [parts.shift(), parts.join("=")];
            if (k && v) {
                const array = k.endsWith("[]");
                if (array) {
                    k = k.replace("[]", "");
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
    } else if (!isObject(item)) {
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
    const prms = path ? path.replace(/^[^?]*\?/, "") : window.location.search;
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
    const func = "makeUrl";
    let path   = [];
    let params = {};
    let path_start, start_idx = 0;

    // noinspection FunctionTooLongJS
    /**
     * @param {string|string[]|object} arg
     *
     * @returns {undefined}           Return value is ignored.
     */
    function processPart(arg) {
        let start, keep, part;

        switch (typeof arg) {
            case "string":  part = arg.trim();  break;
            case "bigint":  part = `${arg}`;    break;
            case "number":  part = `${arg}`;    break;
            case "boolean": part = `${arg}`;    break;
            default:        part = arg;         break;
        }

        if (isEmpty(part)) {
            return;

        } else if (Array.isArray(part)) {
            return part.forEach(processPart);

        } else if (isObject(part)) {
            return Object.assign(params, part);

        } else if (typeof part !== "string") {
            return console.warn(`${func}: ignored part`, part);

        } else if (part === "//") {
            // A token which distinctly denotes the beginning of a URL but is
            // without the leading protocol portion.
            start = window.location.protocol + part;

        } else if (part.startsWith("//")) {
            // A URL fragment without the leading protocol portion.
            processPart(window.location.protocol);
            processPart(part.replace(/^../, ""));
            return;

        } else if (part.startsWith("javascript:")) {
            // Show this as-is (although it probably shouldn't be seen here).
            start = part;
            keep  = true;

        } else if ((part === "https://") || (part === "http://")) {
            start = part;

        } else if ((part === "https:") || (part === "http:")) {
            start = part + "//";

        } else if (part.startsWith("https:") || part.startsWith("http:")) {
            // Full URL with leading protocol ("https://host/path?params").
            const parts = part.split("//");
            processPart(parts.shift());    // Protocol portion.
            processPart(parts.join("//")); // Remainder of the argument.
            return;

        } else if (part.includes("?")) {
            const parts = part.split("?");
            parts.shift().split("/").forEach(processPart);    // Path portion
            Object.assign(params, asParams(parts.join("&"))); // Params portion
            return;

        } else if (part.includes("&") || part.includes("=")) {
            return Object.assign(params, asParams(part));

        } else if (part.includes("/")) {
            return part.split("/").forEach(processPart);
        }

        // Add to the path, with adjustments as determined above.

        if (start && path_start) {
            // Invalid arguments supplied.
            console.warn(`${func}: second URL starter "${arg}"`);
        } else if (start) {
            // Prepare leading URL part (ending with "//") so that the right
            // number of slashes remain when joined below.
            part       = keep ? start : start.replace(/\/\/$/, "/").trim();
            path_start = part;
            start_idx  = path.length;
        } else if (!keep) {
            // Remove leading and trailing slash(es), if any.
            part = part.replace(/^\/+/, "").replace(/\/+$/, "").trim();
        }

        if (part) {
            path.push(part);
        }
    }

    // Accumulate path parts and param parts.
    parts.forEach(processPart);

    // Assemble the parts of the path.  If the start of the path does not
    // happen to be the first argument it will be brought to the beginning.
    if (isEmpty(path)) {
        path.push(window.location.origin + window.location.pathname);
    } else if (!path_start) {
        path.unshift(window.location.origin);
    } else {
        const tmp_path = [path_start];
        tmp_path.push(...path.slice(0, start_idx));
        tmp_path.push(...path.slice(start_idx + 1));
        path = tmp_path;
    }

    // Assemble the parts of the parameters.
    let url = path.join("/");
    params  = compact(params);
    if (isPresent(params)) {
        url += "?" + $.map(params, (v,k) => `${k}=${v}`).join("&");
    }
    return url;
}

/**
 * Provide an action for a cancel button, redirecting to the value of the
 * *data-path* attribute if present or redirecting back otherwise.
 *
 * @param {string|Selector} [arg]
 */
export function cancelAction(arg) {
    let url, $el;
    const str = (typeof arg === "string") ? arg : undefined;
    if (str?.match(/^back$|^\/|^https?:|^javascript:/i)) {
        url = arg;
    } else if (arg) {
        $el = $(arg);
        url = $el.attr("data-path") || $el.attr("href") || "back";
    }
    if (url?.toLowerCase() === "back") {
        url = "";                       // Previous page.
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
