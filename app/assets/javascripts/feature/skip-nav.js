// app/assets/javascripts/feature/skip-nav.js


import { AppDebug }             from "../application/debug";
import { appSetup }             from "../application/setup";
import { Emma }                 from "../shared/assets";
import { selector }             from "../shared/css";
import { isMissing, isPresent } from "../shared/definitions";
import { selfOrParent }         from "../shared/html";


const MODULE = "SkipNav";
const DEBUG  = Emma.Debug.JS_DEBUG_SKIP_NAV;

AppDebug.file("feature/skip-nav", MODULE, DEBUG);

appSetup(MODULE, function() {

    /**
     * CSS class indicating a "skip navigation" container.
     *
     * @readonly
     * @type {string}
     */
    const SKIP_MENU_CLASS = "skip-nav";
    const SKIP_MENU       = selector(SKIP_MENU_CLASS);

    /** @type {jQuery} */
    const $nav = $(SKIP_MENU);

    // Only perform these actions on the appropriate pages.
    if (isMissing($nav)) { return }

    /**
     * Console output functions for this module.
     */
    const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Toggle visibility of skip navigation menu associated with **target**,
     * which may reference either the container itself or any of its children.
     *
     * @param {Selector} target
     * @param {boolean}  [new_state]  Default: toggle state.
     *
     * @returns {boolean}             Menu visibility.
     */
    function toggleSkipMenu(target, new_state) {
        const $menu = selfOrParent(target, SKIP_MENU);
        if (OUT.debugging()) {
            switch (new_state) {
                case true:  OUT.debug("SHOW skip menu");   break;
                case false: OUT.debug("HIDE skip menu");   break;
                default:    OUT.debug("TOGGLE skip menu"); break;
            }
        }
        return $menu.toggleClass("visible", new_state).hasClass("visible");
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    // Make the hidden navigation menu visible when one of its links receives
    // focus.
    $nav.find('a')
        .on("focus", function() { toggleSkipMenu(this, true) })
        .on("blur",  function() { toggleSkipMenu(this, false) });

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
    // 'target: "_top"' alone will not move the focus -- without an anchor tag,
    // after clicking on the "Skip to top" link the view would scroll to the
    // top but tabbing would resume with the link following "Skip to top".)
    if (isMissing($('#top'))) {
        $('<div id="top">').addClass("visuallyhidden").prependTo('body');
    }
*/

});
