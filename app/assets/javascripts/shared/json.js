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
            const key   = `${k}`.padEnd(max_width);
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
 * Replacer function for {@link JSON.stringify}.
 *
 * @param {*} _this
 * @param {*} item
 *
 * @returns {string|*}
 */
function stringifyReplacer(_this, item) {
    const type = typeof(item);
    switch (true) {
        case (type === 'undefined'):    return '(undefined)';
        case (item === null):           return '(null)';
        case (item instanceof Date):    return asDateTime(item);
        case isEmpty(item):             return item;
        case (type === 'object'):       return possiblyInlined(item);
        default:                        return item;
    }
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
    let json = postProcess(JSON.stringify(obj, null, ' '));
    json = json.replaceAll(/\[\s+/g, '[');
    json = json.replaceAll(/\s+]/g,  ']');
    json = json.replaceAll(/{\s*/g,  '{ ');
    json = json.replaceAll(/\s*}/g,  ' }');
    json = json.replaceAll(/\s+/g,   ' ');
    return (json.length <= threshold) ? json : obj;
}

/**
 * Make the result of {@link JSON.stringify} look less like JSON.
 *
 * @param {string} item
 *
 * @returns {string}
 */
function postProcess(item) {
    // noinspection RegExpRedundantEscape
    return item
        .replaceAll(/\\"/g, '"')
        .replaceAll(/"(\(\w+\))"/g, '$1')
        .replaceAll(/"(\{.+\})"/gm, '$1')
        .replaceAll(/"(\[.+\])"/gm, '$1')
        .replaceAll(/^( *)"(\w+)(\s*)":/gm,  '$1$2:$3')
        .replaceAll(/^( *)"(\S+?)(\s+)":/gm, '$1"$2":');
}
