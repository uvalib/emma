// app/assets/javascripts/shared/definitions.js


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
    if (!item) {
        return true;
    } else if (isDefined(item.length)) {
        return !item.length;
    } else if (typeof item === 'object') {
        for (let property in item) {
            if (item.hasOwnProperty(property)) {
                return false;
            }
        }
        return true;
    }
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
