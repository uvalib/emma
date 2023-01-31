// app/assets/javascripts/channels/submit-channel.js


import { AppDebug }           from '../application/debug';
import { CableChannel }       from '../shared/cable-channel';
import { hexRand }            from '../shared/random';
import { SubmitRequest }      from '../shared/submit-request';
import { SubmitResponseBase } from '../shared/submit-response';


const CHANNEL = 'SubmitChannel';
const DEBUG   = true;

AppDebug.file('channels/submit-channel', CHANNEL, DEBUG);

export class SubmitChannel extends CableChannel {

    static CLASS_NAME     = CHANNEL;
    static DEBUGGING      = DEBUG;

    static CHANNEL_NAME   = CHANNEL;
    static STREAM_ID      = hexRand();
    static DEFAULT_ACTION = 'submission_request';

    // ========================================================================
    // CableChannel overrides
    // ========================================================================

    /**
     * _createRequest
     *
     * @param {*} data
     *
     * @returns {SubmitRequest}
     * @protected
     *
     * @see "SubmitChannel#submission_request"
     */
    _createRequest(data) {
        return SubmitRequest.wrap(data);
    }

    /**
     * _createResponse
     *
     * @param {*} data
     *
     * @returns {SubmitResponseBase}
     * @protected
     *
     * @see "SubmitChannel#submission_response"
     */
    _createResponse(data) {
        return SubmitResponseBase.wrap(data);
    }
}
