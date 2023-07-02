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
 * @typedef {SubmitResponseItem[]} SubmitResponseData
 */

/**
 * @typedef {object} SubmitStepResponseItem
 *
 * @property {string} [note]
 * @property {string} [error]
 */

/**
 * @typedef {Object.<string,SubmitStepResponseItem>} SubmitStepResponseItems
 */

/**
 * @typedef {object} SubmitStepResponseData
 *
 * @property {number}                  count
 * @property {string[]}                submitted
 * @property {string[]}                [invalid]
 * @property {SubmitStepResponseItems} [success]
 * @property {SubmitStepResponseItems} [failure]
 */

/**
 * SubmitResponseSubclass
 *
 * @typedef {
 *      SubmitResponse|
 *      SubmitInitialResponse|
 *      SubmitStepResponse|
 *      SubmitFinalResponse|
 *      SubmitControlResponse
 * } SubmitResponseSubclass
 */

// ============================================================================
// Type definitions - payloads
// ============================================================================

/**
 * @typedef {ChannelResponsePayload} BaseSubmitResponsePayload
 *
 * @property {boolean} [simulation]
 * @property {string}  manifest_id
 *
 * @see "SubmissionService::Response::TEMPLATE"
 */

/**
 * @typedef {BaseSubmitResponsePayload} SubmitResponsePayload
 *
 * @property {SubmitResponseData} data
 *
 * @see "SubmissionService::SubmitResponse::TEMPLATE"
 */

/**
 * @typedef {BaseSubmitResponsePayload} SubmitStepResponsePayload
 *
 * @property {string}                 step
 * @property {SubmitStepResponseData} data
 *
 * @see "SubmissionService::StepResponse::TEMPLATE"
 */

/**
 * @typedef {BaseSubmitResponsePayload} SubmitControlResponsePayload
 *
 * @property {string} command
 *
 * @see "SubmissionService::ControlResponse::TEMPLATE"
 */

/**
 * SubmitResponseSubclassPayload
 *
 * @typedef {
 *      SubmitResponsePayload|
 *      SubmitStepResponsePayload|
 *      SubmitControlResponsePayload
 * } SubmitResponseSubclassPayload
 */

// ============================================================================
// Classes
// ============================================================================

/**
 * A SubmitChannel response message.
 *
 * @extends ChannelResponse
 * @extends BaseSubmitResponsePayload
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
     * @type {BaseSubmitResponsePayload}
     */
    static TEMPLATE = deepFreeze({
        simulation:  undefined,
        status:      undefined,
        manifest_id: undefined,
        ...super.TEMPLATE,
    });

    /**
     * Allowed status values.
     *
     * @readonly
     * @type {Object.<string,string>}
     *
     * @see "SubmitChannel::Response#STATUS"
     */
    static STATUS = deepFreeze({
        INITIAL:      'STARTING',
        STEP:         'STEP',
        INTERMEDIATE: 'DONE',
        FINAL:        'COMPLETE',
        ACK:          'ACK',
    });

    /**
     * @readonly
     * @type {Object.<string,string>}
     */
    STATUS = this.constructor.STATUS;

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

    /** @returns {BaseSubmitResponsePayload} */
    get payload()        { return super.payload }

    get simulation()     { return !!this.payload.simulation }
    get manifest_id()    { return this.payload.manifest_id }

    get isAck()          { return this.status === this.STATUS.ACK }
    get isInitial()      { return this.status === this.STATUS.INITIAL }
    get isIntermediate() { return this.status === this.STATUS.INTERMEDIATE }
    get isFinal()        { return this.status === this.STATUS.FINAL }

    // ========================================================================
    // Methods
    // ========================================================================

    /** @returns {BaseSubmitResponsePayload} */
    toObject() { return super.toObject() }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Return the item if it is an instance or create one if not.
     *
     * @param {SubmitResponseBase|BaseSubmitResponsePayload|object} item
     *
     * @returns {SubmitResponseSubclass}
     */
    static wrap(item) {
        // noinspection OverlyComplexBooleanExpressionJS
        return ((item instanceof this) && item)   ||
            SubmitControlResponse.candidate(item) ||
            SubmitFinalResponse.candidate(item)   ||
            SubmitStepResponse.candidate(item)    ||
            SubmitResponse.candidate(item)        ||
            super.wrap(item);
    }

    /**
     * Indicate whether the item is a candidate payload for the current class.
     *
     * @param {SubmitResponseBase|BaseSubmitResponsePayload|object} item
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
 * @extends SubmitResponseBase
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
        data: [],
    });

    // ========================================================================
    // Properties
    // ========================================================================

    /** @returns {SubmitResponsePayload} */
    get payload() { return super.payload }

    /** @returns {SubmitResponseData} */
    get data()    { return this.payload.data || [] }

    /** @returns {SubmitResponseItem[]} */
    get items()   { return this.data }

    // ========================================================================
    // Methods
    // ========================================================================

    /** @returns {SubmitResponsePayload} */
    toObject() { return super.toObject() }

}

