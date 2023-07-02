// app/assets/javascripts/feature/help.js


import { AppDebug }   from '../application/debug';
import { appSetup }   from '../application/setup';
import { isMissing }  from '../shared/definitions';
import { deepFreeze } from '../shared/objects';


const MODULE = 'Help';

AppDebug.file('feature/help', MODULE);

appSetup(MODULE, function() {

    /** @type {jQuery} */
    const $help_content = $('.help-section');

    // Only perform these actions on the appropriate pages.
    if (isMissing($help_content)) {
        return;
    }

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Selectors for elements that should not appear actionable when they are
     * part of help contents.
     *
     * @type {string[]}
     */
    const ILLUSTRATION_ONLY = deepFreeze([
        '.for-example'
    ]);

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * All instances of illustration-only classes.
     *
     * @type {jQuery}
     */
    const $illustrations = $help_content.find(ILLUSTRATION_ONLY.join(','));

    // ========================================================================
    // Actions
    // ========================================================================

    // Ensure that elements intended for the purpose of illustration do not
    // act like live controls.
    $illustrations.each((_, element) => {
        const $e = $(element);
        $e.attr('tabindex',       -1);
        $e.attr('role',           'none');
        $e.css( 'pointer-events', 'none');
        $e.css( 'cursor',         'auto');
        $e.parent().css('cursor', 'text');
    });

});
