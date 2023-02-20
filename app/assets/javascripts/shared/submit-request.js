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

    get manifest_id() { return this.requestPayload.manifest_id }
    get items()       { return this.requestPayload.items }

    /** @returns {SubmitRequestPayload} */
    get parts() { return this._parts }

    /** @returns {SubmitRequestPayload} */
    get requestPayload() { return super.requestPayload }

    // ========================================================================
    // Methods
    // ========================================================================

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
        return (item instanceof this) && item ||
            SubmitControlRequest.candidate(item) ||
            SubmitRequest.candidate(item);
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
        return isObject(item);
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
        command: undefined,
        job_id:  undefined,
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

    get command() { return this.payload.command }
    get job_id()  { return this.requestPayload.job_id }

    // noinspection JSCheckFunctionSignatures
    /** @returns {SubmitControlRequestPayload} */
    get parts() { return super.parts }

    // noinspection JSCheckFunctionSignatures
    /** @returns {SubmitControlRequestPayload} */
    get requestPayload() { return super.requestPayload }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Indicate whether the item is a candidate payload for the current class.
     *
     * @param {*} item
     *
     * @returns {boolean}
     */
    static isCandidate(item) {
        return isObject(item) && item.hasOwnProperty('command');
    }

}
