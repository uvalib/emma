// app/assets/javascripts/shared/search-in-progress.js


import { AppDebug }   from "../application/debug";
import { Emma }       from "./assets";
import { selector }   from "./css";
import { onPageExit } from "./events";
import { Overlay }    from "./overlay";


const MODULE = "SearchInProgress";
const DEBUG  = Emma.Debug.JS_DEBUG_SEARCH_IN_PROGRESS;

AppDebug.file("shared/search-in-progress", MODULE, DEBUG);

// ============================================================================
// Class SearchInProgress
// ============================================================================

/**
 * Despite the name, the single instance of this class controls the display of
 * the .search-in-progress overlay which is automatically shown at page exit
 * on all pages. <p/>
 *
 * Due to the CSS definition, nothing will appear immediately; it shouldn't be
 * perceptible on quick page transitions, however the overlay is still present
 * to prevent further interaction with the current page until it is replaced by
 * the new page.
 *
 * @extends Overlay
 */
export class SearchInProgress extends Overlay {

    static CLASS_NAME = "SearchInProgress";
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Constants
    // ========================================================================

    static OVERLAY_CLASS = "search-in-progress";

    // ========================================================================
    // Class fields
    // ========================================================================

    /**
     * Flag controlling whether the overlay is displayed on page exit.
     *
     * @type {boolean}
     * @protected
     */
    static _show_on_exit = true;

    // ========================================================================
    // Class properties
    // ========================================================================

    // noinspection JSUnusedGlobalSymbols
    static set showOnPageExit(v) { this._show_on_exit = !!v }
    static get showOnPageExit()  { return this._show_on_exit }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Set up an instance to control the .search-in-progress overlay. <p/>
     *
     * Individual modules may initiate showing/hiding the SearchInProgress for
     * specific long-running operations, but in general modules do not have to
     * be aware of the overlay.  In particular, this sets up display of the
     * overlay on page exit (although this may be suppressed at any point via
     * *`SearchInProgress.showOnPageExit = false`*).
     *
     * @param {boolean} [no_on_page_exit]
     */
    static initialize(no_on_page_exit) {
        this.hide(); // Make sure it's hidden at the start of a new page.
        if (!no_on_page_exit) {
            onPageExit(() => this.showOnPageExit && this.show());
        }
    }

    /**
     * This override is necessary to ensure that the overlay and its container
     * are found during page transitions.
     *
     * @param {boolean} [show]
     */
    toggle(show) {
        const container  = this.constructor.CONTAINER_CLASS;
        const $container = $('body').children(selector(container));
        const overlay    = this.constructor.OVERLAY_CLASS;
        const $overlay   = $container.children(selector(overlay));
        const marker     = this.constructor.VISIBLE_MARKER;
        const visible    = this.constructor.suppressed ? false : show;
        $container.toggleClass(marker, visible);
        $overlay.toggleClass(marker, visible);
        this._info('toggle', visible);
    }
}
