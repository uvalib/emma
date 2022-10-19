// app/assets/javascripts/shared/callbacks.js


import { BaseClass } from './base-class'


// ============================================================================
// Type definitions
// ============================================================================

/**
 * CallbackChainFunction
 *
 * If the function returns *false*, subsequent functions in the chain will
 * still execute but will receive *halted* set to *true*.  There is no
 * provision for a subsequent function to "un-halt" the chain.
 *
 * @typedef {
 *      function(
 *          $target:     jQuery,
 *          check_only?: boolean,
 *          halted?:     boolean
 *      ): boolean|undefined
 * } CallbackChainFunction
 */

// ============================================================================
// Class CallbackChain
// ============================================================================

export class CallbackChain extends BaseClass {

    static CLASS_NAME = 'CallbackChain';

    // ========================================================================
    // Fields
    // ========================================================================

    /** @type {CallbackChainFunction[]} */ callbacks;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new callback chain instance.
     *
     * @param {...(CallbackChainFunction|CallbackChainFunction[])} [callbacks]
     */
    constructor(...callbacks) {
        super();
        this.callbacks = [...callbacks].flat();
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Add callback(s) to the start of the chain.
     *
     * @param {...(CallbackChainFunction|CallbackChainFunction[])} callbacks
     *
     * @returns {CallbackChainFunction[]}
     */
    prepend(...callbacks) {
        return this.callbacks = [...callbacks, ...this.callbacks].flat();
    }

    /**
     * Add callback(s) to the end of the chain.
     *
     * @param {...(CallbackChainFunction|CallbackChainFunction[])} callbacks
     *
     * @returns {CallbackChainFunction[]}
     */
    append(...callbacks) {
        return this.callbacks = [...this.callbacks, ...callbacks].flat();
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * check
     *
     * @param {Selector} target
     * @param {boolean}  [halted]
     *
     * @returns {boolean}
     */
    check(target, halted) {
        return this.invoke(target, true, halted);
    }

    /**
     * invoke
     *
     * @param {Selector} target
     * @param {boolean}  [check_only]
     * @param {boolean}  [halted]
     *
     * @returns {boolean}
     */
    invoke(target, check_only, halted) {
        let ok      = !halted;
        let $target = $(target);
        this.callbacks.forEach(function(cb) {
            ok = (cb($target, check_only, !ok) !== false) && ok;
        });
        return ok;
    }

}
