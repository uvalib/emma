// app/assets/javascripts/feature/skip-nav.js


import { AppDebug }             from '../application/debug';
import { appSetup }             from '../application/setup';
import { selector }             from '../shared/css';
import { isMissing, isPresent } from '../shared/definitions';
import { selfOrParent }         from '../shared/html';


const MODULE = 'SkipNav';
const DEBUG  = true;

AppDebug.file('feature/skip-nav', MODULE, DEBUG);

appSetup(MODULE, function() {

    /**
     * CSS class indicating a "skip navigation" container.
     *
     * @readonly
     * @type {string}
     */
    const SKIP_MENU_CLASS = 'skip-nav';
    const SKIP_MENU       = selector(SKIP_MENU_CLASS);

    /** @type {jQuery} */
    const $nav = $(SKIP_MENU);

    // Only perform these actions on the appropriate pages.
    if (isMissing($nav)) { return }

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
     * @returns {boolean}             Menu visibility.
     */
    function toggleSkipMenu(target, new_state) {
        const $menu = selfOrParent(target, SKIP_MENU);
        if (_debugging()) {
            if (new_state === true)  { _debug('SHOW skip menu') } else
            if (new_state === false) { _debug('HIDE skip menu') } else
                                     { _debug('TOGGLE skip menu') }
        }
        return $menu.toggleClass('visible', new_state).hasClass('visible');
    }

    // ========================================================================
    // Functions - other
    // ========================================================================

    /**
     * Indicate whether console debugging is active.
     *
     * @returns {boolean}
     */
    function _debugging() {
        return AppDebug.activeFor(MODULE, DEBUG);
    }

    /**
     * Emit a console message if debugging.
     *
     * @param {...*} args
     */
    function _debug(...args) {
        _debugging() && console.log(`${MODULE}:`, ...args);
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    // Make the hidden navigation menu visible when one of its links receives
    // focus.
    $nav.find('a')
        .focus(function() { toggleSkipMenu(this, true)  })
        .blur( function() { toggleSkipMenu(this, false) });

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
    const $main_skip_nav = $nav.filter('.main');
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

});
