// app/assets/javascripts/feature/help.js


import { AppDebug }   from '../application/debug';
import { appSetup }   from '../application/setup';
import { isMissing }  from '../shared/definitions';
import { deepFreeze } from '../shared/objects';


const MODULE = 'feature/help';

AppDebug.file(MODULE);

appSetup(MODULE, function() {

    /** @type {jQuery} */
    let $help_content = $('.help-section');

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
    let $illustrations = $help_content.find(ILLUSTRATION_ONLY.join(','));

    // ========================================================================
    // Actions
    // ========================================================================

    // Ensure that elements intended for the purpose of illustration do not
    // act like live controls.
    $illustrations.each(function() {
        let $this = $(this);
        $this.attr('tabindex',       -1);
        $this.attr('role',           'none');
        $this.css( 'pointer-events', 'none');
        $this.css( 'cursor',         'auto');
        $this.parent().css('cursor', 'text');
    });

});
