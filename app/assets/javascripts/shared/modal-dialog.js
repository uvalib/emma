// app/assets/javascripts/shared/modal-dialog.js
//
// noinspection JSUnusedGlobalSymbols


import { AppDebug }          from "../application/debug";
import { selector }          from "./css";
import { isMissing }         from "./definitions";
import { ModalBase, TOGGLE } from "./modal-base";


const MODULE = "ModalDialog";
const DEBUG  = true;

AppDebug.file("shared/modal-dialog", MODULE, DEBUG);

// ============================================================================
// Class ModalDialog
// ============================================================================

/**
 * A class for managing the state of a modal dialog that may be accessible by
 * one or more activation toggle controls.
 *
 * @extends ModalBase
 */
export class ModalDialog extends ModalBase {

    static CLASS_NAME = "ModalDialog";
    static DEBUGGING  = DEBUG;

    static MODAL_CLASS = "modal-popup";
    static MODAL       = selector(this.MODAL_CLASS);

    /**
     * The attribute which relates activation toggle control(s) to the modal
     * popup on the page.
     *
     * @readonly
     * @type {string}
     */
    static SELECTOR_ATTR = "data-modal-selector";

    /**
     * The attribute which specifies the subclass which should be generated for
     * the activation toggle control.
     *
     * @readonly
     * @type {string}
     */
    static CLASS_ATTR = "data-modal-class";

    // ========================================================================
    // Class fields
    // ========================================================================

    /** @type {boolean} */ static all_initialized;

    // ========================================================================
    // Fields
    // ========================================================================

    /** @type {jQuery} */ $root;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {Selector} modal
     * @param {Selector} [root]       Default: <body>.
     */
    constructor(modal, root) {
        super(undefined, modal);
        this.$root = $(root || 'body');
    }

    // ========================================================================
    // Properties
    // ========================================================================

    /**
     * The self-identification of the popup element which is used to match
     * activation toggle control(s) to this modal.
     *
     * @returns {Selector}
     */
    get selector() {
        return this.modalPanel.attr(this.SELECTOR_ATTR);
    }

    /**
     * A selector which matches activation toggle controls associated with this
     * modal.
     *
     * @returns {Selector}
     */
    get toggleSelector() {
        return `${TOGGLE}[${this.SELECTOR_ATTR}="${this.selector}"]`;
    }

    /**
     * All activation toggle controls which may be associated with this modal.
     *
     * @returns {jQuery}
     */
    get allToggles() {
        return this.$root.find(this.toggleSelector);
    }

    // noinspection FunctionNamingConventionJS
    get SELECTOR_ATTR() { return this.constructor.SELECTOR_ATTR }

    // ========================================================================
    // Methods - ModalBase overrides
    // ========================================================================

    /**
     * Open the popup element. <p/>
     *
     * Generally, this can't be used on a modal popup because ModalBase
     * operations assume a relationship with a toggle button, and that is set
     * only by opening the modal via {@link toggleModal}.
     *
     * @param {boolean} [no_halt]     If **true**, hooks cannot halt the chain.
     *
     * @returns {boolean}
     */
    open(no_halt) {
        if (this.modalControl) {
            return super.open(no_halt);
        } else {
            this._error("cannot open - this.modalControl not set");
            return false;
        }
    }

    // ========================================================================
    // Methods - popup toggle controls
    // ========================================================================

    /**
     * Set up all related modal activation toggle control(s) to operate with
     * this instance.
     *
     * @param {Selector} [toggles]
     *
     * @returns {jQuery}              The provided or discovered toggles.
     */
    associateAll(toggles) {
        this._debug("associateAll: toggles =", toggles, "modal =", this);
        const $toggles = toggles ? $(toggles) : this.allToggles;
        return $toggles.map((_, toggle) => this.associate(toggle));
    }

    // ========================================================================
    // Class properties
    // ========================================================================

    /**
     * All modal popups; i.e., popups attached to the page body that can be
     * potentially associated with multiple control buttons (serially).
     *
     * @type {jQuery}
     */
    static get $all_modals() {
        return $('body').children(this.MODAL);
    }

    /**
     * The modal popups associated with the subclass.
     *
     * @type {jQuery}
     */
    static get $modal() {
        const match = `[${this.CLASS_ATTR}="${this.CLASS_NAME}"]`;
        return this.$all_modals.filter(match);
    }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Create a ModalDialog instance for each modal popup and associate it with
     * all related activation toggle controls.
     *
     * @returns {boolean}
     */
    static initializeAll() {
        const func  = "initializeAll";
        let updated = false;
        let $modals;
        if (this.all_initialized) {
            this._debug(`${func}: already initialized`);
        } else if (isMissing($modals = this.$all_modals)) {
            this._debug(`${func}: no modals on this page`);
        } else {
            this._debug(`${func}: ${$modals.length} modals`);
            this.$all_modals.each((_, modal) => {
                const $modal = $(modal);
                const type   = $modal.attr(this.CLASS_ATTR);
                let instance;

                if (type && (type !== this.CLASS_NAME)) {
                    this._debug(`${func}: skipping modal for`, type, $modal);

                } else if ((instance = $modal.data(this.INSTANCE_DATA))) {
                    this._debug(`${func}: already linked`, instance, $modal);

                } else {
                    this._debug(`${func}: $modal =`, $modal);
                    instance = new this($modal);
                }

                if (instance) { instance.associateAll() }
            });
            updated = true;
        }
        return updated;
    }

}
