// app/assets/javascripts/shared/form.js


import { isMissing } from '../shared/definitions'


// ============================================================================
// Functions
// ============================================================================

/**
 * Adjust input elements to prevent password managers from interpreting certain
 * fields like "Title" as ones that they should offer to autocomplete (unless
 * the field has been explicitly rendered with autocomplete turned on).
 *
 * @param {Selector} input
 */
export function turnOffAutocomplete(input) {
    $(input).each(function() {
        if (this instanceof HTMLInputElement) {
            let $element     = $(this);
            let autocomplete = $element.attr('autocomplete');
            let last_pass    = $element.attr('data-lpignore');
            if (isMissing(autocomplete)) {
                $element.attr('autocomplete', (autocomplete = 'off'));
            }
            if (isMissing(last_pass) && (autocomplete === 'off')) {
                $element.attr('data-lpignore', 'true'); // Needed for LastPass.
            }
        }
    });
}
