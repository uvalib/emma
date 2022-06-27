// app/assets/javascripts/shared/search-in-progress.js


import { selector }  from '../shared/css'
import { isMissing } from '../shared/definitions'
import { BaseClass } from '../shared/base-class'


// ============================================================================
// Class SearchInProgress
// ============================================================================

export class SearchInProgress extends BaseClass {

    static CLASS_NAME     = 'SearchInProgress';

    static VISIBLE_MARKER = 'visible';
    static OVERLAY_CLASS  = 'search-in-progress';
    static OVERLAY        = selector(this.OVERLAY_CLASS);

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
        return this.constructor._instance || this.#initialize(overlay);
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * Initialize the instance.
     *
     * @private
     *
     * @param {Selector} [overlay]
     *
     * @returns {this}
     */
    #initialize(overlay) {
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
     * @param {boolean} [show]
     */
    toggle(show) {
        this.$overlay.toggleClass(this.constructor.VISIBLE_MARKER, show);
    }

    // ========================================================================
    // Class properties
    // ========================================================================

    static get instance() { return this._instance ||= new this }
  //static get overlay()  { return this.instance.$overlay }

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
}
