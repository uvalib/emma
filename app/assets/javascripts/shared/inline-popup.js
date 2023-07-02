// app/assets/javascripts/shared/inline-popup.js
//
// noinspection JSUnusedGlobalSymbols


import { AppDebug }             from '../application/debug';
import { HIDDEN, selector }     from './css';
import { isMissing, isPresent } from './definitions';
import { windowEvent }          from './events';
import { ModalBase }            from './modal-base';


const MODULE = 'InlinePopup';
const DEBUG  = false;

AppDebug.file('shared/inline-popup', MODULE, DEBUG);

// ============================================================================
// Class InlinePopup
// ============================================================================

/**
 * A class for managing the state of an inline popup, with a visible toggle
 * control and an (initially-hidden) popup-panel.
 *
 * @extends ModalBase
 *
 * @example
 *  <div class="inline-popup">
 *      <div class="control">...</div>
 *      <div class="popup-panel">...</div>
 *  </div>
 */
export class InlinePopup extends ModalBase {

    static CLASS_NAME      = 'InlinePopup';
    static DEBUGGING       = DEBUG;

    static ENCLOSURE_CLASS = 'inline-popup';
    static ENCLOSURE       = selector(this.ENCLOSURE_CLASS);

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {Selector} control
     * @param {Selector} [modal]
     */
    constructor(control, modal) {
        let [$control, _modal] = [$(control), modal];
        if ($control.is(InlinePopup.ENCLOSURE)) {
            _modal   = $control.children(InlinePopup.PANEL);
            $control = $control.children(InlinePopup.TOGGLE);
        }
        super($control, _modal);
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Open the popup element.
     *
     * @param {boolean} [no_halt]     If **true**, hooks cannot halt the chain.
     *
     * @returns {boolean}
     */
    open(no_halt) {
        const result = super.open(no_halt);
        if (isPresent(this.constructor.$open_popups)) {
            this.constructor._attachWindowEventHandlers();
        }
        return result;
    }

    /**
     * Close the popup element.
     *
     * @param {boolean}  [no_halt]    If **true**, hooks cannot halt the chain.
     *
     * @returns {boolean}
     */
    close(no_halt) {
        const result = super.close(no_halt);
        if (isMissing(this.constructor.$open_popups)) {
            this.constructor._detachWindowEventHandlers();
        }
        return result;
    }

    // ========================================================================
    // Class properties
    // ========================================================================

    /**
     * Inline popup wrappers containing a "control" and a "popup-panel".
     *
     * @type {jQuery}
     */
    static get $enclosures() { return $(this.ENCLOSURE).not('.for-example') }

    /**
     * All inline popup panel elements on the page.
     *
     * @type {jQuery}
     */
    static get $popups() { return this.$enclosures.children(this.PANEL) }

    /**
     * All popups which are currently open.
     *
     * @returns {jQuery}
     */
    static get $open_popups() { return this.$popups.not(HIDDEN) }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Create an InlinePopup instance for each inline popup on the current
     * page.
     */
    static initializeAll() {
        this._debug('initializeAll');
        const $popups = this.$enclosures;
        if (isPresent($popups)) {
            $popups.each((_, enclosure) => new this(enclosure));
            this._attachWindowEventHandlers();
        }
    }

    /**
     * Close all indicated popups (by default, all inline popups that are not
     * already closed).
     *
     * @param {Selector} [popups]     Default: {@link $open_popups}.
     */
    static closeAllOpenPopups(popups) {
        const func    = 'closeAllOpenPopups';
        const $popups = popups ? $(popups) : this.$open_popups;
        $popups.each((_, p) =>
            this.instanceFor(p)?.close() ||
            this._error(`${func}: no data(${this.MODAL_INSTANCE_DATA}) for`, p)
        );
    }

    /**
     * Find the associated popup element.
     *
     * @param {Selector} target
     *
     * @returns {jQuery}
     */
    static findPopup(target) {
        const $tgt = $(target);
        if ($tgt.is(this.PANEL))     { return $tgt }
        if ($tgt.is(this.TOGGLE))    { return $tgt.siblings(this.PANEL) }
        if ($tgt.is(this.ENCLOSURE)) { return $tgt.children(this.PANEL) }
        return $tgt.parents(this.ENCLOSURE).first().children(this.PANEL);
    }

    /**
     * Find the associated InlinePopup instance.
     *
     * @param {Selector} target
     *
     * @returns {InlinePopup|undefined}
     */
    static instanceFor(target) {
        const $target = $(target);
        return super.instanceFor($target) ||
            this.findPopup($target).data(this.MODAL_INSTANCE_DATA);
    }

    /**
     * Actions when leaving the page.
     *
     * @see appTeardown()
     */
    static teardown() {
        this.closeAllOpenPopups();
        this._detachWindowEventHandlers();
    }

    // ========================================================================
    // Class methods - internal
    // ========================================================================

    /**
     * Set up event handlers on {@link window}.
     *
     * @param {boolean} [attach]    Default **true**.
     *
     * @protected
     */
    static _attachWindowEventHandlers(attach) {
        const detach  = (attach === false);
        const options = detach ? { listen: false } : {};
        windowEvent('keyup', this._onKeyUp.bind(this), options);
        windowEvent('click', this._onClick.bind(this), options);
    }

    /**
     * Remove event handlers from {@link window}.
     *
     * @protected
     */
    static _detachWindowEventHandlers() {
        this._attachWindowEventHandlers(false);
    }

    /**
     * Allow the **Escape** key to close an open popup. <p/>
     *
     * If the event originates from outside of a popup control or open popup,
     * then close all open popups.
     *
     * @param {jQuery.Event|KeyboardEvent} event
     *
     * @returns {EventHandlerReturn}
     * @protected
     */
    static _onKeyUp(event) {
        //this._debug(`_onKeyUp: key "${key}"`, event);
        const key = event.key;
        if (key === 'Escape') {
            this._debug(`_onKeyUp: key "${key}"`, event);
            const $target  = $(event.target);
            const $popup   = this.findPopup($target).not(HIDDEN);
            const instance = this.instanceFor($popup);
            if (instance) {
                this._debug('> ESC pressed - close the open popup');
                if (instance._hidePopup($target)) {
                    return false;
                }
            } else {
                this._debug('> ESC pressed - close ALL open popups');
                this.closeAllOpenPopups();
                return false;
            }
        }
    }

    /**
     * Close all popups that are not hidden when clicking outside of a popup
     * control or popup panel.
     *
     * @param {jQuery.Event|MouseEvent} event
     *
     * @returns {undefined}
     * @protected
     */
    static _onClick(event) {
        //this._debug('_onClick:', event);
        let inside = undefined;

        // Clicked directly on a popup control or panel.
        const $target = $(event.target);
        inside ||= $target.is(this.PANEL)     && 'on an open popup panel';
        inside ||= $target.is(this.ENCLOSURE) && 'within a popup control';
        inside ||= $target.is(this.TOGGLE)    && 'on a popup control';

        // Clicked inside a popup control or panel.
        const $parent = !inside && $target.parents();
        inside ||= $parent.is(this.PANEL)     && 'within an open popup panel';
        inside ||= $parent.is(this.ENCLOSURE) && 'on a popup control';

        // Clicked outside?
        if (inside) {
            this._debug(`> CLICK ${inside}`);
        } else {
            this._debug('> CLICK outside of popup controls or panels');
            this.closeAllOpenPopups();
        }
    }

}
