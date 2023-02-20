// app/assets/javascripts/shared/submit-response.js


import { AppDebug }             from '../application/debug';
import { ChannelResponse }      from './channel-response';
import { deepFreeze, isObject } from './objects';


const MODULE = 'SubmitResponse';
const DEBUG  = true;

AppDebug.file('shared/submit-response', MODULE, DEBUG);

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {object} SubmitResponseItem
 */

/**
 * @typedef {SubmitResponseItem[]} SubmitResponseItems
 */

/**
 * @typedef SubmitStepResponseData
 *
 * @property {number}                 count
 * @property {string[]}               submitted
 * @property {string[]}               [success]
 * @property {Object.<number,string>} [failure]
 * @property {string[]}               [invalid]
 */

/**
 * @typedef SubmitStatusResponseData
 *
 * @property {number}                 count
 * @property {string[]}               submitted
 * @property {string[]}               [success]
 * @property {Object.<number,string>} [failure]
 * @property {string[]}               [invalid]
 */

/**
 * SubmitResponseSubclass
 *
 * @typedef {
 *      SubmitControlResponse|
 *      SubmitStatusResponse|
 *      SubmitStepResponse|
 *      SubmitResponse
 * } SubmitResponseSubclass
 */

// ============================================================================
// Type definitions - payloads
// ============================================================================

/**
 * @typedef {ChannelResponsePayload} SubmitResponseBasePayload
 *
 * @property {string} manifest_id
 */

/**
 * @typedef {SubmitResponseBasePayload} SubmitResponsePayload
 *
 * @property {SubmitResponseItems} data
 */

/**
 * @typedef {SubmitResponseBasePayload} SubmitStepResponsePayload
 *
 * @property {string}                 step
 * @property {SubmitStepResponseData} data
 */

/**
 * @typedef {SubmitResponseBasePayload} SubmitControlResponsePayload
 *
 * @property {string} command
 */

/**
 * @typedef {SubmitResponseBasePayload} SubmitStatusResponsePayload
 *
 * @property {SubmitStatusResponseData} data
 */

/**
 * SubmitResponseSubclassPayload
 *
 * @typedef {
 *      SubmitStatusResponsePayload|
 *      SubmitControlResponsePayload|
 *      SubmitStepResponsePayload|
 *      SubmitResponsePayload
 * } SubmitResponseSubclassPayload
 */

// ============================================================================
// Classes
// ============================================================================

/**
 * A SubmitChannel response message.
 *
 * @extends SubmitResponseBasePayload
 *
 * @see "SubmitChannel::Response"
 * @see "SubmissionService::Response"
 */
export class SubmitResponseBase extends ChannelResponse {

