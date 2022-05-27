// app/assets/javascripts/shared/objects.js


import { isDefined, isPresent } from '../shared/definitions'


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
    if (typeof(item) === 'undefined')        { return []; }        else
    if (item === null)                       { return []; }        else
    if (Array.isArray(item))                 { return item; }      else
    if (typeof item?.forEach === 'function') { return [...item]; } else
    if (typeof item?.toArray === 'function') { return item.toArray(); }
    return [item];
}

/**
 * Transform an object into an array of key-value pairs.
 *
 * @param {object} item
 *
 * @returns {[string, any][]}
 */
export function objectEntries(item) {
    if (item && (typeof item === 'object')) {
        return Object.entries(item).filter(kv => item.hasOwnProperty(kv[0]));
    } else {
        return [];
    }
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
    const type = item && typeof(item);
    let result;
    if (type === 'object') {
        result = item;
    } else if (type === 'string') {
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
        let pr = objectEntries(item).map(kv => [kv[0], compact(kv[1], trim)]);
        return Object.fromEntries(pr.filter(kv => isPresent(kv[1])));

    } else {
        return item;
    }
}

/**
 * Flatten one or more nested arrays.
 *
 * @param {...*} args
 *
 * @returns {Array}
 */
export function flatten(...args) {
    let item, result = [];
    if (args.length > 1) {
        args.forEach(v => result.push(...flatten(v)));
    } else if (Array.isArray((item = args[0]))) {
        item.forEach(v => result.push(...flatten(v)));
    } else if (typeof item === 'string') {
        (item = item.trim()) && result.push(item);
    } else {
        isDefined(item) && result.push(item);
    }
    return result;
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
        let prs  = objectEntries(item).map(kv => [kv[0], deepFreeze(kv[1])]);
        new_item = Object.fromEntries(prs);
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
        return deep ? $.extend(true, {}, item) : $.extend({}, item);
    } else if (typeof item === 'string') {
        return '' + item;
    } else {
        return item;
    }
}

// noinspection JSUnusedGlobalSymbols
/**
 * Make a duplicate of the given array.
 *
 * @param {array|undefined} item
 * @param {boolean}         [shallow]   If *true* make a shallow copy.
 *
 * @returns {array}
 */
export function dupArray(item, shallow) {
    return Array.isArray(item) ? dup(item, !shallow) : [];
}

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

/**
 * Find the size of the largest array value.
 *
 * For an array of numbers, returns the maximum value.
 * For any other array, returns the size of the largest element.
 *
 * @param {*}      item
 * @param {number} [minimum]
 *
 * @returns {number}
 */
export function maxSize(item, minimum = 0) {
    return arrayWrap(item).reduce(
        function(max_size, item) {
            let size = 0;
            if (typeof item === 'number') {
                size = item;
            } else if (typeof item?.length === 'number') {
                size = item.length;
            }
            return Math.max(size, max_size);
        },
    minimum);
}
