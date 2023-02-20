// app/assets/javascripts/shared/json.js


import { AppDebug }                     from '../application/debug';
import { maxSize }                      from './arrays';
import { isEmpty }                      from './definitions';
import { asObject, isObject, toObject } from './objects';
import { asDateTime }                   from './time';


AppDebug.file('shared/json');

// ============================================================================
// Constants
// ============================================================================

const DEF_INDENT     = 2;
const DEF_INLINE_MAX = 80;

// ============================================================================
// Functions
// ============================================================================

/**
 * Render a data object as a sequence of lines.
 *
 * @param {object} data
 * @param {number} indent         Indentation of nested object.
 *
 * @returns {string}
 */
export function renderJson(data, indent = DEF_INDENT) {
    const item = alignKeys(data);
    const json = JSON.stringify(item, stringifyReplacer, indent);
    return postProcess(json);
}

// ============================================================================
// Functions - internal
// ============================================================================

/**
 * Recursively regenerate an item so that its object keys are replaced with
 * names appended with zero or more spaces in order to make each key the same
 * length.
 *
 * @param {array|object|*} item
 *
 * @returns {array|object|*}
 */
function alignKeys(item) {
    if (isObject(item)) {
        const object    = asObject(item);
        const max_width = maxSize(Object.keys(object));
        return toObject(object, (k, v) => {
            const space = Math.max(0, (max_width - k.length));
            const key   = `${k}` + ' '.repeat(space);
            const value = alignKeys(v);
            return [key, value];
        });
    } else if (Array.isArray(item)) {
        return item.map(element => alignKeys(element));
    } else {
        return item;
    }
}

/**
 * Replacer function for `JSON.stringify`.
 *
 * @param {*} _this
 * @param {*} item
 *
 * @returns {string|*}
 */
function stringifyReplacer(_this, item) {
    const type = typeof(item);
    if (type === 'undefined')      { return '(undefined)' }
    else if (item === null)        { return '(null)' }
    else if (item instanceof Date) { return asDateTime(item) }
    else if (isEmpty(item))        { return item }
    else if (type === 'object')    { return possiblyInlined(item) }
    return item;
}

/**
 * Render a data object as a sequence of lines.
 *
 * @param {object} obj
 * @param {number} threshold          Threshold for rendering a nested object
 *                                      on a single line.
 *
 * @returns {string|*}
 */
function possiblyInlined(obj, threshold = DEF_INLINE_MAX) {
    const json =
        postProcess(JSON.stringify(obj, null, ' '))
            .replace(/\[\s+/g, '[')
            .replace(/\s+]/g,  ']')
            .replace(/{\s*/g,  '{ ')
            .replace(/\s*}/g,  ' }')
            .replace(/\s+/g,   ' ');
    return (json.length <= threshold) ? json : obj;
}

/**
 * Make the result of `JSON.stringify` look less like JSON.
 *
 * @param {string} item
 *
 * @returns {string}
 */
function postProcess(item) {
    // noinspection RegExpRedundantEscape
    return item
        .replace(/\\"/g, '"')
        .replace(/"(\(\w+\))"/g, '$1')
        .replace(/"(\{.+\})"/gm, '$1')
        .replace(/"(\[.+\])"/gm, '$1')
        .replace(/^( *)"(\w+)(\s*)":/gm,  '$1$2:$3')
        .replace(/^( *)"(\S+?)(\s+)":/gm, '$1"$2":');
}
