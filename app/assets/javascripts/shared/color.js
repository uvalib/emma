// app/assets/javascripts/shared/color.js


import { DEF_HEX_DIGITS, HEX_BASE, hexString } from '../shared/css'


// ============================================================================
// Functions
// ============================================================================

/**
 * Return a value as an RGB hex color.
 *
 * @param {string|number} value
 *
 * @returns {string}
 */
export function rgbColor(value) {
    const digits = hexString(value, DEF_HEX_DIGITS);
    return '#' + digits;
}

/**
 * Given a RGB hex color, return the inverse color.
 *
 * @param {string|number} value
 *
 * @returns {string}
 */
export function rgbColorInverse(value) {
    const digits = hexString(value, DEF_HEX_DIGITS);
    return '#' + rotateHexDigits(digits);
}

/**
 * Add an increment to each hex digit in the string (module base 16).
 *
 * @param {string} value
 * @param {number} [shift]
 *
 * @returns {string}
 */
export function rotateHexDigits(value, shift = HEX_BASE/2) {
    const digits = hexString(value);
    return Array.from(digits)
        .map(digit => hexString((Number(`0x${digit}`) + shift) % HEX_BASE))
        .join('');
}
