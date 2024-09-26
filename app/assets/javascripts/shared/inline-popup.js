// app/assets/javascripts/shared/inline-popup.js
//
// noinspection JSUnusedGlobalSymbols


import { AppDebug }                 from "../application/debug";
import { Emma }                     from "./assets";
import { HIDDEN, selector }         from "./css";
import { isMissing, isPresent }     from "./definitions";
import { windowEvent }              from "./events";
import { keyCombo }                 from "./keyboard";
import { ModalBase, PANEL, TOGGLE } from "./modal-base";


const MODULE = "InlinePopup";
const DEBUG  = Emma.Debug.JS_DEBUG_INLINE_POPUP;

AppDebug.file("shared/inline-popup", MODULE, DEBUG);

// ============================================================================
// Constants
// ============================================================================

const ENCLOSURE_CLASS = "inline-popup";
const ENCLOSURE       = selector(ENCLOSURE_CLASS);

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

    static CLASS_NAME      = "InlinePopup";
    static DEBUGGING       = DEBUG;

    static ENCLOSURE       = selector(ENCLOSURE_CLASS);

    // ========================================================================
    // Class fields
    // ========================================================================

    /** @type {boolean} */ static all_initialized;

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
        if ($control.is(ENCLOSURE)) {
            _modal   = $control.children(PANEL);
            $control = $control.children(TOGGLE);
        }
        super($control, _modal);
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Open the popup element.
     *
     * @param {boolean} [no_halt]     If *true*, hooks cannot halt the chain.
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
     * @param {boolean}  [no_halt]    If *true*, hooks cannot halt the chain.
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
    static get $enclosures() { return $(ENCLOSURE).not('.for-example') }

    /**
     * All inline popup panel elements on the page.
     *
     * @type {jQuery}
     */
    static get $popups() { return this.$enclosures.children(PANEL) }

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
     *
     * @returns {boolean}
     */
    static initializeAll() {
        const func  = "initializeAll";
        let updated = false;
        let $popups;
        if (this.all_initialized) {
            this._debug(`${func}: already initialized`);
        } else if (isMissing($popups = this.$enclosures)) {
            this._debug(`${func}: no inline popups on this page`);
        } else {
            this._debug(`${func}: ${$popups.length} inline popups`);
            $popups.each((_, enclosure) => new this(enclosure));
            this._attachWindowEventHandlers();
            updated = true;
        }
        return updated;
    }

    /**
     * Close all indicated popups (by default, all inline popups that are not
     * already closed).
     *
     * @param {Selector} [popups]     Default: {@link $open_popups}.
     */
    static closeAllOpenPopups(popups) {
        const func    = "closeAllOpenPopups";
        const $popups = popups ? $(popups) : this.$open_popups;
        $popups.each((_, p) =>
            this.instanceFor(p)?.close() ||
                this._error(`${func}: no data(${this.INSTANCE_DATA}) for`, p)
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
        if ($tgt.is(PANEL))     { return $tgt }
        if ($tgt.is(TOGGLE))    { return $tgt.siblings(PANEL) }
        if ($tgt.is(ENCLOSURE)) { return $tgt.children(PANEL) }
        return $tgt.parents(ENCLOSURE).first().children(PANEL);
    }

    /**
     * Find the associated InlinePopup instance.
     *
     * @param {Selector} target
     *
     * @returns {InlinePopup|undefined}
     */
    static instanceFor(target) {
        const name = this.INSTANCE_DATA;
        const $tgt = $(target);
        return super.instanceFor($tgt) || this.findPopup($tgt).data(name);
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
     * @param {boolean} [attach]    Default *true*.
     *
     * @protected
     */
    static _attachWindowEventHandlers(attach) {
        const detach  = (attach === false);
        const options = detach ? { listen: false } : {};
        windowEvent("keyup", this._onKeyUp.bind(this), options);
        windowEvent("click", this._onClick.bind(this), options);
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
     * @param {KeyboardEvt} event
     *
     * @returns {EventHandlerReturn}
     * @protected
     */
    static _onKeyUp(event) {
        const key  = keyCombo(event);
        const func = "_onKeyUp"; //this._debug(`${func}: key "${key}"`, event);
        if (key === "Escape") {
            this._debug(`${func}: key "${key}"`, event);
            const $target  = $(event.target);
            const $popup   = this.findPopup($target);
            const instance = this.instanceFor($popup);
            if (!instance) {
                this._info("> ESC pressed - close ALL open popups");
                this.closeAllOpenPopups();
            } else if (instance.isOpen) {
                this._info("> ESC pressed - close the open popup");
                instance.close();
            }
        }
    }

    /**
     * Close all popups that are not hidden when clicking outside of a popup
     * control or popup panel.
     *
     * @param {MouseEvt} event
     *
     * @returns {undefined}
     * @protected
     */
    static _onClick(event) {
        //this._debug("_onClick:", event);
        let inside = undefined;

        // Clicked directly on a popup control or panel.
        const $target = $(event.target);
        inside ||= $target.is(PANEL)     && "on an open popup panel";
        inside ||= $target.is(ENCLOSURE) && "within a popup control";
        inside ||= $target.is(TOGGLE)    && "on a popup control";

        // Clicked inside a popup control or panel.
        const $parent = !inside && $target.parents();
        inside ||= $parent.is(PANEL)     && "within an open popup panel";
        inside ||= $parent.is(ENCLOSURE) && "on a popup control";

        // Clicked outside?
        if (inside) {
            this._info(`> CLICK ${inside}`);
        } else {
            this._info("> CLICK outside of popup controls or panels");
            this.closeAllOpenPopups();
        }
    }

}
