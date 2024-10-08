// app/assets/javascripts/application/debug.js
//
// Application-wide debugging control.
//
// NOTE: It is assumed that this file is always imported in each JavaScript
//  source file, particularly to expose the @typedefs in "types.js".


import "./types"


/**
 * Default setting for emitting console log output as each module file is read.
 *
 * @type {boolean}
 */
const FILE_DEBUG = true;

// noinspection FunctionNamingConventionJS, JSUnusedGlobalSymbols
/**
 * An instance of this class is assigned to window.APP_DEBUG to allow
 * per-module control of debug output from the console. <p/>
 *
 * _**Turning debugging on or off:**_
 * ```
 *      window.APP_DEBUG.on(module_name);
 *      window.APP_DEBUG.off(module_name);
 * ```
 * persists between pages via localStorage. <p/>
 *
 * _**Resetting debug status for a module:**_
 * ```
 *      window.APP_DEBUG.reset(module_name);
 * ```
 * removes it from localStorage so that the default setting for the module is
 * honored. <p/>
 */
export class AppDebug {

    static CLASS_NAME = "AppDebug";

    // ========================================================================
    // Type definitions
    // ========================================================================

    /**
     * @typedef {boolean|"true"|"false"} BooleanValue
     */

    /**
     * @typedef {object} LoggingFunctions
     *
     * @property {function():boolean}       debugging
     * @property {function():string}        logPrefix
     * @property {function(...*):undefined} error
     * @property {function(...*):undefined} warn
     * @property {function(...*):undefined} log
     * @property {function(...*):undefined} info
     * @property {function(...*):undefined} debug
     */

    // ========================================================================
    // Constants
    // ========================================================================

    static STORE_KEY        = "DEBUG";
    static GLOBAL_STORE_KEY = this.STORE_KEY;
    static STORE_KEY_PREFIX = `${this.STORE_KEY}/`;

    /**
     * Console string substitution sequence.
     *
     * @see https://developer.mozilla.org/en-US/docs/Web/API/console
     *
     * @type {RegExp}
     */
    static CONSOLE_FMT_MATCH = /%[cdfioOs]|%(\d+(\.\d+)?|\.\d+)[dfi]/;

    /**
     * For use with {@link consoleFmt}.
     *
     * @type {Object.<string,string>}
     */
    static CONSOLE_BOX_FMT = {
        display:        "inline-block",
        padding:        "0 0.25em",
        margin:         "-0.375em 0",
        "line-height":  "1.75",
        "font-size":    "larger",
        color:          "white",
        background:     "red",
    };

    /**
     * Right-aligned width of the leading module name in console output.
     *
     * @type {number}
     */
    static MOD_ALIGN = 15;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance, by default initializing based on the dynamic
     * settings injected into `<head>` so that debugging is off by default when
     * deployed and on by default otherwise.
     *
     * @param {BooleanValue} [setting]
     */
    constructor(setting) {
        let active = setting;
        if (typeof active === "undefined") {
            // noinspection JSUnresolvedVariable
            const settings = window.ASSET_OVERRIDES?.OverrideScriptSettings;
            active = settings?.APP_DEBUG;
            if (typeof active === "undefined") {
                const deployed = settings ? settings.DEPLOYED : true;
                const in_test  = (settings?.RAILS_ENV === "test");
                active = !deployed && !in_test;
            }
        }
        this.active = active;
    }

    // ========================================================================
    // Class methods - internal
    // ========================================================================

    /**
     * Store true/false setting.
     *
     * @param {string}       key
     * @param {BooleanValue} value
     *
     * @returns {"true"|"false"}
     * @protected
     */
    static _set(key, value) {
        let setting = value.toString();
        try {
            localStorage.setItem(key, setting);
        } catch (error) {
            console.warn(`${this.CLASS_NAME}: ${key}: ${error}`);
            setting = "false";
        }
        return setting;
    }

    /**
     * Retrieve a true/false setting.
     *
     * @param {string} key
     *
     * @returns {"true"|"false"|undefined}
     * @protected
     */
    static _get(key) {
        return localStorage.getItem(key) || undefined;
    }

