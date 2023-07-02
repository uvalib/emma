// app/assets/javascripts/shared/submit-modal.js
//
// Bulk submission monitor popup.
//
// noinspection LocalVariableNamingConventionJS, JSUnusedGlobalSymbols


import { AppDebug }                       from '../application/debug';
import { appTeardown }                    from '../application/setup';
import { SubmitChannel }                  from '../channels/submit-channel';
import { selector }                       from './css';
import { isEmpty, isPresent }             from './definitions';
import { htmlDecode }                     from './html';
import { renderJson }                     from './json';
import { ModalDialog }                    from './modal-dialog';
import { ModalHideHooks, ModalShowHooks } from './modal_hooks';
import { isObject }                       from './objects';
import { asString, isString }             from './strings';
import { SubmitStepResponse }             from './submit-response';
import {
    SubmitControlRequest,
    SubmitRequest,
} from './submit-request';


const MODULE = 'SubmitModal';
const DEBUG  = true;

AppDebug.file('shared/submit-modal', MODULE, DEBUG);

// ============================================================================
// Class SubmitModal
// ============================================================================

/**
 * Despite its name, this class holds the bulk submission monitoring logic and
 * is only secondarily a modal that can be used to view the WebSocket responses
 * that underlie that logic.
 *
 * @extends ModalDialog
 */
export class SubmitModal extends ModalDialog {

    static CLASS_NAME = 'SubmitModal';
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Constants - .data() names
    // ========================================================================

    /**
     * The .data() key for storing the generated submission request.
     *
     * @readonly
     * @type {string}
     */
    static REQUEST_DATA = 'submitRequest';

    /**
     * The .data() key for storing received status.
     *
     * @readonly
     * @type {string}
     */
    static STATUS_DATA = 'submitStatus';

    // ========================================================================
    // Constants
    // ========================================================================

    static MODAL_CLASS          = 'monitor-popup';
    static CONTAINER_CLASS      = 'monitor-container';
    static HEADING_CLASS        = 'monitor-heading';
    static LOG_TOGGLE_CLASS     = 'log-toggle';
    static LOG_MARKER_CLASS     = 'with-log';

    static MODAL                = selector(this.MODAL_CLASS);
    static CONTAINER            = selector(this.CONTAINER_CLASS);
    static HEADING              = selector(this.HEADING_CLASS);
    static LOG_TOGGLE           = selector(this.LOG_TOGGLE_CLASS);

    // Submission status elements

    static STATUS_DISPLAY_CLASS = 'monitor-status';
    static NOTICE_CLASS         = 'notice';

    static STATUS_DISPLAY       = selector(this.STATUS_DISPLAY_CLASS);
    static NOTICE               = selector(this.NOTICE_CLASS);

    // Submission output elements

    static OUTPUT_CLASS         = 'monitor-output';
    static DISPLAY_CLASS        = 'display';
    static SUCCESS_CLASS        = 'success';
    static FAILURE_CLASS        = 'failure';

    static OUTPUT               = selector(this.OUTPUT_CLASS);
    static DISPLAY              = selector(this.DISPLAY_CLASS);
    static SUCCESS              = selector(this.SUCCESS_CLASS);
    static FAILURE              = selector(this.FAILURE_CLASS);

    // Log display elements

    static LOG_DISPLAY_CLASS    = 'monitor-log';
    static RESULTS_CLASS        = 'item-results';
    static ERRORS_CLASS         = 'item-errors';
    static DIAGNOSTICS_CLASS    = 'item-diagnostics';

    static LOG_DISPLAY          = selector(this.LOG_DISPLAY_CLASS);
    static RESULTS              = selector(this.RESULTS_CLASS);
    static ERRORS               = selector(this.ERRORS_CLASS);
    static DIAGNOSTICS          = selector(this.DIAGNOSTICS_CLASS);

    // ========================================================================
    // Class fields
    // ========================================================================

    /**
     * Communication channel set up once on the class.
     *
     * @type {SubmitChannel|undefined}
     * @protected
     */
    static _channel;

    /**
     * The control for the current submission sequence which has reserved use
     * of the channel.
     *
     * @type {jQuery|undefined}
     * @protected
     */
    static _channel_owner;

    // ========================================================================
    // Fields
    // ========================================================================

