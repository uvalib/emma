// app/assets/javascripts/shared/base-class.js


// ============================================================================
// Class BaseClass
// ============================================================================

/**
 * The base for application-defined classes which provides logging support.
 */
export class BaseClass {

    static CLASS_NAME = 'BaseClass';

    constructor()   { this.invalid = false }

    // ========================================================================
    // Properties
    // ========================================================================

    get className() { return this.constructor.className }

    // ========================================================================
    // Protected methods
    // ========================================================================

    _log(...args)   { this.constructor._log(...args) }
    _warn(...args)  { this.constructor._warn(...args) }
    _error(...args) { this.constructor._error(...args) }

    // ========================================================================
    // Class properties
    // ========================================================================

    static get className()  { return this.CLASS_NAME }

    // ========================================================================
    // Class protected methods
    // ========================================================================

    static _log(...args)    { console.log(this.className, ...args) }
    static _warn(...args)   { console.warn(this.className, ...args) }
    static _error(...args)  { console.error(this.className, ...args) }

}
