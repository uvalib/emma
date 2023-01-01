// app/assets/javascripts/shared/objects.js


import { AppDebug }             from '../application/debug';
import { isDefined, isPresent } from './definitions';


AppDebug.file('shared/objects');

// ============================================================================
// Functions
// ============================================================================

/**
 * Generate an object from JSON (used in place of `JSON.parse`).
 *
 * @param {*}                 item
 * @param {string|false|null} [caller]  Null or false for no diagnostic message
 * @param {function}          [reviver] To JSON.parse.
 *
 * @returns {object|undefined}
 */
export function fromJSON(item, caller, reviver) {
    const func = isDefined(caller) ? caller : 'fromJSON';
    const type = item && typeof(item);
    let result;
    if (type === 'object') {
        result = item;
        if (reviver) {
            console.warn(`${func}: reviver not called for item =`, item);
        }
    } else if (type === 'string') {
        try {
            result = reviver ? JSON.parse(item, reviver) : JSON.parse(item);
        }
        catch (err) {
            func && console.warn(`${func}: ${err} - item:\n`, item);
        }
    } else if (item) {
        console.warn(`${func}: unexpected type "${type}" for`, item);
    }
    return result;
}

/**
 * Generate a copy of the item without blank elements.
 *
 * @template T
 *
 * @param {T}       item
 * @param {boolean} [trim]            If *false*, don't trim white space.
 *
 * @returns {T}
 */
export function compact(item, trim) {
    if (typeof item === 'string') {
        return (trim === false) ? item : item.trim();

    } else if (Array.isArray(item)) {
        return item.map(v => compact(v, trim)).filter(v => isPresent(v));

    } else if (typeof item === 'object') {
        const pr = objectEntries(item).map(([k,v]) => [k, compact(v, trim)]);
        return Object.fromEntries(pr.filter(([_,v]) => isPresent(v)));

    } else {
        return item;
    }
}

/**
 * Make a completely frozen copy of an item.
 *
 * @template T
 *
 * @param {T} item       Source item (which will be unaffected).
 *
 * @returns {T}          An immutable copy of *item*.
 */
export function deepFreeze(item) {
    let new_item;
    if (Array.isArray(item)) {
        new_item = item.map(v => deepFreeze(v));
    } else if (typeof item === 'object') {
        const pr = objectEntries(item).filter(([k,v]) => [k, deepFreeze(v)]);
        new_item = Object.fromEntries(pr);
    } else {
        new_item = item;
    }
    return Object.freeze(new_item);
}

/**
 * Make a deep copy of the given item.
 *
 * @template T
 *
 * @param {T} item
 *
 * @returns {T}
 */
export function deepDup(item) {
    return dup(item, true);
}

/**
 * Make a duplicate of the given item.
 *
 * @template T
 *
 * @param {T}       item
 * @param {boolean} [deep]            If *true* make a deep copy.
 *
 * @returns {T}
 */
export function dup(item, deep) {
    if (Array.isArray(item)) {
        return deep ? item.map(v => dup(v, deep)) : [...item];
    } else if (typeof item === 'object') {
        return deep ? $.extend(true, {}, item) : { ...item };
    } else if (typeof item === 'string') {
        return '' + item;
    } else {
        return item;
    }
}

// ============================================================================
// Functions - returning Object
// ============================================================================

/**
 * Make a duplicate of the given object.
 *
 * @param {object|undefined} item
 * @param {boolean}          [shallow]  If *true* make a shallow copy.
 *
 * @returns {object}
 */
export function dupObject(item, shallow) {
    return (typeof item === 'object') ? dup(item, !shallow) : {};
}

/**
 * Create an Object from array of key-value pairs, or from an array of keys
 * and a mapper function which returns a value for the given key.
 *
 * If *src* is an object or an array of key-value pairs, *map_fn* is optional.
 * If *pair_out* is set to *false*, *map_fn* is assumed to emit a value only;
 * otherwise *map_fn* is assumed to return a key-value pair.
 *
 * If *src* is an array of single values, *map_fn* is required.  If *pair_out*
 * is set to *true*, *map_fn* is assumed to return a key-value pair; otherwise
 * *map_fn* is assume to emit a value only.
 *
 * Invalid pairs elements are silently discarded.
 *
 * @param {string[]|[string,*][]|object}        src
 * @param {function(string)|function(string,*)} [map_fn]
 * @param {boolean}                             [pair_out]
 *
 * @returns {object}
 */
export function toObject(src, map_fn, pair_out) {
    const func   = 'toObject';
    const array  = Array.isArray(src);
    const object = !array && (typeof src === 'object');
    const mapper = (typeof map_fn === 'function') ? map_fn : undefined;
    const arity  = mapper?.length || -1;
    let result;
    if (!array && !object) {
        console.warn(`${func}: not an array or object:`, src);
    } else if (mapper && (arity < 1)) {
        console.error(`${func}: mapper must take 1 or 2 args:`, mapper);
    } else {
        const pair = kv => Array.isArray(kv) && (kv.length === 2) && !!kv[0];
        const in1  = (arity === 1);
        const in2  = (arity >=  2);
        const out1 = (pair_out === false);
        const out2 = (pair_out === true);
        let fn     = undefined;
        if (object || pair(src[0])) {
            fn ||= in2  &&  out1 && (([k,v]) => [k, mapper(k,v)]);
            fn ||= in1  && !out2 && (([k,_]) => [k, mapper(k)]);
            fn ||= in2           && (([k,v]) => mapper(k,v));
            fn ||= in1           && (([k,_]) => mapper(k));
            fn ||=                  (([k,v]) => [k, v]);
        } else {
            fn ||= out2 && mapper;
            fn ||= in2  && ((k,idx) => [idx, mapper(k,idx)]);
            fn ||= in1  && ((k)     => [k,   mapper(k)]);
            fn ||=         ((k)     => [k,   k]);
        }
        result = object ? Object.entries(src) : src;
        result = result.map(fn).filter(pair);
        result = Object.fromEntries(result);
    }
    return result || {};
}

// ============================================================================
// Functions - returning Array
// ============================================================================

/**
 * Transform an object into an array of key-value pairs.
 *
 * @param {object} item
 *
 * @returns {[string, any][]}
 */
export function objectEntries(item) {
    if (item && (typeof item === 'object')) {
        return Object.entries(item).filter(([k,_]) => item.hasOwnProperty(k));
    } else {
        return [];
    }
}

// ============================================================================
// Functions - other
// ============================================================================

/**
 * Indicate whether two objects are effective the same.
 *
 * @param {array|object|any} item1
 * @param {array|object|any} item2
 *
 * @returns {boolean}
 */
export function equivalent(item1, item2) {
    const a1 = Array.isArray(item1);
    const a2 = Array.isArray(item2);
    const o1 = !a1 && (typeof item1 === 'object');
    const o2 = !a2 && (typeof item2 === 'object');
    let result;
    if (o1 && o2) {
        const keys1 = Object.keys(item1);
        const keys2 = Object.keys(item2);
        if ((result = equivalent(keys1, keys2))) {
            $.each(item1, function(key, value1) { // continue while equivalent
                return !(result &&= equivalent(value1, item2[key]));
            });
        }
    } else if (a1 && a2) {
        if ((result = (item1.length === item2.length))) {
            const array1 = [...item1].sort();
            const array2 = [...item2].sort();
            $.each(array1, function(idx, value1) { // continue while equivalent
                return !(result &&= equivalent(value1, array2[idx]));
            });
        }
    } else {
        result = (item1 === item2);
    }
    return result;
}
