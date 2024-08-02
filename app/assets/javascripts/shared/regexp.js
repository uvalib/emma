// app/assets/javascripts/shared/regexp.js


import { AppDebug } from "../application/debug";
import { uniq }     from "./arrays";


AppDebug.file("shared/regexp");

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {("d"|"g"|"i"|"m"|"s"|"u"|"v"|"y")} RegExpFlag
 */

/**
 * @typedef {(
 *  "hasIndices"    |
 *  "global"        |
 *  "ignoreCase"    |
 *  "multiline"     |
 *  "dotAll"        |
 *  "unicode"       |
 *  "unicodeSets"   |
 *  "sticky"
 * )} RegExpProp
 */

/**
 * @typedef {object} RegExpOptions
 *
 * @property {boolean} hasIndices
 * @property {boolean} global
 * @property {boolean} ignoreCase
 * @property {boolean} multiline
 * @property {boolean} dotAll
 * @property {boolean} unicode
 * @property {boolean} unicodeSets
 * @property {boolean} sticky
 *
 * @property {boolean} d
 * @property {boolean} g
 * @property {boolean} i
 * @property {boolean} m
 * @property {boolean} s
 * @property {boolean} u
 * @property {boolean} v
 * @property {boolean} y
 */

// ============================================================================
// Constants
// ============================================================================

/**
 * @type {Object<RegExpProp, RegExpFlag>}
 */
export const REGEX_OPTIONS = {
    hasIndices:  "d",
    global:      "g",
    ignoreCase:  "i",
    multiline:   "m",
    dotAll:      "s",
    unicode:     "u",
    unicodeSets: "v",
    sticky:      "y",
};

/**
 * @type {string}
 */
export const REGEX_FLAGS = Object.values(REGEX_OPTIONS).join("");

// ============================================================================
// Functions
// ============================================================================

/**
 * Simulate a multi-line regular expression (i.e., like Ruby /.../x).
 *
 * If the final argument matches a string of {@link RegExpFlag} characters or
 * an object with {@link RegExpProp} keys, then it is used to set the options
 * of the new instance.
 *
 * @param args
 *
 * @returns {RegExp}
 */
export function regexp(...args) {
    let flags, last = args.at(-1);
    if (last && !(last instanceof RegExp)) {
        if (typeof last === "string") {
            last = Array.from(last);
        } else {
            flags = []; // Ensure that args gets popped.
        }
        if (Array.isArray(last)) {
            const is_flag = new RegExp(`[${REGEX_FLAGS}]`);
            if (last.every(c => is_flag.test(c))) {
                flags = last;
            }
        } else if (typeof last === "object") {
            for (const [prop, flag] of Object.entries(REGEX_OPTIONS)) {
                if (last[prop] || last[flag]) { flags.push(flag) }
            }
        }
        if (flags) { args.pop() }
        flags = flags?.length ? uniq(flags).join("") : undefined;
    }
    const expr = args.map(v => (v instanceof RegExp) ? v.source : v).join("");
    return flags ? new RegExp(expr, flags) : new RegExp(expr);
}

/**
 * Combine regular expressions.
 *
 * @param args
 *
 * @returns {RegExp}
 */
export function union(...args) {
    let flags = [];
    let expr  = args.map(v => {
        const re = (v instanceof RegExp) ? v : regexp(v);
        if (re.flags)       { flags.push(...re.flags.split("")) }
        if (re.hasIndices)  { flags.push("d") }
        if (re.dotAll)      { flags.push("s") }
        if (re.unicodeSets) { flags.push("v") }
        return re.source;
    });
    expr  = expr.join("|");
    flags = flags.length ? uniq(flags).join("") : undefined;
    return flags ? new RegExp(expr, flags) : new RegExp(expr);
}
