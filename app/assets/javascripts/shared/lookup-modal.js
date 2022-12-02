// app/assets/javascripts/shared/lookup-modal.js
//
// Bibliographic Lookup
//
// noinspection LocalVariableNamingConventionJS, JSUnusedGlobalSymbols


import { LookupChannel }                   from '../channels/lookup-channel'
import { arrayWrap }                       from './arrays'
import { selector }                        from './css'
import { turnOffAutocomplete }             from './form'
import { HTML_BREAK }                      from './html'
import { renderJson }                      from './json'
import { LookupRequest }                   from './lookup-request'
import { ModalDialog }                     from './modal-dialog'
import { ModalHideHooks, ModalShowHooks }  from './modal_hooks'
import { deepFreeze, dupObject, toObject } from './objects'
import { randomizeName }                   from './random'
import { camelCase }                       from './strings'
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
    presence,
} from './definitions'
import {
    debounce,
    handleClickAndKeypress,
    handleEvent,
    handleHoverAndFocus,
    isEvent,
} from './events'


// ============================================================================
// Class LookupModal
// ============================================================================

export class LookupModal extends ModalDialog {

    static CLASS_NAME = 'LookupModal';
    static DEBUGGING  = false;

    // ========================================================================
    // Constants - .data() names
    // ========================================================================

    /**
     * The .data() key for storing the generated lookup request.
     *
     * @readonly
     * @type {string}
     */
    static REQUEST_DATA = 'lookupRequest';

    /**
     * The .data() key for storing the field replacements selected by the user.
     *
     * @readonly
     * @type {string}
     */
    static FIELD_RESULTS_DATA = 'lookupFieldResults';

    /**
     * The name by which parts of a search request can be passed in via jQuery
     * data().
     *
     * @readonly
     * @type {string}
     */
    static SEARCH_TERMS_DATA = 'lookupSearchTerms';

    /**
     * The name by which the result of a search request can be passed back via
     * jQuery data().
     *
     * @readonly
     * @type {string}
     */
    static SEARCH_RESULT_DATA = 'lookupSearchResult';

    /**
     * For saving a previous field value via jQuery .data() to compare against
     * its current value.
     *
     * @readonly
     * @type {string}
     */
    static FIELD_LATEST_DATA = 'latestValue';

    /**
     * For persisting the field value lock state via jQuery .data().
     *
     * @readonly
     * @type {string}
     */
    static FIELD_LOCKED_DATA = 'locked';

    /**
     * For storing and retrieving entries values via jQuery .data().
     *
     * @readonly
     * @type {string}
     */
    static ENTRY_ITEM_DATA = 'itemData';

    // ========================================================================
    // Constants
    // ========================================================================

    static MODAL_CLASS          = 'lookup-popup';
    static QUERY_PANEL_CLASS    = 'lookup-query';
    static QUERY_TERMS_CLASS    = 'terms';
    static STATUS_PANEL_CLASS   = 'lookup-status';
    static NOTICE_CLASS         = 'notice';
    static SERVICES_CLASS       = 'services';
    static ENTRIES_CLASS        = 'lookup-entries';
    static HEAD_ENTRY_CLASS     = 'head';
    static FIELD_VALUES_CLASS   = 'field-values';
    static FIELD_LOCKS_CLASS    = 'field-locks';
    static LOCK_CLASS           = 'lock-input';
    static ORIG_VALUES_CLASS    = 'original-values';
    static RESULT_CLASS         = 'result';
    static COMMIT_CLASS         = 'commit';
    static LOADING_CLASS        = 'loading';
    static DISABLED_MARKER      = 'disabled';

    static MODAL                = selector(this.MODAL_CLASS);
    static QUERY_PANEL          = selector(this.QUERY_PANEL_CLASS);
    static QUERY_TERMS          = selector(this.QUERY_TERMS_CLASS);
    static STATUS_PANEL         = selector(this.STATUS_PANEL_CLASS);
    static NOTICE               = selector(this.NOTICE_CLASS);
    static SERVICES             = selector(this.SERVICES_CLASS);
    static ENTRIES              = selector(this.ENTRIES_CLASS);
    static HEAD_ENTRY           = selector(this.HEAD_ENTRY_CLASS);
    static FIELD_VALUES         = selector(this.FIELD_VALUES_CLASS);
    static FIELD_LOCKS          = selector(this.FIELD_LOCKS_CLASS);
    static LOCK                 = selector(this.LOCK_CLASS);
    static ORIG_VALUES          = selector(this.ORIG_VALUES_CLASS);
    static RESULT               = selector(this.RESULT_CLASS);
    static COMMIT               = selector(this.COMMIT_CLASS);
    static LOADING              = selector(this.LOADING_CLASS);
    static DISABLED             = selector(this.DISABLED_MARKER);

    static HEADING_ROWS = [
        this.HEAD_ENTRY,
        this.FIELD_VALUES,
        this.FIELD_LOCKS,
    ].join(',');

    static RESERVED_ROWS = [
        this.HEAD_ENTRY,
        this.FIELD_VALUES,
        this.FIELD_LOCKS,
        this.ORIG_VALUES,
        this.LOADING,
    ].join(',');

    // Manual input elements

    static PROMPT_CLASS         = 'lookup-prompt';
    static PROMPT               = selector(this.PROMPT_CLASS);

    // Diagnostic output elements

    static HEADING_CLASS        = 'lookup-heading';
    static OUTPUT_CLASS         = 'lookup-output';
    static RESULTS_CLASS        = 'item-results';
    static ERRORS_CLASS         = 'item-errors';
    static DIAGNOSTICS_CLASS    = 'item-diagnostics';

    static HEADING              = selector(this.HEADING_CLASS);
    static OUTPUT               = selector(this.OUTPUT_CLASS);
    static RESULTS              = selector(this.RESULTS_CLASS);
    static ERRORS               = selector(this.ERRORS_CLASS);
    static DIAGNOSTICS          = selector(this.DIAGNOSTICS_CLASS);

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Schema for the columns displayed for each displayed lookup entry.
     *
     * @readonly
     * @type {Object.<string, {label: string, non_data?: boolean}>}
     */
    static ENTRY_TABLE = deepFreeze({ // TODO: I18n
        selection:              { label: 'USE',  non_data: true },
        tag:                    { label: 'FROM', non_data: true },
        dc_identifier:          { label: 'IDENTIFIER' },
        dc_title:               { label: 'TITLE' },
        dc_creator:             { label: 'AUTHOR/CREATOR' },
        dc_publisher:           { label: 'PUBLISHER' },
        emma_publicationDate:   { label: 'DATE' },
        dcterms_dateCopyright:  { label: 'YEAR' },
        dc_description:         { label: 'DESCRIPTION' },
    });

    /**
     * All entry column keys.
     *
     * @readonly
     * @type {string[]}
     */
    static ALL_COLUMNS = Object.keys(this.ENTRY_TABLE);

    /**
     * Keys for columns related to entry data values.
     *
     * @readonly
     * @type {string[]}
     */
    static DATA_COLUMNS = deepFreeze(
        Object.entries(this.ENTRY_TABLE).map(
            ([field, config]) => config.non_data ? [] : field
        ).flat()
    );

    /**
     * A table of separator style names and their associated separator
     * characters.
     *
     * * space: Space, tab, newline and <strong>|</strong> (pipe)
     * * pipe:  Only <strong>|</strong> (pipe)
     *
     * @readonly
     * @type {StringTable}
     */
    static SEPARATORS = {
        space: '\\s|',
        pipe:  '|',
    };

    /**
     * The default key into {@link SEPARATORS}.
     *
     * @readonly
     * @type {string}
     */
    static DEF_SEPARATORS_KEY = 'pipe';

    // ========================================================================
    // Fields
    // ========================================================================

    // Operational status elements

    /** @type {jQuery} */ $query_panel;
    /** @type {jQuery} */ $query_terms;
    /** @type {jQuery} */ $status_panel;
    /** @type {jQuery} */ $notice;
    /** @type {jQuery} */ $services;

    // Result entry elements

