// app/assets/javascripts/vendor/select2.js
//
// Load jQuery in a module to be included in the "application.js" manifest so
// that the required initialization is in place to respond to "turbolinks:load"


import { AppDebug } from "../application/debug";
import { appSetup } from "../application/setup";
import select2      from "select2";


const PATH = "vendor/select2";

AppDebug.file(PATH);

appSetup(PATH, () => select2($));

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {object} Select2Options
 *
 * @property {object}               [ajax]
 * @property {boolean}              [allowClear]
 * @property {string}               [amdLanguageBase]
 * @property {boolean}              [closeOnSelect]
 * @property {object[]}             [data]
 * @property {boolean}              [debug]
 * @property {string}               [dir]
 * @property {boolean}              [disabled]
 * @property {boolean}              [dropdownAutoWidth]
 * @property {string}               [dropdownCssClass]
 * @property {jQuery|HTMLElement}   [dropdownParent]
 * @property {function}             [escapeMarkup]
 * @property {string|object}        [language]
 * @property {function}             [matcher]
 * @property {number}               [maximumInputLength]
 * @property {number}               [maximumSelectionLength]
 * @property {number}               [minimumInputLength]
 * @property {number}               [minimumResultsForSearch]
 * @property {boolean}              [multiple]
 * @property {string|object}        [placeholder]
 * @property {string}               [selectionCssClass]
 * @property {boolean}              [selectOnClose]
 * @property {function}             [sorter]
 * @property {boolean|object[]}     [tags]
 * @property {function}             [templateResult]
 * @property {function}             [templateSelection]
 * @property {theme}                [selectionCssClass]
 * @property {function}             [tokenizer]
 * @property {string[]}             [tokenSeparators]
 * @property {string}               [width]
 * @property {boolean}              [scrollAfterSelect]
 *
 * <hr/>
 * Select2 configuration options.
 *
 * @see https://select2.org/configuration/options-api
 */
