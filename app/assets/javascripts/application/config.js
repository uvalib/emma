// app/assets/javascripts/application/config.js
//
// Application-wide configuration values.


import { AppDebug } from './debug';
import { regexp }   from '../shared/regexp';


AppDebug.file('application/config');

// ============================================================================
// Functions - interpolation
// ============================================================================

const FORMAT_MATCH = regexp(
    /(\d+\$\*\d+\$|\d+\$|[ #+0-]+)?/,   // $1 - optional flags
    /(\d+)?/,                           // $2 - optional width
    /(\.\d+)?/,                         // $3 - optional precision
    /([bBdiouxXeEfgGcpsaA])/            // $4 - required format type
);

const JS_INTERPOLATION       = /\${([^}\n]+)}/g;
const SIMPLE_NAMED_REFERENCE = /%{([^}\n]+)}/g;
const FORMAT_NAMED_REF_BASE  = /%<([^>\n]+)>/g;
const FORMAT_NAMED_REFERENCE = regexp(
    FORMAT_NAMED_REF_BASE,              // $1 - name
    FORMAT_MATCH,                       // flags, width, precision, format type
    { global: true }
);

const INTERPOLATION_PATTERNS = {
    '${': JS_INTERPOLATION,
    '%{': SIMPLE_NAMED_REFERENCE,
    '%<': FORMAT_NAMED_REFERENCE,
};

/**
 * Manually interpolate a string.
 *
 * @param {string|*}    item
 * @param {StringTable} values
 *
 * @returns {string|*}
 */
export function interpolate(item, values) {
    if (typeof item !== 'string') { return item }
    let res = item;
    for (const [key, pattern] of Object.entries(INTERPOLATION_PATTERNS)) {
        if (item.includes(key)) {
            res = res.replaceAll(pattern, (str, name) => values[name] || str);
        }
    }
    return res;
}
