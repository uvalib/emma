// app/assets/javascripts/shared/xhr.js


import { AppDebug }         from '../application/debug';
import { isMissing }        from './definitions';
import { HTTP }             from './http';
import { fromJSON, hasKey } from './objects';
import { secondsSince }     from './time';
import { makeUrl }          from './url';


const MODULE = 'XHR';
const DEBUG  = true;

AppDebug.file('shared/xhr', MODULE, DEBUG);

/**
 * Console output functions for this module.
 */
const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

// ============================================================================
// Type definitions
// ============================================================================

/** @typedef {'xml'|'html'|'script'|'json'|'jsonp'|'text'} AjaxDataType */

/** @typedef {function(any,string,XMLHttpRequest)}    AjaxSuccessCallback  */
/** @typedef {function(XMLHttpRequest,string,string)} AjaxErrorCallback    */
/** @typedef {function(XMLHttpRequest,string)}        AjaxCompleteCallback */

/**
 * @typedef {object} AjaxOptions
 *
 * Options beginning with an underscore are local to {@link xmit}().
 *
 * @property {boolean}                          [_ignoreBody]
 * @property {object}                           [accepts]
 * @property {boolean}                          [async]
 * @property {function(XMLHttpRequest,object)}  [beforeSend]
 * @property {boolean}                          [cache]
 * @property {AjaxCompleteCallback}             [complete]
 * @property {object}                           [contents]
 * @property {string|boolean}                   [contentType]
 * @property {object}                           [context]
 * @property {object}                           [converters]
 * @property {boolean}                          [crossDomain]
 * @property {object|array|string}              [data]
 * @property {function(string,string)}          [dataFilter]
 * @property {AjaxDataType}                     [dataType]
 * @property {AjaxErrorCallback}                [error]
 * @property {boolean}                          [global]
 * @property {object}                           [headers]
 * @property {boolean}                          [ifModified]
 * @property {boolean}                          [isLocal]
 * @property {string|boolean}                   [jsonp]
 * @property {string|function}                  [jsonpCallback]
 * @property {string}                           [method]
 * @property {string}                           [mimeType]
 * @property {string}                           [password]
 * @property {boolean}                          [processData]
 * @property {object}                           [scriptAttrs]
 * @property {string}                           [scriptCharset]
 * @property {object}                           [statusCode]
 * @property {AjaxSuccessCallback}              [success]
 * @property {number}                           [timeout]
 * @property {boolean}                          [traditional]
 * @property {string}                           [type]
 * @property {string}                           [url]
 * @property {string}                           [username]
 * @property {function:XMLHttpRequest}          [xhr]
 * @property {object}                           [xhrFields]
 *
 * @see https://api.jquery.com/jquery.ajax/#jQuery-ajax-settings
 */

/**
 * @typedef {
 *      function(
 *          result:  object|undefined,
 *          warning: string|undefined,
 *          error:   string|undefined,
 *          xhr:     XMLHttpRequest
 *      )
 * } XmitCallback
 *
 * - result:    Response message body.
 * - warning:   Possible warning message.
 * - error:     Possible error message.
 * - xhr:       Request response object.
 */

// ============================================================================
// Functions - send
// ============================================================================

/** @returns {void} */

export function get(  path, prm, opt, cb) { xmit('GET',   path, prm, opt, cb) }
export function head( path, prm, opt, cb) { xmit('HEAD',  path, prm, opt, cb) }
export function put(  path, prm, opt, cb) { xmit('PUT',   path, prm, opt, cb) }
export function post( path, prm, opt, cb) { xmit('POST',  path, prm, opt, cb) }
export function patch(path, prm, opt, cb) { xmit('PATCH', path, prm, opt, cb) }

/**
 * Transmit to an external site.
 *
 * @param {string}                   method
 * @param {string}                   path
 * @param {string|object}            prm
 * @param {AjaxOptions|XmitCallback} [opt]
 * @param {XmitCallback}             [cb]
 *
 * @see https://api.jquery.com/jquery.ajax/#jQuery-ajax-settings
 */
