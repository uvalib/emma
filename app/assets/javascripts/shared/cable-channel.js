// app/assets/javascripts/shared/cable-channel.js
//
// noinspection JSUnusedGlobalSymbols


import { AppDebug }           from '../application/debug';
import { Api }                from './api';
import { BaseClass }          from './base-class';
import { ChannelRequest }     from './channel-request';
import { ChannelResponse }    from './channel-response';
import { isDefined, isEmpty } from './definitions';
import { onPageExit }         from './events';
import { asString }           from './strings';


const MODULE = 'CableChannel';
const DEBUG  = true;

AppDebug.file('shared/cable-channel', MODULE, DEBUG);

/**
 * CableChannel
 *
 * @extends BaseClass
 */
export class CableChannel extends BaseClass {

    static CLASS_NAME = 'CableChannel';
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * The name of the JavaScript class is the same as the name of the
     * corresponding Ruby class.
     *
     * @note This is set as a constant in ../channels/*.js simply to make use
     *  of RubyMine linkage and for any performance reason.
     *
     * @type {string}
     */
    static CHANNEL_NAME;

    /**
     * The stream ID for the subclass generated at load time to uniquely
     * identify the subclass instance associated with the current browser tab.
     *
     * @type {string}
     */
    static STREAM_ID;

    /**
     * The name of the channel action should be the same as the name of the
     * receiving Ruby class method.
     *
     * @type {string}
     */
    static DEFAULT_ACTION;

    // ========================================================================
    // Variables
    // ========================================================================

    /** @type {Subscription} */              _channel;
    /** @type {string} */                    _stream_id;
    /** @type {string} */                    _action;

    /** @type {ChannelResponse|undefined} */ _res;
    /** @type {string|undefined} */          _err;
    /** @type {string|undefined} */          _dia;

    /** @type {function[]} */                _res_cb;
    /** @type {function[]} */                _err_cb;
    /** @type {function[]} */                _dia_cb;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {string} [stream_id]
     */
    constructor(stream_id) {
        super();
        this._stream_id = stream_id;
    }

    // ========================================================================
    // Properties - channel management
    // ========================================================================

    /** @returns {Subscription} */
    get channel() {
        return this._channel;
    }
    set channel(sub) {
        this._channel = sub || undefined;
    }

    /** @returns {string} */
    get channelName() {
        return this.constructor.channelName;
    }

    /** @returns {string} */
    get channelAction() {
        return this._action || this.constructor.channelAction;
    }
    set channelAction(action) {
        this._action = action;
    }

    /**
     * A unique identifier to differentiate this channel.
     *
     * @returns {string}
     *
     * @see "ApplicationCable::Channel#_stream_id"
     */
    get streamId() {
        return this._stream_id ||= this.constructor.streamId;
    }

    /**
     * The channel for the session.
     *
     * @returns {{ channel: string, stream_id: string }}
     *
     * @see "ApplicationCable::Channel#stream_name"
     */
    get streamName() {
        return { channel: this.channelName, stream_id: this.streamId };
    }

    /**
     * Generate a label for diagnostic output which identifies the specific
     * channel (including stream ID).
     *
     * @returns {string}
     */
    get streamLabel() {
        const stream = this.streamName;
        return `${stream.channel}[${stream.stream_id}]`;
    }

    // ========================================================================
    // Methods - channel management
    // ========================================================================

    /**
     * Force the channel to close.
     *
     * @see "ApplicationCable::Channel#unsubscribed"
     */
    disconnect() {
        this._debug('disconnect');
        this.channel?.unsubscribe();
        this.channel    = undefined;
        this.result     = undefined;
        this.error      = undefined;
        this.diagnostic = undefined;
    }

    /**
     * Assert that the channel should automatically disconnect when leaving the
     * page.
     *
     * @param {boolean} [debug]
     */
    disconnectOnPageExit(debug) {
        const disconnect = this.disconnect.bind(this);
        const debugging  = isDefined(debug) ? debug : this._debugging;
        onPageExit(disconnect, debugging);
    }

    // ========================================================================
    // Message processing
    // ========================================================================

    /**
     * Create a request object from the provided terms then invoke the server
     * method defined in lookup_channel.rb.
     *
     * @note {@link setCallback} is expected to have been called first.
     *
     * @param {*}      data
     * @param {string} [req_action]   Default: {@link channelAction}.
     *
     * @returns {boolean}
     *
     * @see "LookupChannel#lookup_request"
     */
    request(data, req_action) {
        const action  = req_action || this.channelAction;
        this._debug(`request: action ${action}; data =`, data);
        const channel = this.channel;
        const payload = channel && data;
        const request = payload && this._createRequest(payload).requestPayload;
        if (!channel) {
            this.setError('Channel not open');
        } else if (isEmpty(data)) {
            this.setError('No input');
        } else if (isEmpty(request)) {
            this.setError('Empty payload');
        } else if (isEmpty(this._res_cb)) {
            this.setError('No request callback set');
        } else {
            return !!channel.perform(action, request);
        }
        return false;
    }

