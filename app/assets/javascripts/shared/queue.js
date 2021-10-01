// app/assets/javascripts/shared/queue.js

//= require shared/assets
//= require shared/definitions

// ============================================================================
// Class Queue
// ============================================================================

/**
 * A generic FIFO queue.
 */
class Queue {

    constructor(...args) { this.array = flatten(args) }

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

    // ========================================================================
    // Properties
    // ========================================================================

    get first()     { return this.array[0] }
    get last()      { return this.array[this.array.length-1] }
    get presence()  { return this.isEmpty() ? undefined : this.array }

    // ========================================================================
    // Private methods @note: Not yet handled properly by the Terser compressor
    // ========================================================================

    log(...args)   { this.constructor.log(...args) }
    warn(...args)  { this.constructor.warn(...args) }
    error(...args) { this.constructor.error(...args) }
    //#log(...args)   { this.constructor.log(...args) }
    //#warn(...args)  { this.constructor.warn(...args) }
    //#error(...args) { this.constructor.error(...args) }

    // ========================================================================
    // Class properties
    // ========================================================================

    static get className() { return 'Queue' }

    // ========================================================================
    // Class methods
    // ========================================================================

    static log(...args)    { console.log(this.className, ...args) }
    static warn(...args)   { console.warn(this.className, ...args) }
    static error(...args)  { console.error(this.className, ...args) }
}

// ============================================================================
// Class CallbackQueue
// ============================================================================

/**
 * A queue for managing a set of callbacks.
 */
class CallbackQueue extends Queue {

    /**
     * Create a new instance.
     *
     * @param {function|function[]} args
     */
    constructor(...args) {
        super(...args.filter(arg => this.validate(arg)));
    }

    // ========================================================================
    // Queue method overrides
    // ========================================================================

    /**
     * Push a callback on to the queue.
     *
     * @param {function|function[]} args
     *
     * @returns {number|undefined}
     */
    push(...args) {
        const elements = args.filter(arg => this.validate(arg));
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
        return true;
    }

    // ========================================================================
    // Properties
    // ========================================================================

    /**
     * Property which returns the process function only if there are any
     * callbacks in queue.
     *
     * @returns {function|undefined}
     */
    get callbacks() {
        return this.presence && this.process
    }

    // ========================================================================
    // Private methods @note: Not yet handled properly by the Terser compressor
    // ========================================================================

    /**
     * Indicate whether *arg* is an allowable queue element.
     *
     * @param {function|*} callback
     * @param {string}     [from]
     *
     * @returns {boolean}
     */
    validate(callback, from) {
    //#validate(callback, from) {
        const type = typeof(callback);
        if (type === 'function') {
            return true;
        } else {
            const warning = `invalid element type "${type}"`;
            this.warn(from ? `${from}: ${warning}` : warning);
            return false;
        }
    }

    // ========================================================================
    // Class properties
    // ========================================================================

    static get className() { return 'CallbackQueue' }
}
