// app/assets/javascripts/shared/objects.js


import { isDefined, isPresent } from './definitions'


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
        const pr = objectEntries(item).map(kv => [kv[0], compact(kv[1],trim)]);
        return Object.fromEntries(pr.filter(kv => isPresent(kv[1])));

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
        const pr = objectEntries(item).map(kv => [kv[0], deepFreeze(kv[1])]);
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
 * Invalid pairs elements are silently discarded.
 *
 * @param {Array}            array
 * @param {function(string)} [mapper]
 *
 * @returns {object}
 *
 * @overload toObject(array, mapper)
 *  @param {string[]}         array
 *  @param {function(string)} mapper
 *  @returns {object}
 *
 * @overload toObject(array)
 *  @param {[string,*][]}     array
 *  @returns {object}
 */
export function toObject(array, mapper) {
    let obj, prs;
    if (Array.isArray(array)) {
        prs = mapper ? array.map(k => k && [k, mapper(k)]) : array;
        prs = prs.filter(v => Array.isArray(v) && (v.length === 2));
        obj = Object.fromEntries(prs);
    } else if (typeof array === 'object') {
        obj = array;
    } else {
        console.warn('toObject: not an array:', array);
    }
    return obj || {};
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
        return Object.entries(item).filter(kv => item.hasOwnProperty(kv[0]));
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
