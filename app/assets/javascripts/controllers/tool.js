// app/assets/javascripts/controllers/tool.js


import { isMissing }      from '../shared/definitions'
import * as MathDetective from '../tool/math-detective'
import * as Lookup        from '../tool/bibliographic-lookup'


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

    // ========================================================================
    // Bibliographic lookup
    // ========================================================================

    if ($body.hasClass('lookup')) {
        Lookup.setup($body).then(
            result => console.log('lookup loaded:', (result || 'OK')),
            reason => console.warn('lookup failed:', reason)
        );
    }

});
