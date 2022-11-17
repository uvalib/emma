// app/assets/javascripts/shared/modal-dialog.js
//
// noinspection JSUnusedGlobalSymbols


import { selector }  from './css'
import { ModalBase } from './modal-base'


// ============================================================================
// Class ModalDialog
// ============================================================================

/**
 * A class for managing the state of a modal dialog that may be accessible by
 * one or more toggle buttons.
 */
export class ModalDialog extends ModalBase {

    static CLASS_NAME = 'ModalDialog';
    static DEBUGGING  = false;

    static MODAL_CLASS = 'modal-popup';
    static MODAL       = selector(this.MODAL_CLASS);

    /**
     * The attribute which relates toggle(s) to the modal popup on the page.
     *
     * @readonly
     * @type {string}
     */
    static SELECTOR_ATTR = 'data-modal-selector';

    /**
     * The attribute which specifies the subclass which should be generated for
     * the modal popup toggle.
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

    get modalPanel()    { return this.$modal }
    get activeControl() { return this.$toggle }

    /**
     * The self-identification of the popup element which is used to match
     * toggle control(s) to this modal.
     *
     * @returns {Selector}
     */
    get selector() {
        return this.$modal.attr(this.constructor.SELECTOR_ATTR);
    }

    /**
     * A selector which matches toggle controls associated with this modal.
     *
     * @returns {Selector}
     */
    get toggleSelector() {
        const toggle_sel = this.constructor.TOGGLE;
        const data_attr  = this.constructor.SELECTOR_ATTR;
        return `${toggle_sel}[${data_attr}="${this.selector}"]`;
    }

    /**
     * All popup toggle controls which may be associated with this modal.
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
     * Open the popup element.
     *
     * Generally, this can't be used on a modal popup because ModalBase
     * operations assume a relationship with a toggle button, and that is set
     * only by opening the modal via {@link toggleModal}.
     *
     * @param {boolean} [no_halt]     If *true*, hooks cannot halt the chain.
     *
     * @returns {boolean}
     */
    open(no_halt) {
        if (this.$toggle) {
            return super.open(no_halt);
        } else {
            this._error('cannot open - this.toggleControl not set');
            return false;
        }
    }

    /**
     * Toggle visibility of the associated popup.
     *
     * On any given cycle, the first execution of this method should be due to
     * the user pressing a toggle button.  That button is set here as the
     * current "owner" of the modal dialog.
     *
     * @param {Selector} [target]     Default: {@link $toggle}.
     */
    toggleModal(target) {
        const $target = target && $(target);
        this.$toggle ||= $target;
        super.toggleModal($target);
    }

    /**
     * Close the popup element.
     *
     * @param {Selector} [target]     Event target causing the action.
     * @param {boolean}  [no_halt]    If *true*, hooks cannot halt the chain.
     *
     * @returns {boolean}
     */
    hidePopup(target, no_halt) {
        const hidden = super.hidePopup(target, no_halt);
        if (hidden) {
            this.$toggle = undefined;
        }
        return hidden;
    }

    // ========================================================================
    // Methods - popup toggle controls
    // ========================================================================

    /**
     * Set up all related modal toggles to operate with this instance.
     *
     * @param {Selector} [toggles]
     *
     * @returns {jQuery}              The provided or discovered toggles.
     */
    associateAll(toggles) {
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
    static get $modals() { return $('body').children(this.MODAL) }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Create a ModalDialog instance for each modal popup and associate it with
     * all related modal toggle controls.
     *
     * @returns {jQuery}              The provided or discovered toggles.
     */
    static initializeAll() {
        let $toggles    = $();
        const type_data = this.CLASS_ATTR;
        const this_type = this.CLASS_NAME;
        const link_data = this.MODAL_INSTANCE_DATA;
        this.$modals.each((_, element) => {
            const $modal = $(element);
            let instance, type;
            if ((type = $modal.data(type_data)) && (type !== this_type)) {
                this._debug(`skipping modal for ${type}`);
            } else if ((instance = $modal.data(link_data))) {
                this._debug('modal already linked to', instance);
            } else {
                // noinspection JSUnresolvedFunction
                $.merge($toggles, this.new($modal).associateAll());
            }
        });
        return $toggles;
    }

}
