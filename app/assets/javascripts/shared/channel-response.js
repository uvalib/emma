// app/assets/javascripts/shared/channel-response.js


import { BaseClass }           from './base-class'
import { deepDup, deepFreeze } from './objects'


// ============================================================================
// Type definitions
// ============================================================================

/**
 * ChannelResponsePayload
 *
 * @typedef {{
 *     status?:   string,
 *     user?:     string,
 *     time?:     string,
 *     job_id?:   string,
 *     class?:    string,
 *     data?:     *,
 *     data_url?: string,
 * }} ChannelResponsePayload
 */

// ============================================================================
// Class ChannelResponse
// ============================================================================

/**
 * A channel response message.
 *
 * @extends ChannelResponsePayload
 */
export class ChannelResponse extends BaseClass {

    static CLASS_NAME = 'ChannelResponse';

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
      //service:  undefined,
        user:     undefined,
        time:     undefined,
      //duration: undefined,
      //count:    undefined,
      //discard:  undefined,
        job_id:   undefined,
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
     * @param {ChannelResponse|ChannelResponsePayload} [msg_obj]
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
  //get service()   { return this.payload.service }
    get user()      { return this.payload.user }
    get time()      { return this.payload.time }
  //get duration()  { return this.payload.duration }
  //get count()     { return this.payload.count }
  //get discard()   { return this.payload.discard }
    get job_id()    { return this.payload.job_id }
    get class()     { return this.payload.class }
    get data()      { return this.payload.data }
    get data_url()  { return this.payload.data_url }

    get payload()   { return this._payload }

    /**
     * An independent copy of the response payload.
     *
     * @returns {ChannelResponsePayload}
     */
    get payloadCopy() {
        return deepDup(this.payload);
    }

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