    /**
     * Process a request response. <p/>
     *
     * If the entire response can't be sent back at one time, the response
     * will hold the URL from which the missing data can be acquired.
     *
     * @param {ChannelResponsePayload|undefined} msg_obj
     *
     * @see "ApplicationCable::Response#convert_to_data_url!"
     */
    response(msg_obj) {
        this._debug('response', msg_obj);
        if (msg_obj?.data_url) {
            this.fetchData(
                msg_obj.data_url,
                result => this.setResult({ ...msg_obj, data: result })
            );
        } else {
            this.setResult(msg_obj);
        }
    }

    /**
     * Get data that was replaced by a URL reference because it was too large.
     *
     * @param {string}       url
     * @param {XmitCallback} callback
     */
    fetchData(url, callback) {
        this._debug('fetchData', url);
        new Api(url, { callback: callback }).get();
    }

    /**
     * _createRequest
     *
     * @param {*} data
     *
     * @returns {ChannelRequest}
     * @protected
     */
    _createRequest(data) {
        return ChannelRequest.wrap(data);
    }

    /**
     * _createResponse
     *
     * @param {*} data
     *
     * @returns {ChannelResponse}
     * @protected
     */
    _createResponse(data) {
        return ChannelResponse.wrap(data);
    }

    // ========================================================================
    // Response data
    // ========================================================================

    get result() { return this._res }
    set result(data) {
        this._debug('set result', data);
        this._res = data && this._createResponse(data);
        this._res && this.callbacks.forEach(cb => cb(this._res));
    }

    get callbacks() { return this._res_cb ||= [] }
    set callbacks(callbacks) {
        this._debug('set callbacks', callbacks);
        this._res_cb = [...callbacks].flat();
    }

    /**
     * Get the data message content.
     *
     * @returns {ChannelResponse|undefined}
     */
    getResult() {
        return this.result;
    }

    /**
     * Set the data message content.
     *
     * @param {ChannelResponsePayload|undefined} data
     */
    setResult(data) {
        //this._debug('setResult: data =', data);
        this.result = data;
    }

    /**
     * Assign the function(s) that will be invoked when something is received over
     * LookupChannel.
     *
     * @param {...(function|function[])} callbacks
     */
    setCallback(...callbacks) {
        //this._debug('setCallback: callbacks =', callbacks);
        this.callbacks = callbacks;
    }

    /**
     * Assign additional function(s) that will be invoked when something is
     * received over LookupChannel.
     *
     * @note If {@link setCallback} is called after this, the added callbacks
     *  are cleared.
     *
     * @param {...(function|function[])} callbacks
     */
    addCallback(...callbacks) {
        this._debug('addCallback: callbacks =', callbacks);
        this.callbacks = [...this.callbacks, ...callbacks];
    }

    // ========================================================================
    // Error information
    // ========================================================================

    get error() { return this._err }
    set error(text) {
        this._debug('set error', text);
        this._err = text;
        this._err && this.error_callbacks.forEach(cb => cb(this._err));
    }

    get error_callbacks() { return this._err_cb ||= [] }
    set error_callbacks(callbacks) {
        this._debug('set error callbacks', callbacks);
        this._err_cb = [...callbacks].flat();
    }

    /**
     * Get the error message content.
     *
     * @returns {string|undefined}
     */
    getError() {
        return this.error;
    }

    /**
     * Set the error message content.
     *
     * @param {string|undefined} text
     * @param {...*}             log_extra
     */
    setError(text, ...log_extra) {
        //this._debug(`setError: ${text}`, ...log_extra);
        const data = log_extra.map(v => asString(v)).join(', ')
        this.error = data ? `${text}: ${data}` : text;
    }

    /**
     * setErrorCallback
     *
     * @param {...(function|function[])} callbacks
     */
    setErrorCallback(...callbacks) {
        //this._debug('setErrorCallback: callbacks =', callbacks);
        this.error_callbacks = callbacks;
    }

    /**
     * addErrorCallback
     *
     * @param {...(function|function[])} callbacks
     */
    addErrorCallback(...callbacks) {
        this._debug('addErrorCallback: callbacks =', callbacks);
        this.error_callbacks = [...this.error_callbacks, ...callbacks];
    }

    // ========================================================================
    // Diagnostic information
    // ========================================================================

