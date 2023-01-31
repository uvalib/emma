// app/assets/javascripts/shared/channel-response.js


import { AppDebug }            from '../application/debug';
import { BaseClass }           from './base-class';
import { deepDup, deepFreeze } from './objects';


const MODULE = 'ChannelResponse';
const DEBUG  = true;

AppDebug.file('shared/channel-response', MODULE, DEBUG);

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef ChannelResponsePayload
 *
 * @property {string} [status]
 * @property {string} [user]
 * @property {string} [job_id]
 * @property {string} [job_type]
 * @property {string} [time]
 * @property {number} [duration]
 * @property {number} [late]
 * @property {number} [count]
 * @property {string} [class]
 * @property {*}      [data]
 * @property {string} [data_url]
 */

// ============================================================================
// Class ChannelResponse
// ============================================================================

/**
 * A channel response message.
 *
 * @extends ChannelResponsePayload
 *
 * @see "ApplicationCable::Response"
 * @see "ApplicationJob::Response"
 */
export class ChannelResponse extends BaseClass {

    static CLASS_NAME = 'ChannelResponse';
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Constants
    // ========================================================================

    // noinspection JSUnusedGlobalSymbols
    /**
     * @readonly
     * @enum {string}
     */
    static JOB_STATUS = deepFreeze([
        'WORKING',
        'LATE',
        'DONE',
        'WAITING',
        'COMPLETE',
        'PARTIAL',
        'TIMEOUT',
    ]);

    static FINAL_STATES = deepFreeze(['COMPLETE', 'PARTIAL', 'TIMEOUT']);

    /**
     * A blank object containing an array value for every key defined by
     * {@link REQUEST_TYPE}.
     *
     * @readonly
     * @type {ChannelResponsePayload}
     *
     * @see "ApplicationCable::Response::TEMPLATE"
     */
    static TEMPLATE = deepFreeze({
        status:   undefined,
        user:     undefined,
        job_id:   undefined,
        job_type: undefined,
        time:     undefined,
        duration: undefined,
        late:     undefined,
        count:    undefined,
        class:    undefined,
        data:     undefined,
        data_url: undefined,
    });

    // ========================================================================
    // Fields
    // ========================================================================

    /** @type {ChannelResponsePayload} */ _payload;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {ChannelResponse|ChannelResponsePayload|object} [msg_obj]
     */
    constructor(msg_obj) {
        super();
        if (msg_obj instanceof this.constructor) {
            this._payload = msg_obj.payloadCopy;
        } else if (typeof msg_obj === 'object') {
            this._payload = deepDup(msg_obj);
        } else if (msg_obj) {
            const error = `${typeof msg_obj} unexpected`;
            this._warn(error, msg_obj);
            // noinspection JSValidateTypes
            this._payload = { error: error };
        }
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get status()    { return this.payload.status }
    get user()      { return this.payload.user }
    get job_id()    { return this.payload.job_id }
    get job_type()  { return this.payload.job_type }
    get time()      { return this.payload.time }
    get duration()  { return this.payload.duration }
    get late()      { return this.payload.late }
    get count()     { return this.payload.count }
    get class()     { return this.payload.class }
    get data()      { return this.payload.data }
    get data_url()  { return this.payload.data_url }

    get payload()     { return this._payload }
    get payloadCopy() { return this.toObject() }

    /**
     * Indicate whether the response represents the completion of the original
     * request.
     *
     * @returns {boolean}
     */
    get final() {
        return this.constructor.FINAL_STATES.includes(this.status);
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * An independent copy of the response payload.
     *
     * @returns {ChannelResponsePayload}
     */
    toObject() {
        return deepDup(this.payload);
    }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Return the item if it is an instance or create one if not.
     *
     * @param {ChannelResponse|ChannelResponsePayload|object} item
     *
     * @returns {ChannelResponse}
     */
    static wrap(item) {
        return (item instanceof this) ? item : new this(item);
    }

}
