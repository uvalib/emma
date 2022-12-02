// app/assets/javascripts/shared/base-class.js
//
// noinspection FunctionNamingConventionJS, JSUnusedGlobalSymbols


// No imports


// ============================================================================
// Class BaseClass
// ============================================================================

/**
 * The base for application-defined classes which provides logging support.
 *
 * **Usage Notes**
 * Subclasses are expected to define an explicit static CLASS_NAME in order to
 * make use of the diagnostic methods defined here.  (Relying on `this.name`
 * isn't sufficient because that will yield the *minified* name rather than the
 * expected original class name.)
 */
export class BaseClass {

    static CLASS_NAME = 'BaseClass';

    /**
     * Default console debug output setting (overridden per class).
     *
     * @type {boolean}
     */
    static DEBUGGING = false;

    // ========================================================================
    // Constructor
    // ========================================================================

    constructor() {
        this._debug(`${this.CLASS_NAME} CTOR`);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get CLASS_NAME() { return this.constructor.CLASS_NAME }
    get debugging()  { return this.constructor.debugging }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    _log(...args)   { this.constructor._log(...args) }
    _warn(...args)  { this.constructor._warn(...args) }
    _error(...args) { this.constructor._error(...args) }
    _debug(...args) { this.constructor._debug(...args) }

    // ========================================================================
    // Class properties
    // ========================================================================

    /** @returns {boolean} */
    static get debugging() {
        return window.DEBUG.activeFor(this.CLASS_NAME, this.DEBUGGING);
    }

    // ========================================================================
    // Class methods - internal
    // ========================================================================

    static _log(...args)    { console.log(this.CLASS_NAME, ...args) }
    static _warn(...args)   { console.warn(this.CLASS_NAME, ...args) }
    static _error(...args)  { console.error(this.CLASS_NAME, ...args) }
    static _debug(...args)  { this.debugging && this._log(...args) }

}
