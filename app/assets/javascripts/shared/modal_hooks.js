// app/assets/javascripts/shared/modal_hooks.js


import { BaseClass }     from '../shared/base-class'
import { CallbackChain } from '../shared/callbacks'
import { isPresent }     from '../shared/definitions'


// ============================================================================
// Class ModalHooks
// ============================================================================

/**
 * Essentially a namespace for a set of methods for managing a dedicated
 * callback chain attached to a given modal toggle control.
 */
class ModalHooks extends BaseClass {

    static CLASS_NAME = 'ModalHooks';

    static DEBUGGING = false;

    // ========================================================================
    // Constructor
    // ========================================================================

    constructor(..._) { super(); this._error('INVALID CALL TO CONSTRUCTOR'); }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * The .data() name holding an instance of this class is simply the name of
     * the class.
     *
     * @returns {string}
     */
    static get dataName() {
        return this.CLASS_NAME;
    }

    /**
     * Initialize a chain of callback hooks.
     *
     * @param {Selector}                                           toggle
     * @param {...(CallbackChainFunction|CallbackChainFunction[])} callbacks
     *
     * @returns {CallbackChain}
     */
    static set(toggle, ...callbacks) {
        let $toggle = $(toggle);
        if (this.DEBUGGING) { this._check('set', $toggle, callbacks) }
        let hooks = new CallbackChain(...callbacks);
        $toggle.data(this.dataName, hooks);
        return hooks;
    }

    /**
     * Add callback(s) to the end of the chain.
     *
     * @param {Selector}                                           toggle
     * @param {...(CallbackChainFunction|CallbackChainFunction[])} callbacks
     *
     * @returns {CallbackChain}
     */
    static append(toggle, ...callbacks) {
        let $toggle = $(toggle);
        if (this.DEBUGGING) { this._check('append', $toggle, callbacks) }
        /** @type {CallbackChain|undefined} */
        let hooks = $toggle.data(this.dataName);
        return hooks?.append(...callbacks) || this.set($toggle, ...callbacks);
    }

    /**
     * Add callback(s) to the start of the chain.
     *
     * @param {Selector}                                           toggle
     * @param {...(CallbackChainFunction|CallbackChainFunction[])} callbacks
     *
     * @returns {CallbackChain}
     */
    static prepend(toggle, ...callbacks) {
        let $toggle = $(toggle);
        if (this.DEBUGGING) { this._check('prepend', $toggle, callbacks) }
        /** @type {CallbackChain|undefined} */
        let hooks = $toggle.data(this.dataName);
        return hooks?.prepend(...callbacks) || this.set($toggle, ...callbacks);
    }

    /**
     * Remove all callbacks from the chain.
     *
     * @param {Selector} toggle
     *
     * @returns {CallbackChain}
     */
    static clear(toggle) {
        let hooks = new CallbackChain;
        $(toggle).data(this.dataName, hooks);
        return hooks;
    }

    // ========================================================================
    // Class methods - internal
    // ========================================================================

    static _check(func, $toggle, callbacks) {
        isPresent($toggle)   || this._warn(`${func}: empty/missing toggle`);
        isPresent(callbacks) || this._warn(`${func}: empty/missing callbacks`);
    }

}

// ============================================================================
// Class ModalShowHooks
// ============================================================================

/**
 * A set of methods for managing a callback chain attached to a given modal
 * toggle control which are invoked when the associated modal popup is opened.
 */
export class ModalShowHooks extends ModalHooks {

    static CLASS_NAME = 'ModalShowHooks';

    // No subclass-specific methods currently defined.
}

// ============================================================================
// Class ModalHideHooks
// ============================================================================

/**
 * A set of methods for managing a callback chain attached to a given modal
 * toggle control which are invoked when the associated modal popup is closed.
 */
export class ModalHideHooks extends ModalHooks {

    static CLASS_NAME = 'ModalHideHooks';

    // No subclass-specific methods currently defined.
}