    /** @type {jQuery} */ $entries_display;
    /** @type {jQuery} */ $entries_list;
    /** @type {jQuery} */ $loading;

    // Result entry elements

    /** @type {jQuery} */ $selected_entry;
    /** @type {jQuery} */ $field_values;
    /** @type {jQuery} */ $field_locks;
    /** @type {jQuery} */ $original_values;

    // Manual input elements

    /** @type {jQuery} */ $prompt;
    /** @type {jQuery} */ $input;
    /** @type {jQuery} */ $submit;
    /** @type {jQuery} */ $separator;

    // Communications output elements

    /** @type {jQuery} */ $heading;
    /** @type {jQuery} */ $output;
    /** @type {jQuery} */ $results;
    /** @type {jQuery} */ $errors;
    /** @type {jQuery} */ $diagnostics;

    /**
     * The first selection radio button on the modal popup.
     *
     * @type {jQuery|undefined}
     */
    $start_tabbable;

    /**
     * Communication channel.
     *
     * @type {LookupChannel}
     * @protected
     */
    _channel;

    /**
     * Whether the source implements manual input of search terms.
     *
     * @type {boolean}
     */
    manual;

    /**
     * Whether the source displays diagnostic output elements.
     *
     * @type {boolean}
     */
    output;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {Selector} modal
     * @param {boolean}  [output]   Display communications from channel.
     * @param {boolean}  [manual]   Accept manually-entered search terms.
     */
    constructor(modal, manual, output) {

        super(modal);

        this.$modal ||= this.setupPanel(`body > ${this.constructor.MODAL}`);
        this.manual   = isDefined(manual) && manual;
        this.output   = isDefined(output) ? output : this.manual;

        // ====================================================================
        // Initialization
        // ====================================================================

        // Manual input elements

        if (this.manual) {
            const submit = this.manualSubmission.bind(this);
            handleClickAndKeypress(this.inputSubmit, submit);
            handleEvent(this.inputText, 'keyup', submit);
            turnOffAutocomplete(this.inputText);
            this.queryPanel.addClass(this.constructor.HIDDEN_MARKER);
        } else {
            this.inputPrompt.addClass(this.constructor.HIDDEN_MARKER);
        }

        if (this.output) {
            this.initializeDisplay(this.resultDisplay);
            this.initializeDisplay(this.errorDisplay);
            this.initializeDisplay(this.diagnosticDisplay);
        } else {
            this.outputHeading.addClass(this.constructor.HIDDEN_MARKER);
            this.outputDisplay.addClass(this.constructor.HIDDEN_MARKER);
        }
    }

    // ========================================================================
    // Class properties - setup
    // ========================================================================

    /**
     * Communication channel set up once on the class.
     *
     * @type {LookupChannel}
     * @protected
     */
    static _channel;

    /**
     * Communication channel set up once on the class.
     *
     * @type {LookupChannel}
     */
    static get channel() {
        return this._channel;
    }

    /**
     * Register callbacks with the provided channel.
     *
     * @param {LookupChannel} channel
     * @protected
     */
    static set channel(channel) {
        this._debug('CLASS set channel', channel);
        channel.disconnectOnPageExit(this.debugging);
        this._channel = channel;
    }

    // ========================================================================
    // Class methods - setup
    // ========================================================================

    /**
     * Setup a modal with interactive bibliographic lookup.
     *
     * @param {Selector}                                      toggle
     * @param {CallbackChainFunction|CallbackChainFunction[]} [show_hooks]
     * @param {CallbackChainFunction|CallbackChainFunction[]} [hide_hooks]
     *
     * @returns {LookupChannel}
     */
    static async setup(toggle, show_hooks, hide_hooks) {
        this._debug('CLASS setup', toggle);

        // One-time setup of the communication channel.
        this.channel ||= await LookupChannel.newInstance();

        const $toggle  = $(toggle);
        /** @type {LookupModal|undefined} instance */
        const instance = this.instanceFor($toggle);
        if (instance) {
            instance.channel = this.channel;
            instance._setHooksFor($toggle, show_hooks, hide_hooks);
        }

        return this.channel;
    }

    // ========================================================================
    // Properties - setup
    // ========================================================================

    /**
     * Get the communication channel for this class.
     *
     * @returns {LookupChannel}
     */
    get channel() {
        return this._channel;
    }

    /**
     * Register callbacks with the communication channel for this class.
     *
     * @param {LookupChannel} channel
     */
    set channel(channel) {
        this._debug('set channel', channel);

        const _cbSearchResultsData  = this.updateSearchResultsData.bind(this);
        const _cbStatusPanel        = this.updateStatusPanel.bind(this);
        const _cbEntries            = this.updateEntries.bind(this);

        channel.addCallback(_cbSearchResultsData);
        channel.addCallback(_cbStatusPanel);
        channel.addCallback(_cbEntries);

        if (this.output) {

            const _cbResult     = this.updateResultDisplay.bind(this);
            const _cbError      = this.updateErrorDisplay.bind(this);
            const _cbDiagnostic = this.updateDiagnosticDisplay.bind(this);

            channel.addCallback(_cbResult);
            channel.setErrorCallback(_cbError);
            channel.setDiagnosticCallback(_cbDiagnostic);
        }

        this._channel = channel;
    }

    // ========================================================================
    // Methods - setup
    // ========================================================================

    /**
     * Merge the show/hide hooks defined on the toggle button with the ones
     * provided by the modal instance.
     *
     * @param {jQuery}                                        $toggle
     * @param {CallbackChainFunction|CallbackChainFunction[]} [show_hooks]
     * @param {CallbackChainFunction|CallbackChainFunction[]} [hide_hooks]
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
     * Indicate whether operations are occurring within a modal dialog.
     *
     * @returns {boolean}
     */
    get isModal() {
        return true;
    }

