// app/assets/javascripts/shared/lookup-response.js


import { AppDebug }        from "../application/debug";
import { ChannelResponse } from "./channel-response";
import { deepFreeze }      from "./objects";


const MODULE = "LookupResponse";
const DEBUG  = true;

AppDebug.file("shared/lookup-response", MODULE, DEBUG);

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
 * @property {string|string[]}                                 [service]
 * @property {string|string[]}                                 [discard]
 * @property {LookupResponseItemsData|LookupResponseBlendData} [data]
 */

// ============================================================================
// Class LookupResponse
// ============================================================================

/**
 * A lookup response message.
 *
 * @extends ChannelResponse
 * @extends LookupResponsePayload
 */
export class LookupResponse extends ChannelResponse {

    static CLASS_NAME = "LookupResponse";
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * A blank payload object.
     *
     * @readonly
     * @type {LookupResponsePayload}
     *
     * @see "LookupChannel::LookupResponse::TEMPLATE"
     */
    static TEMPLATE = deepFreeze({
        status:  undefined,
        service: undefined,
        ...super.TEMPLATE,
        discard: undefined,
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
    get payload() { return super.payload }
    get service() { return this.payload.service }
    get discard() { return this.payload.discard }

    // ========================================================================
    // Methods
    // ========================================================================

    /** @returns {LookupResponsePayload} */
    toObject() { return super.toObject() }

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
