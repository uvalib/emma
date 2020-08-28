// app/assets/javascripts/feature/skip-nav.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    /** @type {jQuery} */
    let $nav = $('.skip-nav');

    // Only perform these actions on the appropriate pages.
    if (isMissing($nav)) { return; }

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Flag controlling console debug output.
     *
     * @constant
     * @type {boolean}
     */
    const DEBUGGING = false;

    /**
     * CSS class indicating a "skip navigation" container.
     *
     * @constant
     * @type {string}
     */
    const SKIP_MENU = 'skip-nav';

    // ========================================================================
    // Event handlers
    // ========================================================================

    // Make the hidden navigation menu visible when one of its links receives
    // focus.
    $nav.find('a')
        .focus(function() { toggleSkipMenu(this, true);  })
        .blur( function() { toggleSkipMenu(this, false); });

    // ========================================================================
    // Actions
    // ========================================================================

    // The main skip nav menu has to be generated after all templates have been
    // given an opportunity to contribute to it, which means that it will be
    // inserted near the end of the DOM tree.
    //
    // To make it immediately available to screen readers, it needs to be moved
    // so that it is the first element that is encountered when tabbing.
    //
    let $main_skip_nav = $nav.filter('.main');
    if (isPresent($main_skip_nav)) {
        $main_skip_nav.prependTo('body');
    }

/*
    // Inject a hidden target for the "#top" anchor.  (This is needed because
    // "target: '_top'" alone will not move the focus -- without an anchor tag,
    // after clicking on the "Skip to top" link the view would scroll to the
    // top but tabbing would resume with the link following "Skip to top".)
    if (isMissing($('#top'))) {
        $('<div id="top">').addClass('visuallyhidden').prependTo('body');
    }
*/

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Toggle visibility of the skip navigation menu associated with *target*,
     * which may reference either the container itself or any of its children.
     *
     * @param {Selector} target
     * @param {boolean}  [new_state]  Default: toggle state.
     *
     * @return {boolean}              Menu visibility.
     */
    function toggleSkipMenu(target, new_state) {
        let $this = $(target);
        let $menu =
            $this.hasClass(SKIP_MENU) ? $this : $this.parents('.' + SKIP_MENU);
        if (DEBUGGING) {
            let change;
            if (new_state === true) {
                change = 'SHOW';
            } else if (new_state === false) {
                change = 'HIDE';
            } else {
                change = 'TOGGLE';
            }
            debug(`${change} skip menu`);
        }
        return $menu.toggleClass('visible', new_state).hasClass('visible');
    }

    // ========================================================================
    // Functions - other
    // ========================================================================

    /**
     * Emit a console message if debugging.
     *
     * @param {...*} args
     */
    function debug(...args) {
        if (DEBUGGING) { consoleLog(...args); }
    }

});
