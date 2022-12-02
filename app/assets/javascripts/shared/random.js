// app/assets/javascripts/shared/random.js


// No imports


// ============================================================================
// Constants
// ============================================================================

/**
 * Hexadecimal numbering system base.
 *
 * @readonly
 * @type {number}
 */
export const HEX_BASE = 16;

/**
 * Default digits for {@link hexRand}.
 *
 * @readonly
 * @type {number}
 */
export const DEF_HEX_DIGITS = 6;

// ============================================================================
// Functions
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
export function randomizeName(css_class) {
    return css_class + '-' + hexRand();
}
