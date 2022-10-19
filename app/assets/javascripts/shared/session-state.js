// app/assets/javascripts/shared/session-state.js


import { BaseClass }             from './base-class'
import { isPresent, notDefined } from './definitions'
import { fromJSON }              from './objects'


// ============================================================================
// Functions
// ============================================================================

/**
 * Clear all sessionStorage items prefixed with the given name.
 *
 * @param {string}  name
 * @param {boolean} [debug]
 *
 * @returns {number}                  Items removed.
 */
export function removeByPrefix(name, debug) {
    const func   = 'removeByPrefix';
    const prefix = `${name}-`;
    const keys   = [];
    let key, idx = 0;
    while ((key = sessionStorage.key(idx++))) {
        if (key.startsWith(prefix)) {
            keys.push(key);
        }
    }
    if (isPresent(keys)) {
        debug && console.log(`${func}: removing`, keys);

        keys.forEach(key => sessionStorage.removeItem(key));

        // noinspection JSUnresolvedFunction
        debug && keys
            .filter( key => (sessionStorage.getItem(key) !== null))
            .forEach(key => console.warn(`${func}: ${key} NOT REMOVED`));
    }
    return keys.length;
}

// ============================================================================
// Class SessionState
// ============================================================================

/**
 * Manage state information stored in a single sessionStorage entry.
 */
export class SessionState extends BaseClass {

    static CLASS_NAME = 'SessionState';

    // ========================================================================
    // Fields
    // ========================================================================

    /** @type {string} */ storage_key;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {string|RegExp} name    Base name for sessionStorage entry.
     */
    constructor(name) {
        super();
        this.storage_key = this._makeKeyName(name);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get keyPrefix() { return this.constructor.keyPrefix; }

    /**
     * Get the raw value from sessionStorage.
     *
     * @returns {string|null}
     */
    get raw() {
        return sessionStorage.getItem(this.storage_key);
    }

    /**
     * Set the raw value in sessionStorage.
     *
     * @param {string|null} new_value
     */
    set raw(new_value) {
        if (new_value) {
            try {
                sessionStorage.setItem(this.storage_key, new_value);
            }
            catch (err) {
                this._warn(`set: ${err}`);
            }
        } else {
            this.clear();
        }
    }

    /**
     * Get the object value from sessionStorage.
     *
     * @returns {object}
     */
    get value() {
        const caller = `${this.CLASS_NAME}: get`;
        return fromJSON(this.raw, caller) || {};
    }

    /**
     * Set the value in sessionStorage.
     *
     * @param {*} new_value
     */
    set value(new_value) {
        this.raw = JSON.stringify(new_value);
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Set the value in sessionStorage.
     *
     * @param {*} [new_value]
     */
    update(new_value) {
        this.value = new_value || {};
    }

    /**
     * Remove the sessionStorage state value.
     */
    clear() {
        sessionStorage.removeItem(this.storage_key);
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * Normalize a value to the form of an object.
     *
     * @param {*} v
     *
     * @returns {object}
     * @protected
     */
    _objectify(v) {
        switch (typeof v) {
            case 'object':  return v;
            case 'boolean': return { enabled: v };
            case 'symbol':  return { value:   v.description };
            default:        return { value:   v };
        }
    }

    /**
     * Generate a sessionStore key name, prefixed with keyPrefix() if defined
     * by the subclass.
     *
     * @param {*} v
     *
     * @returns {string}
     * @protected
     */
    _makeKeyName(v) {
        let result;
        switch (typeof v) {
            case 'string':  result = v;                                 break;
            case 'bigint':  result = v.toString();                      break;
            case 'number':  result = v.toString();                      break;
            case 'boolean': result = v.toString();                      break;
            case 'symbol':  result = v.description;                     break;
            case 'object':  result = (v instanceof RegExp) && v.source; break;
        }
        if ((result = result?.trim())) {
            result = result.replaceAll(/[^a-z0-9_]+/ig, '-');
        } else if (v) {
            console.error('makeKeyName: invalid:', v);
        } else {
            console.error('makeKeyName: missing base key name');
        }
        result ||= 'KEY_NAME';
        return this.keyPrefix ? `${this.keyPrefix}-${result}` : result;
    }

    // ========================================================================
    // Class properties
    // ========================================================================

    /** @returns {string|undefined} */
    static get keyPrefix() { return undefined }
}

// ============================================================================
// Class SessionToggle
// ============================================================================

// noinspection JSUnusedGlobalSymbols
/**
 * A binary on/off state saved in sessionStorage.
 */
export class SessionToggle extends SessionState {

    static CLASS_NAME = 'SessionToggle';

    // ========================================================================
    // Type definitions
    // ========================================================================

    /**
     * ToggleState
     *
     * @typedef {{
     *     enabled?: string|null|undefined,
     * }} ToggleState
     */

    // ========================================================================
    // Properties - SessionState overrides
    // ========================================================================

    /**
     * Get the state value from sessionStorage.
     *
     * @returns {boolean}
     */
    get value() {
        return super.value.enabled === true;
    }

    /**
     * Set the state value in sessionStorage.
     *
     * @param {boolean|ToggleState} new_value
     */
    set value(new_value) {
        super.value = this._objectify(new_value || false);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    /**
     * An alias for this.value.
     *
     * @returns {boolean}
     */
    get enabled() { return this.value }

    /**
     * Set the state value in sessionStorage.
     *
     * @param {boolean|ToggleState} new_value   Default: *true*.
     */
    set enabled(new_value) {
        this.value = notDefined(new_value) || new_value;
    }

    // ========================================================================
    // Methods
    // ========================================================================

    enable()  { this.enabled = true }
    disable() { this.enabled = false }
}
