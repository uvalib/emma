// app/assets/javascripts/channels/lookup-channel.js


import { AppDebug }       from "../application/debug";
import { CableChannel }   from "../shared/cable-channel";
import { LookupRequest }  from "../shared/lookup-request";
import { LookupResponse } from "../shared/lookup-response";
import { hexRand }        from "../shared/random";


const CHANNEL = "LookupChannel";
const DEBUG   = true;

AppDebug.file("channels/lookup-channel", CHANNEL, DEBUG);

/**
 * LookupChannel
 *
 * @extends CableChannel
 */
export class LookupChannel extends CableChannel {

    static CLASS_NAME     = CHANNEL;
    static DEBUGGING      = DEBUG;

    static CHANNEL_NAME   = CHANNEL;
    static STREAM_ID      = hexRand();
    static DEFAULT_ACTION = "lookup_request";

    // ========================================================================
    // CableChannel overrides
    // ========================================================================

    /**
     * _createRequest
     *
     * @param {string|string[]|LookupRequest|LookupRequestPayload} terms
     *
     * @returns {LookupRequest}
     * @protected
     *
     * @see "LookupChannel#lookup_request"
     */
    _createRequest(terms) {
        return LookupRequest.wrap(terms);
    }

    /**
     * _createResponse
     *
     * @param {*} data
     *
     * @returns {LookupResponse}
     * @protected
     *
     * @see "LookupChannel#lookup_response"
     */
    _createResponse(data) {
        return LookupResponse.wrap(data);
    }
}
