// app/assets/javascripts/shared/keyboard.js


import { AppDebug } from "../application/debug";
import { uniq }     from "./arrays";


AppDebug.file("shared/keyboard");

// ============================================================================
// Constants
// ============================================================================

/**
 * CSS attributes for use with {@link AppDebug.consoleFmt}.
 *
 * @type {Object.<string,string>}
 */
const CONSOLE_KEY_FMT = {
    display:            "inline-block",
    padding:            "0 0.25em",
    "line-height":      "1.25",
    "font-weight":      "bold",
    color:              "blue",
    background:         "yellow",
    outline:            "1px solid red",
    "border-radius":    "0.25em",
};

/**
 * All modifier keys.
 *
 * @type {Set<string>}
 *
 * @see https://developer.mozilla.org/en-US/docs/Web/API/UI_Events/Keyboard_event_key_values#modifier_keys
 */
const MODIFIERS = Object.freeze(new Set([
    "Alt",
    "AltGraph",
    "CapsLock",
    "Control",
    "Fn",
    "FnLock",
    "Hyper",
    "Meta",
    "NumLock",
    "ScrollLock",
    "Shift",
    "Super",
    "Symbol",
    "SymbolLock",
]));

// ============================================================================
// Functions
// ============================================================================

/**
 * Return a string that specifies the key combination pressed, or the empty
 * string if *event* is not valid. <p/>
 *
 * Key combinations include "Shift+" only for key names longer than one
 * character.  (_I.e., "Shift+Space" but not "Shift+A".) <p/>
 *
 * Combinations retain case so control-C is "Control+c" versus
 * control-shift-C, which is "Control+Shift+C".
 *
 * @param {KeyboardEvt} event
 *
 * @returns {string}
 */
export function keyCombo(event) {
    const key = event?.key;
    if (!key) { return "" }
    const modifier = [];
    if (event.ctrlKey)  { modifier.push("Control") }
    if (event.shiftKey) { modifier.push("Shift") }
    if (event.altKey)   { modifier.push("Alt") }
    if (event.metaKey)  { modifier.push("Meta") }
    const combo = uniq([...modifier, event.key]).join("+");
    return combo.match(/^Shift\+.$/) ? key : combo;
}

/**
 * Generate console log arguments for log output including a key combo.
 *
 * @param {string} text               Text preceding the key
 * @param {string} key                Result from {@link keyCombo}.
 * @param {...*}   args
 *
 * @returns {[string, string, ...*]}
 */
export function keyFormat(text, key, ...args) {
    const name  = (key === " ") ? "Space" : key;
    const parts = AppDebug.consoleFmt(name, CONSOLE_KEY_FMT, ...args);
    return text ? AppDebug.consoleArgs(text, ...parts) : parts;
}

/**
 * Indicate whether a result of {@link keyCombo} represents a key press of just
 * modifier key(s) like "Shift" or "Ctrl+Alt".
 *
 * @param {string}  key
 *
 * @returns {boolean}
 */
export function modifiersOnly(key) {
    return key.split("+").every(part => MODIFIERS.has(part));
}