    static CLASS_NAME = 'SubmitResponseBase';
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * A blank payload object.
     *
     * @readonly
     * @type {SubmitResponseBasePayload}
     *
     * @see "SubmitChannel::Response::TEMPLATE"
     */
    static TEMPLATE = deepFreeze({
        status:      undefined,
        manifest_id: undefined,
        ...super.TEMPLATE,
    });

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {SubmitResponse|SubmitResponsePayload|object} [msg_obj]
     */
    constructor(msg_obj) {
        super(msg_obj);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get manifest_id()    { return this.payload.manifest_id }

    get isInitial()      { return this.status === 'STARTING' }
    get isFinal()        { return this.status === 'COMPLETE' }
    get isIntermediate() { return this.status === 'DONE' }

    /** @returns {SubmitResponseBasePayload} */
    get payload() { return this._payload }

    /** @returns {SubmitResponseBasePayload} */
    get payloadCopy() { return super.payloadCopy }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Return the item if it is an instance or create one if not.
     *
     * @param {SubmitResponseBase|SubmitResponseBasePayload|object} item
     *
     * @returns {SubmitResponseSubclass}
     */
    static wrap(item) {
        return (item instanceof this) && item ||
            SubmitControlResponse.candidate(item) ||
            SubmitStepResponse.candidate(item) ||
            SubmitResponse.candidate(item);
    }

    /**
     * Indicate whether the item is a candidate payload for the current class.
     *
     * @param {SubmitResponseBase|SubmitResponseBasePayload|object} item
     *
     * @returns {SubmitResponseSubclass|SubmitResponseBase|undefined}
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
 * A bulk submission response message.
 *
 * @extends SubmitResponsePayload
 *
 * @see "SubmitChannel::SubmitResponse"
 * @see "SubmissionService::SubmitResponse"
 */
export class SubmitResponse extends SubmitResponseBase {

    static CLASS_NAME = 'SubmitResponse';
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * A blank payload object.
     *
     * @readonly
     * @type {SubmitResponsePayload}
     */
    static TEMPLATE = deepFreeze({
        ...super.TEMPLATE,
        data: {},
    });

    // ========================================================================
    // Properties
    // ========================================================================

    get items() { return this.data?.items || [] }

    // noinspection JSCheckFunctionSignatures
    /** @returns {SubmitResponsePayload} */
    get payload() { return this._payload }

    // noinspection JSCheckFunctionSignatures
    /** @returns {SubmitResponsePayload} */
    get payloadCopy() { return super.payloadCopy }

}

// noinspection JSCheckFunctionSignatures
/**
 * A response message with results from a bulk submission step.
 *
 * @extends SubmitStepResponsePayload
 *
 * @see "SubmitChannel::StepResponse"
 * @see "SubmissionService::StepResponse"
 * @see "SubmissionService::BatchSubmitResponse"
 */
export class SubmitStepResponse extends SubmitResponseBase {

    static CLASS_NAME = 'SubmitStepResponse';
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * A blank payload object.
     *
     * @readonly
     * @type {SubmitStepResponsePayload}
     */
    static TEMPLATE = deepFreeze({
        status: undefined,
        step:   undefined,
        ...super.TEMPLATE,
        data: {
            count:     0,
            submitted: [],
            success:   [],
            failure:   {},
            invalid:   [],
        },
    });

    // ========================================================================
    // Properties
    // ========================================================================

    get step()      { return this.payload.step }
    get submitted() { return this.payload.data?.submitted || [] }
    get success()   { return this.payload.data?.success   || [] }
    get failure()   { return this.payload.data?.failure   || {} }
    get invalid()   { return this.payload.data?.invalid   || [] }

    // noinspection JSCheckFunctionSignatures
    /** @returns {SubmitStepResponsePayload} */
    get payload() { return this._payload }

    // noinspection JSCheckFunctionSignatures
    /** @returns {SubmitStepResponsePayload} */
    get payloadCopy() { return super.payloadCopy }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Indicate whether the item is a candidate payload for the current class.
     *
     * This casts an intermediate batch status response as a step response
     * so that onSubmissionResponse() in manifest-remit.js will work even if
     * only responses at the end of batch jobs are returned (and step responses
     * have been turned off). [Not currently possible in the server-side code.]
     *
     * @param {*} item
     *
     * @returns {boolean}
     */
    static isCandidate(item) {
        if (!isObject(item)) { return false }
        return item.hasOwnProperty('step') || (item.status === 'DONE');
    }

}

// noinspection JSCheckFunctionSignatures
/**
 * A bulk submission job control response.
 *
 * COMMANDS =
 *  'start'
 *  'stop'
 *  'pause'
 *  'resume'
 *
 * @extends SubmitControlResponsePayload
 *
 * @see "SubmitChannel::ControlResponse"
 * @see "SubmissionService::ControlResponse"
 */
export class SubmitControlResponse extends SubmitResponseBase {

    static CLASS_NAME = 'SubmitControlResponse';
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * A blank payload object.
     *
     * @readonly
     * @type {SubmitControlResponsePayload}
     */
    static TEMPLATE = deepFreeze({
        command: undefined,
        ...super.TEMPLATE
    });

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {SubmitControlResponse|SubmitControlResponsePayload|string} item
     */
    constructor(item) {
        if (typeof item === 'string') {
            super();
            this.payload.command = item;
        } else {
            super(item);
        }
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get command() { return this.payload.command }

    // noinspection JSCheckFunctionSignatures
    /** @returns {SubmitControlResponsePayload} */
    get payload() { return this._payload }

    // noinspection JSCheckFunctionSignatures
    /** @returns {SubmitControlResponsePayload} */
    get payloadCopy() { return super.payloadCopy }

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

/**
 * A bulk submission status response.
 *
 * @extends SubmitStatusResponsePayload
 *
 * @see "SubmitChannel::StatusResponse"
 * @see "SubmissionService::StatusResponse"
 */
export class SubmitStatusResponse extends SubmitResponseBase {

    static CLASS_NAME = 'SubmitStatusResponse';
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * A blank payload object.
     *
     * @readonly
     * @type {SubmitStatusResponsePayload}
     *
     * @see "SubmitChannel::StatusResponse::TEMPLATE"
     */
    static TEMPLATE = deepFreeze({
        ...super.TEMPLATE,
        data: {
            count:     undefined,
            submitted: undefined,
            success:   undefined,
            failure:   undefined,
            invalid:   undefined,
        },
    });

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {SubmitStatusResponse|SubmitStatusResponsePayload} item
     */
    constructor(item) {
        super(item);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    // noinspection JSCheckFunctionSignatures
    /** @returns {SubmitStatusResponsePayload} */
    get payload() { return this._payload }

    // noinspection JSCheckFunctionSignatures
    /** @returns {SubmitStatusResponsePayload} */
    get payloadCopy() { return super.payloadCopy }

}
