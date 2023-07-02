// app/assets/javascripts/controllers/user_sessions.js


import { AppDebug }               from '../application/debug';
import { appSetup }               from '../application/setup';
import { isMissing }              from '../shared/definitions';
import { handleClickAndKeypress } from '../shared/accessibility';


const PATH = 'controllers/user_sessions';

AppDebug.file(PATH);

appSetup(PATH, function() {

    /** @type {jQuery} */
    const $inline_forms = $('.sign-in-form.inline');

    // Only perform these actions on the appropriate pages.
    if (isMissing($inline_forms)) {
        return;
    }

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Marker class indicating that the inline form elements should not be
     * displayed.
     *
     * @readonly
     * @type {string}
     *
     * @see file:app/assets/stylesheets/controllers/_user_sessions.scss .sign-in-form.inline.obscured
     */
    const INVISIBLE_MARKER = 'obscured';

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * Controls which toggle the visibility of associated inline forms.
     *
     * @type {jQuery}
     */
    const $inline_form_links = $inline_forms.children('.form-label');

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Toggle visibility of inline sign-in form fields.
     *
     * @param {jQuery.Event|UIEvent} [event]
     */
    function toggleInlineForm(event) {
        const $control = $(event.currentTarget || event.target);
        const $form    = $control.parent();
        $form.toggleClass(INVISIBLE_MARKER);
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleClickAndKeypress($inline_form_links, toggleInlineForm);

});
