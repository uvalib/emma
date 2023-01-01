// app/assets/javascripts/shared/lookup-response.js


import { AppDebug }        from '../application/debug';
import { ChannelResponse } from './channel-response';
import { deepFreeze }      from './objects';


const MODULE = 'LookupResponse';
const DEBUG  = true;

AppDebug.file('shared/lookup-response', MODULE, DEBUG);

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
 * @typedef LookupResponseItemsData
 *
 * @property {LookupResponseItems} items
 */

/**
 * @typedef LookupResponseBlendData
 *
 * @property {LookupResponseItem} blend
 */

/**
 * @typedef {ChannelResponsePayload} LookupResponsePayload
 *
 * @property {string|string[]} [service]
 * @property {number}          [duration]
 * @property {number}          [count]
 * @property {string|string[]} [discard]
 * @property {LookupResponseItemsData|LookupResponseBlendData} [data]
 */

// ============================================================================
// Class LookupResponse
// ============================================================================

/**
 * A lookup response message.
 *
 * @extends LookupResponsePayload
 */
export class LookupResponse extends ChannelResponse {

    static CLASS_NAME = 'LookupResponse';
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * A blank object containing an array value for every key defined by
     * {@link REQUEST_TYPE}.
     *
     * @readonly
     * @type {LookupResponsePayload}
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
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {LookupResponse|LookupResponsePayload|object} [msg_obj]
     */
    constructor(msg_obj) {
        super(msg_obj);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    /** @returns {LookupResponsePayload} */
    get payload()     { return this._payload }

    get service()     { return this.payload.service }
    get duration()    { return this.payload.duration }
    get count()       { return this.payload.count }
    get discard()     { return this.payload.discard }

    /** @returns {LookupResponsePayload} */
    get payloadCopy() { return super.payloadCopy }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Return the item if it is an instance or create one if not.
     *
     * @param {LookupResponse|LookupResponsePayload|object} item
     *
     * @returns {LookupResponse}
     */
    static wrap(item) {
        // noinspection JSValidateTypes
        return super.wrap(item);
    }

}
