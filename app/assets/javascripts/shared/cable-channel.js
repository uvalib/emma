// app/assets/javascripts/shared/cable-channel.js
//
// noinspection JSUnusedGlobalSymbols


import { Api }                           from './api'
import { BaseClass }                     from './base-class'
import { ChannelRequest }                from './channel-request'
import { ChannelResponse }               from './channel-response'
import { isDefined, isEmpty, isPresent } from './definitions'
import { onPageExit }                    from './events'
import { hexRand }                       from './random'
import { asString }                      from './strings'


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

    /** @type {string} */       _channel_name;
    /** @type {string} */       _channel_action;
    /** @type {string} */       _stream_id;

    /** @type {object} */       _dat;
    /** @type {string} */       _err;
    /** @type {string} */       _dia;

    /** @type {function[]} */   _dat_cb;
    /** @type {function[]} */   _err_cb;
    /** @type {function[]} */   _dia_cb;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new channel instance.
     *
     * @param {string} [action]
     * @param {string} [name]
     * @param {string} [id]
     */
    constructor(action, name, id) {
        super();
        this._channel_action = action;
        this._channel_name   = name;
        this._stream_id      = id;
    }

    // ========================================================================
    // Properties - channel management
    // ========================================================================

    /**
     * The channel.
     *
     * @returns {Subscription}
     */
    get channel() {
        return this._channel;
    }

    /**
     * channelName
     *
     * @returns {string}
     */
    get channelName() {
        return this._channel_name ||= this.constructor.CHANNEL_NAME;
    }

    /**
     * channelAction
     *
     * @returns {string}
     */
    get channelAction() {
        return this._channel_action ||= this.constructor.CHANNEL_ACTION;
    }

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
        const name = this.streamName;
        const chan = name.channel;
        const sid  = name.stream_id;
        return sid ? `${chan}[${sid}]` : chan;
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
        const debugging  = isDefined(debug) ? debug : this.debugging;
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
        this._debug('set data:', v);
        this._dat = this._createResponse(v);
        this.callbacks.forEach(cb => cb(this._dat));
    }

    get callbacks() { return this._dat_cb ||= [] }
    set callbacks(callbacks) {
        this._debug('set callbacks');
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
        this._debug('addCallback');
        this.callbacks = [...this.callbacks, ...callbacks];
    }

    // ========================================================================
    // Error information
    // ========================================================================

    get error() { return this._err }
    set error(text) {
        this._debug('set error:', text);
        this._err = text
        this.error_callbacks.forEach(cb => cb(this._err));
    }

    get error_callbacks() { return this._err_cb ||= [] }
    set error_callbacks(callbacks) {
        this._debug('set error callbacks');
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
         this.error_callbacks = callbacks;
    }

    /**
     * addErrorCallback
     *
     * @param {...(function|function[])} callbacks
     */
    addErrorCallback(...callbacks) {
        this._debug('addErrorCallback');
        this.error_callbacks = [...this.error_callbacks, ...callbacks];
    }

    // ========================================================================
    // Diagnostic information
    // ========================================================================

    get diagnostic() { return this._dia }
    set diagnostic(text) {
        this._debug('set diagnostic:', text);
        this._dia = `${this.streamLabel} ${text}`;
        this.diagnostic_callback.forEach(cb => cb(this._dia));
    }

    get diagnostic_callback() { return this._dia_cb ||= [] }
    set diagnostic_callback(callbacks) {
        this._debug('set diagnostic callbacks');
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
        this.diagnostic_callback = callbacks;
    }

    /**
     * addDiagnosticCallback
     *
     * @param {...(function|function[])} callbacks
     */
    addDiagnosticCallback(...callbacks) {
        this._debug('addDiagnosticCallback');
        this.diagnostic_callback = [...this.diagnostic_callback, ...callbacks];
    }

    // ========================================================================
    // Internal methods - channel management
    // ========================================================================

    /**
     * Attach the instance to a channel.
     *
     * @returns {CableChannel}
     */
    async setupInstance() {
        if (this._channel) { this._error('_channel is already set') }
        this._channel = await this._createChannel();
        return this;
    }

    /**
     * Setup a channel.
     *
     * @param {boolean} [verbose]     Default: {@link debugging}.
     *
     * @returns {Subscription}
     * @protected
     */
    async _createChannel(verbose) {
        const dia            = isDefined(verbose) ? verbose : this.debugging;
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
        return import('../channels/consumer').then(
            module => module.createChannel(identity, functions),
            reason => warning('import failed:', reason)
        );
    }

    // ========================================================================
    // Class properties
    // ========================================================================

    static get instance()    { return this._instance ||= new this() }
    static get channelName() { return this.instance.channelName }
    static get streamId()    { return this.instance.streamId }
    static get streamName()  { return this.instance.streamName }
    static get streamLabel() { return this.instance.streamLabel }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Return a connected instance of the channel.
     *
     * @returns {CableChannel}
     */
    static async newInstance() {
        return this.instance.setupInstance();
    }

    // ========================================================================
    // Class methods - internal
    // ========================================================================

    /**
     * Indicate whether console debugging is active.
     *
     * @returns {boolean}
     */
    static get debugging() {
        return window.DEBUG.activeFor(this.CHANNEL_NAME, false);
    }

    /**
     * Emit a console message if debugging.
     *
     * @param {string} text
     * @param {...*}   [extra]
     */
    static _debug(text, ...extra) {
        if (!this.debugging) { return }
        const note = `${this.streamLabel} ${text}`;
        if (isPresent(extra)) {
            super._debug(`${note}:`, ...extra)
        } else {
            super._debug(note);
        }
    }
}