/**
 * The initial bulk submission response message.
 *
 * @extends SubmitResponse
 *
 * @see "SubmitChannel::InitialResponse"
 * @see "SubmissionService::InitialResponse"
 */
export class SubmitInitialResponse extends SubmitResponse {

    static CLASS_NAME = 'SubmitInitialResponse';
    static DEBUGGING  = DEBUG;

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
        return isObject(item) && (item.status === this.STATUS.INITIAL);
    }

}

// noinspection JSCheckFunctionSignatures
/**
 * A response message with results from a bulk submission step.
 *
 * @extends SubmitResponseBase
 * @extends SubmitStepResponsePayload
 * @extends SubmitStepResponseData
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
        simulation: undefined,
        status:     undefined,
        step:       undefined,
        ...super.TEMPLATE,
        data: {
            count:     0,
            invalid:   [],
            submitted: [],
            success:   {},
            failure:   {},
        },
    });

    // ========================================================================
    // Properties
    // ========================================================================

    /** @returns {SubmitStepResponsePayload} */
    get payload()   { return super.payload }

    /** @returns {SubmitStepResponseData} */
    get data()      { return this._payload.data  || {} }
    get count()     { return this.payload.count  || 0 }
    get step()      { return this.payload.step }

    get invalid()   { return this.data.invalid   || [] }
    get submitted() { return this.data.submitted || [] }
    get success()   { return this.data.success   || {} }
    get failure()   { return this.data.failure   || {} }

    // ========================================================================
    // Methods
    // ========================================================================

    /** @returns {SubmitStepResponsePayload} */
    toObject() { return super.toObject() }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Indicate whether the item is a candidate payload for the current class.
     * <p/>
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
        return isObject(item) && (
            !!item.step ||
            (item.status === this.STATUS.STEP) ||
            (item.status === this.STATUS.INTERMEDIATE)
        );
    }

}

/**
 * The last bulk submission response message.
 *
 * @extends SubmitStepResponse
 *
 * @see "SubmitChannel::FinalResponse"
 * @see "SubmissionService::FinalResponse"
 */
export class SubmitFinalResponse extends SubmitStepResponse {

    static CLASS_NAME = 'SubmitFinalResponse';
    static DEBUGGING  = DEBUG;

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
        return isObject(item) && (item.status === this.STATUS.FINAL);
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
 * @extends SubmitResponseBase
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
        simulation: undefined,
        command:    undefined,
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

    /** @returns {SubmitControlResponsePayload} */
    get payload() { return super.payload }

    get command() { return this.payload.command }

    // ========================================================================
    // Methods
    // ========================================================================

    /** @returns {SubmitControlResponsePayload} */
    toObject() { return super.toObject() }

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
        return isObject(item) && !!item.command;
    }

}
