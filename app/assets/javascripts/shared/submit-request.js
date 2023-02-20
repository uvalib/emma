// app/assets/javascripts/shared/submit-request.js
//
// noinspection JSUnusedGlobalSymbols


import { AppDebug }             from '../application/debug';
import { ChannelRequest }       from './channel-request';
import { deepFreeze, isObject } from './objects';


const MODULE = 'SubmitRequest';
const DEBUG  = true;

AppDebug.file('shared/submit-request', MODULE, DEBUG);

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {ChannelRequestPayload} SubmitRequestPayload
 *
 * @property {boolean}  [simulation]
 * @property {string}   manifest_id
 * @property {string[]} items           IDs of ManifestItems to submit.
 *
 * @see "SubmissionService::Request::TEMPLATE"
 */

/**
 * @typedef {SubmitRequestPayload} SubmitControlRequestPayload
 *
 * @property {string} command
 * @property {string} job_id
 *
 * @see "SubmissionService::ControlRequest::TEMPLATE"
 */

// ============================================================================
// Class SubmitRequest
// ============================================================================

/**
 * A bulk submission request message.
 *
 * @extends SubmitRequestPayload
 *
 * @see "SubmissionService::SubmitRequest"
 * @see "SubmissionService::BatchSubmitRequest"
 */
export class SubmitRequest extends ChannelRequest {

    static CLASS_NAME = 'SubmitRequest';
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * A blank payload object.
     *
     * @readonly
     * @type {SubmitRequestPayload}
     */
    static TEMPLATE = deepFreeze({
        simulation:  undefined,
        manifest_id: undefined,
        items:       [],
    });

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {string|string[]|SubmitRequestPayload} [data]
     * @param {*}                                    [_args]
     */
    constructor(data, ..._args) {
        super(data);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    /** @returns {SubmitRequestPayload} */
    get parts() { return this._parts }

    get simulation()  { return !!this.parts.simulation }
    get manifest_id() { return this.parts.manifest_id }
    get items()       { return this.parts.items }

    // ========================================================================
    // Methods
    // ========================================================================

    /** @returns {SubmitRequestPayload} */
    toObject() { return super.toObject() }

    /**
     * Add one or more items.
     *
     * @param {string|string[]|SubmitRequestPayload} [item]
     * @param {*}                                    [_ignored]
     */
    add(item, ..._ignored) {
        super.add(item);
    }

    /**
     * Create a request payload from the provided value.
     *
     * @param {string|string[]} v
     * @param {*}               [_ignored]
     *
     * @returns {SubmitRequestPayload}
     */
    parse(v, ..._ignored) {
        return super.parse(v);
    }

    /**
     * Split the item string into an array of key/value pairs.
     *
     * @param {string} item
     *
     * @returns {object}
     */
    extractParts(item) {
        return super.extractParts(item);
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * Generate a new empty request payload.
     *
     * @returns {SubmitRequestPayload}
     * @protected
     */
    _blankParts() {
        return super._blankParts();
    }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Generate a new empty request payload.
     *
     * @returns {SubmitRequestPayload}
     */
    static blankParts() {
        return super.blankParts();
    }

    /**
     * Return the item if it is an instance or create one if not.
     *
     * @param {*} [item]
     * @param {*} [args]
     *
     * @returns {SubmitControlRequest|SubmitRequest}
     */
    static wrap(item, ...args) {
        return ((item instanceof this) && item)  ||
            SubmitControlRequest.candidate(item) ||
            SubmitRequest.candidate(item)        ||
            super.wrap(item, ...args);
    }

    /**
     * Return an instance of the current class which is *item* or, if possible,
     * based on the contents of *item*.
     *
     * @param {SubmitRequest|SubmitRequestPayload|object} item
     *
     * @returns {SubmitControlRequest|SubmitRequest|undefined}
     */
    static candidate(item) {
        if (item instanceof this) {
            return item;
        } else if (this.isCandidate(item)) {
            return new this(item);
        }
    }

    /**
     * Indicate whether the item is a candidate payload for the current class.
     *
     * @param {*} item
     *
     * @returns {boolean}
     */
    static isCandidate(item) {
        const obj   = isObject(item);
        if (obj && item.manifest_id) { return true }
        const items = obj ? item.items : item;
        const first = Array.isArray(items) && typeof(items[0]);
        return (first === 'string') || (first === 'number');
    }

}

// noinspection JSCheckFunctionSignatures
/**
 * A bulk submission job control message.
 *
 * @extends SubmitControlRequestPayload
 *
 * @see "SubmissionService::ControlRequest"
 */
export class SubmitControlRequest extends SubmitRequest {

    static CLASS_NAME = 'SubmitControlRequest';
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Constants
    // ========================================================================

    static ACTIONS = [
        'start',
        'stop',
        'pause',
        'resume',
    ];

    /**
     * A blank payload object.
     *
     * @readonly
     * @type {SubmitControlRequestPayload}
     */
    static TEMPLATE = deepFreeze({
        simulation: undefined,
        command:    undefined,
        job_id:     undefined,
        ...super.TEMPLATE,
    });

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {string} command
     * @param {string} [job_id]
     */
    constructor(command, job_id) {
        super();
        const values = {};
        if (command) { values.command = command }
        if (job_id)  { values.job_id  = job_id  }
        this.add(values);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    /** @returns {SubmitControlRequestPayload} */
    get parts()   { return super.parts }
    get length()  { return this.command ? (1 + super.length) : 0 }

    get command() { return this.parts.command }
    get job_id()  { return this.parts.job_id }

    // ========================================================================
    // Methods
    // ========================================================================

    /** @returns {SubmitControlRequestPayload} */
    toObject() { return super.toObject() }

    // ========================================================================
    // Class methods
    // ========================================================================

    static isCandidate(item) {
        return isObject(item) && !!item.command;
    }

}
