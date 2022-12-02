// app/assets/javascripts/channels/lookup-channel.js


import { CableChannel }   from '../shared/cable-channel'
import { LookupRequest }  from '../shared/lookup-request'
import { LookupResponse } from '../shared/lookup-response'


const CHANNEL = 'LookupChannel';

export class LookupChannel extends CableChannel {

    static CLASS_NAME     = CHANNEL;
    static CHANNEL_NAME   = CHANNEL;
    static CHANNEL_ACTION = 'lookup_request';

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
     */
    _createResponse(data) {
        return LookupResponse.wrap(data);
    }
}
