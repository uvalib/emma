// app/assets/javascripts/shared/channel-request.js


import { AppDebug }                       from '../application/debug';
import { arrayWrap }                      from './arrays'
import { BaseClass }                      from './base-class';
import { isEmpty, isPresent, notDefined } from './definitions';
import { fromJSON, toObject }             from './objects';


const MODULE = 'ChannelRequest';
const DEBUG  = true;

AppDebug.file('shared/channel-request', MODULE, DEBUG);

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {object} ChannelRequestPayload
 */

// ============================================================================
// Class ChannelRequest
// ============================================================================

/**
 * An outbound channel message.
 *
 * @extends BaseClass
 */
export class ChannelRequest extends BaseClass {

    static CLASS_NAME = 'ChannelRequest';
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * A blank payload object
     *
     * @readonly
     * @type {ChannelRequestPayload}
     */
    static TEMPLATE = Object.freeze({});

    // ========================================================================
    // Fields
    // ========================================================================

    /** @type {ChannelRequestPayload} */
    _parts;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {*} [items]
     * @param {*} [_args]
     */
    constructor(items, ..._args) {
        super();
        this.clear();
        this.add(items);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get parts()  { return this._parts }
    get length() { return Object.keys(this._parts).length }

    /**
     * A copy of the request payload object (possibly a subset of the payload
     * data depending on the subclass).
     *
     * @returns {ChannelRequestPayload}
     */
    get requestPayload() {
        return this.toObject();
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * A copy of the request payload data.
     *
     * @returns {ChannelRequestPayload}
     */
    toObject() {
        return $.extend(true, this._blankParts(), this.parts);
    }

    /**
     * Clear all request parts.
     */
    clear() {
        this._debug('clear');
        this._parts = this._blankParts();
    }

    /**
     * Add one or more items.
     *
     * @param {*} [item]
     * @param {*} [_args]
     */
    add(item, ..._args) {
        this._debug('add', item);
        if (notDefined(item)) { return }
        const type  = typeof(item);
        const obj   = (type !== 'string') && !Array.isArray(item);
        const value = obj ? item : this.parse(item, ..._args);
        if (isPresent(value)) {
            this._appendParts(value.parts || value);
        } else {
            this._warn('nothing to add');
        }
    }

    /**
     * Create a request payload from the provided value.
     *
     * @param {string|string[]} v
     * @param {*}               [_args]
     *
     * @returns {ChannelRequestPayload}
     */
    parse(v, ..._args) {
        this._debug('parse', v);
        const items = (typeof v === 'string') ? v.split("\n") : arrayWrap(v);
        return toObject(items, (item) => this.extractParts(item));
    }

    /**
     * Split the item string into key/value pairs ordered according to
     * {@link TEMPLATE}.
     *
     * @param {string} item
     *
     * @returns {object}
     */
    extractParts(item) {
        this._debug('extractParts', item);
        return { ...this._blankParts(), ...fromJSON(item) };
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * Append the elements from *src* to this._parts.
     *
     * @param {object} src
     *
     * @protected
     */
    _appendParts(src) {
        this._debug('_appendParts', src);
        const template = this.constructor.TEMPLATE;
        Object.keys(template).forEach(key => {
            const src_v = src[key];
            if (isPresent(src_v)) {
                let new_v = src_v;
                if (Array.isArray(template[key])) {
                    const dst_v = this.parts[key];
                    new_v = Array.from(new Set([...dst_v, ...new_v]));
                }
                this.parts[key] = new_v;
            }
        });
    }

    /**
     * Generate a new empty request payload.
     *
     * @returns {ChannelRequestPayload}
     * @protected
     */
    _blankParts() {
        return this.constructor.blankParts();
    }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Generate a new empty request payload.
     *
     * @returns {ChannelRequestPayload}
     */
    static blankParts() {
        return $.extend(true, {}, this.TEMPLATE);
    }

    /**
     * Return the item if it is an instance or create one if not.
     *
     * @param {*} [item]
     * @param {*} [args]
     *
     * @returns {this}
     */
    static wrap(item, ...args) {
        if ((item instanceof this) && isEmpty(args)) {
            return item;
        } else {
            return new this(item, ...args);
        }
    }
}