    /** @type {jQuery} */ $container;
    /** @type {jQuery} */ $heading;
    /** @type {jQuery} */ $log_toggle;

    // Submission status elements

    /** @type {jQuery} */ $status_display;
    /** @type {jQuery} */ $notice;

    // Submission output elements

    /** @type {jQuery} */ $output;
    /** @type {jQuery} */ $success;
    /** @type {jQuery} */ $failure;

    // Log display elements

    /** @type {jQuery} */ $log_display;
    /** @type {jQuery} */ $results;
    /** @type {jQuery} */ $errors;
    /** @type {jQuery} */ $diagnostics;

    // Callbacks

    /** @type {function(SubmitResponseSubclass)} */ response_callback;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {Selector} modal
     */
    constructor(modal) {
        super(modal);
        this.$modal ||= this.setupPanel(this.constructor.$modal);
        this.initializeStatusDisplay();
        this.initializeOutputDisplay();
        this.initializeLogDisplay();
        this._handleClickAndKeypress(this.logToggle, this.onToggleDetails);
    }

    // ========================================================================
    // Class properties - channel
    // ========================================================================

    /**
     * Communication channel set up once on the class.
     *
     * @type {SubmitChannel|undefined}
     */
    static get channel() {
        return this._channel;
    }

    /**
     * Register callbacks with the provided channel.
     *
     * @param {SubmitChannel|undefined} channel
     * @protected
     */
    static set channel(channel) {
        if (channel) {
            channel.disconnectOnPageExit(this._debugging);
            this._info('set channel', channel);
        } else {
            this._info('clear channel');
        }
        this._channel = channel;
    }

    static get channelOwner() { return this._channel_owner }
    static set channelOwner(owner) {
        const control = (owner instanceof this) ? owner.modalControl : owner;
        this._channel_owner = control;
    }

    // ========================================================================
    // Class methods - channel
    // ========================================================================

    static ownsChannel(owner) {
        const control = (owner instanceof this) ? owner.modalControl : owner;
        return control === this.channelOwner;
    }

    /**
     * Register callbacks with the communication channel for this instance.
     *
     * @param {SubmitModal|jQuery|undefined} owner
     *
     * @returns {SubmitChannel|undefined}
     */
    static reserveChannel(owner) {
        const func    = 'reserveChannel';
        const control = (owner instanceof this) ? owner.modalControl : owner;
        if (!control) {
            this._warn(`${func}: null owner invalid`);
        } else if (control === this.channelOwner) {
            this._debug(`${func}: already owned by`, owner);
        } else {
            this._debug(`${func}: for`, control);
            this._debug(`${func}: channel =`, this._channel);
            this.channelOwner = control;
            return this._channel;
        }
    }

    // ========================================================================
    // Class methods - setup
    // ========================================================================

    /**
     * @typedef {object} ChannelCallbacks
     *
     * WebSocket event handlers.
     *
     * @property {function}         [initialized]
     * @property {function}         [connected]
     * @property {function}         [rejected]
     * @property {function(object)} [received]
     * @property {function}         [disconnected]
     */

    /**
     * @typedef {ChannelCallbacks} SubmitModalCallbacks
     *
     * @property {CallbackChainFunction}            [onOpen]     ModalShowHooks
     * @property {CallbackChainFunction}            [onClose]    ModalHideHooks
     * @property {function(SubmitResponseSubclass)} [onResponse]
     *
     */

    /**
     * Setup a modal to display bulk submission responses.
     *
     * @param {Selector}             toggle
     * @param {SubmitModalCallbacks} [callbacks]
     *
     * @returns {SubmitChannel|undefined}
     */
    static async setupFor(toggle, callbacks) {
        const func = 'setupFor';
        this._debug(`${func}: toggle =`, toggle);
        this._debug(`${func}: existing toggle.data(modalInstance) =`, this.instanceFor(toggle));
        this._debug(`${func}: existing SubmitModal._channel =`, this._channel);

        // Sort out callbacks.
        const channel_cbs = {}, show_hooks = [], hide_hooks = [];
        let   response_callback;
        if (isObject(callbacks)) {
            for (const [name, cb] of Object.entries(callbacks)) {
                switch (name) {
                    case 'onOpen':     show_hooks.push(cb);    break;
                    case 'onClose':    hide_hooks.push(cb);    break;
                    case 'onResponse': response_callback = cb; break;
                    default:           channel_cbs[name] = cb; break;
                }
            }
        } else {
            response_callback = callbacks;
        }

        // One-time setup of the communication channel.
        this.channel ||= await this.setupChannel(channel_cbs);

        const $toggle  = $(toggle);
        const instance = this.instanceFor($toggle) || this.associate($toggle);
        if (instance) {
            this._debug(`${func}: instance =`, instance);
            instance._setHooksFor($toggle, show_hooks, hide_hooks);
            if (response_callback) {
                instance.response_callback = response_callback;
            }
        } else {
            this._warn(`${func}: no instance for $toggle =`, $toggle);
        }

        return this.channel;
    }

