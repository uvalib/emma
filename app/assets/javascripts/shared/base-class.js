// app/assets/javascripts/shared/base-class.js
//
// noinspection FunctionNamingConventionJS, JSUnusedGlobalSymbols


import { AppDebug } from '../application/debug';


const MODULE = 'BaseClass';
const DEBUG  = false;

AppDebug.file('shared/base-class', MODULE, DEBUG);

// ============================================================================
// Class BaseClass
// ============================================================================

/**
 * The base for application-defined classes which provides logging support.
 * <p/>
 *
 * **Usage Notes** <p/>
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
    static DEBUGGING = DEBUG;

    /**
     * Right-aligned width of the leading class name in console output.
     *
     * @type {number}
     */
    static CLASS_ALIGN = AppDebug.MOD_ALIGN;
    static IN_INSTANCE = Symbol('');
    static IN_CLASS    = Symbol('CLASS');

    /**
     * If debugging, emit a log entry for the constructor.
     *
     * @type {boolean}
     */
    static DEBUG_CTOR = true;

    // ========================================================================
    // Constructor
    // ========================================================================

    constructor() {
        this._debug('CTOR');
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get CLASS_NAME() { return this.constructor.CLASS_NAME }
    get CONTEXT()    { return this.constructor.IN_INSTANCE }

    // ========================================================================
    // Properties - internal
    // ========================================================================

    /** @returns {boolean} */
    get _debugging() { return this.constructor._debugging }

    /** @returns {string} */
    get _logPrefix() { return this.constructor._logPrefix }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /** @returns {undefined} */
    _error(...args)  { this.constructor._error(this.CONTEXT, ...args) }

    /** @returns {undefined} */
    _warn(...args)   { this.constructor._warn(this.CONTEXT, ...args) }

    /** @returns {undefined} */
    _log(...args)    { this.constructor._log(this.CONTEXT, ...args) }

    /** @returns {undefined} */
    _info(...args)   { this.constructor._info(this.CONTEXT, ...args) }

    /** @returns {undefined} */
    _debug(...args)  { this.constructor._debug(this.CONTEXT, ...args) }

    /** @returns {array} */
    _prefix(...args) { return this.constructor._prefix(this.CONTEXT, ...args) }

    // ========================================================================
    // Class properties
    // ========================================================================

    static get CONTEXT() { return this.IN_CLASS }

    // ========================================================================
    // Class properties - internal
    // ========================================================================

    /**
     * Indicate whether diagnostic console output is enabled for the class and
     * its instances.
     *
     * @returns {boolean}
     * @protected
     */
    static get _debugging() {
        return AppDebug.activeFor(this.CLASS_NAME, this.DEBUGGING);
    }

    /**
     * Leading text for class console messages.
     *
     * @returns {string}
     * @protected
     */
    static get _logPrefix() {
        const class_name = this.CLASS_NAME.padEnd(this.CLASS_ALIGN);
        return `${class_name} -`;
    }

    // ========================================================================
    // Class methods - internal
    // ========================================================================

    /** @returns {undefined} */
    static _error(...args) { console.error(...this._prefix(...args)) }

    /** @returns {undefined} */
    static _warn(...args)  { console.warn(...this._prefix(...args)) }

    /** @returns {undefined} */
    static _log(...args)   { console.log(...this._prefix(...args)) }

    /** @returns {undefined} */
    static _info(...args)  {
        this._debugging && console.info(...this._prefix(...args));
    }

    /** @returns {undefined} */
    static _debug(...args) {
        this._debugging && console.debug(...this._prefix(...args));
    }

    /**
     * Prepend {@link _logPrefix} to an argument list.
     *
     * @param {Symbol,array,*} first
     * @param {...*}           [args]
     *
     * @returns {*[]}
     * @protected
     */
    static _prefix(first, ...args) {
        let start, context;
        if (typeof first === 'symbol') {
            start   = Array.isArray(args[0]) ? args.shift() : [];
            context = first;
        } else if (Array.isArray(first)) {
            start   = first;
            context = (typeof start[0] === 'symbol') && start.shift();
        } else {
            start   = [first];
            context = (typeof args[0] === 'symbol') && args.shift();
        }
        if (!context) {
            start = [this.CONTEXT.description, ...start]; // Def. class context
        } else if (context.description) {
            start = [context.description, ...start];
        }
        return AppDebug.consoleArgs(this._logPrefix, ...start, ...args);
    }

}
