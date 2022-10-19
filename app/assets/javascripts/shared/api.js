// app/assets/javascripts/shared/api.js


import { BaseClass } from './base-class'
import { HTTP }      from './http'
import { dupObject } from './objects'
import { makeUrl }   from './url'
import * as xhr      from './xhr'
import { Rails }     from '../vendor/rails'


// ============================================================================
// Class API
// ============================================================================

/**
 * A generic API interface.
 */
export class Api extends BaseClass {

    static CLASS_NAME = 'Api';

    // ========================================================================
    // Type definitions
    // ========================================================================

    /**
     * Api_Options
     *
     * @typedef {{
     *     base_url?: string,
     *     api_key?:  string,
     *     callback?: XmitCallback,
     * }} Api_Options
     */

    // ========================================================================
    // Fields
    // ========================================================================

    /** @type {object}                   */ result      = {};
    /** @type {string}                   */ base_url    = '';
    /** @type {string}                   */ state       = 'initialized';
    /** @type {number}                   */ status      = HTTP.ok;
    /** @type {string|undefined}         */ api_key;
    /** @type {XmitCallback|undefined}   */ callback;
    /** @type {XMLHttpRequest|undefined} */ xhr;
    /** @type {string|undefined}         */ message;
    /** @type {string|undefined}         */ warning;
    /** @type {string|undefined}         */ error;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {string}      base_url    Defaults to the EMMA server.
     * @param {Api_Options} [options]
     */
    constructor(base_url, options = {}) {
        super();
        this.base_url = base_url || options.base_url || '';
        this.api_key  = options.api_key;
        this.callback = options.callback;
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get isRemote() { return this.base_url?.startsWith('http') || false }
    get isLocal()  { return !this.isRemote }
    get response() { return xhr.response(this.xhr) }

    // ========================================================================
    // Methods
    // ========================================================================

    get(  path, prm, opt, cb) { this.xmit('GET',   path, prm, opt, cb) }
    head( path, prm, opt, cb) { this.xmit('HEAD',  path, prm, opt, cb) }
    put(  path, prm, opt, cb) { this.xmit('PUT',   path, prm, opt, cb) }
    post( path, prm, opt, cb) { this.xmit('POST',  path, prm, opt, cb) }
    patch(path, prm, opt, cb) { this.xmit('PATCH', path, prm, opt, cb) }

    /**
     * Transmit to an external API resource.
     *
     * @param {string}                   method
     * @param {string}                   path
     * @param {string|object}            prm
     * @param {AjaxOptions|XmitCallback} [opt]
     * @param {XmitCallback}             [cb]
     *
     * @see xhr.xmit()
     */
    xmit(method, path, prm, opt, cb) {
        let url;
        if (!path) {
            url = this.base_url;
        } else if (path.startsWith('http')) {
            url = path;
        } else {
            url = makeUrl(this.base_url, path);
        }

        let caller_cb, settings;
        switch (typeof opt) {
            case 'function': caller_cb = opt;            break;
            case 'object':   settings  = dupObject(opt); break;
        }
        caller_cb ||= cb || this.callback;
        settings  ||= {};
        settings.headers = this._addHeaders(settings.headers);

        const callback = (...args) => this._xmitOnComplete(...args, caller_cb);
        xhr.xmit(method, url, prm, settings, callback);
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * Callback invoked when the transmission is complete (either successfully
     * or not).
     *
     * @param {object}           result     Response message body.
     * @param {string|undefined} warning    Possible warning message.
     * @param {string|undefined} error      Possible error message.
     * @param {XMLHttpRequest}   xhr        Request response object.
     * @param {XmitCallback}     [cb]
     *
     * @protected
     */
    _xmitOnComplete(result, warning, error, xhr, cb) {
        this.result  = result || {};
        this.message = this.result.message || 'done';
        this.warning = warning;
        this.error   = error;
        this.xhr     = xhr;
        this.status  = xhr?.status || HTTP.internal_server_error;
        cb?.(result, warning, error, xhr);
    }

    /**
     * Generate message headers based on the nature of the API.
     *
     * @param {object} [current_headers]
     *
     * @returns {object}
     * @protected
     */
    _addHeaders(current_headers) {
        const headers = dupObject(current_headers);
        if (this.isLocal) {
            headers['X-CSRF-Token'] = Rails.csrfToken();
        }
        if (this.api_key) {
            headers['X-API-Key'] = this.api_key;
        }
        return headers;
    }
}
