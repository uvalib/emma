// app/assets/javascripts/shared/decode.js
//
// noinspection JSUnusedGlobalSymbols


import { AppDebug }           from "../application/debug";
import { isDefined }          from "./definitions";
import { fromJSON, isObject } from "./objects";


AppDebug.file("shared/decode");

// ============================================================================
// Functions - Type conversions
//
// These are primarily for *.js.erb files to allow values that will be inserted
// by ERB pre-processing to be expressed as a string, so that the Javascript
// has valid syntax even before pre-processing.
// ============================================================================

/**
 * Convert a string prepared with "#js" to an array or object.
 *
 * @param {string} arg
 *
 * @returns {array|object|undefined}
 *
 * @see file:config/boot.rb "#js"
 */
export function decodeJSON(arg) {
    const func = "decodeJSON";
    const str  = arg.replaceAll(/\n/g, "\\n");
    return fromJSON(str, func, (k, v) => {
        const encoded = (typeof v === "string") && v.includes("%5C");
        return encoded ? decodeURIComponent(v).replaceAll(/\\"/g, '"') : v;
    });
}

/**
 * Interpret a string as an Array definition.
 *
 * @param {*}      arg
 * @param {string} [separator]
 *
 * @returns {array}
 */
export function decodeArray(arg, separator = ",") {
    let s;
    switch (true) {
        case (!arg):                            return [];
        case Array.isArray(arg):                return arg;
        case (typeof arg === "object"):         return Object.values(arg);
        case (typeof arg !== "string"):         return [arg];
        case (s = arg.trim()).startsWith("["):  return decodeJSON(s);
    }
    return s.split(separator).map(v => v.trim());
}

/**
 * Interpret a string as an Object definition.
 *
 * @param {*} arg
 *
 * @returns {object}
 */
export function decodeObject(arg) {
    const result = (typeof arg === "string") ? decodeJSON(arg) : arg;
    return isObject(result) ? result : {};
}

/**
 * Interpret a string as a boolean value.
 *
 * @param {*} arg
 *
 * @returns {boolean}
 */
export function decodeBoolean(arg) {
    switch (typeof arg) {
        case "boolean": return arg;
        case "string":  return arg.toLowerCase() === "true";
        default:        return isDefined(arg);
    }
}

/**
 * Interpret a string as a integer value.
 *
 * @param {*} arg
 *
 * @returns {number}
 */
export function decodeInteger(arg) {
    switch (typeof arg) {
        case "number": return arg;
        case "string": return Math.max(0, parseInt(arg));
        default:       return 0;
    }
}