    /**
     * The element which holds data properties.  In the case of a modal dialog,
     * this is the element through which new user-specified field values are
     * communicated back to the originating page.
     *
     * @returns {jQuery}
     */
    get dataElement() {
        return this.$toggle || this.$modal;
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Submit the query terms as a lookup request.
     *
     * @param {|jQuery.Event|Event|KeyboardEvent} event
     */
    manualSubmission(event) {
        if (isEvent(event, KeyboardEvent) && (event.key !== 'Enter')) {
            return;
        }
        this._debug('manualSubmission:', event);
        if (this.isModal) {
            // Don't allow the manual submission to close the dialog.
            event.stopPropagation();
            event.preventDefault();
        } else {
            // Force regeneration of lookup request from input search terms.
            this.clearRequestData();
        }
        this.performRequest();
    }

    /**
     * Submit the query automatically when the popup is opened.
     *
     * @param {jQuery}  _$target      Unused.
     * @param {boolean} check_only
     * @param {boolean} [halted]
     *
     * @returns {boolean|undefined}
     *
     * @see onShowModalHook
     */
    onShowModal(_$target, check_only, halted) {
        this._debug('onShowModal:', _$target, check_only, halted);
        if (check_only || halted) { return }
        this.resetSearchResultsData();
        this.clearFieldResultsData();
        this.updateSearchTerms();
        this.disableCommit();
        this.resetEntries();
        this.showLoading();
        this.performRequest();
    }

    /**
     * Commit when leaving the popup from the Update button.
     *
     * @param {jQuery}  $target       Checked for `.is(COMMIT)`.
     * @param {boolean} check_only
     * @param {boolean} [halted]
     *
     * @returns {boolean|undefined}
     *
     * @see onHideModalHook
     */
    onHideModal($target, check_only, halted) {
        this._debug('onHideModal:', $target, check_only, halted);
        if (check_only || halted) {
            // do nothing
        } else if ($target.is(this.constructor.COMMIT)) {
            this.commitFieldValuesEntry();
        } else {
            this.clearFieldResultsData();
        }
    }

    /**
     * Perform the lookup request.
     */
    performRequest() {
        this._debug('performRequest');
        this.initializeStatusPanel();
        if (this.output) {
            this.clearResultDisplay();
            this.clearErrorDisplay();
        }
        this.channel.request(this.getRequestData());
    }

    // ========================================================================
    // Methods - request data
    // ========================================================================

    /**
     * Get the current lookup request.
     *
     * @returns {LookupRequest}
     */
    getRequestData() {
        const request = this.dataElement.data(this.constructor.REQUEST_DATA);
        return request || this.setRequestData(this.getSearchTerms());
    }

    /**
     * Set the current lookup request.
     *
     * @param {string|string[]|LookupRequest|LookupRequestPayload} data
     *
     * @returns {LookupRequest}       The current request object.
     */
    setRequestData(data) {
        this._debug('setRequestData:', data);
        let request;
        if (data instanceof LookupRequest) {
            request = data;
            this.separators = request.separators;
        } else {
            request = new LookupRequest(data, this.separators);
        }
        this.dataElement.data(this.constructor.REQUEST_DATA, request);
        return request;
    }

    /**
     * Clear the current lookup request.
     *
     * @returns {void}
     */
    clearRequestData() {
        this._debug('clearRequestData');
        this.dataElement.removeData(this.constructor.REQUEST_DATA);
    }

    // ========================================================================
    // Methods - response data
    // ========================================================================

    /**
     * Lookup results are stored as a table of job identifiers mapped on to
     * their associated responses.
     *
     * @typedef {{[job_id: string]: LookupResponsePayload}} LookupResults
     */

    /**
     * Get response data stored on the data object.
     *
     * @returns {LookupResults|undefined}
     */
    get searchResultsData() {
        return this.dataElement.data(this.constructor.SEARCH_RESULT_DATA);
    }

    /**
     * Set response data on the data object.
     *
     * @param {LookupResults|undefined} value
     */
    set searchResultsData(value) {
        this._debug('set searchResultsData:', value);
        const new_value = value || this._blankSearchResultsData();
        this.dataElement.data(this.constructor.SEARCH_RESULT_DATA, new_value);
    }

    /**
     * Empty response data from the data object.
     *
     * @returns {LookupResults}
     */
    resetSearchResultsData() {
        this._debug('resetSearchResultsData');
        return this.searchResultsData = this._blankSearchResultsData();
    }

    /**
     * Update the data object with the response data.
     *
     * @param {LookupResponse} message
     */
    updateSearchResultsData(message) {
        this._debug('updateSearchResultsData:', message);
        const key = message.job_id || randomizeName('response');
        const obj = this.searchResultsData || this.resetSearchResultsData();
        obj[key]  = message.payloadCopy;
    }

    /**
     * Generate an empty response data object.
     *
     * @returns {LookupResults}
     * @protected
     */
    _blankSearchResultsData() {
        return {};
    }

    // ========================================================================
    // Methods - original field values data
    // ========================================================================

    /**
     * Get the original field values supplied via the lookup button.
     *
     * @returns {EmmaData}
     */
    get originalFieldValues() {
        return this.dataElement.data(this.constructor.ENTRY_ITEM_DATA) || {};
    }

    /**
     * Get the original field values supplied via the lookup button.
     *
     * @param {string} [caller]       For log messages.
     *
     * @returns {EmmaData}
     */
    getOriginalFieldValues(caller) {
        const data = this.originalFieldValues;
        if (isMissing(data)) {
            const func = caller || 'getOriginalFieldValues';
            const name = this.constructor.ENTRY_ITEM_DATA;
            this._warn(`${func}: toggle missing .data(${name})`);
        }
        return data;
    }

    // ========================================================================
    // Methods - new field values data
    // ========================================================================

    /**
     * Get user-selected field values stored on the data object.
     *
     * @returns {LookupResponseItem|undefined}
     */
    get fieldResultsData() {
        return this.dataElement.data(this.constructor.FIELD_RESULTS_DATA);
    }

    /**
     * Store the user-selected field values on the data object.
     *
     * @param {LookupResponseItem|undefined} value
     */
    set fieldResultsData(value) {
        this._debug('set fieldResultsData:', value);
        const new_value = value || {};
        this.dataElement.data(this.constructor.FIELD_RESULTS_DATA, new_value);
    }

    /**
     * Clear the user-selected field values from lookup.
     *
     * @returns {void}
     */
    clearFieldResultsData() {
        this._debug('clearFieldResultsData');
        this.dataElement.removeData(this.constructor.FIELD_RESULTS_DATA);
    }

    // ========================================================================
    // Methods - lookup query display
    // ========================================================================

    /**
     * The element with the display of the query currently being performed.
     *
     * @returns {jQuery}
     */
    get queryPanel() {
        return this.$query_panel ||=
            presence(this.$modal.find(this.constructor.QUERY_PANEL));
    }

    /**
     * The element containing the query currently being performed.
     *
     * @returns {jQuery}
     */
    get queryTerms() {
        return this.$query_terms ||=
            this.queryPanel.find(this.constructor.QUERY_TERMS);
    }

    // ========================================================================
    // Methods - lookup status display
    // ========================================================================

    /**
     * The element displaying the state of the parallel requests.
     *
     * @returns {jQuery}
     */
    get statusPanel() {
        this.$status_panel ||=
            presence(this.$modal.find(this.constructor.STATUS_PANEL));
        this.$status_panel ||=
            this.makeStatusPanel().insertAfter(this.inputPrompt);
        return this.$status_panel;
    }

    /**
     * The element for displaying textual status information.
     *
     * @returns {jQuery}
     */
    get statusNotice() {
        return this.$notice ||= this.statusPanel.find(this.constructor.NOTICE);
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
     * The element containing the dynamic set of external services.
     *
     * @returns {jQuery}
     */
    get serviceStatuses() {
        return this.$services ||=
            this.statusPanel.find(this.constructor.SERVICES);
    }

    /**
     * Add status element(s) for external service(s).
     *
     * @param {string|string[]} services
     *
     * @returns {void}
     */
    addServiceStatuses(services) {
        this._debug('addServiceStatuses:', services);
        const $services = this.serviceStatuses;
        if (isMissing($services.children('label'))) {
            $('<label>').text('Searching:').prependTo($services);
        }
        let names = arrayWrap(services);
        let data  = $services.data('names');
        if (data) {
            names = names.filter(srv => !data.includes(srv));
        } else {
            $services.data('names', (data = []));
        }
        if (isPresent(names)) {
            const statuses = names.map(name => this.makeServiceStatus(name));
            $services.append(statuses);
            data.push(...names);
        }
        $services.removeClass('invisible');
    }

    /**
     * Clear service status contents and data.
     */
    clearServiceStatuses() {
        this._debug('clearServiceStatuses');
        this.serviceStatuses.removeData('names').find('.service').remove();
    }

    /**
     * Change status values based on received data.
     *
     * @param {LookupResponse} message
     */
    updateStatusPanel(message) {
        const func  = 'updateStatusPanel';
        this._debug(`${func}:`, message);
        const state = message.status?.toUpperCase();
        const srv   = message.service;
        const data  = message.data;
        let finish, notice, n_tip, status;
        switch (state) {

            // Waiter states

            case 'STARTING':
                notice = 'Working';
                this.addServiceStatuses(srv);
                break;
            case 'TIMEOUT':
                notice = 'Done';
                n_tip  = 'Some searches took longer than expected';
                finish = true;
                break;
            case 'PARTIAL':
                notice = 'Done';
                n_tip  = 'Partial results received';
                finish = true;
                break;
            case 'COMPLETE':
                notice = 'Done';
                finish = true;
                break;

            // Worker states

            case 'WORKING':
                notice =`${this.statusNotice.text()}.`;
                break;
            case 'LATE':
                status = 'late';
                break;
            case 'DONE':
                status = isEmpty(data?.items) ? ['done', 'empty'] : 'done';
                break;

            // Other

            default:
                this._warn(`${func}: ${message.status}: unexpected`);
                break;
        }
        if (notice) { this.setStatusNotice(notice, n_tip) }
        if (status) { this.serviceStatuses.find(`.${srv}`).addClass(status) }
        if (finish) { this.hideLoading() }
    }

    // ========================================================================
    // Methods - lookup status display
    // ========================================================================

    /**
     * Put the status panel into the default state with any previous service
     * status elements removed.
     */
    initializeStatusPanel() {
        this._debug('initializeStatusPanel');
        this.serviceStatuses.removeClass('invisible');
        this.clearServiceStatuses();
        this.setStatusNotice('Starting...');
    }

    /**
     * Generate the element displaying the state of the parallel requests.
     *
     * @param {string} [css_class]    Default: {@link STATUS_PANEL_CLASS}
     *
     * @returns {jQuery}
     */
    makeStatusPanel(css_class) {
        const css        = css_class || this.constructor.STATUS_PANEL_CLASS;
        const $container = $('<div>').addClass(css);
        const $services  = this.makeServiceStatuses();
        const $notice    = this.makeStatusNotice();
        return $container.append($services, $notice);
    }

    /**
     * Generate the element for displaying textual status information.
     *
     * @param {string} [css_class]    Default: {@link NOTICE_CLASS}
     *
     * @returns {jQuery}
     */
    makeStatusNotice(css_class) {
        const css = css_class || this.constructor.NOTICE_CLASS;
        return $('<div>').addClass(css);
    }

    /**
     * Generate the element containing the dynamic set of external services.
     *
     * @param {string} [css_class]    Default: {@link SERVICES_CLASS}
     *
     * @returns {jQuery}
     */
    makeServiceStatuses(css_class) {
        const css = css_class || this.constructor.SERVICES_CLASS;
        return $('<div>').addClass(css);
    }

    /**
     * Generate an element for displaying the status of an external service.
     *
     * @param {string} [name]         Service name; default: 'unknown'.
     * @param {string} [css_class]    Default: 'service'
     *
     * @returns {jQuery}
     */
    makeServiceStatus(name, css_class) {
        const css     = css_class || 'service';
        const service = name      || 'unknown';
        const classes = `${css} ${service}`;
        const label   = camelCase(service);
        return $('<div>').addClass(classes).text(label);
    }

    // ========================================================================
    // Methods - commit
    // ========================================================================

    /**
     * The button(s) for updating {@link FIELD_RESULTS_DATA} from the current
     * contents of {@link $field_values}.
     *
     * @returns {jQuery}
     */
    get commitButton() {
        return this.$modal.find(this.constructor.COMMIT);
    }

    /**
     * Enable commit button(s).
     *
     * @param {boolean} [enable]      If *false*, disable.
     *
     * @returns {jQuery}              The commit button(s).
     */
    enableCommit(enable) {
        this._debug('enableCommit:', enable);
        const $button = this.commitButton;
        const marker  = this.constructor.DISABLED_MARKER;
        const set     = (enable === false);
        return $button.toggleClass(marker, set).prop('disabled', set);
    }

    /**
     * Disable commit button(s).
     *
     * @param {boolean} [disable]     If *false*, enable.
     *
     * @returns {jQuery}              The commit button(s).
     */
    disableCommit(disable) {
        this._debug('disableCommit:', disable);
        const $button = this.commitButton;
        const marker  = this.constructor.DISABLED_MARKER;
        const set     = (disable !== false);
        return $button.toggleClass(marker, set).prop('disabled', set);
    }

    // ========================================================================
    // Methods - values
    // ========================================================================

    /**
     * Get the value associated with an element.
     *
     * @param {Selector} element
     *
     * @returns {string}
     */
    getValue(element) {
        const $elem = $(element);
        if ($elem.is('textarea')) {
            return $elem.val()?.trim() || '';
        } else {
            return this.getLatestFieldValue($elem) || $elem.text().trim();
        }
    }

    /**
     * Transform an input value into the expected form for a data value.
     *
     * @param {*} item
     *
     * @returns {string[]|string}
     */
    toDataValue(item) {
        if (Array.isArray(item)) {
            return item.map(v => v?.trim ? v.trim() : v).filter(v => v);

        } else if (typeof item !== 'string') {
            return item?.toString() || '';

        } else if (item.includes("\n")) {
            // noinspection TailRecursionJS
            return this.toDataValue(item.split("\n"));

        } else {
            return item.trim();
        }
    }

    /**
     * Transform a data value into an input value.
     *
     * @param {*} item
     *
     * @returns {string}
     */
    toInputValue(item) {
        if (typeof item === 'string') {
            return item.trim();

        } else if (Array.isArray(item)) {
            return this.toDataValue(item).join("\n");

        } else {
            return this.toDataValue(item);
        }
    }

    // ========================================================================
    // Methods - replacement field values
    // ========================================================================

    /**
     * Get the entry row element containing the field values that will be
     * reported back to the form.
     *
     * @returns {jQuery}
     */
    get fieldValuesEntry() {
        return this.$field_values;
    }

    /**
     * Set the field values row element.
     *
     * @param {jQuery} $entry
     */
    set fieldValuesEntry($entry) {
        this.$field_values = $entry;
    }

    /**
     * Fill the fields values row element from item data attached to the toggle
     * button and toggle the lock state of each associated column accordingly.
     *
     * @param {string} [caller]       For log messages.
     *
     * @returns {jQuery}
     */
    refreshFieldValuesEntry(caller) {
        const func   = caller || 'refreshFieldValuesEntry';
        const data   = this.getOriginalFieldValues(func);
        const $entry = this.fieldValuesEntry;
        this.fillEntry($entry, data);
        $entry.find('textarea').each((_, column) => {
            const $field = $(column);
            const lock   = !!this.getValue($field);
            this.lockFor($field).prop('checked', lock);
            this.lockFieldValue($field, lock);
        });
        return $entry;
    }

    /**
     * Invoked when the user commits to the new field values.
     */
    commitFieldValuesEntry() {
        const func = 'commitFieldValuesEntry';
        this._debug(func);
        const original = this.getOriginalFieldValues(func);
        const current  = this.getColumnValues(this.fieldValuesEntry);
        const result   = {};
        $.each(current, (field, value) => {
            let use_value = true;
            if (original.hasOwnProperty(field)) {
                const orig = this.toInputValue(original[field]);
                const curr = this.toInputValue(value);
                use_value  = (curr !== orig);
            }
            if (use_value) {
                result[field] = value;
            }
        });
        this.fieldResultsData = result;
    }

    /**
     * Get the field value element.
     *
     * @param {string|jQuery|HTMLElement} field
     *
     * @returns {jQuery}
     */
    fieldValueCell(field) {
        const func = 'fieldValueCell';
        let $result;
        if (typeof field === 'string') {
            $result = this.fieldValuesEntry.find(`[data-field="${field}"]`);
        } else {
            $result = $(field);
        }
        if (!$result.is('textarea[data-field]')) {
            this._warn(`${func}: not a field value:`, field);
        }
        return $result;
    }

    /**
     * Get the data field associated with the given element (from either itself
     * or the nearest parent).
     *
     * @param {Selector} target
     *
     * @returns {string|undefined}
     */
    fieldFor(target) {
        const df   = 'data-field';
        const $tgt = $(target);
        return $tgt.attr(df) || $tgt.parents(`[${df}]`).first().attr(df);
    }

    /**
     * If a field value column is not already locked, lock it if its contents
     * have changed.
     *
     * @param {jQuery.Event|Event} event
     */
    lockIfChanged(event) {
        this._debug('lockIfChanged:', event);
        const $textarea = $(event.target);
        const current   = this.getValue($textarea);
        const previous  = this.getLatestFieldValue($textarea);
        if (current !== previous) {
            this.setLatestFieldValue($textarea, current);
            if (!this.isLockedFieldValue($textarea)) {
                this.lockFor($textarea).click();
            }
        }
        const field    = $textarea.attr('data-field');
        const original = this.originalFieldValues[field] || '';
        if (current !== this.toInputValue(original)) {
            this.enableCommit();
        }
    }

    /**
     * Get the most-recently-saved value for a field value element.
     *
     * @param {jQuery} $textarea
     *
     * @returns {string}
     */
    getLatestFieldValue($textarea) {
        const value_name = this.constructor.FIELD_LATEST_DATA;
        return $textarea.data(value_name)?.trim() || '';
    }

    /**
     * Set the most-recently-saved value for a field value element.
     *
     * @param {jQuery} $textarea
     * @param {string} [value]        Default: current value of $textarea.
     */
    setLatestFieldValue($textarea, value) {
        const value_name = this.constructor.FIELD_LATEST_DATA;
        const new_value  = isDefined(value) ? value : this.getValue($textarea);
        $textarea.data(value_name, new_value);
    }

    // ========================================================================
    // Methods - field locks
    // ========================================================================

    /**
     * Get the entry row element containing the lock/unlock radio buttons
     * controlling the updatability of each associated field value.
     *
     * @returns {jQuery}
     */
    get fieldLocksEntry() {
        return this.$field_locks;
    }

    /**
     * Set the field locks row element.
     *
     * @param {jQuery} $entry
     */
    set fieldLocksEntry($entry) {
        this.$field_locks = $entry;
    }

    /**
     * Get the field lock associated with the given data field.
     *
     * @param {Selector} target
     *
     * @returns {jQuery}
     */
    lockFor(target) {
        const field = this.fieldFor(target);
        /** @type {jQuery} */
        let $column = this.fieldLocksEntry.children(`[data-field="${field}"]`);
        return $column.find(this.constructor.LOCK);
    }

    /**
     * Indicate whether the given field value is locked.
     *
     * @param {string|jQuery|HTMLElement} field
     *
     * @returns {boolean}
     */
    isLockedFieldValue(field) {
        const flag_name = this.constructor.FIELD_LOCKED_DATA;
        return !!this.fieldValueCell(field).data(flag_name);
    }

    /**
     * Lock the associated field value from being updated by changing the
     * selected entry.
     *
     * (The field is not disabled, so it is still editable by the user.)
     *
     * @param {string|jQuery|HTMLElement} field
     * @param {boolean}                   [locking] If *false*, unlock instead.
     */
    lockFieldValue(field, locking) {
        this._debug('lockFieldValue:', field, locking);
        const flag_name = this.constructor.FIELD_LOCKED_DATA;
        const lock      = (locking !== false);
        this.fieldValueCell(field).data(flag_name, lock);
    }

    /**
     * Unlock the associated field value to allow updating by changing the
     * selected entry.
     *
     * @param {string|jQuery|HTMLElement} field
     * @param {boolean}                   [unlocking] If *false*, lock instead.
     */
    unlockFieldValue(field, unlocking) {
        this._debug('unlockFieldValue:', field, unlocking);
        const flag_name = this.constructor.FIELD_LOCKED_DATA;
        const lock      = (unlocking === false);
        this.fieldValueCell(field).data(flag_name, lock);
    }

    /**
     * The lock/unlock control is toggled.
     *
     * @param {jQuery.Event|Event} event
     */
    toggleFieldLock(event) {
        this._debug('toggleFieldLock:', event);
        const $target = $(event.target);
        const field   = this.fieldFor($target);
        const lock    = $target.is(':checked');
        this.lockFieldValue(field, lock);
        this.columnLockout(field, lock);
    }

    /**
     * Toggle the appearance of a column of values based on the locked state of
     * the related field.
     *
     * @param {string}  field
     * @param {boolean} lock
     */
    columnLockout(field, lock) {
        const HEAD    = this.constructor.HEADING_ROWS;
        const $rows   = this.entriesList.children('.row').not(HEAD);
        const $column = $rows.children(`[data-field="${field}"]`);
        $column.toggleClass('locked-out', lock);
    }

    /**
     * Add 'locked-out' to every field of an entry row according to the locked
     * state of the related field.
     *
     * @param {Selector} entry
     */
    fieldLockout(entry) {
        $(entry).children('[data-field]').each((_, column) => {
            const $field = $(column);
            const field  = $field.attr('data-field');
            const locked = this.isLockedFieldValue(field);
            $field.toggleClass('locked-out', locked);
        });
    }

    // ========================================================================
    // Methods - original values entry
    // ========================================================================

    /**
     * Get the entry row element containing the field values that were
     * originally supplied by to the form.
     *
     * @returns {jQuery}
     */
    get originalValuesEntry() {
        return this.$original_values;
    }

    /**
     * Set the original values row element.
     *
     * @param {jQuery} $entry
     */
    set originalValuesEntry($entry) {
        this.$original_values = $entry;
    }

    /**
     * Fill the original values row element from item data attached to the
     * toggle button.
     *
     * @param {string} [caller]       For log messages.
     *
     * @returns {jQuery}
     */
    refreshOriginalValuesEntry(caller) {
        const func   = caller || 'refreshOriginalValuesEntry';
        const data   = this.getOriginalFieldValues(func);
        const $entry = this.originalValuesEntry;
        this.fillEntry($entry, data);
        $entry.data(this.constructor.ENTRY_ITEM_DATA, dupObject(data));
        return $entry;
    }

    // ========================================================================
    // Methods - entry selection
    // ========================================================================

    /**
     * Get the entry row element that has been selected by the user.
     *
     * @returns {jQuery}
     */
    get selectedEntry() {
        return this.$selected_entry ||=
            this.entrySelectButtons.filter(':checked').parents('.row').first();
    }

    /**
     * Set the entry row element that has been selected by the user.
     *
     * @param {jQuery} $entry
     */
    set selectedEntry($entry) {
        this.$selected_entry = $entry;
    }

    /**
     * Reset the selected entry to the "ORIGINAL" entry.
     */
    resetSelectedEntry() {
        this._debug('resetSelectedEntry');
        this.$selected_entry = null;
    }

    /**
     * Use the entry row selected by the user to update unlocked field values.
     *
     * @param {Selector} [entry]      Default: {@link selectedEntry}
     */
    useSelectedEntry(entry) {
        this._debug('useSelectedEntry:', entry);
        const $entry   = entry && (this.selectedEntry = $(entry));
        const values   = this.entryValues($entry || this.selectedEntry);
        const $fields  = this.fieldValuesEntry;
        const columns  = $fields.children('[data-field]').toArray();
        const unlocked = columns.filter(col => !this.isLockedFieldValue(col));
        const writable = unlocked.map(col => this.fieldFor(col));
        this.fillEntry($fields, values, writable);
    }

    /**
     * The user selects a lookup result entry as the basis for the new field
     * values for the originating submission entry.
     *
     * The event target is assumed to have an entry row as a parent.
     *
     * @param {jQuery.Event|Event} event
     */
    selectEntry(event) {
        this._debug('selectEntry:', event);
        this.hideLoading();
        /** @type {jQuery} */
        const $target = $(event.currentTarget || event.target),
              $entry  = $target.parents('.row').first();
        if ($target.attr('type') !== 'radio') {
            $target.focus();
            $entry.find('[type="radio"]').click();
        } else if ($target.is(':checked')) {
            this.entrySelectButtons.not($target).prop('checked', false);
            this.useSelectedEntry($entry);
            if ($entry.is(this.constructor.RESULT)) {
                this.enableCommit();
            } else if (this.commitButton.is(this.constructor.DISABLED)) {
                // For the initial selection of the "ORIGINAL" row, lock all
                // the fields that already have data.
                $entry.children('[data-field]').each((_, column) => {
                    const $field = $(column);
                    const value  = this.getValue($field);
                    if (isPresent(value)) {
                        this.lockFor($field).click();
                    }
                });
            }
        }
    }

    /**
     * Accentuate all of the elements of the related entry.
     *
     * The event target is assumed to have an entry row as a parent.
     *
     * @param {jQuery.Event|Event} event
     */
    highlightEntry(event) {
        const $target = $(event.target);
        const $entry  = $target.parents('.row').first();
        $entry.children().toggleClass('highlight', true);
    }

    /**
     * De-accentuate all of the elements of the related entry.
     *
     * The event target is assumed to have an entry row as a parent.
     *
     * @param {jQuery.Event|Event} event
     */
    unhighlightEntry(event) {
        const $target = $(event.target);
        const $entry  = $target.parents('.row').first();
        $entry.children().toggleClass('highlight', false);
    }

    // ========================================================================
    // Methods - entry values
    // ========================================================================

    /**
     * Get a copy of the given entry's field values.
     *
     * @param {Selector} entry
     *
     * @returns {LookupResponseItem}
     */
    entryValues(entry) {
        const $entry = $(entry);
        const values = $entry.data(this.constructor.ENTRY_ITEM_DATA);
        return values ? dupObject(values) : this.getColumnValues($entry);
    }

    /**
     * Get the values of the entry from its data fields.
     *
     * @param {jQuery}   $entry
     * @param {string[]} [fields]
     *
     * @returns {LookupResponseItem}
     */
    getColumnValues($entry, fields) {
        const columns = fields || this.constructor.DATA_COLUMNS
        return toObject(columns, c => this.getColumnValue($entry, c));
    }

    /**
     * Get the value(s) of the entry's data field.
     *
     * @param {jQuery} $entry
     * @param {string} field
     *
     * @returns {string[]|string}
     */
    getColumnValue($entry, field) {
        /** @type {jQuery} */
        const $column = $entry.children(`[data-field="${field}"]`);
        const value   = this.getValue($column);
        return this.toDataValue(value);
    }

    /**
     * Update the entry's data field displayed value(s).
     *
     * @param {jQuery} $entry
     * @param {string} field
     * @param {*}      field_value
     */
    setColumnValue($entry, field, field_value) {
        /** @type {jQuery} */
        const $column = $entry.children(`[data-field="${field}"]`);
        let value     = this.toInputValue(field_value);
        this.setLatestFieldValue($column, value);

        if ($column.is('textarea')) {
            // Operating on a column of the $field_values entry.  In addition
            // to setting the value of the input field, store a copy for use
            // when checking for editing.
            $column.val(value);

        } else if (isPresent($column)) {
            // Operating on a column of a result entry.  Separate discrete
            // value parts visually with breaks.
            let $text = $column.children('.text');
            if (isMissing($text)) {
                $text = $('<div>').addClass('text').appendTo($column);
            }
            value = this.toDataValue(field_value);
            if (Array.isArray(value)) {
                const $tmp  = $('<i>');
                const lines = value.map(line => $tmp.text(line).html());
                $text.html(lines.join(HTML_BREAK));
            } else {
                $text.text(value);
            }
        }
    }

    // ========================================================================
    // Methods - entry display
    // ========================================================================

    /**
     * The container of the element containing the list of entries.
     *
     * @returns {jQuery}
     */
    get entriesDisplay() {
        this.$entries_display ||=
            presence(this.$modal.find(this.constructor.ENTRIES));
        this.$entries_display ||=
            this.makeEntriesDisplay().insertAfter(this.statusPanel);
        return this.$entries_display;
    }

    /**
     * The element containing all generated lookup entries.
     *
     * @returns {jQuery}
     */
    get entriesList() {
        return this.$entries_list ||= this.entriesDisplay.find('.list');
    }

    /**
     * All entry selection radio buttons.
     *
     * **Implementation Notes**
     * This can't be "memoized" because the set of radio buttons will change
     * as entries are added dynamically.
     *
     * @returns {jQuery}
     */
    get entrySelectButtons() {
        return this.entriesList.find('.selection [type="radio"]');
    }

    /**
     * Present a candidate lookup result entry.
     *
     * @param {LookupResponse} message
     */
    updateEntries(message) {
        const func = 'updateEntries';
        const data = message.data;
        const init = this.isModal && !this.tabCycleStart;

        if (message.status === 'STARTING') {
            this._debug(`${func}: ignoring STARTING message`);

        } else if (isMissing(data)) {
            this._warn(`${func}: missing message.data`);

        } else if (data.blend) {
            this._debug(`${func}: ignoring empty message.data.blend`);

        } else if (isMissing(data.items)) {
            this._warn(`${func}: empty message.data.items`);

        } else {
            const request = this.getRequestData();
            const req_ids = presence(request.ids);
            const service = camelCase(message.service);
            $.each(data.items, (id, items) => {
                if (!req_ids || req_ids.includes(id)) {
                    items.forEach(item => this.addEntry(item, service));
                }
            });
        }

        this.tabCycleStart ||= init && this.$start_tabbable;
    }

    /**
     * Include a candidate lookup result entry.
     *
     * @param {LookupResponseItem} item
     * @param {string}             [label]
     * @param {string}             [css_class]
     *
     * @returns {jQuery}
     */
    addEntry(item, label, css_class) {
        this._debug('addEntry:', item, label, css_class);
        const $list  = this.entriesList;
        const row    = $list.children('.row').length;
        const $entry = this.makeResultEntry(row, label, css_class);
        this.fieldLockout($entry);
        this.fillEntry($entry, item);
        if (item) {
            $entry.data(this.constructor.ENTRY_ITEM_DATA, dupObject(item));
        }
        return $entry.appendTo($list);
    }

    /**
     * Fill *$entry* data fields from *item*.
     *
     * @param {jQuery}             $entry
     * @param {LookupResponseItem} item
     * @param {string[]}           [fields]
     *
     * @returns {jQuery}
     */
    fillEntry($entry, item, fields) {
        const data    = item || {};
        const columns = fields || this.constructor.DATA_COLUMNS
        columns.forEach(col => this.setColumnValue($entry, col, data[col]));
        return $entry;
    }

    /**
     * Remove all entries (not including the head and field values rows).
     *
     * If $entries_list does not exist, this returns immediately.
     */
    resetEntries() {
        const func = 'resetEntries';
        this._debug(func);
        if (this.$entries_list) {
            const RESERVED_ROWS = this.constructor.RESERVED_ROWS;
            this.$entries_list.children().not(RESERVED_ROWS).remove();
            this.refreshOriginalValuesEntry(func);
        } else {
            // Cause an empty list with reserved rows to be created.
            this.entriesList;
        }
        this.resetSelectedEntry();
        this.refreshFieldValuesEntry(func);
    }

    /**
     * The placeholder indicating that loading is occurring.
     *
     * @returns {jQuery}
     */
    get loadingPlaceholder() {
        return this.$loading ||=
            this.entriesList.children(this.constructor.LOADING);
    }

    /**
     * Show the placeholder indicating that loading is occurring.
     */
    showLoading() {
        const hidden = this.constructor.HIDDEN_MARKER;
        this.loadingPlaceholder.toggleClass(hidden, false);
    }

    /**
     * Hide the placeholder indicating that loading is occurring.
     */
    hideLoading() {
        const hidden = this.constructor.HIDDEN_MARKER;
        this.loadingPlaceholder.toggleClass(hidden, true);
    }

    // ========================================================================
    // Methods - entry display
    // ========================================================================

    /**
     * Generate the container including the initially-empty list of entries.
     *
     * @param {string} [css_class]    Default: {@link ENTRIES_CLASS}
     *
     * @returns {jQuery}
     */
    makeEntriesDisplay(css_class) {
        const css      = css_class || this.constructor.ENTRIES_CLASS;
        const $display = $('<div>').addClass(css);
        const $list    = this.makeEntriesList();
        return $display.append($list);
    }

    /**
     * Generate the list of entries containing only the "reserved" non-entry
     * rows (column headers, field values, and field locks).
     *
     * @param {string} [css_class]    Default: 'list'
     *
     * @returns {jQuery}
     */
    makeEntriesList(css_class) {
        const css        = css_class || 'list';
        const cols       = this.constructor.ALL_COLUMNS.length;
        const $list      = $('<div>').addClass(`${css} columns-${cols}`);
        let row          = 0;
        const $heads     = this.makeHeadEntry(row++);
        const $values    = this.makeFieldValuesEntry(row++);
        const $locks     = this.makeFieldLocksEntry(row++);
        const $originals = this.makeOriginalValuesEntry(row++);
        const $loading   = this.makeLoadingPlaceholder();
        return $list.append($heads, $values, $locks, $originals, $loading);
    }

    /**
     * Generate a lookup results entries heading row.
     *
     * @param {number} row
     * @param {string} [css_class]    Default: {@link HEAD_ENTRY_CLASS}
     *
     * @returns {jQuery}
     */
    makeHeadEntry(row, css_class) {
        const css    = css_class || this.constructor.HEAD_ENTRY_CLASS;
        const fields = this.constructor.ALL_COLUMNS;
        const cols   = fields.map(label => this.makeHeadColumn(label));
        return this.makeEntry(row, cols, css);
    }

    /**
     * Generate the lookup results entries row which is primed with the
     * user-selected lookup result entry.
     *
     * @param {number} row
     * @param {string} [css_class]    Default: {@link HEAD_ENTRY_CLASS}
     *
     * @returns {jQuery}
     */
    makeFieldValuesEntry(row, css_class) {
        const css     = css_class || this.constructor.FIELD_VALUES_CLASS;
        const fields  = this.constructor.DATA_COLUMNS;
        const $select = this.makeBlankColumn();
        const $label  = this.makeTagColumn();
        const inputs  = fields.map(field => this.makeFieldInputColumn(field));
        const cols    = [$select, $label, ...inputs];
        this.respondAsHighlightable(inputs);
        return this.fieldValuesEntry = this.makeEntry(row, cols, css);
    }

    /**
     * Generate the row of controls which lock/unlock the contents of the
     * associated field value.
     *
     * Headings for the first two columns are displayed here rather than the
     * head row.
     *
     * @param {number} row
     * @param {string} [css_class]    Default: {@link FIELD_LOCKS_CLASS}
     *
     * @returns {jQuery}
     */
    makeFieldLocksEntry(row, css_class) {
        const css     = css_class || this.constructor.FIELD_LOCKS_CLASS;
        const fields  = this.constructor.DATA_COLUMNS;
        const TABLE   = this.constructor.ENTRY_TABLE;
        const $select = this.makeBlankColumn(TABLE['selection'].label);
        const $label  = this.makeTagColumn(TABLE['tag'].label);
        const locks   = fields.map(field => this.makeFieldLockColumn(field));
        const cols    = [$select, $label, ...locks];
        return this.fieldLocksEntry = this.makeEntry(row, cols, css);
    }

    /**
     * Generate the field contents of the original values row element.
     *
     * @param {number} row
     * @param {string} [css_class]    Default: {@link ORIG_VALUES_CLASS}
     *
     * @returns {jQuery}
     */
    makeOriginalValuesEntry(row, css_class) {
        const func = 'makeOriginalValuesEntry';
        const tag  = 'ORIGINAL'; // TODO: I18n
        const css  = css_class || this.constructor.ORIG_VALUES_CLASS;
        this.originalValuesEntry = this.makeResultEntry(row, tag, css);
        return this.refreshOriginalValuesEntry(func);
    }

    /**
     * Generate a row of data values from a lookup result entry.
     *
     * @param {number} row
     * @param {string} tag
     * @param {string} [css_class]    Default: {@link RESULT_CLASS}.
     *
     * @returns {jQuery}
     */
    makeResultEntry(row, tag, css_class) {
        const css    = css_class || this.constructor.RESULT_CLASS;
        const fields = this.constructor.DATA_COLUMNS;
        const label  = tag || 'Result'; // TODO: I18n
        const $radio = this.makeSelectColumn();
        const $label = this.makeTagColumn(label);
        const values = fields.map(field => this.makeDataColumn(field));
        const cols   = [$radio, $label, ...values];
        this._handleClickAndKeypress($label, this.selectEntry);
        this.respondAsHighlightable([$label, ...values]);
        this.respondAsVisibleOnFocus(cols);
        return this.makeEntry(row, cols, css);
    }

    /**
     * Generate a new row to be included in list of lookup results entries.
     *
     * @param {number}   row
     * @param {jQuery[]} columns
     * @param {string}   [css_class]
     *
     * @returns {jQuery}
     */
    makeEntry(row, columns, css_class) {
        const css    = 'row';
        const $entry = $('<div>').addClass(`${css} row-${row}`);
        if (css_class) {
            $entry.addClass(css_class);
        }
        let col    = 0;
        const cols = columns.map($c => $c.addClass(`row-${row} col-${col++}`));
        return $entry.append(cols);
    }

    /**
     * Generate the element containing the loading placeholder image.
     *
     * @param {boolean} [visible]     If *true* do not create hidden.
     * @param {string}  [css_class]   Default: {@link LOADING_CLASS}.
     *
     * @returns {jQuery}
     */
    makeLoadingPlaceholder(visible, css_class) {
        const css    = css_class || this.constructor.LOADING_CLASS;
        const hidden = visible ? '' : this.constructor.HIDDEN_MARKER;
        const $line  = $('<div>').addClass(`${css} ${hidden}`);
        const $image = $('<div>'); // @see stylesheets/controllers/_entry.scss
        return $line.append($image);
    }

    /**
     * Generate the input area for a specific data field.
     *
     * @param {string}          field
     * @param {string|string[]} [value]
     * @param {string}          [css_class]
     *
     * @returns {jQuery}
     */
    makeFieldInputColumn(field, value, css_class) {
        const $cell = $('<textarea>').attr('data-field', field);
        $cell.val(this.toInputValue(value));
        if (css_class) {
            $cell.addClass(css_class);
        }
        this.monitorEditing($cell);
        return $cell;
    }

    /**
     * Generate a field lock element.
     *
     * @param {string}         field
     * @param {boolean|string} [value]
     * @param {string}         [css_class]
     *
     * @returns {jQuery}
     */
    makeFieldLockColumn(field, value, css_class) {
        const $cell = $('<div>').attr('data-field', field);
        if (css_class) {
            $cell.addClass(css_class);
        }
        const parts = this.makeLockControl(`lock-${field}`);
        return $cell.append(parts);
    }

    /**
     * Generate an invisible checkbox paired with a visible indicator.
     *
     * @param {string}  [name]
     * @param {boolean} [checked]
     * @param {string}  [css_class]   Default: {@link LOCK_CLASS}.
     *
     * @returns {[jQuery,jQuery]}
     */
    makeLockControl(name, checked, css_class) {
        const css      = css_class || this.constructor.LOCK_CLASS;
        let $slider    = $('<div>').addClass('slider');
        let $indicator = $('<div>').addClass('lock-indicator').append($slider);
        let $checkbox  = $('<input>').attr('type', 'checkbox').addClass(css);
        isDefined(name)    && $checkbox.attr('name',    name);
        isDefined(checked) && $checkbox.prop('checked', checked);
        this._handleEvent($checkbox, 'change', this.toggleFieldLock);
        return [$checkbox, $indicator];
    }

    /**
     * Generate a radio button for selecting the associated entry.
     *
     * @param {boolean} [active]
     * @param {string}  [css_class]   Default: 'selection'.
     *
     * @returns {jQuery}
     */
    makeSelectColumn(active, css_class) {
        const css   = css_class || 'selection';
        const $cell = $('<div>').addClass(css);
        const parts = this.makeSelectControl(active);
        return $cell.append(parts);
    }

    /**
     * Generate an invisible radio button paired with a visible indicator.
     *
     * @param {boolean} [active]
     * @param {string}  [css_class]
     *
     * @returns {[jQuery,jQuery]}
     */
    makeSelectControl(active, css_class) {
        const $outer     = $('<div>').addClass('outer');
        const $inner     = $('<div>').addClass('inner');
        const $indicator = $('<div>').addClass('select-indicator');
        const $radio     = $('<input>').attr('type', 'radio');
        if (css_class) {
            $radio.addClass(css_class);
        }
        $radio.prop('checked', (active === true));
        this._handleEvent($radio, 'change', this.selectEntry);
        this.$start_tabbable ||= $radio;
        return [$radio, $indicator.append($outer, $inner)];
    }

    /**
     * Generate a heading row element with the label of the related data field.
     *
     * @param {string} field
     * @param {string} [css_class]
     *
     * @returns {jQuery}
     */
    makeHeadColumn(field, css_class) {
        const value = this.constructor.ENTRY_TABLE[field]?.label || field;
        return this.makeBlankColumn(value, css_class);
    }

    /**
     * Generate an element for holding a designation for the related entry.
     *
     * @param {string} [label]
     * @param {string} [css_class]    Default: 'tag'.
     *
     * @returns {jQuery}
     */
    makeTagColumn(label, css_class) {
        const css = css_class || 'tag';
        return this.makeBlankColumn(label).addClass(css);
    }

    /**
     * Generate an element for holding the value of the given field from the
     * related entry.
     *
     * @param {string} field
     * @param {string} [value]
     * @param {string} [css_class]
     *
     * @returns {jQuery}
     */
    makeDataColumn(field, value, css_class) {
        const $cell = this.makeBlankColumn(value).attr('data-field', field);
        if (css_class) {
            $cell.addClass(css_class);
        }
        this._handleClickAndKeypress($cell, this.selectEntry);
        return $cell;
    }

    /**
     * Generate an empty column element.
     *
     * @param {string} [label]
     * @param {string} [css_class]
     *
     * @returns {jQuery}
     */
    makeBlankColumn(label, css_class) {
        const $content = $('<span class="text">').text(label || '');
        const $cell    = $('<div>');
        if (css_class) {
            $cell.addClass(css_class);
        }
        return $cell.append($content);
    }

    // ========================================================================
    // Methods - event handlers
    // ========================================================================

    /**
     * Setup event handlers on a field value column to lock the field if the
     * user changes it manually.
     *
     * @param {Selector} item
     */
    monitorEditing(item) {
        const $item  = $(item);
        const locker = this.lockIfChanged.bind(this);
        handleEvent($item, 'input', debounce(locker));
    }

    /**
     * Make the given items highlight when hovered or focused.
     *
     * @param {Selector|Selector[]} items
     */
    respondAsHighlightable(items) {
        const enter = this.highlightEntry.bind(this);
        const leave = this.unhighlightEntry.bind(this);
        arrayWrap(items).forEach(i => handleHoverAndFocus($(i), enter, leave));
    }

    /**
     * Make the given items scroll into view when visited by tabbing.
     *
     * @note This doesn't do anything yet...
     *
     * @param {Selector|Selector[]} items
     */
    respondAsVisibleOnFocus(items) {
        //const scroll = (ev => $(ev.target)[0].scrollIntoView(false));
        //arrayWrap(items).forEach(i => handleEvent($(i), 'focus', scroll));
    }

    // ========================================================================
    // Methods - input - prompt display
    // ========================================================================

    /**
     * The element containing manual input controls.
     *
     * @returns {jQuery}
     */
    get inputPrompt() {
        return this.$prompt ||= this.$modal.find(this.constructor.PROMPT);
    }

    /**
     * The <input> control for manual input.
     *
     * @returns {jQuery}
     */
    get inputText() {
        return this.$input ||= this.inputPrompt.find('[type="text"]');
    }

    /**
     * The submit button for manual input.
     *
     * @returns {jQuery}
     */
    get inputSubmit() {
        return this.$submit ||=
            this.inputPrompt.find('[type="submit"], .submit');
    }

    /**
     * The radio buttons for manual selection of allowed separator(s).
     *
     * @returns {jQuery}
     */
    get inputSeparator() {
        return this.$separator ||= this.inputPrompt.find('[type="radio"]');
    }

    // ========================================================================
    // Methods - input - search terms
    // ========================================================================

    /**
     * Get the terms to lookup.
     *
     * @returns {string|undefined}
     */
    getSearchTerms() {
        return this.inputText.val();
    }

    /**
     * Set the terms to lookup.
     *
     * @param {string|string[]} terms
     * @param {string}          [separator]
     *
     * @returns {jQuery}
     */
    setSearchTerms(terms, separator) {
        this._debug('setSearchTerms:', terms, separator);
        const chars  = (separator || this.separators).replaceAll('\\s', ' ');
        const sep    = chars[0];
        const parts  = arrayWrap(terms);
        const $query = this.queryTerms;
        if (isPresent($query)) {
            const query_parts =
                parts.map(function(part) {
                    const words  = part.split(':');
                    const prefix = words.shift();
                    let value    = words.join(':');
                    if (value.match(/\s/)) {
                        value = `"${value}"`;
                    }
                    return `${prefix}:${value}`;
                });
            $query.text(query_parts.join(' '));
        }
        return this.inputText.val(parts.join(sep));
    }

    /**
     * Create the lookup request from the search terms provided by the event
     * target.
     *
     * @param {jQuery.Event|Event} [event]
     */
    updateSearchTerms(event) {
        this._debug('updateSearchTerms:', event);
        const $data_src = event ? $(event.target) : this.dataElement;
        const data      = $data_src.data(this.constructor.SEARCH_TERMS_DATA);
        const request   = this.setRequestData(data);
        this.setSearchTerms(request.terms);
    }

    // ========================================================================
    // Methods - input - separator selection
    // ========================================================================

    /**
     * Return the currently-selected separator character(s).
     *
     * @returns {string}
     */
    get separators() {
        const key = this.inputSeparator.filter(':checked').val();
        const SEP = this.constructor.SEPARATORS;
        return SEP[key] || SEP[this.constructor.DEF_SEPARATORS_KEY];
    }

    /**
     * Update the separator radio button selection if necessary.
     *
     * @param {string} new_characters
     */
    set separators(new_characters) {
        if (this.separators !== new_characters) {
            const $separator = this.inputSeparator;
            $.each(this.constructor.SEPARATORS, function(key, characters) {
                if (new_characters !== characters) { return true } // continue
                $separator.filter(`[value="${key}"]`).trigger('click');
                return false; // break
            });
        }
    }

    // ========================================================================
    // Properties - output - message display
    // ========================================================================

    /**
     * The <h2> before the output display area.
     *
     * @returns {jQuery}
     */
    get outputHeading() {
        return this.$heading ||= this.$modal.find(this.constructor.HEADING);
    }

    /**
     * The output display area container
     *
     * @returns {jQuery}
     */
    get outputDisplay() {
        return this.$output ||= this.$modal.find(this.constructor.OUTPUT);
    }

    /**
     * Direct result display.
     *
     * @returns {jQuery}
     */
    get resultDisplay() {
        return this.$results ||=
            this.outputDisplay.find(this.constructor.RESULTS);
    }

    /**
     * Direct error display.
     *
     * @returns {jQuery}
     */
    get errorDisplay() {
        return this.$errors ||=
            this.outputDisplay.find(this.constructor.ERRORS);
    }

    /**
     * Direct diagnostics display.
     *
     * @returns {jQuery}
     */
    get diagnosticDisplay() {
        return this.$diagnostics ||=
            this.outputDisplay.find(this.constructor.DIAGNOSTICS);
    }

    // ========================================================================
    // Methods - output - message display
    // ========================================================================

    /**
     * Remove result display contents.
     */
    clearResultDisplay() {
        this.resultDisplay.text('');
    }

    /**
     * Remove error display contents.
     */
    clearErrorDisplay() {
        this.errorDisplay.text('');
    }

    /**
     * Remove diagnostic display contents.
     */
    clearDiagnosticDisplay() {
        this.diagnosticDisplay.text('');
    }

    /**
     * Update the main display element.
     *
     * @param {LookupResponse|LookupResponsePayload} message
     */
    updateResultDisplay(message) {
        const data = message?.payload || message || {};
        this.updateDisplay(this.resultDisplay, data);
    }

    /**
     * Update the error log element.
     *
     * @param {object} data
     */
    updateErrorDisplay(data) {
        this.updateDisplay(this.errorDisplay, data);
    }

    /**
     * Update the diagnostics display element.
     *
     * @param {object} data
     */
    updateDiagnosticDisplay(data) {
        this.updateDisplay(this.diagnosticDisplay, data, '');
    }

    /**
     * Update the contents of a display element.
     *
     * @param {jQuery} $element
     * @param {object} data
     * @param {string} gap
     */
    updateDisplay($element, data, gap = "\n") {
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
     * Initialize the state of a display element.
     *
     * @param {jQuery} $element
     */
    initializeDisplay($element) {
        if (!$element.attr('readonly')) {
            $element.attr('readonly', 'true');
        }
        $element.text('');
    }

}
