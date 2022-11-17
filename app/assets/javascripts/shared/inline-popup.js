// app/assets/javascripts/shared/inline-popup.js
//
// noinspection JSUnusedGlobalSymbols


import { selector }    from './css'
import { isPresent }   from './definitions'
import { handleEvent } from './events'
import { ModalBase }   from './modal-base'


// ============================================================================
// Class InlinePopup
// ============================================================================

/**
 * A class for managing the state of an inline popup, with a visible toggle
 * control and an (initially-hidden) popup-panel.
 *
 * @example
 *  <div class="inline-popup">
 *      <div class="control">...</div>
 *      <div class="popup-panel">...</div>
 *  </div>
 */
export class InlinePopup extends ModalBase {

    static CLASS_NAME      = 'InlinePopup';

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
        let [_control, _modal] = [$(control), modal];
        if (_control.is(InlinePopup.ENCLOSURE)) {
            _modal   = _control.children(InlinePopup.PANEL);
            _control = _control.children(InlinePopup.TOGGLE);
        }
        super(_control, _modal);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get popupPanel()   { return this.$modal }
    get popupControl() { return this.$toggle }

    // ========================================================================
    // Class properties
    // ========================================================================

    /**
     * Inline popup wrappers containing a 'control' and a 'popup-panel'.
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
    static get $open_popups() { return this.$popups.not(this.HIDDEN) }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Create an InlinePopup instance for each inline popup on the current
     * page.
     *
     * @returns {jQuery}              The discovered inline popup toggles.
     */
    static initializeAll() {
        const $toggles = $();
        const $popups  = this.$enclosures;
        if (isPresent($popups)) {
            $popups.each((_, enclosure) => {
                // noinspection JSUnresolvedVariable
                $.merge($toggles, this.new(enclosure).popupControl);
            });
            this._attachWindowEventHandlers();
        }
        return $toggles;
    }

    /**
     * Close all indicated popups (by default, all inline popups that are not
     * already closed).
     *
     * @param {Selector} [popups]     Default: `{@link $open_popups}`.
     */
    static hideAllOpenPopups(popups) {
        const func    = 'hideAllOpenPopups';
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

    // ========================================================================
    // Class methods - internal
    // ========================================================================

    /**
     * Set up event handlers on 'window'.
     *
     * @protected
     */
    static _attachWindowEventHandlers() {
        const $window   = $(window);
        const on_key_up = this._onKeyUp.bind(this);
        const on_click  = this._onClick.bind(this);
        handleEvent($window, 'keyup', on_key_up);
        handleEvent($window, 'click', on_click);
    }

    /**
     * Allow "Escape" key to close an open popup.
     *
     * If the event originates from outside of a popup control or open popup,
     * then close all open popups.
     *
     * @param {jQuery.Event|KeyboardEvent} event
     *
     * @returns {boolean|undefined}
     * @protected
     */
    static _onKeyUp(event) {
        // this._debugEvent('_onKeyUp', event);
        const key = event.key;
        if (key === 'Escape') {
            const $target  = $(event.target);
            const $popup   = this.findPopup($target).not(this.HIDDEN);
            const instance = this.instanceFor($popup);
            if (instance) {
                this._debug('> ESC pressed - close the open popup');
                if (instance.hidePopup($target)) {
                    return false;
                }
            } else {
                this._debug('> ESC pressed - close ALL open popups');
                this.hideAllOpenPopups();
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
        // this._debugEvent('_onClick', event);
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
            this.hideAllOpenPopups();
        }
    }

}
