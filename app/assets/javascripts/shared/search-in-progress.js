// app/assets/javascripts/shared/search-in-progress.js


import { Emma }       from './assets'
import { BaseClass }  from './base-class'
import { selector }   from './css'
import { isMissing }  from './definitions'
import { onPageExit } from './events'


// ============================================================================
// Class SearchInProgress
// ============================================================================

/**
 * Despite the name, the single instance of this class controls the display of
 * the .search-in-progress overlay which is automatically shown at page exit.
 *
 * Due to the CSS definition, nothing will appear immediately; it shouldn't be
 * be perceptible on quick page transitions, however the overlay is still
 * present to prevent further interaction with the current page until it is
 * replaced by the new page.
 */
export class SearchInProgress extends BaseClass {

    static CLASS_NAME     = 'SearchInProgress';

    // ========================================================================
    // Constants
    // ========================================================================

    static VISIBLE_MARKER = 'visible';
    static OVERLAY_CLASS  = 'search-in-progress';
    static OVERLAY        = selector(this.OVERLAY_CLASS);

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

    /**
     * Flag controlling whether to avoid displaying the overlay.
     *
     * @type {boolean}
     * @protected
     */
    static _suppressed = false;

    // ========================================================================
    // Fields
    // ========================================================================

    /**
     * Related '.search-in-progress' element.
     *
     * @type {jQuery|undefined}
     */
    $overlay;

    // ========================================================================
    // Class fields
    // ========================================================================

    /**
     * The singleton instance
     *
     * @type {this|undefined}
     */
    static _instance;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {Selector} [overlay]
     *
     * @returns {this}
     */
    constructor(overlay) {
        super();
        return this.constructor._instance || this._initialize(overlay);
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * Initialize the instance.
     *
     * @param {Selector} [overlay]
     *
     * @returns {this}
     * @protected
     */
    _initialize(overlay) {
        this.$overlay = overlay ? $(overlay) : this.constructor.findOverlay();
        if (isMissing(this.$overlay)) {
            this._warn(`No "${this.constructor.OVERLAY_CLASS}" on this page.`);
        }
        return this;
    }

    // ========================================================================
    // Methods
    // ========================================================================

    show() { this.toggle(true)  }
    hide() { this.toggle(false) }

    /**
     * Toggle search-in-progress visibility.
     *
     * If suppressed, this always hides the overlay.
     *
     * @param {boolean} [show]
     */
    toggle(show) {
        const visible = this.constructor.suppressed ? false : show;
        this.$overlay.toggleClass(this.constructor.VISIBLE_MARKER, visible);
    }

    // ========================================================================
    // Class properties
    // ========================================================================

    static get instance() { return this._instance ||= new this }

    // noinspection JSUnusedGlobalSymbols
    static set showOnPageExit(v) { this._show_on_exit = !!v; }
    static get showOnPageExit()  { return this._show_on_exit; }

    static set suppressed(v)     { this._suppressed = !!v; }
    static get suppressed()      { return this._suppressed; }

    // ========================================================================
    // Class methods
    // ========================================================================

    static show()       { this.instance.show() }
    static hide()       { this.instance.hide() }
    static toggle(show) { this.instance.toggle(show) }

    /**
     * Locate the page element for the search-in-progress overlay.
     *
     * @param {Selector} [overlay]    Default: {@link OVERLAY}.
     *
     * @returns {jQuery}
     */
    static findOverlay(overlay) {
        return $('body').children(overlay || this.OVERLAY);
    }

    /**
     * Set up an instance to control the search-in-progress overlay.
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

// ============================================================================
// Actions
// ============================================================================

$(document).on('turbolinks:load', function() {
    const no_on_page_exit = (Emma.RAILS_ENV === 'test');
    SearchInProgress.initialize(no_on_page_exit);
});
