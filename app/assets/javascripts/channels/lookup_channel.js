// app/assets/javascripts/channels/lookup_channel.js


import { hexRand }            from '../shared/css'
import { isEmpty, isPresent } from '../shared/definitions'
import { LookupRequest }      from '../shared/lookup-request'
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
let lookup_dat_cb;
let lookup_err;
let lookup_err_cb;
let lookup_dia;
let lookup_dia_cb;

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
        lookup_dat_cb && lookup_dat_cb(data);
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

// ============================================================================
// Response data
// ============================================================================

/**
 * Assign the function that will be invoked when something is received over
 * LookupChannel.
 *
 * @param {function} fn
 */
export function setCallback(fn) {
    _debug('setCallback');
    lookup_dat_cb = fn;
}

/**
 * Create a request object from the provided terms then invoke the server
 * method defined in lookup_channel.rb.
 *
 * @note {@link setCallback} is expected to have been called first.
 *
 * @param {string|string[]|LookupRequest|LookupRequestObject} terms
 * @param {string|string[]}                                   [separator]
 *
 * @returns {boolean}
 *
 * @see "LookupChannel#lookup_request"
 */
export function request(terms, separator) {
    _debug('request', terms);
    let requested = false;
    const request = LookupRequest.parts(terms, separator);
    if (isEmpty(request)) {
        setError('No input');
    } else if (!lookup_dat_cb) {
        setError('No request callback set');
    } else {
        requested = !!lookup_channel.perform('lookup_request', request);
    }
    return requested;
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
    lookup_err_cb && lookup_err_cb(lookup_err);
}

/**
 * setErrorCallback
 *
 * @param {function} fn
 */
export function setErrorCallback(fn) {
    _debug('setErrorCallback');
    lookup_err_cb = fn;
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
    lookup_dia_cb && lookup_dia_cb(lookup_dia);
}

/**
 * Getting a message: this callback will be invoked once we receive something
 * over LookupChannel.
 *
 * @param {function} fn
 */
export function setDiagnosticCallback(fn) {
    _debug('setDiagnosticCallback');
    lookup_dia_cb = fn;
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