    get diagnostic() { return this._dia }
    set diagnostic(text) {
        this._debug('set diagnostic', text);
        this._dia = text && `${this.streamLabel} ${text}`;
        this._dia && this.diagnostic_callbacks.forEach(cb => cb(this._dia));
    }

    get diagnostic_callbacks() { return this._dia_cb ||= [] }
    set diagnostic_callbacks(callbacks) {
        this._debug('set diagnostic callbacks', callbacks);
        this._dia_cb = [...callbacks].flat();
    }

    /**
     * Get the diagnostic information content.
     *
     * @returns {string|undefined}
     */
    getDiagnostic() {
        return this.diagnostic;
    }

    /**
     * Set the diagnostic information content.
     *
     * @param {string|undefined} text
     * @param {...*}             log_extra
     */
    setDiagnostic(text, ...log_extra) {
        //this._debug(`setDiagnostic: ${text}`, ...log_extra);
        const data = log_extra.map(v => asString(v)).join(', ');
        this.diagnostic = data ? `${text}: ${data}` : text;
    }

    /**
     * Getting a message: this callback will be invoked once we receive something
     * over LookupChannel.
     *
     * @param {...(function|function[])} callbacks
     */
    setDiagnosticCallback(...callbacks) {
        //this._debug('setDiagnosticCallback: callbacks =', callbacks);
        this.diagnostic_callbacks = callbacks;
    }

    /**
     * addDiagnosticCallback
     *
     * @param {...(function|function[])} callbacks
     */
    addDiagnosticCallback(...callbacks) {
        this._debug('addDiagnosticCallback: callbacks =', callbacks);
        this.diagnostic_callbacks =
            [...this.diagnostic_callbacks, ...callbacks];
    }

    // ========================================================================
    // Methods - channel management - internal
    // ========================================================================

    /**
     * Attach the instance to a channel.
     *
     * @param {ChannelCallbacks} [callbacks]
     *
     * @returns {CableChannel|undefined}
     */
    async setupInstance(callbacks) {
        this._debug('setupInstance: this =', this);
        if (this.channel) {
            this._log('_channel is already set');
        } else {
            this.channel = await this._createChannel(callbacks);
        }
        return this.channel && this;
    }

    /**
     * Setup a channel.
     *
     * @param {ChannelCallbacks} [callbacks]
     * @param {boolean}          [verbose]      Default: {@link _debugging}.
     *
     * @returns {Subscription|undefined}
     * @protected
     */
    async _createChannel(callbacks, verbose) {
        this._debug('_createChannel: this =', this);
        const dia            = isDefined(verbose) ? verbose : this._debugging;
        const set_diagnostic = dia ? this.setDiagnostic.bind(this) : undefined;
        const make_response  = this.response.bind(this);
        const warning        = this._warn.bind(this);
        const stream_name    = this.streamName;
        const functions      = { ...callbacks };
        const received_cb    = functions.received;

        /**
         * Called when there's incoming data on the WebSocket for this channel.
         * If a "received" callback was supplied, it will be called first.
         * Note that this is the raw data on the channel (before "data_url" is
         * resolved if in the data).
         *
         * @param {object} data
         */
        functions.received = function(data) {
            received_cb?.(data);
            make_response(data);
        };

        if (set_diagnostic) {
            functions.initialized  ||= () => set_diagnostic('initialized');
            functions.rejected     ||= () => set_diagnostic('rejected');
            functions.connected    ||= () => set_diagnostic('connected');
            functions.disconnected ||= () => set_diagnostic('disconnected');
            functions.received     ||= () => set_diagnostic('received');
        }
        return import('./cable-consumer').then(
            module => module.createChannel(stream_name, functions),
            reason => warning('import failed:', reason)
        );
    }

    // ========================================================================
    // Properties - internal
    // ========================================================================

    get _logPrefix() {
        const label = this.streamLabel.padEnd(this.constructor.CLASS_ALIGN);
        return `${label} -`;
    }

    // ========================================================================
    // Class properties
    // ========================================================================

    static get channelName()   { return this.CHANNEL_NAME }
    static get channelAction() { return this.DEFAULT_ACTION }
    static get streamId()      { return this.STREAM_ID }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Return a connected instance of the channel.
     *
     * @param {string|ChannelCallbacks} [arg1]
     * @param {ChannelCallbacks}        [arg2]
     *
     * @returns {CableChannel|undefined}
     */
    static async newInstance(arg1, arg2) {
        const str = (typeof arg1 === 'string');
        const [stream_id, callbacks] = str ? [arg1, arg2] : [undefined, arg1];
        return (new this(stream_id)).setupInstance(callbacks);
    }
}
