// app/assets/javascripts/shared/queue.js
//
// noinspection JSUnusedGlobalSymbols


import { AppDebug }  from "../application/debug";
import { flatten }   from "./arrays";
import { BaseClass } from "./base-class";
import { isEmpty }   from "./definitions";


const MODULE = "Queue";
const DEBUG  = false;

AppDebug.file("shared/queue", MODULE, DEBUG);

// ============================================================================
// Class Queue
// ============================================================================

/**
 * A generic FIFO queue.
 *
 * @extends BaseClass
 */
export class Queue extends BaseClass {

    static CLASS_NAME = "Queue";
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Fields
    // ========================================================================

    /** @type {Array} */ array;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {...any} args
     */
    constructor(...args) {
        super();
        this.array = flatten(...args);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get first()     { return this.array[0] }
    get last()      { return this.array[this.array.length-1] }
    get presence()  { return this.isEmpty() ? undefined : this.array }

    // ========================================================================
    // Methods
    // ========================================================================

    length()        { return this.array.length }
    isEmpty()       { return !this.array.length }
    notEmpty()      { return !!this.array.length }

    clear()         { this.array = [] }
    push(...args)   { return this.array.push(...args) }
    pop()           { return this.array.shift() }
    forEach(fn)     { this.array.forEach(fn) }
}

// ============================================================================
// Class CallbackQueue
// ============================================================================

/**
 * A queue for managing a set of callbacks.
 *
 * @extends Queue
 */
export class CallbackQueue extends Queue {

    static CLASS_NAME = "CallbackQueue";

    // ========================================================================
    // Fields
    // ========================================================================

    /** @type {boolean} */ finished = false;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {...function} args
     */
    constructor(...args) {
        super(...args.filter(arg => this._validate(arg)));
    }

    // ========================================================================
    // Methods - Queue overrides
    // ========================================================================

    /**
     * Push a callback on to the queue.
     *
     * @param {...function} args
     *
     * @returns {number|undefined}
     */
    push(...args) {
        const elements = args.filter(arg => this._validate(arg));
        return isEmpty(elements) ? undefined : super.push(...elements);
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Drain the queue, executing each callback present.
     *
     * @returns {true}
     */
    process() {
        this.forEach(fn => fn());
        this.clear();
        return this.finished = true;
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * Indicate whether *arg* is an allowable queue element.
     *
     * @param {function|*} callback
     * @param {string}     [from]
     *
     * @returns {boolean}
     * @protected
     */
    _validate(callback, from) {
        const type  = typeof(callback);
        const valid = (type === "function");
        if (!valid) {
            const warning = `invalid element type "${type}"`;
            this._warn(from ? `${from}: ${warning}` : warning);
        }
        return valid;
    }
}
