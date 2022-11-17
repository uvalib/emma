// app/assets/javascripts/shared/overlay.js


import { BaseClass } from './base-class'
import { selector }  from './css'
import { isMissing } from './definitions'


// ============================================================================
// Class Overlay
// ============================================================================

export class Overlay extends BaseClass {

    static CLASS_NAME = 'Overlay';

    // ========================================================================
    // Constants
    // ========================================================================

    static OVERLAY_CLASS; // To be defined by the subclass.
    static CONTAINER_CLASS = 'overlays';
    static VISIBLE_MARKER  = 'visible';

    // ========================================================================
    // Class fields
    // ========================================================================

    /**
     * Flag controlling whether to avoid displaying the overlay.
     *
     * @type {boolean}
     * @protected
     */
    static _suppressed = false;

    /**
     * Overlay container element.
     *
     * @type {jQuery|undefined}
     */
    static _container;

    /**
     * The singleton instance
     *
     * @type {this|undefined}
     */
    static _instance;

    // ========================================================================
    // Fields
    // ========================================================================

    /**
     * Related overlay element.
     *
     * @type {jQuery|undefined}
     */
    $overlay;

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
        this.$overlay = this.constructor.findOverlay(overlay);
        return this;
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get container() { return this.constructor.container }
    get overlay()   { return this.$overlay ||= this.constructor.findOverlay() }

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
        const marker  = this.constructor.VISIBLE_MARKER;
        const visible = this.constructor.suppressed ? false : show;
        this.container.toggleClass(marker, visible);
        this.overlay.toggleClass(marker, visible);
    }

    // ========================================================================
    // Class properties
    // ========================================================================

    static get instance()  { return this._instance  ||= new this }
    static get container() { return this._container ||= this.findContainer() }

    static set suppressed(v)  { this._suppressed = !!v; }
    static get suppressed()   { return this._suppressed; }

    // ========================================================================
    // Class methods
    // ========================================================================

    static show()       { this.instance.show() }
    static hide()       { this.instance.hide() }
    static toggle(show) { this.instance.toggle(show) }

    /**
     * Locate the page element container for overlays.
     *
     * @returns {jQuery}
     */
    static findContainer() {
        const target  = this.CONTAINER_CLASS;
        const $result = $('body').children(selector(target));
        if (isMissing($result)) {
            this._warn(`No "${target}" on this page.`);
        }
        return $result;
    }

    /**
     * Locate the page element for the search-in-progress overlay.
     *
     * @param {Selector} [overlay]    Default: {@link OVERLAY_CLASS}.
     *
     * @returns {jQuery}
     */
    static findOverlay(overlay) {
        const css    = (typeof overlay === 'string');
        const target = css ? overlay : this.OVERLAY_CLASS;
        let $result;
        if (css || !overlay) {
            $result = this.container.children(selector(target));
        } else {
            $result = $(overlay);
        }
        if (isMissing($result)) {
            this._warn(`No "${target}" on this page.`);
        }
        return $result;
    }
}