    /**
     * Reset a true/false setting.
     *
     * @param {string} key
     *
     * @returns {true}
     * @protected
     */
    static _clear(key)  {
        localStorage.removeItem(key);
        return true;
    }

    /**
     * Translate a module name into a storage key.
     *
     * @param {string} mod
     *
     * @returns {string}
     * @protected
     */
    static _keyFor(mod) {
        const prefix = this.STORE_KEY_PREFIX;
        return mod.startsWith(prefix) ? mod : `${prefix}${mod}`;
    }

    // ========================================================================
    // Class properties
    // ========================================================================

    /**
     * Get global debugging status.
     *
     * @returns {boolean}
     */
    static get active() {
        return this._get(this.GLOBAL_STORE_KEY) === "true";
    }

    /**
     * Set global debugging status.
     *
     * @param {BooleanValue} setting
     */
    static set active(setting) {
        const unset = (typeof setting === "undefined") || (setting === null);
        const value = unset ? false : setting;
        this._set(this.GLOBAL_STORE_KEY, value);
    }

    /**
     * Currently persisted storage keys.
     *
     * @returns {string[]}
     */
    static get statusKeys() {
        const keys = [];
        for (let i = 0; i < localStorage.length; i++) {
            const key = localStorage.key(i);
            if (key?.startsWith(this.STORE_KEY_PREFIX)) { keys.push(key) }
        }
        return keys;
    }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Get the debug setting for the indicated module.
     *
     * @param {string} mod
     *
     * @returns {"true"|"false"|undefined}
     */
    static get(mod) {
        const key = this._keyFor(mod);
        return this._get(key);
    }

    /**
     * Set debugging on/off for the indicated module, overriding its internal
     * default if one was given.
     *
     * @param {string}       mod
     * @param {BooleanValue} [active]   Default: *true*.
     *
     * @returns {"true"|"false"}
     */
    static set(mod, active) {
        const key = this._keyFor(mod);
        const val = (typeof active === "undefined") || active;
        return this._set(key, val);
    }

    /**
     * Restore the initial self-defined debug setting for the indicated
     * module.
     *
     * @param {string} mod
     *
     * @returns {true}
     */
    static reset(mod) {
        const key = this._keyFor(mod);
        return this._clear(key);
    }

    /**
     * Turn on debugging for the indicated module, overriding its internal
     * default if one was given.
     *
     * @param {string} mod
     *
     * @returns {"true"|"false"}
     */
    static on(mod) {
        if (!this.active) { console.warn("NOTE: window.APP_DEBUG not active") }
        return this.set(mod, true);
    }

    /**
     * Turn off debugging for the indicated module, overriding its
     * internal default if one was given.
     *
     * @param {string} mod
     *
     * @returns {"true"|"false"}
     */
    static off(mod) {
        return this.set(mod, false);
    }

    /**
     * Indicate the persisted debugging status for the given module.
     *
     * @param {string} mod
     *
     * @returns {boolean|undefined}
     */
    static isActive(mod) {
        if (!this.active) { return false }
        const active = this.get(mod);
        if (typeof active !== "undefined") { return active === "true" }
    }

    /**
     * Indicate the current debugging status for the given module or report
     * the given default if no status is persisted.
     *
     * @param {string}  mod
     * @param {boolean} [mod_default]
     *
     * @returns {boolean}
     */
    static activeFor(mod, mod_default) {
        const active = this.isActive(mod);
        if (typeof active === "undefined") {
            return mod_default || false;
        } else {
            return active;
        }
    }

    /**
     * Reset all debug settings by removing all localStorage entries starting
     * with {@link STORE_KEY_PREFIX}.
     *
     * @returns {true}
     */
    static resetAll() {
        this.statusKeys.forEach(key => this._clear(key));
        return true;
    }

    // ========================================================================
    // Class methods - console output
    // ========================================================================

