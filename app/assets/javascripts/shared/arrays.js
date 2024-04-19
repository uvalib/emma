// app/assets/javascripts/shared/arrays.js
//
// noinspection JSUnusedGlobalSymbols


import { AppDebug }              from '../application/debug';
import { isDefined, notDefined } from './definitions';
import { dup }                   from './objects';


AppDebug.file('shared/arrays');

// ============================================================================
// Functions - returning Array
// ============================================================================

/**
 * Make a duplicate of the given array.
 *
 * @param {*}       item
 * @param {boolean} [shallow]         If **true** make a shallow copy.
 *
 * @returns {array}
 */
export function dupArray(item, shallow) {
    switch (true) {
        case Array.isArray(item):       return dup(item, !shallow);
        case isDefined(item?.toArray):  return dup(item.toArray(), !shallow);
        default:                        return arrayWrap(item);
    }
}

/**
 * Create an array to hold the item if it is not already one.
 *
 * @param {*} item
 *
 * @returns {array}
 */
export function arrayWrap(item) {
    switch (true) {
        case notDefined(item):          return [];
        case (item === null):           return [];
        case Array.isArray(item):       return item;
        case isDefined(item?.forEach):  return [...item];
        case isDefined(item?.toArray):  return item.toArray();
        default:                        return [item];
    }
}

/**
 * Return a copy with no more than one of any element.
 *
 * @param {*[]} items
 *
 * @returns {*[]}
 */
export function uniq(items) {
    const array = arrayWrap(items);
    return [...new Set(array)];
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
 * Find the size of the largest array value. <p/>
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
        (max, val) => {
            const size = (typeof val === 'number') ? val : (val?.length || 0);
            return Math.max(size, max);
        },
        minimum
    );
}

/**
 * Remove an element from the given array.
 *
 * @param {*[]} array
 * @param {*}   element
 *
 * @returns {boolean}             True if the element was found.
 */
export function removeFrom(array, element) {
    const index = array.indexOf(element);
    const found = (index >= 0);
    if (found) { array.splice(index, 1) }
    return found;
}
