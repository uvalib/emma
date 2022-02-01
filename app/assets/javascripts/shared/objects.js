// app/assets/javascripts/shared/objects.js


import { isPresent } from '../shared/definitions'


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
export function arrayWrap(item) {
    return Array.isArray(item) ? item : [item];
}

/**
 * Transform an object into an array of key-value pairs.
 *
 * @param {object} item
 *
 * @returns {[string, any][]}
 */
export function objectEntries(item) {
    return Object.entries(item).filter(kv => item.hasOwnProperty(kv[0]));
}

/**
 * Generate an object from JSON (used in place of `JSON.parse`).
 *
 * @param {*}      item
 * @param {string} [caller]           For log messages.
 *
 * @returns {object|undefined}
 */
export function fromJSON(item, caller) {
    const func = caller || 'fromJSON';
    let result = undefined;
    if (typeof item == 'object') {
        result = item;
    } else if (item && (typeof item === 'string')) {
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
export function compact(item, trim) {
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
export function flatten(item) {
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
export function deepFreeze(item) {
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
