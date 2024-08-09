// app/assets/javascripts/feature/client-debug.js
//
// This module supports dev-only display of client-side information.


import { AppDebug }             from "../application/debug";
import { appSetup }             from "../application/setup";
import { classesWithin }        from "../shared/css";
import { isMissing, isPresent } from "../shared/definitions";
import { dataAttributesWithin } from "../shared/html";


const MODULE = "ClientDebug";
const DEBUG  = false;

AppDebug.file("feature/client-debug", MODULE, DEBUG);

appSetup(MODULE, function() {

    /** @type {jQuery} */
    const $table = $('.debug-table.client-debug');

    // Only perform these actions on the appropriate pages.
    if (isMissing($table)) { return }

    const $root = $('body');

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Make a debug list item element.
     *
     * @param {string} text
     *
     * @returns {string}
     */
    function item(text) {
        return `<span class="item">${text}</span>`;
    }

    /**
     * If the client debug table has an entry for the given key, fill it in
     * by applying **items_in** to all elements on the page.
     *
     * @param {string}                     key
     * @param {function(string): string[]} items_in
     */
    function fillIn(key, items_in) {
        const $value = $table.find(`.value[data-key="${key}"]`);
        if (isPresent($value)) {
            const names = items_in($root);
            const html  = names.map(name => item(name)).join("\n");
            $value.html(html || "&ndash;");
        }
    }

    // ========================================================================
    // Actions
    // ========================================================================

    // Show `data-*` attributes used within the page. (DEBUG_DATA_ATTR)
    fillIn("data-*", dataAttributesWithin);

    // Show CSS classes used within the page. (DEBUG_CSS_CLASS)
    fillIn("class", classesWithin);

});
