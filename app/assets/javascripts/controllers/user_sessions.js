// app/assets/javascripts/controllers/user_sessions.js


import { isMissing }              from '../shared/definitions'
import { handleClickAndKeypress } from '../shared/events'


$(document).on('turbolinks:load', function() {

    /** @type {jQuery} */
    let $inline_forms = $('.sign-in-form.inline');

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
    const HIDDEN_MARKER = 'obscured';

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * Controls which toggle the visibility of associated inline forms.
     *
     * @type {jQuery}
     */
    let $inline_form_links = $inline_forms.children('.form-label');

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleClickAndKeypress($inline_form_links, toggleInlineForm);

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Toggle visibility of inline sign-in form fields.
     *
     * @param {jQuery.Event|UIEvent} [event]
     */
    function toggleInlineForm(event) {
        let $control = $(event.currentTarget || event.target);
        let $form    = $control.parent();
        $form.toggleClass(HIDDEN_MARKER);
    }

});
