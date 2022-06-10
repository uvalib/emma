// app/assets/javascripts/shared/base-class.js


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

    // ========================================================================
    // Constructor
    // ========================================================================

    constructor() { this.invalid = false }

    // ========================================================================
    // Properties
    // ========================================================================

    // noinspection FunctionNamingConventionJS
    get CLASS_NAME() { return this.constructor.CLASS_NAME }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    _log(...args)   { this.constructor._log(...args) }
    _warn(...args)  { this.constructor._warn(...args) }
    _error(...args) { this.constructor._error(...args) }

    // ========================================================================
    // Class methods - internal
    // ========================================================================

    static _log(...args)    { console.log(this.CLASS_NAME, ...args) }
    static _warn(...args)   { console.warn(this.CLASS_NAME, ...args) }
    static _error(...args)  { console.error(this.CLASS_NAME, ...args) }

}
