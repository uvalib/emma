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
    get _debugging() { return this.constructor._debugging }

    // ========================================================================
    // Properties - internal
    // ========================================================================

    /**
     * Leading text for instance console messages.
     *
     * @returns {string}
     * @protected
     */
    get _log_prefix() {
        return this.constructor._log_prefix;
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    _log(...args)   { console.log(this._log_prefix, ...args) }
    _warn(...args)  { console.warn(this._log_prefix, ...args) }
    _error(...args) { console.error(this._log_prefix, ...args) }
    _debug(...args) { this._debugging && this._log(...args) }

    // ========================================================================
    // Class properties
    // ========================================================================

    /**
     * Indicate whether diagnostic console output is enabled for the class and
     * its instances.
     *
     * @returns {boolean}
     */
    static get _debugging() {
        return window.DEBUG.activeFor(this.CLASS_NAME, this.DEBUGGING);
    }

    // ========================================================================
    // Class properties - internal
    // ========================================================================

    /**
     * Leading text for class console messages.
     *
     * @returns {string}
     * @protected
     */
    static get _log_prefix() {
        return this.CLASS_NAME;
    }

    // ========================================================================
    // Class methods - internal
    // ========================================================================

    static _log(...args)   { console.log(this._log_prefix, ...args) }
    static _warn(...args)  { console.warn(this._log_prefix, ...args) }
    static _error(...args) { console.error(this._log_prefix, ...args) }
    static _debug(...args) { this._debugging && this._log(...args) }

}
