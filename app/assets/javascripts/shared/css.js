// app/assets/javascripts/shared/css.js


import { isEmpty, isPresent } from '../shared/definitions'
import { arrayWrap, compact } from '../shared/objects'


// ============================================================================
// Constants - CSS
// ============================================================================

/**
 * Hexadecimal numbering system base.
 *
 * @constant
 * @type {number}
 */
export const HEX_BASE = 16;

/**
 * Default digits for {@link hexRand}.
 *
 * @constant
 * @type {number}
 */
export const DEF_HEX_DIGITS = 6;

// ============================================================================
// Functions - CSS
// ============================================================================

/**
 * Render a number as a string of hex digits.  If *length* is given, left-fill
 * with zeros if needed.
 *
 * @param {number|string} value
 * @param {number}        [length]
 *
 * @returns {string}
 */
export function hexString(value, length) {
    let result;
    if (typeof value === 'number') {
        result = value.toString(HEX_BASE);
    } else {
        result = value.replace(/\P{Hex}/ug, '').toLowerCase();
    }
    const fill = length ? (length - result.length) : 0;
    return (fill > 0) ? ('0'.repeat(fill) + result) : result;
}

/**
 * Generate a string of random hexadecimal digits, left-filled with zeros if
 * necessary.
 *
 * @param {number} [length]
 *
 * @returns {string}
 */
export function hexRand(length = DEF_HEX_DIGITS) {
    const random = Math.floor(Math.random() * (HEX_BASE ** length));
    return hexString(random, length);
}

/**
 * Create a unique CSS class name by appending a random hex number.
 *
 * @param {string} css_class
 *
 * @returns {string}
 */
export function randomizeClass(css_class) {
    return css_class + '-' + hexRand();
}

/**
 * Toggle the presence of a CSS class for one or more disjoint elements.
 *
 * @param {Selector|Selector[]} sel
 * @param {string}              cls
 * @param {boolean}             [setting]
 */
export function toggleClass(sel, cls, setting) {
    arrayWrap(sel).forEach(element => $(element).toggleClass(cls, setting));
}

/**
 * Normalize singletons and/or arrays of CSS class names.
 *
 * @param {...string|Array} args
 *
 * @returns {string[]}
 */
export function cssClasses(...args) {
    let result = [];
    args.forEach(function(arg) {
        let values = undefined;
        if (typeof arg === 'string') {
            values = arg.trim().replace(/[.\s]+/g, ' ').split(' ');
        } else if (Array.isArray(arg)) {
            values = cssClasses(...arg);
        } else if (typeof arg === 'object') {
            values = cssClasses(arg['class']);
        }
        values = compact(values);
        if (isPresent(values)) {
            result.push(...values);
        }
    });
    return result;
}

/**
 * Join one or more CSS class names or arrays of class names with spaces.
 *
 * @param {...string|Array} args      Passed to {@link cssClasses}.
 *
 * @returns {string}
 */
export function cssClass(...args) {
    return cssClasses(...args).join(' ');
}

/**
 * Form a selector from one or more selectors or class names.
 *
 * @param {...string|Array} args      Passed to {@link cssClasses}.
 *
 * @returns {string}
 */
export function selector(...args) {
    const func = 'selector';
    let result = [];
    args.forEach(function(arg) {
        let entry;
        if (isEmpty(arg)) {
            console.warn(`${func}: skipping empty ${typeof arg} = ${arg}`);

        } else if (Array.isArray(arg)) {
            entry = arg.map(v => v.trim().replace(/\s*,$/, ''));
            entry = entry.map(v => v.startsWith('.') ? v : `.${v}`);
            entry = entry.join(', ');

        } else if (typeof arg === 'object') {
            entry = selector(arg['class']);

        } else if (typeof arg !== 'string') {
            console.warn(`${func}: ignored ${typeof arg} = ${arg}`);

        } else if (arg === ',') {
            entry = ', ';

        } else if (arg.includes(',')) {
            entry = arg.trim().replace(/\s*,\s*/g, ',').split(',');
            entry = cssClasses(...entry);
            entry = entry.map(v => v.startsWith('.') ? v : `.${v}`);
            entry = entry.join(', ');

        } else if (arg.includes(' ')) {
            entry = arg.trim().replace(/\./g, ' ').split(/\s+/);
            entry = '.' + entry.join('.');

        } else if (arg[0] === '#') {    // ID selector
            result.unshift(arg);

        } else if (arg[0] === '.') {    // CSS class selector
            entry = arg;

        } else {                        // CSS class
            entry = `.${arg}`;
        }
        entry = compact(entry);
        if (isPresent(entry)) {
            result.push(entry);
        }
    });
    return result.join('').trim();
}

/**
 * Return an identifying selector for an element -- based on the element ID if
 * it has one.
 *
 * @param {jQuery|HTMLElement} element
 *
 * @returns {string}
 */
export function elementSelector(element) {
    let e = $(element)[0];
    if (e.id) {
        return `#${e.id}`;
    } else if (e.className) {
        return e.localName + '.' + e.className.replace(/\s+/g, '.');
    } else {
        return e.localName;
    }
}
