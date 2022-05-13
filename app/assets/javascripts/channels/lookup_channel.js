// app/assets/javascripts/channels/lookup_channel.js


import { hexRand }       from '../shared/css'
import { isPresent }     from '../shared/definitions'
import { compact }       from '../shared/objects'
import { asString }      from '../shared/strings'
import { createChannel } from '../channels/consumer'


// ============================================================================
// Constants
// ============================================================================

const CHANNEL = 'LookupChannel';
const DEBUG   = true;

/**
 * LookupRequestObject
 *
 * @typedef {{
 *     ids?:   string[],
 *     query?: string[],
 *     limit?: string[],
 * }} LookupRequestObject
 */

/**
 * The valid prefixes for each request type.
 *
 * @constant
 * @type {LookupRequestObject}
 */
const REQUEST_TYPE = {
    ids:    ['isbn', 'issn', 'doi', 'oclc', 'lccn'],
    query:  ['keyword', 'author', 'title'],  // TODO: expand
    limit:  [], // TODO: none yet
};

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
 * @param {string|string[]} terms
 * @param {function} [callback]     Default: the function assigned via
 *                                      {@link setCallback}.
 *
 * @see "LookupChannel#lookup_request"
 */
export function request(terms, callback) {
    _debug('request', terms);
    const request = isPresent(terms) && buildRequest(terms);
    if (isPresent(request)) {
        lookup_dat_cb = callback || lookup_dat_cb;
        lookup_channel.perform('lookup_request', request);
    } else {
        setError('No input');
    }
}

/**
 * Create a lookup request object from the provided terms.
 *
 * @param {string|string[]} terms
 *
 * @returns {LookupRequestObject}
 */
function buildRequest(terms) {
    /** @type {LookupRequestObject} */
    let request = { ids: [], query: [], limit: [] };
    extractRequestParts(terms).forEach(function(part) {
        let [prefix, ...value] = part.split(':');
        if (isPresent(value)) {
            value  = value.join(':');
            prefix = prefix.toLowerCase();
        } else {
            value  = prefix;
            prefix = value.match(/^\d+$/) ? 'isbn' : 'keyword';
        }
        let type;
        $.each(REQUEST_TYPE, function(request_type, prefixes) {
            if (prefixes.includes(prefix)) {
                type = request_type;
            }
            return !type; // break loop if type found
        });
        type ||= 'query';
        request[type].push(`${prefix}:${value}`);
    });
    return compact(request);
}

/**
 * Split the terms string into an array of terms of the form
 *
 * * prefix:value
 * * prefix:'value'     If the value string was single-quoted.
 * * prefix:"value"     If the value string was double-quoted.
 *
 * Terms can be separated by one or more space, tab, ',', ':', or '|'
 * characters.  Values which contain any of those characters must be quoted.
 *
 * @param {string} terms_string
 *
 * @returns {string[]}
 */
function extractRequestParts(terms_string) {
    let terms = terms_string;
    const double_quoted_terms = terms.match(/[^\s,;|"']+:"[^"]*"/g) || [];
    const single_quoted_terms = terms.match(/[^\s,;|"']+:'[^']*'/g) || [];
    let parts = [...double_quoted_terms, ...single_quoted_terms];
    parts.forEach(part => { terms = terms.replace(part, ' ') });
    parts.push(...terms.trim().split(/[\s,;|]+/));
    return compact(parts);
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
