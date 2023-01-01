// app/assets/javascripts/shared/strings.js
//
// noinspection JSUnusedGlobalSymbols


import { AppDebug }      from '../application/debug';
import { objectEntries } from './objects';
import { asDateTime }    from './time';


AppDebug.file('shared/strings');

// ============================================================================
// Functions
// ============================================================================

/**
 * Convert the first character of a string to uppercase.
 *
 * @param {string} item
 *
 * @returns {string}
 */
export function capitalize(item) {
    const s = String(item).trim();
    return s ? (s[0].toUpperCase() + s.slice(1)) : '';
}

/**
 * Convert a string to "snake case".
 *
 * @param {string} item
 *
 * @returns {string}
 */
export function underscore(item) {
    const s     = String(item).trim();
    const start = s.replace(/^(_*).*/, '$1');
    return s.replace(/_*([A-Z]+)/g, '_$1').replace(/^_*/, start).toLowerCase();
}

/**
 * Convert a name to "camel case".
 *
 * @param {string} item
 *
 * @returns {string}
 */
export function camelCase(item) {
    const s     = underscore(item);
    const start = s.replace(/^(_*).*/, '$1');
    return s.split(/_+/).map(i => capitalize(i)).join('').replace(/^/, start);
}

/**
 * Convert a plural to the singular form.
 *
 * @param {string} item
 *
 * @returns {string}
 *
 * @note This isn't meant to be comprehensive; it's tuned to returning the
 *  singular form of existing model/controller names.
 */
export function singularize(item) {
    if (typeof item !== 'string') { return item }
    if (item.endsWith('ies'))     { return item.replace(/ies$/, 'y') }
    if (item.endsWith('es'))      { return item.replace(/es$/,  '')  }
    if (item.endsWith('s'))       { return item.replace(/s$/,   '')  }
    return item;
}

/**
 * Manually interpolate a string.
 *
 * @param {string|*}    item
 * @param {StringTable} values
 *
 * @returns {string|*}
 */
export function interpolate(item, values) {
    if ((typeof item === 'string') && item.includes('${')) {
        return item.replace(/\${([^}\n]+)}/g, ((_, name) => values[name]));
    } else {
        return item;
    }
}

/**
 * Render an item as a string (used in place of `JSON.stringify`).
 *
 * @param {*}      item
 * @param {number} [limit]            Maximum length of result.
 *
 * @returns {string}
 */
export function asString(item, limit) {
    const s_quote = "'";
    const d_quote = '"';
    let result    = '';
    let left      = '';
    let right     = '';
    let space     = '';

    switch (typeof item) {
        case 'string':
            result += item.replace(/\\([^\\])/g, '\\\\$1');
            if (![s_quote, d_quote].includes(item[0])) {
                left = right = d_quote;
            }
            break;
        case 'boolean':
        case 'symbol':
        case 'bigint':
            result += item.toString();
            break;
        case 'number':
            // A numeric, NaN, or Infinity value.
            result += (item || (item === 0)) ? item.toString() : 'null';
            break;
        default:
            if (!item) {
                // Undefined or null value.
                result += 'null';

            } else if (item instanceof RegExp) {
                // A regular expression.
                result += item.toString();

            } else if (item instanceof Date) {
                // A date value.
                result += asDateTime(item);
                left = right = d_quote;

            } else if (Array.isArray(item)) {
                // An array object.
                result = item.map(v => asString(v)).join(', ');
                [left, right] = ['[',']'];

            } else if (item.hasOwnProperty('originalEvent')) {
                // JSON.stringify fails with "cyclic object value" for jQuery
                // events.
                result = asString(item.originalEvent);

            } else {
                // A generic object.
                const pair = (kv) => `"${kv[0]}": ${asString(kv[1])}`;
                result = objectEntries(item).map(pair).join(', ');
                [left, right] = ['{','}'];
                if (result) { space = ' ' }
            }
            break;
    }

    left  = `${left}${space}`;
    right = `${space}${right}`;
    if (limit && (limit < (result.length + left.length + right.length))) {
        const omit = '...';
        const max  = limit - omit.length - left.length - right.length;
        result = (max > 0) ? result.slice(0, max) : '';
        result += omit;
    }
    return left + result + right;
}