    /**
     * Setup a new channel for this subclass.
     *
     * @param {ChannelCallbacks} [callbacks]
     *
     * @returns {SubmitChannel|undefined}
     */
    static async setupChannel(callbacks) {
        console.warn('*** SubmitModal CHANNEL SETUP ***');
        const channel = await SubmitChannel.newInstance(callbacks);
        if (channel) {
            appTeardown(this.CLASS_NAME, this.teardownChannel.bind(this));
            return channel;
        }
    }

    /**
     * Teardown the channel for this subclass if connected.
     */
    static teardownChannel() {
        console.warn('*** SubmitModal CHANNEL TEARDOWN ***', this.channel);
        this.channel?.disconnect();
        this.channel = undefined;
    }

    // ========================================================================
    // Properties - channel
    // ========================================================================

    /**
     * Indicate whether the current modal control has reserved the channel.
     *
     * @returns {boolean}
     */
    get ownsChannel() {
        return this.constructor.ownsChannel(this);
    }

    // ========================================================================
    // Methods - channel
    // ========================================================================

    /**
     * Register callbacks with the communication channel for this instance.
     *
     * @returns {SubmitChannel|undefined}
     */
    _reserveChannel() {
        if (!this.ownsChannel && !this.constructor.reserveChannel(this)) {
            return;
        }
        const ch = this.constructor.channel;
        ch.setCallback(
            this.updateStatusValue.bind(this),
            this.updateStatusDisplay.bind(this),
            this.updateOutputDisplay.bind(this),
            this.updateResultDisplay.bind(this),
        );
        if (isEmpty(ch.error_callbacks)) {
            ch.setErrorCallback(this.updateErrorDisplay.bind(this));
            ch.setDiagnosticCallback(this.updateDiagnosticDisplay.bind(this));
        }
        if (this.response_callback) {
            ch.addCallback(this.response_callback);
        }
        return ch;
    }

    // ========================================================================
    // Methods - setup
    // ========================================================================

