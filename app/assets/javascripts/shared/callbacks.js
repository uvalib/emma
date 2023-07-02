// app/assets/javascripts/shared/callbacks.js


import { AppDebug }  from '../application/debug';
import { BaseClass } from './base-class';


const MODULE = 'CallbackChain';
const DEBUG  = false;

AppDebug.file('shared/callbacks', MODULE, DEBUG);

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {
 *      function(
 *          $target:     jQuery,
 *          check_only?: boolean,
 *          halted?:     boolean
 *      ): boolean|undefined
 * } CallbackChainFunction
 *
 * If the function returns **false**, subsequent functions in the chain will
 * still execute but will receive *halted* set to **true**.  There is no
 * provision for a subsequent function to "un-halt" the chain.
 */

/**
 * @typedef {
 *      CallbackChainFunction|CallbackChainFunction[]
 * } CallbackChainFunctions
 */

// ============================================================================
// Class CallbackChain
// ============================================================================

/**
 * CallbackChain
 *
 * @extends BaseClass
 */
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
     * @param {...CallbackChainFunctions} [callbacks]
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
     * @param {...CallbackChainFunctions} callbacks
     *
     * @returns {CallbackChainFunction[]}
     */
    prepend(...callbacks) {
        return this.callbacks = [...callbacks, ...this.callbacks].flat();
    }

    /**
     * Add callback(s) to the end of the chain.
     *
     * @param {...CallbackChainFunctions} callbacks
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
     * Execute a check on all callbacks in sequence.
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
     * Execute all callbacks in sequence.
     *
     * @param {Selector} target
     * @param {boolean}  [check_only]
     * @param {boolean}  [halted]
     *
     * @returns {boolean}
     */
    invoke(target, check_only, halted) {
        let halt   = halted;
        const $tgt = $(target);
        this.callbacks.forEach(cb => (halt = cb($tgt, check_only, halt)));
        return !halt;
    }

}
