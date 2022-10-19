// app/assets/javascripts/tool/debug.js
//
// Application-wide debugging control.
//
// This is loaded first in application.js to ensure that any module may be able
// to rely on the existence of window.DEBUG.
//
// NOTE: no imports -- this should be independent from any other modules


const STORE_KEY = 'DEBUG';

/**
 * An instance of this class is assigned to window.DEBUG to allow per-module
 * control of debug output from the console.  Turning debugging on or off:
 *
 *  window.DEBUG.on(module_name);
 *  window.DEBUG.off(module_name);
 *
 * will persist between pages via localStorage.
 *
 * Resetting debug status for a module:
 *
 *  window.DEBUG.reset(module_name);
 *
 * removes it from localStorage so that the default setting for the module is
 * honored.
 *
 */
class AppDebug {

    static CLASS_NAME = 'AppDebug';

    /**
     * @typedef {boolean|'true'|'false'} BooleanValue
     */

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance, by default initializing based on the dynamic
     * settings injected into <head> so that debugging is off by default when
     * deployed and on by default otherwise.
     *
     * @param {BooleanValue} [active]
     */
    constructor(active) {
        if (typeof active === 'undefined') {
            // noinspection JSUnresolvedVariable
            const settings = window.ASSET_OVERRIDES?.OverrideScriptSettings;
            const debug    = settings?.APP_DEBUG;
            if (typeof debug === 'undefined') {
                const deployed = settings ? settings.DEPLOYED : true;
                const in_test  = (settings?.RAILS_ENV === 'test');
                this.active = !deployed && !in_test;
            } else {
                this.active = debug;
            }
        } else {
            this.active = active;
        }
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * Store true/false setting.
     *
     * @param {string}       key
     * @param {BooleanValue} [val]
     *
     * @returns {'true'|'false'}
     * @protected
     */
    _set(key, val) {
        const value = this._valueFor(val);
        try {
            localStorage.setItem(key, value);
        }
        catch (err) {
            console.warn(`${this.constructor.CLASS_NAME}: ${key}: ${err}`);
        }
        return value;
    }

    /**
     * Retrieve a true/false setting.
     *
     * @param {string} key
     *
     * @returns {'true'|'false'|null}
     * @protected
     */
    _get(key) {
        return localStorage.getItem(key);
    }

    _delete(key) { localStorage.removeItem(key) }
    _keyFor(mod) { return `${STORE_KEY}/${mod}` }
    _valueFor(v) { return v?.toString() || 'true' }

    // ========================================================================
    // Properties
    // ========================================================================

    /**
     * Get global debugging status.
     *
     * @returns {boolean}
     */
    get active() {
        return this._get(STORE_KEY) === 'true';
    }

    /**
     * Set global debugging status.
     *
     * @param {BooleanValue} val
     */
    set active(val) {
        this._set(STORE_KEY, val);
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Get the debug setting for the indicated module.
     *
     * @param {string} mod
     *
     * @returns {'true'|'false'|null}
     */
    get(mod) {
        const key = this._keyFor(mod);
        return this._get(key);
    }

    /**
     * Set debugging on/off for the indicated module, overriding its internal
     * default if one was given.
     *
     * @param {string}       mod
     * @param {BooleanValue} [active]
     *
     * @returns {'true'|'false'}
     */
    set(mod, active) {
        const key = this._keyFor(mod);
        return this._set(key, active);
    }

    /**
     * Restore the initial self-defined debug setting for the indicated
     * module.
     *
     * @param {string} mod
     */
    reset(mod) {
        const key = this._keyFor(mod);
        this._delete(key);
    }

    // noinspection FunctionNamingConventionJS
    /**
     * Turn on debugging for the indicated module, overriding its internal
     * default if one was given.
     *
     * @param {string} mod
     *
     * @returns {'true'|'false'}
     */
    on(mod) {
        this.active || console.warn('NOTE: window.DEBUG not active');
        return this.set(mod, true);
    }

    /**
     * Turn off debugging for the indicated module, overriding its
     * internal default if one was given.
     *
     * @param {string} mod
     *
     * @returns {'true'|'false'}
     */
    off(mod) {
        return this.set(mod, false);
    }

    /**
     * Indicate the current debugging status for the given module.
     *
     * @param {string}  mod
     * @param {boolean} [mod_default]
     *
     * @returns {boolean}
     */
    activeFor(mod, mod_default) {
        if (!this.active) {
            return false;
        }
        switch (this.get(mod)) {
            case 'true':  return true;
            case 'false': return false;
            default:      return mod_default || false;
        }
    }
}

window.DEBUG ||= new AppDebug;
