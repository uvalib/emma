// app/assets/javascripts/channels/submit-channel.js


import { AppDebug }           from '../application/debug';
import { CableChannel }       from '../shared/cable-channel';
import { hexRand }            from '../shared/random';
import { SubmitResponseBase } from '../shared/submit-response';
import {
    SubmitControlRequest,
    SubmitRequest,
} from '../shared/submit-request';


const CHANNEL = 'SubmitChannel';
const DEBUG   = true;

AppDebug.file('channels/submit-channel', CHANNEL, DEBUG);

/**
 * SubmitChannel
 *
 * @extends CableChannel
 */
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
     * Create a request object from the provided terms then invoke the server
     * method defined in lookup_channel.rb.
     *
     * @note {@link setCallback} is expected to have been called first.
     *
     * @param {*}      data
     * @param {string} [action]
     *
     * @returns {boolean}
     *
     * @see "SubmitChannel#submission_request"
     * @see "SubmitChannel#submission_control"
     */
    request(data, action) {
        if (data instanceof SubmitControlRequest) {
            return super.request(data, 'submission_control');
        } else {
            return super.request(data, action);
        }
    }

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
     * @see "SubmitChannel#initial_response"
     * @see "SubmitChannel#final_response"
     * @see "SubmitChannel#step_response"
     * @see "SubmitChannel#control_response"
     */
    _createResponse(data) {
        return SubmitResponseBase.wrap(data);
    }
}
