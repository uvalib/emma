// app/assets/javascripts/shared/modal-dialog.js
//
// noinspection JSUnusedGlobalSymbols


import { AppDebug }  from '../application/debug';
import { selector }  from './css';
import { ModalBase } from './modal-base';


const MODULE = 'ModalDialog';
const DEBUG  = true;

AppDebug.file('shared/modal-dialog', MODULE, DEBUG);

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

    static CLASS_NAME = 'ModalDialog';
    static DEBUGGING  = DEBUG;

    static MODAL_CLASS = 'modal-popup';
    static MODAL       = selector(this.MODAL_CLASS);

    /**
     * The attribute which relates activation toggle control(s) to the modal
     * popup on the page.
     *
     * @readonly
     * @type {string}
     */
    static SELECTOR_ATTR = 'data-modal-selector';

    /**
     * The attribute which specifies the subclass which should be generated for
     * the activation toggle control.
     *
     * @readonly
     * @type {string}
     */
    static CLASS_ATTR = 'data-modal-class';

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
        return this.modalPanel.attr(this.constructor.SELECTOR_ATTR);
    }

    /**
     * A selector which matches activation toggle controls associated with this
     * modal.
     *
     * @returns {Selector}
     */
    get toggleSelector() {
        const toggle_sel = this.constructor.TOGGLE;
        const data_attr  = this.constructor.SELECTOR_ATTR;
        return `${toggle_sel}[${data_attr}="${this.selector}"]`;
    }

    /**
     * All activation toggle controls which may be associated with this modal.
     *
     * @returns {jQuery}
     */
    get allToggles() {
        return this.$root.find(this.toggleSelector);
    }

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
            this._error('cannot open - this.modalControl not set');
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
        this._debug('associateAll: toggles =', toggles);
        const $toggles = toggles ? $(toggles) : this.allToggles;
        const active   = $toggles.map((_, toggle) => this.associate(toggle));
        return $(active);
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
     * all related modal toggle controls.
     */
    static initializeAll() {
        this._debug('initializeAll');
        this.$all_modals.each((_, modal) => {
            let instance;
            const $modal = $(modal);
            const type   = $modal.attr(this.CLASS_ATTR);
            if (type && (type !== this.CLASS_NAME)) {
                this._debug(`skipping modal for ${type}`);
            } else if ((instance = $modal.data(this.MODAL_INSTANCE_DATA))) {
                this._debug('modal already linked to', instance);
            } else {
                (new this($modal)).associateAll();
            }
        });
    }

}
