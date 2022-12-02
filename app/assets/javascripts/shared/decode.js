// app/assets/javascripts/shared/decode.js
//
// noinspection JSUnusedGlobalSymbols


import { isDefined } from './definitions'
import { fromJSON }  from './objects'


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
 * @returns {Array|Object|undefined}
 *
 * @see file:config/boot.rb "#js"
 */
export function decodeJSON(arg) {
    const func    = 'decodeJSON';
    const string  = arg.replace(/\n/g, '\\n');
    return fromJSON(string, func, (k, v) => {
        const encoded = (typeof v === 'string') && v.includes('%5C');
        return encoded ? decodeURIComponent(v) : v;
    });
}

/**
 * Interpret a string as an Array definition.
 *
 * @param {*}      arg
 * @param {string} [separator]
 *
 * @returns {Array}
 */
export function decodeArray(arg, separator = ',') {
    if (!arg)                    { return []; }
    if (Array.isArray(arg))      { return arg; }
    if (typeof arg === 'object') { return Object.values(arg);  }
    if (typeof arg !== 'string') { return [arg];  }
    const string = arg.trim();
    if (string.startsWith('['))  { return decodeJSON(string); }
    return string.split(separator).map(v => v.trim());
}

/**
 * Interpret a string as an Object definition.
 *
 * @param {*} arg
 *
 * @returns {object}
 */
export function decodeObject(arg) {
    switch (typeof arg) {
        case 'object':  return arg;
        case 'string':  return decodeJSON(arg);
        default:        return {};
    }
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
        case 'boolean': return arg;
        case 'string':  return arg.toLowerCase() === 'true';
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
        case 'number': return arg;
        case 'string': return Math.max(0, parseInt(arg));
        default:       return 0;
    }
}
