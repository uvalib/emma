// app/assets/javascripts/channels/lookup_channel.js


import { Api }                from '../shared/api'
import { hexRand }            from '../shared/css'
import { isEmpty, isPresent } from '../shared/definitions'
import { onPageExit }         from '../shared/events'
import { LookupRequest }      from '../shared/lookup-request'
import { LookupResponse }     from '../shared/lookup-response'
import { asString }           from '../shared/strings'
import { createChannel }      from '../channels/consumer'


// ============================================================================
// Constants
// ============================================================================

const CHANNEL = 'LookupChannel';
const DEBUG   = true;

// ============================================================================
// Variables
// ============================================================================

let stream_id;

let lookup_dat;
let lookup_err;
let lookup_dia;

let lookup_dat_cb = [];
let lookup_err_cb = [];
let lookup_dia_cb = [];

// ============================================================================
// Actions
// ============================================================================

const lookup_channel = createChannel(streamName(), {

    /**
     * Called when there's incoming data on the websocket for this channel.
     *
     * @param {object} data
     */
    received(data) {
        setDiagnostic('received', data);
        response(data);
    },

    initialized:  () => setDiagnostic('initialized'),
    connected:    () => setDiagnostic('connected'),
    disconnected: () => setDiagnostic('disconnected'),
    rejected:     () => setDiagnostic('rejected'),

});

// ============================================================================
// Channel management
// ============================================================================

/**
 * A unique identifier to differentiate this channel.
 *
 * @returns {string}
 *
 * @see "ApplicationCable::Channel#stream_id"
 */
function streamId() {
    return stream_id ||= hexRand();
}

/**
 * The channel for the session.
 *
 * @returns {{ channel: string, stream_id: String? }}
 *
 * @see "ApplicationCable::Channel#stream_name"
 */
function streamName() {
    return { channel: CHANNEL, stream_id: streamId() };
}

/**
 * Generate a label for diagnostic output which identifies the specific
 * channel (including stream ID).
 *
 * @returns {string}
 */
function streamLabel() {
    const name = streamName();
    const chan = name.channel;
    const sid  = name.stream_id;
    return sid ? `${chan}[${sid}]` : chan;
}

/**
 * Force the channel to close.
 *
 * @see "ApplicationCable::Channel#unsubscribed"
 */
export function disconnect() {
    _debug('disconnect');
    lookup_channel.unsubscribe();
}

/**
 * Assert that the channel should automatically disconnect when leaving the
 * page.
 */
export function disconnectOnPageExit() {
    onPageExit(disconnect, DEBUG);
}

// ============================================================================
// Message processing
// ============================================================================

/**
 * Create a request object from the provided terms then invoke the server
 * method defined in lookup_channel.rb.
 *
 * @note {@link setCallback} is expected to have been called first.
 *
 * @param {string|string[]|LookupRequest|LookupRequestObject} terms
 *
 * @returns {boolean}
 *
 * @see "LookupChannel#lookup_request"
 */
export function request(terms) {
    _debug('request', terms);
    const request = LookupRequest.wrap(terms).requestParts;
    let requested = false;
    if (isEmpty(request)) {
        setError('No input');
    } else if (isEmpty(lookup_dat_cb)) {
        setError('No request callback set');
    } else {
        requested = !!lookup_channel.perform('lookup_request', request);
    }
    return requested;
}

/**
 * Handle a request response.
 *
 * If the entire response can't be sent back at one time, the response
 * will hold the URL from which the missing data can be acquired.
 *
 * @param {LookupResponseObject} msg_obj
 *
 * @see "ApplicationCable::Response#convert_to_data_url!"
 */
function response(msg_obj) {
    if (msg_obj.data_url) {
        fetchData(msg_obj.data_url, function(result) {
            setData($.extend({}, msg_obj, { data: result }));
        });
    } else {
        setData(msg_obj);
    }
}

