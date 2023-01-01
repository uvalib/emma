// app/assets/javascripts/shared/form.js


import { AppDebug }  from '../application/debug';
import { isMissing } from './definitions'


AppDebug.file('shared/form');

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
            const $element    = $(this);
            const spell_check = $element.attr('spellcheck');
            const last_pass   = $element.attr('data-lpignore');
            let autocomplete  = $element.attr('autocomplete');
            if (isMissing(spell_check)) {
                $element.attr('spellcheck', 'false');
            }
            if (isMissing(autocomplete)) {
                $element.attr('autocomplete', (autocomplete = 'off'));
            }
            if (isMissing(last_pass) && (autocomplete === 'off')) {
                $element.attr('data-lpignore', 'true'); // Needed for LastPass.
            }
        }
    });
}
