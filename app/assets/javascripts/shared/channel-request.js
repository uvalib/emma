// app/assets/javascripts/shared/channel-request.js


import { arrayWrap }             from './arrays'
import { BaseClass }             from './base-class'
import { isPresent, notDefined } from './definitions'
import { deepFreeze, fromJSON }  from './objects'


// ============================================================================
// Type definitions
// ============================================================================

/**
 * ChannelRequestPayload
 *
 * @typedef {object} ChannelRequestPayload
 */

// ============================================================================
// Class ChannelRequest
// ============================================================================

/**
 * An outbound channel message.
 */
export class ChannelRequest extends BaseClass {

    static CLASS_NAME = 'ChannelRequest';

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * A blank payload object
     *
     * @readonly
     * @type {ChannelRequestPayload}
     */
    static TEMPLATE = deepFreeze(
        {}
    );

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

    get parts() { return this._parts }

    /**
     * Request payload object.
     *
     * @returns {ChannelRequestPayload}
     */
    get requestPayload() {
        return $.extend(true, this._blankParts(), this.parts);
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Clear all request parts.
     */
    clear() {
        this._parts = this._blankParts();
    }

    /**
     * Add one or more items.
     *
     * @param {*} [item]
     * @param {*} [_args]
     */
    add(item, ..._args) {
        if (notDefined(item)) { return }
        const type  = typeof(item);
        const obj   = (type !== 'string') && !Array.isArray(item);
        const value = obj ? item : this.parse(item, ..._args);
        if (isPresent(value)) {
            const req_parts = value.parts || value;
            this._appendParts(this.parts, req_parts);
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
        const items = (typeof v === 'string') ? v.split("\n") : arrayWrap(v);
        return Object.fromEntries(
            $.map(items, (item, idx) => [[idx, this.extractParts(item)]])
        );
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
        return { ...this._blankParts(), ...fromJSON(item) };
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * Generate a new empty request payload.
     *
     * @returns {ChannelRequestPayload}
     * @protected
     */
    _blankParts() {
        return this.constructor.blankParts();
    }

    /**
     * Append the elements from *src* to *dst*.
     *
     * @param {object} dst
     * @param {object} src
     *
     * @returns {object}
     * @protected
     */
    _appendParts(dst, src) {
        let src_val;
        $.each(dst, function(key, val) {
            if (isPresent(src_val = src[key])) {
                dst[key] = Array.from(new Set([...val, ...src_val]));
            }
        });
        return dst;
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
     * @returns {ChannelRequest}
     */
    static wrap(item, ...args) {
        if ((item instanceof this) && notDefined(args)) {
            return item;
        } else {
            return new this(item, args);
        }
    }
}
