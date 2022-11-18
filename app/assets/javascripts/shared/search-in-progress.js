// app/assets/javascripts/shared/search-in-progress.js


import { onPageExit } from './events'
import { Overlay }    from './overlay'


// ============================================================================
// Class SearchInProgress
// ============================================================================

/**
 * Despite the name, the single instance of this class controls the display of
 * the .search-in-progress overlay which is automatically shown at page exit
 * on all pages.
 *
 * Due to the CSS definition, nothing will appear immediately; it shouldn't be
 * be perceptible on quick page transitions, however the overlay is still
 * present to prevent further interaction with the current page until it is
 * replaced by the new page.
 */
export class SearchInProgress extends Overlay {

    static CLASS_NAME = 'SearchInProgress';

    // ========================================================================
    // Constants
    // ========================================================================

    static OVERLAY_CLASS = 'search-in-progress';

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
    static set showOnPageExit(v) { this._show_on_exit = !!v; }
    static get showOnPageExit()  { return this._show_on_exit; }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Set up an instance to control the .search-in-progress overlay.
     *
     * Individual modules may initiate showing/hiding the SearchInProgress for
     * specific long-running operations, but in general modules do not have to
     * be aware of the overlay.  In particular, this sets up display of the
     * overlay on page exit (although this may be suppressed at any point via
     * `SearchInProgress.showOnPageExit = false`.
     *
     * @param {boolean} [no_on_page_exit]
     */
    static initialize(no_on_page_exit) {
        this.hide(); // Make sure it's hidden at the start of a new page.
        if (!no_on_page_exit) {
            onPageExit(() => this.showOnPageExit && this.show());
        }
    }
}