export function xmit(method, path, prm, opt, cb) {
    const func   = 'xmit';
    const opt_cb = (typeof opt === 'function') && opt;

    /** @type {AjaxOptions|object} */
    let settings = opt_cb ? { complete: opt_cb } : { ...opt, complete: cb };

    /** @type {object|string} */
    let params = prm;
    if (typeof prm === 'object') {
        params = { ...prm };
        if (hasKey(params, 'settings')) {
            settings = { ...settings, ...params.settings };
            delete params.settings;
        }
    }

    let ignore_body;
    if (hasKey(settings, '_ignoreBody')) {
        ignore_body = settings._ignoreBody;
        delete settings._ignoreBody;
    }

    if (hasKey(settings, 'method')) {
        settings.type ||= settings.method;
        delete settings.method;
    }
    if (settings.type && (settings.type !== method)) {
        OUT.warn(`${func}: "${settings.type}" conflicts with "${method}"`);
        delete settings.type;
    }
    switch (settings.type ||= method) {
        case 'GET':
        case 'HEAD':
            settings.url  ||= makeUrl(path, params);
            break;
        default:
            settings.url  ||= path;
            settings.data ||= params;
            break;
    }
    settings.dataType ||= 'json';

    /**
     * Callbacks defined within this function.
     * @type {{
     *      success:  AjaxSuccessCallback,
     *      error:    AjaxErrorCallback,
     *      complete: AjaxCompleteCallback
     *  }}
     */
    const handlers = {
        success:  onSuccess,
        error:    onError,
        complete: onComplete
    };
    /**
     * Optional callbacks supplied via *opt*.
     * @type {{
     *      success?:  XmitCallback,
     *      error?:    XmitCallback,
     *      complete?: XmitCallback
     * }}
     */
    const callback = {};
    for (const [name, handler] of Object.entries(handlers)) {
        callback[name] = settings[name];
        settings[name] = handler;
    }

    let result, warning, error;
    const start = Date.now();

    $.ajax(settings);

    /**
     * Expect response data returned as JSON.
     *
     * @param {object}         data
     * @param {string}         status
     * @param {XMLHttpRequest} xhr
     */
    function onSuccess(data, status, xhr) {
        OUT.debug(`${func}: received`, (data?.length || 0), 'bytes.');
        if (ignore_body) {
            result = data || {};
        } else if (isMissing(data)) {
            error  = 'no data';
        } else if (typeof(data) !== 'object') {
            error  = `unexpected data type ${typeof data}`;
        } else {
            result = data;
        }
        callback.success?.(result, warning, error, xhr);
    }

    /**
     * Accumulate the status failure message. <p/>
     *
     * This handles what appears to be a very specific jQuery bug where a HEAD
     * response causes jQuery to fail trying to parse the response body.  In
     * this scenario, onSuccess isn't run so the recovery code here will invoke
     * `callback.success` if it is defined.
     *
     * @param {XMLHttpRequest} xhr
     * @param {string}         status
     * @param {string}         message
     */
    function onError(xhr, status, message) {
        let cb = callback.error;
        if ((status === 'parsererror') && (xhr.status < 400)) {
            OUT.debug(`${func}: no response data`);
            cb = callback.success;
            result ||= {};
        } else {
            OUT.debug(`${func}: ${status}: ${message}`);
            const transient = transientError(xhr.status);
            const failure   = `${status}: ${xhr.status} ${message}`;
            if (transient) { warning = failure } else { error = failure }
        }
        cb?.(result, warning, error, xhr);
    }

    /**
     * Actions after the request is completed.
     *
     * @param {XMLHttpRequest} xhr
     * @param {string}         _status
     */
    function onComplete(xhr, _status) {
        OUT.debug(`${func}: completed in`, secondsSince(start), 'sec.');
        if (result) {
            //OUT.debug(`${func}: data from server:`, record);
        } else if (warning) {
            OUT.warn(`${func}: ${settings.url}:`, warning);
        } else {
            error ||= 'unknown failure';
            OUT.error(`${func}: ${settings.url}:`, error);
        }
        callback.complete?.(result, warning, error, xhr);
    }

}

// ============================================================================
// Functions - receive
// ============================================================================

/**
 * Indicate whether the HTTP status code should be treated as a temporary
 * condition.
 *
 * @param {number} code
 *
 * @returns {boolean}
 */
export function transientError(code) {
    switch (code) {
        case HTTP.service_unavailable:
        case HTTP.gateway_timeout:
            return true;
        default:
            return false;
    }
}

/**
 * Retrieve the JSON response.
 *
 * @param {XMLHttpRequest} xhr
 *
 * @returns {object}
 */
export function response(xhr) {
    let result;
    // noinspection JSUnresolvedVariable
    if (typeof xhr.responseJSON === 'function') {
        // noinspection JSUnresolvedVariable
        result = xhr.responseJSON;
    } else if (xhr.responseType === 'json') {
        result = xhr.response;
    } else if (xhr.responseText) {
        result = fromJSON(xhr.responseText);
    }
    return result || {};
}
