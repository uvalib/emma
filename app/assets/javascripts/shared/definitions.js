// app/assets/javascripts/shared/definitions.js


import { AppDebug } from '../application/debug';


AppDebug.file('shared/definitions');

// ============================================================================
// Functions - Element values
// ============================================================================

/**
 * Indicate whether the item is not undefined.
 *
 * @param {*} item
 *
 * @returns {boolean}
 */
export function isDefined(item) {
    return typeof item !== 'undefined';
}

/**
 * Indicate whether the item is not defined.
 *
 * @param {*} item
 *
 * @returns {boolean}
 */
export function notDefined(item) {
    return typeof item === 'undefined';
}

/**
 * Indicate whether the item does not contain a value.
 *
 * @param {*} item
 *
 * @returns {boolean}
 */
export function isEmpty(item) {
    if (item === false)             { return false }
    if (item === 0)                 { return false }
    if (!item)                      { return true }
    if (isDefined(item?.size))      { return !item.size }
    if (isDefined(item?.length))    { return !item.length }
    if (typeof item === 'object')   { return !Object.keys(item).length }
    return false;
}

/**
 * Indicate whether the item contains a value.
 *
 * @param {*} item
 *
 * @returns {boolean}
 */
export function notEmpty(item) {
    return !isEmpty(item);
}

/**
 * Indicate whether the item does not contain a value.
 *
 * @param {*} item
 *
 * @returns {boolean}
 */
export function isMissing(item) {
    return isEmpty(item);
}

/**
 * Indicate whether the item contains a value.
 *
 * @param {*} item
 *
 * @returns {boolean}
 */
export function isPresent(item) {
    return notEmpty(item);
}

/**
 * Return the item itself if it is not empty or undefined otherwise.
 *
 * @template T
 *
 * @param {T} item
 *
 * @returns {T|undefined}
 */
export function presence(item) {
    return isEmpty(item) ? undefined : item;
}
