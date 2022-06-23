// app/assets/javascripts/shared/arrays.js


import { isDefined } from '../shared/definitions'
import { dup }       from '../shared/objects'


// ============================================================================
// Functions - returning Array
// ============================================================================

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

// ============================================================================
// Functions - other
// ============================================================================

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
        (max_size, item) => {
            let size = 0;
            if (typeof item === 'number') {
                size = item;
            } else if (typeof item?.length === 'number') {
                size = item.length;
            }
            return Math.max(size, max_size);
        },
        minimum
    );
}
