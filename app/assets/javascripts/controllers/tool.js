// app/assets/javascripts/controllers/tool.js


import { isMissing }      from '../shared/definitions'
import * as MathDetective from '../tool/math-detective'


// noinspection SpellCheckingInspection
$(document).on('turbolinks:load', function() {

    /**
     * Standalone Utilities pages.
     *
     * @type {jQuery}
     */
    let $body = $('body.tool');

    // Only perform these actions on the appropriate pages.
    if (isMissing($body)) {
        return;
    }

    // ========================================================================
    // Math Detective API tool
    // ========================================================================

    if ($body.hasClass('md')) {
        MathDetective.setup($body);
    }

});
