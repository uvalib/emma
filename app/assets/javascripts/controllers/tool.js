// app/assets/javascripts/controllers/tool.js


import { AppDebug }       from '../application/debug';
import { appSetup }       from '../application/setup';
import { isMissing }      from '../shared/definitions';
import * as Lookup        from '../tool/bibliographic-lookup';
import * as MathDetective from '../tool/math-detective';


const MODULE = 'controllers/tool';

AppDebug.file(MODULE);

// noinspection SpellCheckingInspection
appSetup(MODULE, function() {

    /**
     * Standalone Utilities pages.
     *
     * @type {jQuery}
     */
    const $body = $('body.tool');

    // Only perform these actions on the appropriate pages.
    if (isMissing($body)) {
        return;
    }

    // ========================================================================
    // Math Detective API tool
    // ========================================================================

    if ($body.hasClass('md')) {
        MathDetective.setupFor($body);
    }

    // ========================================================================
    // Bibliographic lookup
    // ========================================================================

    if ($body.hasClass('lookup')) {
        Lookup.setupFor($body);
    }

});