    /**
     * Resolve console arguments to support formatting substitutions.
     *
     * @param {...*} args
     *
     * @returns {*[]}
     */
    static consoleArgs(...args) {
        let parts = Array.isArray(args[0]) ? args.shift() : [];
            parts = [...parts, ...args];

        // Formatting only applies to the first argument.
        if (typeof parts[0] !== "string") { return parts }

        // First argument already has a substitution sequence.
        if (parts[0].match(this.CONSOLE_FMT_MATCH)) { return parts }

        // Look for a substitution sequence in a later argument.
        let found    = -1;
        const leader = [];
        $.each(parts, (idx, part) => {
            if (typeof part === "string") {
                if (part.match(this.CONSOLE_FMT_MATCH)) {
                    found = idx;
                }
                leader.push(part);
            }
            return (found < 0); // break loop if found
        });

        if (found >= 0) {
            return [leader.join(" "), ...parts.slice(found+1)];
        } else {
            return parts;
        }
    }

    /**
     * Generate console log arguments for formatted log output.
     *
     * @param {string}                                 text
     * @param {string|string[]|Object.<string,string>} css
     * @param {...*}                                   args
     *
     * @returns {[string, string, ...*]}
     */
    static consoleFmt(text, css, ...args) {
        let styles;
        if (Array.isArray(css)) {
            styles = css.map(v => v.replace(/[;\s]+$/, ""));
        } else if (typeof css === "object") {
            styles = Object.entries(css).map(([k,v]) => `${k}: ${v}`);
        } else if (typeof css === "string") {
            styles = css.split(/;+\s+/);
        } else {
            return [text, ...args];
        }
        return [`%c${text}`, styles.join("; "), ...args];
    }

    /**
     * Console log output for indicating when a module file is read.
     *
     * @param {string}  path
     * @param {string}  [name]
     * @param {boolean} [debug]
     * @param {...*}    args
     */
    static file(path, name, debug, ...args) {
        const mod = "FILE";
        if (this.activeFor(mod, FILE_DEBUG)) {
            const msg = this.consoleFmt(mod, this.CONSOLE_BOX_FMT, path);
            if (name  !== undefined) { msg.push("|", name) }
            if (debug !== undefined) { msg.push("|", "DEBUG =", debug) }
            console.log(...msg, ...args);
        }
    }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Generate console logging functions for use in the executing module.
     *
     * @param {string}  mod
     * @param {boolean} dbg
     *
     * @returns {LoggingFunctions}
     */
    static consoleLogging(mod, dbg) {
        function debugging()   { return AppDebug.activeFor(mod, dbg) }
        function logPrefix()   { return `${mod.padEnd(AppDebug.MOD_ALIGN)} -` }
        function error(...arg) { console.error(..._prefix(arg)) }
        function warn(...arg)  { console.warn(..._prefix(arg)) }
        function log(...arg)   { console.log(..._prefix(arg)) }
        function info(...a)    { debugging() && console.info(..._prefix(a)) }
        function debug(...a)   { debugging() && console.debug(..._prefix(a)) }
        function _prefix(args) {
            const start = Array.isArray(args[0]) ? args.shift() : [];
            return AppDebug.consoleArgs(logPrefix(), ...start, ...args);
        }
        // noinspection JSValidateTypes
        return { debugging, logPrefix, error, warn, log, info, debug };
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    _set(key, value)    { return this.constructor._set(key, value) }
    _get(key)           { return this.constructor._get(key) }
    _clear(key)         { return this.constructor._clear(key) }
    _keyFor(mod)        { return this.constructor._keyFor(mod) }

    // ========================================================================
    // Properties
    // ========================================================================

    get active()        { return this.constructor.active }
    set active(setting) { this.constructor.active = setting }

    // ========================================================================
    // Methods
    // ========================================================================

    get(mod)            { return this.constructor.get(mod) }
    set(mod, active)    { return this.constructor.set(mod, active) }
    reset(mod)          { return this.constructor.reset(mod) }
    on(mod)             { return this.constructor.on(mod) }
    off(mod)            { return this.constructor.off(mod) }
    isActive(mod)       { return this.constructor.isActive(mod) }
    activeFor(mod, def) { return this.constructor.activeFor(mod, def) }
    resetAll()          { return this.constructor.resetAll() }
    consoleFmt(...args) { return this.constructor.consoleFmt(...args) }
    file(name, ...args) { return this.constructor.file(name, ...args) }
}

window.APP_DEBUG ||= new AppDebug();

AppDebug.file("application/debug");
