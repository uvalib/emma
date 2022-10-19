// app/assets/javascripts/shared/lookup-response.js


import { BaseClass }           from './base-class'
import { deepDup, deepFreeze } from './objects'


// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {EmmaData} LookupResponseItem
 */

/**
 * @typedef {Object.<string,LookupResponseItem[]>} LookupResponseItems
 */

/**
 * @typedef {{ items: LookupResponseItems }} LookupResponseItemsData
 */

/**
 * @typedef {{ blend: LookupResponseItem }} LookupResponseBlendData
 */

/**
 * LookupResponseObject
 *
 * @typedef {{
 *     status?:   string,
 *     service?:  string|string[],
 *     user?:     string,
 *     time?:     string,
 *     duration?: number,
 *     count?:    number,
 *     discard?:  string|string[],
 *     job_id?:   string,
 *     class?:    string,
 *     data?:     LookupResponseItemsData|LookupResponseBlendData,
 *     data_url?: string,
 * }} LookupResponseObject
 */

// ============================================================================
// Class LookupResponse
// ============================================================================

/**
 * A lookup response message.
 *
 * @extends LookupResponseObject
 */
export class LookupResponse extends BaseClass {

    static CLASS_NAME = 'LookupResponse';

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
     * @type {LookupResponseObject}
     *
     * @see "LookupChannel::LookupResponse::TEMPLATE"
     */
    static TEMPLATE = deepFreeze({
        status:   undefined,
        service:  undefined,
        user:     undefined,
        time:     undefined,
        duration: undefined,
        count:    undefined,
        discard:  undefined,
        job_id:   undefined,
        class:    undefined,
        data:     undefined,
        data_url: undefined,
    });

    // ========================================================================
    // Fields
    // ========================================================================

    /** @type {LookupResponseObject} */ object = {};

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {LookupResponse|LookupResponseObject} [msg_obj]
     */
    constructor(msg_obj) {
        super();
        if (msg_obj instanceof this.constructor) {
            this.object = msg_obj.objectCopy;
        } else if (typeof msg_obj === 'object') {
            this.object = deepDup(msg_obj);
        }
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get status()    { return this.object.status }
    get service()   { return this.object.service }
    get user()      { return this.object.user }
    get time()      { return this.object.time }
    get duration()  { return this.object.duration }
    get count()     { return this.object.count }
    get discard()   { return this.object.discard }
    get job_id()    { return this.object.job_id }
    get class()     { return this.object.class }
    get data()      { return this.object.data }
    get data_url()  { return this.object.data_url }

    get final() {
        return this.constructor.FINAL_STATES.includes(this.status);
    }

    get objectCopy() {
        return deepDup(this.object);
    }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Return the item if it is an instance or create one if not.
     *
     * @param {LookupResponse|LookupResponseObject|object} item
     *
     * @returns {LookupResponse}
     */
    static wrap(item) {
        return (item instanceof this) ? item : new this(item);
    }

}