/**
 * Get data that was replaced by a URL reference because it was too large.
 *
 * @param {string}       url
 * @param {XmitCallback} callback
 */
function fetchData(url, callback) {
    new Api(url, { callback: callback }).get();
}

// ============================================================================
// Response data
// ============================================================================

// noinspection JSUnusedGlobalSymbols
/**
 * Get the data message content.
 *
 * @returns {string|undefined}
 */
export function getData() {
    return lookup_dat;
}

/**
 * Set the data message content.
 *
 * @param {LookupResponse|LookupResponseObject} data
 */
export function setData(data) {
    _debug(`setData:`, data);
    lookup_dat = LookupResponse.wrap(data);
    lookup_dat_cb.forEach(cb => cb(lookup_dat));
}

/**
 * Assign the function(s) that will be invoked when something is received over
 * LookupChannel.
 *
 * @param {...function} callbacks
 */
export function setCallback(...callbacks) {
    _debug('setCallback');
    lookup_dat_cb = callbacks;
}

/**
 * Assign additional function(s) that will be invoked when something is
 * received over LookupChannel.
 *
 * @note If {@link setCallback} is called after this, the added callbacks are
 *  cleared.
 *
 * @param {...function} callbacks
 */
export function addCallback(...callbacks) {
    _debug('addCallback');
    lookup_dat_cb.push(...callbacks);
}

// ============================================================================
// Error information
// ============================================================================

// noinspection JSUnusedGlobalSymbols
/**
 * Get the error message content.
 *
 * @returns {string|undefined}
 */
export function getError() {
    return lookup_err;
}

/**
 * Set the error message content.
 *
 * @param {string} text
 * @param {...*}   log_extra
 */
export function setError(text, ...log_extra) {
    _debug(`setError: ${text}`, ...log_extra);
    const data = log_extra.map(v => asString(v)).join(', ');
    lookup_err = data ? `${text}: ${data}` : text;
    lookup_err_cb.forEach(cb => cb(lookup_err));
}

/**
 * setErrorCallback
 *
 * @param {...function} callbacks
 */
export function setErrorCallback(...callbacks) {
    _debug('setErrorCallback');
    lookup_err_cb = callbacks;
}

/**
 * addErrorCallback
 *
 * @param {...function} callbacks
 */
export function addErrorCallback(...callbacks) {
    _debug('addErrorCallback');
    lookup_err_cb.push(...callbacks);
}

// ============================================================================
// Diagnostic information
// ============================================================================

// noinspection JSUnusedGlobalSymbols
/**
 * Get the diagnostic information content.
 *
 * @returns {string|undefined}
 */
export function getDiagnostic() {
    return lookup_dia;
}

/**
 * Set the diagnostic information content.
 *
 * @param {string} text
 * @param {...*}   log_extra
 */
export function setDiagnostic(text, ...log_extra) {
    _debug(`setDiagnostic: ${text}`, ...log_extra);
    const note = `${streamLabel()} ${text}`;
    const data = log_extra.map(v => asString(v)).join(', ');
    lookup_dia = data ? `${note}: ${data}` : note;
    lookup_dia_cb.forEach(cb => cb(lookup_dia));
}

/**
 * Getting a message: this callback will be invoked once we receive something
 * over LookupChannel.
 *
 * @param {...function} callbacks
 */
export function setDiagnosticCallback(...callbacks) {
    _debug('setDiagnosticCallback');
    lookup_dia_cb = callbacks;
}

/**
 * addDiagnosticCallback
 *
 * @param {...function} callbacks
 */
export function addDiagnosticCallback(...callbacks) {
    _debug('addDiagnosticCallback');
    lookup_dia_cb.push(...callbacks);
}

// ============================================================================
// Internal functions
// ============================================================================

function _debug(text, ...extra) {
    if (DEBUG) {
        const note = `${streamLabel()} ${text}`;
        if (isPresent(extra)) {
            console.log(`${note}:`, ...extra);
        } else {
            console.log(note);
        }
    }
}
