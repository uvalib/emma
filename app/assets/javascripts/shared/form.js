// app/assets/javascripts/shared/form.js


import { AppDebug }   from "../application/debug";
import { isMissing }  from "./definitions"
import { deepFreeze } from "./objects";


AppDebug.file("shared/form");

// ============================================================================
// Constants
// ============================================================================

/**
 * Selectors for input fields.
 *
 * @readonly
 * @type {string[]}
 */
export const FORM_FIELD_TYPES = deepFreeze([
    'select',
    'textarea',
    'input[type="checkbox"]',
    'input[type="date"]',
    'input[type="datetime-local"]',
    'input[type="email"]',
    'input[type="month"]',
    'input[type="number"]',
    'input[type="password"]',
    'input[type="range"]',
    'input[type="tel"]',
    'input[type="text"]',
    'input[type="time"]',
    'input[type="url"]',
    'input[type="week"]',
]);

/**
 * Selector for input fields.
 *
 * @readonly
 * @type {string}
 */
export const FORM_FIELD = FORM_FIELD_TYPES.join(", ");

// ============================================================================
// Functions
// ============================================================================

/**
 * Adjust input elements to prevent password managers from interpreting certain
 * fields like "Title" as ones that they should offer to autocomplete (unless
 * the field has been explicitly rendered with autocomplete turned on).
 *
 * @param {Selector} inputs
 * @param {boolean}  [filter]
 */
export function turnOffAutocomplete(inputs, filter) {
    const $inputs   = $(inputs);
    const $elements = filter ? $inputs.filter(FORM_FIELD) : $inputs;
    $elements.each((_, element) => {
        const $element    = $(element);
        const spell_check = $element.attr("spellcheck");
        const last_pass   = $element.attr("data-lpignore");
        let autocomplete  = $element.attr("autocomplete");
        if (isMissing(spell_check)) {
            $element.attr("spellcheck", "false");
        }
        if (isMissing(autocomplete)) {
            $element.attr("autocomplete", (autocomplete = "off"));
        }
        if (isMissing(last_pass) && (autocomplete === "off")) {
            $element.attr("data-lpignore", "true"); // Needed for LastPass.
        }
    });
}

/**
 * Apply {@link turnOffAutocompleteIn} to all inputs within *container*.
 *
 * @param {Selector} container
 */
export function turnOffAutocompleteIn(container) {
    const $inputs = $(container).find(FORM_FIELD);
    turnOffAutocomplete($inputs, false);
}
