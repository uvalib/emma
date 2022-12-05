// app/assets/javascripts/shared/cable-channel.js
//
// noinspection JSUnusedGlobalSymbols


import { Api }                from './api'
import { BaseClass }          from './base-class'
import { ChannelRequest }     from './channel-request'
import { ChannelResponse }    from './channel-response'
import { isDefined, isEmpty } from './definitions'
import { onPageExit }         from './events'
import { hexRand }            from './random'
import { asString }           from './strings'


export class CableChannel extends BaseClass {

    static CLASS_NAME = 'CableChannel';

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
     * The name of the channel action should be the same as the name of the
     * receiving Ruby class method.
     *
     * @type {string}
     */
    static CHANNEL_ACTION;

    // ========================================================================
    // Class variables
    // ========================================================================

    /** @type {CableChannel} */
    static _instance;

    // ========================================================================
    // Variables
    // ========================================================================

    /** @type {Subscription} */ _channel;
    /** @type {string} */       _stream_id;

    /** @type {object} */       _dat;
    /** @type {string} */       _err;
    /** @type {string} */       _dia;

    /** @type {function[]} */   _dat_cb;
    /** @type {function[]} */   _err_cb;
    /** @type {function[]} */   _dia_cb;

    // ========================================================================
    // Properties - channel management
    // ========================================================================

    /** @returns {Subscription} */
    get channel() { return this._channel }

    /** @returns {string} */
    get channelName() { return this.constructor.channelName }

    /** @returns {string} */
    get channelAction() { return this.constructor.channelAction }

    /**
     * A unique identifier to differentiate this channel.
     *
     * @returns {string}
     *
     * @see "ApplicationCable::Channel#_stream_id"
     */
    get streamId() {
        return this._stream_id ||= hexRand();
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
        this.channel.unsubscribe();
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
     * @param {*} data
     *
     * @returns {boolean}
     *
     * @see "LookupChannel#lookup_request"
     */
    request(data) {
        this._debug('request', data);
        const request = data && this._createRequest(data).requestPayload;
        if (isEmpty(data)) {
            this.setError('No input');
        } else if (isEmpty(request)) {
            this.setError('Empty payload');
        } else if (isEmpty(this._dat_cb)) {
            this.setError('No request callback set');
        } else {
            return !!this.channel.perform(this.channelAction, request);
        }
        return false;
    }

    /**
     * Handle a request response.
     *
     * If the entire response can't be sent back at one time, the response
     * will hold the URL from which the missing data can be acquired.
     *
     * @param {ChannelResponsePayload} msg_obj
     *
     * @see "ApplicationCable::Response#convert_to_data_url!"
     */
    response(msg_obj) {
        if (msg_obj.data_url) {
            this.fetchData(
                msg_obj.data_url,
                result => this.setData({ ...msg_obj, data: result })
            );
        } else {
            this.setData(msg_obj);
        }
    }

    /**
     * Get data that was replaced by a URL reference because it was too large.
     *
     * @param {string}       url
     * @param {XmitCallback} callback
     */
    fetchData(url, callback) {
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

    get data() { return this._dat }
    set data(v) {
        this._debug('set data', v);
        this._dat = this._createResponse(v);
        this.callbacks.forEach(cb => cb(this._dat));
    }

    get callbacks() { return this._dat_cb ||= [] }
    set callbacks(callbacks) {
        this._debug('set callbacks', callbacks);
        this._dat_cb = [...callbacks].flat();
    }

    /**
     * Get the data message content.
     *
     * @returns {object|undefined}
     */
    getData() {
        return this.data;
    }

    /**
     * Set the data message content.
     *
     * @param {ChannelResponse|ChannelResponsePayload} data
     */
    setData(data) {
        this.data = data;
    }

    /**
     * Assign the function(s) that will be invoked when something is received over
     * LookupChannel.
     *
     * @param {...(function|function[])} callbacks
     */
    setCallback(...callbacks) {
        this._debug('setCallback: callbacks =', callbacks);
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
        this._err = text
        this.error_callbacks.forEach(cb => cb(this._err));
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
     * @param {string} text
     * @param {...*}   log_extra
     */
    setError(text, ...log_extra) {
        this._debug(`setError: ${text}`, ...log_extra);
        const data = log_extra.map(v => asString(v)).join(', ')
        this.error = data ? `${text}: ${data}` : text;
    }

    /**
     * setErrorCallback
     *
     * @param {...(function|function[])} callbacks
     */
    setErrorCallback(...callbacks) {
        this._debug('setErrorCallback: callbacks =', callbacks);
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
        this._dia = `${this.streamLabel} ${text}`;
        this.diagnostic_callbacks.forEach(cb => cb(this._dia));
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
     * @param {string} text
     * @param {...*}   log_extra
     */
    setDiagnostic(text, ...log_extra) {
        this._debug(`setDiagnostic: ${text}`, ...log_extra);
        this._warn(`setDiagnostic: ${text}`, ...log_extra); // TODO: remove
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
        this._debug('setDiagnosticCallback: callbacks =', callbacks);
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
    // Internal methods - channel management
    // ========================================================================

    /**
     * Attach the instance to a channel.
     *
     * @returns {CableChannel}
     */
    setupInstance() {
        if (this._channel) { this._error('_channel is already set') }
        this._createChannel();
        return this;
    }

    /**
     * Setup a channel.
     *
     * @param {boolean} [verbose]     Default: {@link _debugging}.
     *
     * @returns {Subscription}
     * @protected
     */
    async _createChannel(verbose) {
        const dia            = isDefined(verbose) ? verbose : this._debugging;
        const set_diagnostic = dia ? this.setDiagnostic.bind(this) : undefined;
        const make_response  = this.response.bind(this);
        const warning        = this._warn.bind(this);
        const identity       = this.streamName;
        const functions      = {
            /**
             * Called when there's incoming data on the websocket for this
             * channel.
             *
             * @param {object} data
             */
            received(data) {
                set_diagnostic?.('received', data);
                make_response(data);
            }
        };
        if (set_diagnostic) {
            functions.initialized  = () => set_diagnostic('initialized');
            functions.connected    = () => set_diagnostic('connected');
            functions.disconnected = () => set_diagnostic('disconnected');
            functions.rejected     = () => set_diagnostic('rejected');
        }
        this._channel = await import('../channels/consumer').then(
            module => module.createChannel(identity, functions),
            reason => warning('import failed:', reason)
        );
        return this._channel;
    }

    // ========================================================================
    // Properties - internal
    // ========================================================================

    get _log_prefix() { return this.streamLabel }

    // ========================================================================
    // Class properties
    // ========================================================================

    static get instance()      { return this._instance ||= new this() }
    static get channelName()   { return this.CHANNEL_NAME }
    static get channelAction() { return this.CHANNEL_ACTION }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Return a connected instance of the channel.
     *
     * @returns {CableChannel}
     */
    static newInstance() {
        return this.instance.setupInstance();
    }
}