    /**
     * Merge the show/hide hooks defined on the toggle button with the ones
     * provided by the modal instance.
     *
     * @param {jQuery}                 $toggle
     * @param {CallbackChainFunctions} [show_hooks]
     * @param {CallbackChainFunctions} [hide_hooks]
     *
     * @protected
     */
    _setHooksFor($toggle, show_hooks, hide_hooks) {
        this._debug('_setHooksFor:', $toggle, show_hooks, hide_hooks);
        const show_modal = this.onShowModal.bind(this);
        const hide_modal = this.onHideModal.bind(this);
        ModalShowHooks.set($toggle, show_hooks, show_modal);
        ModalHideHooks.set($toggle, hide_modal, hide_hooks);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    /**
     * The element which holds data properties.  In the case of a modal dialog,
     * this is the element through which new user-specified field values are
     * communicated back to the originating page.
     *
     * @returns {jQuery}
     */
    get dataElement() {
        return this.modalControl || this.modalPanel;
    }

    /**
     * The element containing all of the submission-specific functional
     * elements.
     *
     * @returns {jQuery}
     */
    get container() {
        return this.$container ||=
            this.modalPanel.find(this.constructor.CONTAINER);
    }

    // ========================================================================
    // Methods - event handlers
    // ========================================================================

    /**
     * Actions taken when the popup is opened.
     *
     * @param {jQuery}  _$target      Unused.
     * @param {boolean} check_only
     * @param {boolean} [halted]
     *
     * @returns {EventHandlerReturn}
     *
     * @see onShowModalHook
     */
    onShowModal(_$target, check_only, halted) {
        this._debug('onShowModal:', _$target, check_only, halted);
        if (check_only || halted) { return }
        this._debug('onShowModal actions?');
    }

    /**
     * Actions taken when the popup is closed.
     *
     * @param {jQuery}  _$target      Unused.
     * @param {boolean} check_only
     * @param {boolean} [halted]
     *
     * @returns {EventHandlerReturn}
     *
     * @see onHideModalHook
     */
    onHideModal(_$target, check_only, halted) {
        this._debug('onHideModal:', _$target, check_only, halted);
        if (check_only || halted) { return }
        this._debug('onHideModal actions?');
    }

    /**
     * Show/hide diagnostic information.
     */
    onToggleDetails() {
        this.container.toggleClass(this.constructor.LOG_MARKER_CLASS);
    }

    // ========================================================================
    // Methods - commands
    // ========================================================================

    /**
     * Perform a bulk submission operation.
     *
     * @param {string}               action
     * @param {SubmitRequest|object} [data]
     *
     * @returns {boolean}
     *
     * @see SubmitControlRequest.ACTIONS
     */
    command(action, data) {
        this._debug(`command: ${action}: data =`, data);
        let request;
        if (action === 'start') {
            request = data ? SubmitRequest.wrap(data) : this.getRequestData();
        } else {
            request = new SubmitControlRequest(action);
        }
        return this.performRequest(request);
    }

    /**
     * Perform the requested bulk submission operation.
     *
     * @param {ChannelRequest} request
     *
     * @returns {boolean}
     */
    performRequest(request) {
        this._debug('performRequest', request);
        this.initializeStatusDisplay();
        this.clearOutputDisplay();
        this.clearLogDisplay();
        const channel = this._reserveChannel();
        if (channel) {
            return channel.request(request);
        } else {
            this._error('Could not acquire submission channel');
            return false;
        }
    }

    // ========================================================================
    // Methods - request data
    // ========================================================================

    /**
     * Get the current submission request.
     *
     * @returns {SubmitRequest}
     */
    getRequestData() {
        return this.dataElement.data(this.constructor.REQUEST_DATA);
    }

    /**
     * Set the current submission request.
     *
     * @param {string|string[]|SubmitRequest|SubmitRequestPayload} data
     *
     * @returns {SubmitRequest}       The current request object.
     */
    setRequestData(data) {
        this._debug('setRequestData:', data);
        const name    = this.constructor.REQUEST_DATA;
        const request = SubmitRequest.wrap(data);
        this.dataElement.data(name, request);
        return request;
    }

    /**
     * Clear the current submission request.
     *
     * @returns {void}
     */
    clearRequestData() {
        this._debug('clearRequestData');
        const name = this.constructor.REQUEST_DATA;
        this.dataElement.removeData(name);
    }

    // ========================================================================
    // Methods - response data
    // ========================================================================

    /**
     * Submission results are stored as a table of job identifiers mapped on to
     * their associated responses.
     *
     * @typedef {{[job_id: string]: SubmitResponsePayload}} SubmitResults
     */

    /**
     * The reported overall bulk submission status.
     *
     * @returns {BaseSubmitResponsePayload}
     */
    get submitStatus() {
        return this.getSubmitStatus() || {};
    }

    /**
     * The reported overall bulk submission status.
     *
     * @returns {BaseSubmitResponsePayload|undefined}
     */
    getSubmitStatus() {
        return this.dataElement.data(this.constructor.STATUS_DATA);
    }

    /**
     * Update the reported overall bulk submission status.
     *
     * @param {BaseSubmitResponsePayload} value
     *
     * @return {BaseSubmitResponsePayload}
     */
    setSubmitStatus(value) {
        this._debug('setSubmitStatus:', value);
        this.dataElement.data(this.constructor.STATUS_DATA, value);
        return value;
    }

    /**
     * updateStatusValue
     *
     * @param {SubmitResponseSubclass} message
     */
    updateStatusValue(message) {
        this._debug('updateStatusValue:', message);
        const payload = message.toObject();
        this.setSubmitStatus(payload);
    }

    // ========================================================================
    // Methods - heading
    // ========================================================================

    /**
     * The `<h1>` near the top of the panel.
     *
     * @returns {jQuery}
     */
    get panelHeading() {
        return this.$heading ||= this.container.find(this.constructor.HEADING);
    }

    // ========================================================================
    // Methods - submission status display
    // ========================================================================

    /**
     * The element displaying the state of the parallel requests.
     *
     * @returns {jQuery}
     */
    get statusDisplay() {
        return this.$status_display ||=
            this.container.find(this.constructor.STATUS_DISPLAY);
    }

    /**
     * The element for displaying textual status information.
     *
     * @returns {jQuery}
     */
    get statusNotice() {
        return this.$notice ||=
            this.statusDisplay.find(this.constructor.NOTICE);
    }

    /**
     * Update the displayed status notice text.
     *
     * @param {string} value
     * @param {string} [tooltip]
     */
    setStatusNotice(value, tooltip) {
        const $notice = this.statusNotice.text(value);
        if (tooltip) {
            $notice.addClass('tooltip').attr('title', tooltip);
        } else {
            $notice.removeClass('tooltip').removeAttr('title');
        }
    }

    /**
     * Change status values based on received data. // TODO: I18n
     *
     * @param {SubmitResponseSubclass} message
     */
    updateStatusDisplay(message) {
        const func  = 'updateStatusDisplay'; this._debug(`${func}:`, message);
        const state = message.status?.toUpperCase();

        let notice;
        switch (state) {

            // Waiter states

            case 'STARTING':
                notice = 'Working';
                break;
            case 'COMPLETE':
                notice = 'Completed';
                break;

            // Worker states

            case 'WORKING':
                notice = `${this.statusNotice.text()}.`;
                break;
            case 'STEP':
                notice = `Submission step "${message.step}"`;
                break;
            case 'DONE':
                notice = 'Worker done';
                break;

            // Other

            default:
                this._warn(`${func}: ${message.status}: unexpected`);
                break;
        }
        if (notice) { this.setStatusNotice(notice) }
    }

    /**
     * Put the status panel into the default state with any previous service
     * status elements removed.
     */
    initializeStatusDisplay() {
        this._debug('initializeStatusDisplay');
        // TODO: initializeStatusDisplay ?
    }

    // ========================================================================
    // Properties - output display
    // ========================================================================

    /**
     * The output display area container.
     *
     * @returns {jQuery}
     */
    get outputDisplay() {
        return this.$output ||= this.container.find(this.constructor.OUTPUT);
    }

    /**
     * Successful submission display.
     *
     * @returns {jQuery}
     */
    get successDisplay() {
        return this.$success ||=
            this.outputDisplay
                .find(this.constructor.SUCCESS)
                .find(this.constructor.DISPLAY);
    }

    /**
     * Failed submission display.
     *
     * @returns {jQuery}
     */
    get failureDisplay() {
        return this.$failure ||=
            this.outputDisplay
                .find(this.constructor.FAILURE)
                .find(this.constructor.DISPLAY);
    }

    // ========================================================================
    // Methods - output display
    // ========================================================================

    /**
     * Remove output display contents.
     */
    clearOutputDisplay() {
        this.successDisplay.text('');
        this.failureDisplay.text('');
    }

    /**
     * Update the appropriate output display element(s).
     *
     * @param {SubmitResponseSubclass} message
     */
    updateOutputDisplay(message) {
        let success, failure;
        if (message instanceof SubmitStepResponse) {
            if (message.status === 'DONE') {
                success = message.success;
            } else {
                failure = message.failure;
            }
        }
        if (isPresent(success)) {
            this.updateOutputDisplayPart(this.successDisplay, success);
        }
        if (isPresent(failure)) {
            this.updateOutputDisplayPart(this.failureDisplay, failure);
        }
    }

    /**
     * Update the contents of an output display element.
     *
     * @param {jQuery}       $element
     * @param {array|object} data
     * @param {string}       gap
     */
    updateOutputDisplayPart($element, data, gap = "\n") {
        const fmt = (v) => {
            let line;
            if (isObject(v)) {
                const [sid, err] = [v.submission_id, v.error];
                if (sid && !err) {
                    line = `submitted as entry ${sid}`; // TODO: I18n
                } else if (err && !sid) {
                    line = err;
                }
            }
            line ||= isString(v) ? v : asString(v);
            return htmlDecode(line) || line || '';
        };
        const val = (v) => Array.isArray(v) ? v.map(fmt).join('; ') : fmt(v);
        let added;
        if (Array.isArray(data)) {
            added = data.map(k => isString(k) ? `${k}: submitted` : val(k)); // TODO: I18n
        } else {
            added = Object.entries(data).map(([k, v]) => `${k}: ${val(v)}`);
        }
        const current = $element.text()?.trimEnd()?.split(gap) || [];
        const result  = [...current, ...added].sort().join(gap);
        $element.text(result);
    }

    /**
     * Initialize the state of the output display container.
     */
    initializeOutputDisplay() {
        const parts = [this.successDisplay, this.failureDisplay];
        parts.forEach(part => {
            const $part = $(part);
            if (!$part.attr('readonly')) { $part.attr('readonly', 'true') }
            $part.text('');
        });
    }

    // ========================================================================
    // Properties - log display
    // ========================================================================

    /**
     * The panel control for toggling log details.
     *
     * @returns {jQuery}
     */
    get logToggle() {
        return this.$log_toggle ||=
            this.$modal.find(this.constructor.LOG_TOGGLE);
    }

    /**
     * The log display area container.
     *
     * @returns {jQuery}
     */
    get logDisplay() {
        return this.$log_display ||=
            this.container.find(this.constructor.LOG_DISPLAY);
    }

    /**
     * Direct result display.
     *
     * @returns {jQuery}
     */
    get resultDisplay() {
        return this.$results ||=
            this.logDisplay.find(this.constructor.RESULTS);
    }

    /**
     * Direct error display.
     *
     * @returns {jQuery}
     */
    get errorDisplay() {
        return this.$errors ||=
            this.logDisplay.find(this.constructor.ERRORS);
    }

    /**
     * Direct diagnostics display.
     *
     * @returns {jQuery}
     */
    get diagnosticDisplay() {
        return this.$diagnostics ||=
            this.logDisplay.find(this.constructor.DIAGNOSTICS);
    }

    // ========================================================================
    // Methods - log display
    // ========================================================================

    /**
     * Remove result log display contents.
     */
    clearLogDisplay() {
        this.resultDisplay.text('');
        this.errorDisplay.text('');
    }

    /**
     * Update the main log display element.
     *
     * @param {SubmitResponseSubclass|SubmitResponseSubclassPayload} message
     */
    updateResultDisplay(message) {
        const data = message?.payload || message || {};
        this.updateLogDisplayPart(this.resultDisplay, data);
    }

    /**
     * Update the error log display element.
     *
     * @param {object} data
     */
    updateErrorDisplay(data) {
        this.updateLogDisplayPart(this.errorDisplay, data);
    }

    /**
     * Update the diagnostics log display element.
     *
     * @param {object} data
     */
    updateDiagnosticDisplay(data) {
        this.updateLogDisplayPart(this.diagnosticDisplay, data, '');
    }

    /**
     * Update the contents of a log display element.
     *
     * @param {jQuery} $element
     * @param {object} data
     * @param {string} gap
     */
    updateLogDisplayPart($element, data, gap = "\n") {
        const added = renderJson(data);
        let text    = $element.text()?.trimEnd();
        if (text) {
            text = text.concat("\n", gap, added);
        } else {
            text = added;
        }
        $element.text(text);
    }

    /**
     * Initialize the state of the log display container.
     */
    initializeLogDisplay() {
        const parts =
            [this.resultDisplay, this.errorDisplay, this.diagnosticDisplay];
        parts.forEach(part => {
            const $part = $(part);
            if (!$part.attr('readonly')) { $part.attr('readonly', 'true') }
            $part.text('');
        });
    }

    // ========================================================================
    // Class properties
    // ========================================================================

    /**
     * The modal popup associated with this class.
     *
     * @type {jQuery}
     */
    static get $modal() {
        const match = this.MODAL;
        return this.$all_modals.filter(match);
    }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Set up related modal toggle(s) to operate with this instance.
     *
     * @param {Selector} toggles
     *
     * @returns {SubmitModal|undefined}
     */
    static associate(toggles) {
        const func     = 'associate';
        const name     = this.MODAL_INSTANCE_DATA;
        const instance = this.$modal.data(name);
        if (instance) {
            this._debug(`${func}: toggles =`, toggles);
            instance.associateAll(toggles);
        } else {
            this._warn(`${func}: no .data(${name}) for`, this.$modal);
        }
        return instance;
    }

}
