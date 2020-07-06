// app/assets/javascripts/feature/help.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    /** @type {jQuery} */
    var $help_content = $('body').find('.help-section');

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
    var ILLUSTRATION_ONLY = [
        '.advanced-search-toggle',
        '.bookshare-sign-in',
     // '.menu-label',                // Not a functional element.
        '.search-button',
        '.session-link',
        '.sign-in-button'
    ];

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * All instances of illustration-only classes.
     *
     * @type {jQuery}
     */
    var $illustrations = $help_content.find(ILLUSTRATION_ONLY.join(','));

    // ========================================================================
    // Actions
    // ========================================================================

    // Ensure that elements intended for the purpose of illustration do not
    // act like live controls.
    $illustrations.each(function() {
        var $this = $(this);
        $this.attr('tabindex',       -1);
        $this.attr('role',           'none');
        $this.css( 'pointer-events', 'none');
        $this.css( 'cursor',         'auto');
        $this.parent().css('cursor', 'text');
    });

});
