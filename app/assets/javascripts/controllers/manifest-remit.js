// app/assets/javascripts/controllers/manifest-remit.js


import { AppDebug }                            from '../application/debug'
import { appSetup }                            from '../application/setup'
import { removeFrom }                          from '../shared/arrays'
import { BaseClass }                           from '../shared/base-class'
import { selector, toggleHidden }              from '../shared/css'
import { handleClickAndKeypress, handleEvent } from '../shared/events'
import { flashError, flashMessage }            from '../shared/flash'
import { selfOrDescendents, selfOrParent }     from '../shared/html'
import { fromJSON }                            from '../shared/objects'
import { asString }                            from '../shared/strings'
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
    notDefined,
} from '../shared/definitions';
import {
    MANIFEST_ATTR,
    attribute,
    buttonFor,
    enableButton,
    initializeButtonSet,
    serverBulkSend as serverManifestSend,
} from '../shared/manifests';


const MODULE = 'ManifestRemit';
const DEBUG  = true;

AppDebug.file('controllers/manifest-remit', MODULE, DEBUG);

// noinspection SpellCheckingInspection, FunctionTooLongJS
appSetup(MODULE, function() {

    /**
     * Manifest creation page.
     *
     * @type {jQuery}
     */
    const $body = $('body.manifest:not(.select)').filter('.remit');

    // Only perform these actions on the appropriate pages.
    if (isMissing($body)) {
        return;
    }

    // ========================================================================
    // Constants
    // ========================================================================

    const SUBMISSION_TRAY_CLASS     = 'submission-buttons';
    const START_BUTTON_CLASS        = 'start-button';
    const STOP_BUTTON_CLASS         = 'stop-button';
    const PAUSE_BUTTON_CLASS        = 'pause-button';
    const RESUME_BUTTON_CLASS       = 'resume-button';

    const AUXILIARY_TRAY_CLASS      = 'auxiliary-buttons';
    const REMOTE_FILE_CLASS         = 'remote-file';
    const LOCAL_FILE_CLASS          = 'local-file';
    const FILE_BUTTON_CLASS         = 'file-button';

    const SUBMISSION_COUNTS_CLASS   = 'submission-counts'
    const TOTAL_COUNT_CLASS         = 'total';
    const READY_COUNT_CLASS         = 'ready';
    const TRANSMITTING_COUNT_CLASS  = 'transmitting';
    const FAILED_COUNT_CLASS        = 'failed';
    const SUCCEEDED_COUNT_CLASS     = 'succeeded';

    const SUBMISSION_LIST_CLASS     = 'submission-status-list';
    const SUBMISSION_CLASS          = 'submission-status';
    const CONTROLS_CLASS            = 'controls';
    //const CHECKBOX_CLASS          = 'checkbox';
    const DB_STATUS_CLASS           = 'db-status';
    const FILE_STATUS_CLASS         = 'file-status';
    const UPLOAD_STATUS_CLASS       = 'upload-status';
    const INDEX_STATUS_CLASS        = 'index-status';
    const ACTIVE_MARKER             = 'active';
    const NOT_STARTED_MARKER        = 'not-started';
    const FILE_MISSING_MARKER       = 'file-missing';
    const DATA_MISSING_MARKER       = 'data-missing';
    const BLOCKED_MARKER            = 'blocked';
    const FAILED_MARKER             = 'failed';
    const SUCCEEDED_MARKER          = 'succeeded';
    const DONE_MARKER               = 'done';

    const SUBMISSION_TRAY       = selector(SUBMISSION_TRAY_CLASS);
    const START_BUTTON          = selector(START_BUTTON_CLASS);
    const STOP_BUTTON           = selector(STOP_BUTTON_CLASS);
    const PAUSE_BUTTON          = selector(PAUSE_BUTTON_CLASS);
    const RESUME_BUTTON         = selector(RESUME_BUTTON_CLASS);

    const AUXILIARY_TRAY        = selector(AUXILIARY_TRAY_CLASS);
    const REMOTE_FILE           = selector(REMOTE_FILE_CLASS);
    const LOCAL_FILE            = selector(LOCAL_FILE_CLASS);
    const FILE_BUTTON           = selector(FILE_BUTTON_CLASS);

    const SUBMISSION_COUNTS     = selector(SUBMISSION_COUNTS_CLASS);
    const TOTAL_COUNT           = selector(TOTAL_COUNT_CLASS);
    const READY_COUNT           = selector(READY_COUNT_CLASS);
    const TRANSMITTING_COUNT    = selector(TRANSMITTING_COUNT_CLASS);
    const FAILED_COUNT          = selector(FAILED_COUNT_CLASS);
    const SUCCEEDED_COUNT       = selector(SUCCEEDED_COUNT_CLASS);

    const SUBMISSION_LIST       = selector(SUBMISSION_LIST_CLASS);
    const SUBMISSION_HEAD       = selector(SUBMISSION_CLASS, '.head');
    const SUBMISSION            = selector(SUBMISSION_CLASS) + ':not(.head)';
    const CONTROLS              = selector(CONTROLS_CLASS);
    const CHECKBOX              = 'input[type="checkbox"]';
    const DB_STATUS             = selector(DB_STATUS_CLASS);
    const FILE_STATUS           = selector(FILE_STATUS_CLASS);
    const UPLOAD_STATUS         = selector(UPLOAD_STATUS_CLASS);
    const INDEX_STATUS          = selector(INDEX_STATUS_CLASS);
    const ACTIVE                = selector(ACTIVE_MARKER);
    const NOT_STARTED           = selector(NOT_STARTED_MARKER);
    const FILE_MISSING          = selector(FILE_MISSING_MARKER);
    const DATA_MISSING          = selector(DATA_MISSING_MARKER);
    const BLOCKED               = selector(BLOCKED_MARKER);
    const FAILED                = selector(FAILED_MARKER);
    const SUCCEEDED             = selector(SUCCEEDED_MARKER);
    const DONE                  = selector(DONE_MARKER);

    // ========================================================================
    // Classes
    // ========================================================================

    /**
     * Base class for managing counter value elements.
     */
    class Counter extends BaseClass {

        static CLASS_NAME = 'BaseClass';

        /**
         * Default console debug output setting (overridden per class).
         *
         * @type {boolean}
         */
        static DEBUGGING = false;

        // ====================================================================
        // Class fields
        // ====================================================================

        /**
         * All Counter subclass instances.
         *
         * @type {Counter[]}
         * @protected
         */
        static _all = [];

        // ====================================================================
        // Fields
        // ====================================================================

        /**
         * The counter element.
         *
         * @type {jQuery}
         */
        $element;

        /**
         * The counter value element.
         *
         * @type {jQuery}
         */
        $target;

        // ====================================================================
        // Constructor
        // ====================================================================

        constructor(selector) {
            super();
            this.$element = $submit_counts.find(selector);
            this.$target  = selfOrDescendents(this.$element, '.value');
            this.constructor._all.push(this);
        }

        // ====================================================================
        // Properties
        // ====================================================================

        get value()  { return Number(this.$target.text() || 0) }
        set value(v) { this.$target.text(Number(v || 0)) }

        // ====================================================================
        // Methods
        // ====================================================================

        clear() { this.value = 0 }
        reset(v = this.constructor.current) { this.value = v }

        // ====================================================================
        // Class properties
        // ====================================================================

        static get current() { return 0 }

        // ====================================================================
        // Class methods
        // ====================================================================

        static clearAll() { this._all.forEach(instance => instance.clear()) }
        static resetAll() { this._all.forEach(instance => instance.reset()) }
    }

    /**
     * The number of manifest items in the manifest.
     */
    class TotalCounter extends Counter {
        static CLASS_NAME = 'TotalCounter';
        constructor()        { super(TOTAL_COUNT) }
        static get current() { return $submissions.length }
    }

    /**
     * The number of manifest items ready for submission.
     */
    class ReadyCounter extends Counter {
        static CLASS_NAME = 'ReadyCounter';
        constructor()        { super(READY_COUNT) }
        static get current() { return submissionsWhere(isReady).length }
    }

    /**
     * The number of manifest items currently being submitted.
     */
    class TransmitCounter extends Counter {
        static CLASS_NAME = 'TransmitCounter';
        constructor()        { super(TRANSMITTING_COUNT) }
        static get current() { return submissionsWhere(isTransmitting).length }
    }

    /**
     * The number of failed manifest item submissions.
     */
    class FailedCounter extends Counter {
        static CLASS_NAME = 'FailedCounter';
        constructor()        { super(FAILED_COUNT) }
        static get current() { return submissionsWhere(isFailed).length }
    }

    /**
     * The number of successfully submitted manifest items.
     */
    class SucceededCounter extends Counter {
        static CLASS_NAME = 'SucceededCounter';
        constructor()        { super(SUCCEEDED_COUNT) }
        static get current() { return submissionsWhere(isSucceeded).length }
    }

    // ========================================================================
    // Variables - counts
    // ========================================================================

    const $submit_counts  = $(SUBMISSION_COUNTS);

    // @see "en.emma.bulk.submit.counts"
    const counter = {
        total:        new TotalCounter(),
        ready:        new ReadyCounter(),
        transmitting: new TransmitCounter(),
        failed:       new FailedCounter(),
        succeeded:    new SucceededCounter(),
    };

    // ========================================================================
    // Variables - buttons
    // ========================================================================

    /**
     * Manifest submission controls.
     *
     * @type {jQuery}
     */
    const $submit_tray = $(SUBMISSION_TRAY);
    const $start       = $submit_tray.find(START_BUTTON);
    const $stop        = $submit_tray.find(STOP_BUTTON);
    const $pause       = $submit_tray.find(PAUSE_BUTTON);
    const $resume      = $submit_tray.find(RESUME_BUTTON);

    /**
     * Table of symbolic names for button elements.
     *
     * @type {Object.<string,jQuery>}
     */
    const SUBMISSION_BUTTONS = {
        start:  $start,
        stop:   $stop,
        pause:  $pause,
        resume: $resume,
    };

    /**
     * Table of button enabling functions.
     *
     * @type {Object.<string,function(enable?: boolean)>}
     */
    const SUBMISSION_ENABLE = Object.fromEntries(
        Object.keys(SUBMISSION_BUTTONS).map(
            name => [name, (v => enableSubmissionButton(name, v))]
        )
    );

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Initialize the Manifest submission controls.
     */
    function initializeSubmissionForm() {
        _debug('initializeSubmissionForm');
        initializeSubmissionButtons();
        initializeSubmissions();
        initializeLocalFilesResolution();
        initializeRemoteFilesResolution();
        updateSubmitReady();
        Counter.resetAll();
    }

    /**
     * A submission entry correlated with a ManifestItem.
     *
     * @param {Selector} item
     *
     * @returns {jQuery}
     */
    function submission(item) {
        return selfOrParent(item, SUBMISSION);
    }

    // ========================================================================
    // Functions - buttons
    // ========================================================================

    /**
     * initializeSubmissionButtons
     */
    function initializeSubmissionButtons() {
        const func = 'initializeSubmissionButtons'; //_debug(func);
        initializeButtonSet(SUBMISSION_BUTTONS, func);
        submissionsActive(false);
    }

    /**
     * Change submission button state.
     *
     * @param {string}           type       A {@link SUBMISSION_BUTTONS} key.
     * @param {boolean}          [enable]
     * @param {ActionProperties} [prop]     Overrides configured properties.
     *
     * @returns {jQuery|undefined}
     */
    function enableSubmissionButton(type, enable, prop) {
        const func    = 'enableSubmissionButton';
        _debug(`${func}: type = "${type}"; enable = "${enable}"`);
        const $button = buttonFor(type, SUBMISSION_BUTTONS, func);
        return enableButton($button, enable, type, prop);
    }

    /**
     * Submit Manifest items.
     *
     * @param {jQuery.Event|UIEvent} [event]
     */
    function onSubmissionStart(event) {
        const func = 'onSubmissionStart'; _debug(`${func}: event =`, event);
        const fail = 'Submission failed'; // TODO: I18n
        if (submissionsActive()) {
            _error(`${fail} - already submitting`);
        } else {
            submissionRequest('start', func, fail);
        }
    }

    /**
     * Terminate the current Manifest submission.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function onSubmissionStop(event) {
        const func = 'onSubmissionStop'; _debug(`${func}: event =`, event);
        const fail = 'Cancel failed'; // TODO: I18n
        if (!submissionsActive()) {
            _error(`${fail} - not submitting`);
        } else {
            submissionRequest('stop', func, fail);
        }
    }

    /**
     * Pause the current Manifest submission.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function onSubmissionPause(event) {
        const func = 'onSubmissionPause'; _debug(`${func}: event =`, event);
        const fail = 'Pause failed'; // TODO: I18n
        if (!submissionsActive()) {
            _error(`${fail} - not submitting`);
        } else if (submissionsPaused()) {
            _error(`${fail} - already paused`);
        } else {
            submissionRequest('pause', func, fail);
        }
    }

    /**
     * Resume the currently-paused Manifest submission.
     *
     * @param {jQuery.Event|UIEvent} event
     */
    function onSubmissionResume(event) {
        const func = 'onSubmissionResume'; _debug(`${func}: event =`, event);
        const fail = 'Resume failed'; // TODO: I18n
        if (!submissionsActive()) {
            _error(`${fail} - not submitting`);
        } else if (!submissionsPaused()) {
            _error(`${fail} - not paused`);
        } else {
            submissionRequest('resume', func, fail);
        }
    }

    /**
     * Perform a Manifest submission action on the server.
     *
     * @param {string} action
     * @param {string} [caller]
     * @param {string} [fail]
     */
    function submissionRequest(action, caller, fail) {
        const func     = caller || 'submissionRequest';
        const manifest = manifestId();
        if (!manifest) {
            _error(`${func}: no manifest ID`);
            return;
        }

        serverManifestSend(`${action}/${manifest}`, {
            caller:    func,
            onError:   onError,
            onSuccess: onSuccess,
        });

        /**
         * Process a Manifest submission action error response from the server.
         *
         * @param {object} [data]
         */
        function onError(data) {
            const tag = fail || `${action} failed`;
            const msg = data ? `${tag} - ${asString(data)}` : tag;
            flashError(msg);
        }

        /**
         * Respond to a Manifest submission action received from the server.
         *
         * @param {object} [data]
         */
        function onSuccess(data) {
            _debug(`${func}: data =`, data);
            controlSubmissions(action, data, func);
            Counter.resetAll();
        }
    }

    // ========================================================================
    // Functions - auxiliary controls
    // ========================================================================

    const $auxiliary_tray = $(AUXILIARY_TRAY);
    const $remote_file    = $auxiliary_tray.find(REMOTE_FILE);
    const $local_file     = $auxiliary_tray.find(LOCAL_FILE);
    const $file_input     = $local_file.find('input[type="file"]');

    let local_files  = [];
    let remote_files = [];
    let local_to_go  = [];
    let remote_to_go = [];

    function updateLocalFilesReady(setting) {
        const ready = isDefined(setting) ? setting : isEmpty(local_to_go);
        toggleHidden($local_file, ready);
        return ready;
    }

    function updateRemoteFilesReady(setting) {
        const ready = isDefined(setting) ? setting : isEmpty(remote_to_go);
        toggleHidden($remote_file, ready);
        return ready;
    }

    /**
     * Submit button tooltip override. # TODO: I18n
     *
     * @type {string}
     */
    const SUBMISSION_BLOCKED_TOOLTIP =
        'Files must be resolved before the submission process can begin';

    /**
     * Change whether the Submit button is enabled based on conditions.
     *
     * If not ready, a custom tooltip is provided to indicate the reason.
     */
    function updateSubmitReady() {
        const local_ready  = updateLocalFilesReady();
        const remote_ready = updateRemoteFilesReady();
        const blocked      = !local_ready || !remote_ready;
        const prop         = {};
        if (blocked) { prop.tooltip = SUBMISSION_BLOCKED_TOOLTIP }
        enableSubmissionButton('start', !blocked, prop);
        counter.ready.reset();
    }

    // ========================================================================
    // Functions - submissions
    // ========================================================================

    /**
     * controlSubmissions
     *
     * @param {string} action
     * @param {object} [data]
     * @param {string} [caller]
     *
     * @returns {void}
     */
    function controlSubmissions(action, data, caller) {
        switch (action) {
            case 'start':  return startSubmissions(data);
            case 'stop':   return stopSubmissions(data);
            case 'pause':  return pauseSubmissions(data);
            case 'resume': return resumeSubmissions(data);
        }
        const func = caller || 'controlSubmissions';
        _error(`${func}: ${action}: invalid`);
    }

    function startSubmissions(_data) {
        _debug('START SUBMISSIONS');
        if (isMissing(submissionsWhere(isChecked))) {
            submissionsWhere(isReady).each((_, item) => selectItem(item));
            updateGroupSelect();
        }
        submissionsActive(true);
    }

    function stopSubmissions(_data) {
        _debug('STOP SUBMISSIONS');
        submissionsActive(false);
    }

    function pauseSubmissions(_data) {
        _debug('PAUSE SUBMISSIONS');
        submissionsPaused(true);
    }

    function resumeSubmissions(_data) {
        _debug('RESUME SUBMISSIONS');
        submissionsPaused(false);
    }

    let started = false;
    let paused  = false;

    /**
     * submissionsActive
     *
     * @param {boolean} [now]
     *
     * @returns {boolean}
     */
    function submissionsActive(now) {
        if (isDefined(now)) {
            started = !!now;
            _debug('SUBMISSION', (started ? 'STARTED' : 'STOPPED'));
            SUBMISSION_ENABLE.start(!started);
            SUBMISSION_ENABLE.stop(started);
            SUBMISSION_ENABLE.pause(started);
            SUBMISSION_ENABLE.resume(false);
            if (!started) {
                const no_submission = $stop.attr('title');
                $pause.attr( 'title', no_submission);
                $resume.attr('title', no_submission);
            }
            paused = false;
        }
        return started;
    }

    /**
     * submissionsPaused
     *
     * @param {boolean} [now]
     *
     * @returns {boolean}
     */
    function submissionsPaused(now) {
        if (isDefined(now)) {
            paused = !!now;
            _debug('SUBMISSION', (paused ? 'PAUSED' : 'RESUMED'));
            SUBMISSION_ENABLE.pause(!paused);
            SUBMISSION_ENABLE.resume(paused);
        }
        return paused;
    }

    // ========================================================================
    // Functions - submission items
    // ========================================================================

    const SUBMIT_BLOCKED   = `${DATA_MISSING}, ${FILE_MISSING}, ${BLOCKED}`;
    const NOT_READY_VALUES = {
        [DB_STATUS]:     `${SUBMIT_BLOCKED}, ${FAILED}`,
        [FILE_STATUS]:   `${SUBMIT_BLOCKED}, ${FAILED}`,
        [UPLOAD_STATUS]: `${SUBMIT_BLOCKED}`,
        [INDEX_STATUS]:  `${SUBMIT_BLOCKED}, ${SUCCEEDED}, ${DONE}`,
    };

    const STATUS_SELECTORS = Object.keys(NOT_READY_VALUES);
    const STATUS_TYPES     = STATUS_SELECTORS.map(s => s.replace(/^\./, ''));

    const FILE_NAME_ATTR   = 'data-file-name';
    const FILE_URL_ATTR    = 'data-file-url';

    const $submission_list = $(SUBMISSION_LIST);
    const $submissions     = $submission_list.find(SUBMISSION);

    /**
     * initializeSubmissions
     */
    function initializeSubmissions() {
        _debug('initializeSubmissions');
        local_files  = [];
        remote_files = [];
        local_to_go  = [];
        remote_to_go = [];
        let changed  = false;
        $submissions.each((_, item) => {
            const $item = $(item);
            STATUS_SELECTORS.forEach(status_selector => {
                const $status = $item.find(status_selector);
                if (isPresent($status)) {
                    let name;
                    if ($status.is(FILE_MISSING)) {
                        const path = $item.attr(FILE_NAME_ATTR) || '';
                        if ((name = path.split('\\').pop().split('/').pop())) {
                            local_files.push(name);
                            local_to_go.push(name);
                        } else if ((name = $item.attr(FILE_URL_ATTR))) {
                            remote_files.push(name);
                            remote_to_go.push(name);
                        }
                    }
                    initializeStatusFor($item, status_selector, name);
                }
            });
            changed = updateItemSelect($item) || changed;
        });
        _debug(`INITIAL local_files  =`, local_files);
        _debug(`INITIAL remote_files =`, remote_files);
    }

    function submissionsMissingFile(name) {
        return submissionsWhere(isMissingFile, name);
    }

    /**
     * Return the matching submission items.
     *
     * @param {function(Selector,...) : boolean} has_property
     * @param {...}                              [args]
     *
     * @returns {jQuery}
     */
    function submissionsWhere(has_property, ...args) {
        return $submissions.filter((_, item) => has_property(item, ...args));
    }

    function isChecked(item) {
        const $item = submission(item);
        return !!checkbox($item)?.checked;
    }

    function isDisabled(item) {
        const $item = submission(item);
        return !!checkbox($item)?.disabled;
    }

    function isReady(item) {
        return !isNotReady(item);
    }

    function isNotReady(item) {
        const $item = $(item);
        return Object.entries(NOT_READY_VALUES).some(
            ([status, invalid]) => $item.find(status).is(invalid)
        );
    }

    function isBlocked(item, selectors = STATUS_SELECTORS) {
        const $item = $(item);
        return selectors.some(status => $item.find(status).is(SUBMIT_BLOCKED));
    }

    function isTransmitting(item, selectors = STATUS_SELECTORS) {
        const $item = $(item);
        return selectors.some(status => $item.find(status).is(ACTIVE));
    }

    function isFailed(item, selectors = STATUS_SELECTORS) {
        const $item = $(item);
        return selectors.some(status => $item.find(status).is(FAILED));
    }

    function isSucceeded(item, selectors = STATUS_SELECTORS) {
        const $item = $(item);
        return selectors.every(status => $item.find(status).is(SUCCEEDED));
    }

    function isMissingFile(item, name) {
        const $status = $(item).find(FILE_STATUS);
        if (!$status.is(FILE_MISSING)) { return false }
        if (!name)                     { return true }
        return $status.find('.name').text() === name;
    }

    // ========================================================================
    // Functions - submission selection
    // ========================================================================

    const $submission_head = $submission_list.find(SUBMISSION_HEAD);
    const $group_checkbox  = $submission_head.find(`${CONTROLS} ${CHECKBOX}`);
    const $item_checkboxes = $submissions.find(`${CONTROLS} ${CHECKBOX}`);

    /**
     * checkbox
     *
     * @param {Selector} item
     * @param {boolean}  [check]      Check/uncheck
     *
     * @returns {HTMLInputElement|undefined}
     */
    function checkbox(item, check) {
        const cb = selfOrDescendents(item, CHECKBOX)[0];
        if (!cb) {
            console.warn('checkbox: missing for item', item);
        } else if (isDefined(check)) {
            cb.checked = !!check;
        }
        return cb;
    }

    /**
     * selectItem
     *
     * @param {Selector} item
     * @param {boolean}  [check]      If *false*, uncheck.
     */
    function selectItem(item, check) {
        const $item   = submission(item);
        const checked = notDefined(check) || !!check;
        checkbox($item, checked);
    }

    /**
     * deselectItem
     *
     * @param {Selector} item
     * @param {boolean}  [uncheck]    If *false*, check.
     */
    function deselectItem(item, uncheck) {
        const $item     = submission(item);
        const unchecked = notDefined(uncheck) || !!uncheck;
        checkbox($item, !unchecked);
    }

    /**
     * Indicate whether an item can be selected by the user.
     *
     * @param {Selector} item
     *
     * @returns {boolean}
     */
    function isItemSelectable(item) {
        const $item = submission(item);
        const cb    = checkbox($item);
        return cb ? !cb.disabled : false;
    }

    /**
     * Allow user selection of an item.
     *
     * @param {Selector} item
     * @param {boolean}  [enable]     If *false*, disable.
     *
     * @returns {boolean}             If selectability changed.
     */
    function enableItemSelect(item, enable) {
        const $item = submission(item);
        const cb    = checkbox($item);
        if (!cb) { return false }
        const was_enabled = !cb.disabled;
        const now_enabled = notDefined(enable) || !!enable;
        cb.disabled       = !now_enabled;
        return (was_enabled !== now_enabled);
    }

    /**
     * Prevent user selection of an item.
     *
     * @param {Selector} item
     * @param {boolean}  [disable]    If *false*, enable.
     *
     * @returns {boolean}             If selectability changed.
     */
    function disableItemSelect(item, disable) {
        const disabled = notDefined(disable) || !!disable;
        return enableItemSelect(item, !disabled);
    }

    /**
     * Update the selectability of an item.
     *
     * @param {Selector} item
     *
     * @returns {boolean}             If selectability changed.
     */
    function updateItemSelect(item) {
        const $item       = submission(item);
        const was_enabled = isItemSelectable($item);
        const old_tooltip = $item.attr('title');
        if (old_tooltip) {
            const tip_data = was_enabled ? 'enabledTip' : 'disabledTip';
            if (notDefined($item.data(tip_data))) {
                $item.data(tip_data, old_tooltip);
            }
        }
        const now_enabled = isReady($item);
        const tip_data    = now_enabled ? 'enabledTip' : 'disabledTip';
        let new_tooltip   = $item.data(tip_data);
        if (notDefined(new_tooltip)) {
            if (!now_enabled) {
                new_tooltip = 'Not selectable until resolved'; // TODO: I18n
                $item.data(tip_data, new_tooltip);
                $item.attr('title', new_tooltip);
            }
        }
        $item.attr('title', (new_tooltip || ''));
        return enableItemSelect($item, now_enabled);
    }

    /**
     * Update the state of the group select checkbox.
     */
    function updateGroupSelect() {
        const func     = 'updateGroupSelect'; _debug(func);
        const group_cb = checkbox($group_checkbox);
        if (!group_cb) { return }
        const all      = $item_checkboxes.length;
        const checked  = $item_checkboxes.filter((_, cb) => cb.checked).length;
        group_cb.checked       = checked;
        group_cb.indeterminate = checked && (checked < all);
    }

    /**
     * Respond after the group checkbox has been changed.
     *
     * @param {jQuery.Event|Event} event
     */
    function onGroupCheckboxChange(event) {
        const func     = 'onGroupCheckboxChange';
        const group_cb = event.currentTarget || event.target;
        _debug(`${func}: event =`, event);
        const checked  = $item_checkboxes.filter((_, cb) => cb.checked).length;
        if (group_cb.checked && checked) {
            group_cb.indeterminate = (checked < $item_checkboxes.length);
        } else {
            const check_all = group_cb.checked;
            $item_checkboxes.toArray().forEach(cb => (cb.checked = check_all));
            group_cb.indeterminate = false;
        }
    }

    /**
     * Respond after an item checkbox has been changed.
     *
     * @param {jQuery.Event|Event} event
     */
    function onItemCheckboxChange(event) {
        _debug('onItemCheckboxChange: event =', event);
        updateGroupSelect();
    }

    // ========================================================================
    // Functions - submission status
    // ========================================================================

    const DEFAULT_LABEL = '???';
    const LABELS_ATTR   = 'data-labels';
    const STATUS_DATA   = 'status';

    /** @type {Object.<string,string>} */
    let status_value_labels;

    /** @type {Set.<string>} */
    let status_values;

    /**
     * The mapping of status class name to label.
     *
     * @returns {Object.<string,string>}
     */
    function statusValueLabels() {
        return status_value_labels ||= getStatusValueLabels();
    }

    /**
     * Extract the mapping of status class name to label.
     *
     * @returns {Object<string,string>}
     */
    function getStatusValueLabels() {
        const func = 'getStatusValueLabels'; //_debug(func);
        const src  = $submission_list.attr(LABELS_ATTR);
        let result;
        if (isMissing(src)) {
            console.warn(`${func}: ${LABELS_ATTR}: missing or empty`);
        } else {
            result = fromJSON(src, func);
        }
        // noinspection JSValidateTypes
        return result || {};
    }

    /**
     * statusValues
     *
     * @returns {Set.<string>}
     */
    function statusValues() {
        return status_values ||= new Set(Object.keys(statusValueLabels()));
    }

    /**
     * statusLabelFor
     *
     * @param {Selector} item
     * @param {string}   status       Status type class or selector.
     * @param {string}   [def_label]
     *
     * @returns {string|undefined}
     */
    function statusLabelFor(item, status, def_label = DEFAULT_LABEL) {
        const key = statusFor(item, status);
        return key && statusValueLabels()[key] || def_label;
    }

    /**
     * statusFor
     *
     * @param {Selector} item
     * @param {string}   status       Status type class or selector.
     *
     * @returns {string|undefined}    Key into {@link statusValueLabels}.
     */
    function statusFor(item, status) {
        //_debug(`statusFor "${status}" for item =` item);
        const $item = submission(item);
        const data  = $item.data(STATUS_DATA);
        const key   = status.replace(/^\./, '');
        return data && data[key] || setStatusFor($item, key);
    }

    /**
     * setStatusFor
     *
     * @param {Selector} item
     * @param {string}   status       Status type class or selector.
     * @param {string}   [new_value]
     *
     * @return {string|undefined}
     */
    function setStatusFor(item, status, new_value) {
        //_debug(`setStatusFor "${new_value}" -> "${status}" for item =` item);
        const $item = submission(item);
        const key   = status.replace(/^\./, '');
        const data  = $item.data(STATUS_DATA);
        let value   = new_value;
        value &&= setStatusValueFor($item, key, value);
        value ||= getStatusValueFor($item, key);
        $item.data(STATUS_DATA, { ...data, [key]: value });
        return value;
    }

    /**
     * getStatusValueFor
     *
     * @param {Selector} item
     * @param {string}   status       Status type class or selector.
     *
     * @return {string|undefined}
     */
    function getStatusValueFor(item, status) {
        //_debug(`getStatusValueFor "${status}" for item =` item);
        const $item   = submission(item);
        const $status = $item.find(selector(status));
        const classes = Array.from($status[0].classList).reverse();
        return classes.find(cls => statusValues().has(cls))
    }

    /**
     * setStatusValueFor
     *
     * @param {Selector} item
     * @param {string}   status       Status type class or selector.
     * @param {string}   new_value
     *
     * @return {string}
     */
    function setStatusValueFor(item, status, new_value) {
        //_debug(`setStatusValueFor "${new_value}" -> "${status}"`);
        const value   = new_value.replace(/^\./, '');
        const $item   = submission(item);
        const $status = $item.find(selector(status));
        if (!$status.hasClass(value)) {
            $status.removeClass(Array.from(statusValues()));
            $status.addClass(value);
            const label    = statusValueLabels()[value];
            const $text    = $status.find('div.text');
            const $details = $status.find('details.text');
            const details  = $status.is(`${DATA_MISSING}, ${FILE_MISSING}`);
            if (details) {
                $details.children('summary').text(label);
            } else {
                $text.text(label);
            }
            toggleHidden($text,    details);
            toggleHidden($details, !details);
        }
        return value;
    }

    /**
     * initializeStatusFor
     *
     * @param {Selector} item
     * @param {string}   status      Status type class or selector.
     * @param {string}   [name]
     */
    function initializeStatusFor(item, status, name) {
        //_debug(`initializeStatusFor "${status}" for item =` item);
        const $item   = submission(item);
        const label   = statusLabelFor($item, status);
        const $status = $item.find(selector(status));
        let $text     = $status.find('div.text');
        let $details  = $status.find('details.text');
        let $summary  = $details.children('summary');
        let $name     = $details.children('.name');

        if (isMissing($text)) {
            $text = $('<div>').addClass('text').prependTo($status);
        }
        $text.text(label);

        if (name) {
            if (isMissing($details)) {
                $details = $('<details>').addClass('text').insertAfter($text);
            }
            if (isMissing($summary)) {
                $summary = $('<summary>').prependTo($details);
            }
            if (isMissing($name)) {
                $name = $('<div>').addClass('name').appendTo($details);
            }
            $details.attr('title', `${label}: ${name}`);
            $summary.text(label);
            $name.text(name);
        }

        toggleHidden($text,    !!name);
        toggleHidden($details, !name);
    }

    // ========================================================================
    // Functions - file resolution
    // ========================================================================

    /**
     * A FileReader along with the original File object.
     */
    class FileReaderExt extends FileReader {

        /** @param {File} file */
        file;

        /** @param {File} file */
        constructor(file) { super(); this.file = file }

        /** @param {Blob} [blob] */
        readAsBinaryString(blob = this.file) { super.readAsBinaryString(blob) }

        read() { this.readAsBinaryString() }

        get stateLabel() {return this.constructor.stateLabel(this.readyState)}

        static stateLabel(state) {
            switch (state) {
                case this.DONE:    return 'DONE';
                case this.EMPTY:   return 'EMPTY';
                case this.LOADING: return 'LOADING';
                default:           return state?.toString?.() || '-';
            }
        }
    }

    /**
     * @type {Object.<string,FileReaderExt>}
     */
    let local_readers;

    /**
     * Local files selected by the user.
     *
     * @returns {Object.<string,FileReaderExt>}
     */
    function localFileReaders() {
        return local_readers ||= {};
    }

    /**
     * Local files selected by the user.
     *
     * @param {string} file_name
     *
     * @returns {FileReaderExt|undefined}
     */
    function localFileReaderFor(file_name) {
        return localFileReaders()[file_name];
    }

    /**
     * Include a local file.
     *
     * @param {File|FileReaderExt} f
     * @param {string}             [caller]     For diagnostics.
     *
     * @returns {FileReaderExt}
     */
    function addLocalFileReader(f, caller) {
        const fr   = (f instanceof FileReader) ? f : new FileReaderExt(f);
        const name = fr.file.name;
        if (localFileReaderFor(name)) {
            const func = caller || 'addLocalFileReader';
            _debug(`${func}: replacing reader for "${name}"`);
        }
        return localFileReaders()[name] = fr;
    }

    /**
     * Initialize local file readers.
     */
    function clearLocalFileReaders() {
        local_readers = undefined;
    }

    // ========================================================================
    // Functions - file resolution - local
    // ========================================================================

    /**
     * Setup handlers for $file_input.
     */
    function initializeLocalFilesResolution() {
        _debug('initializeLocalFilesResolution');
        clearLocalFileReaders();
        clearLocalFileSelection();
        handleClickAndKeypress($file_input, beforeLocalFilesSelected);
        handleEvent($file_input, 'change', afterLocalFilesSelected);
    }

    /**
     * @type {File[]|undefined}
     */
    let local_file_selection;

    /**
     * Local files selected by the user.
     *
     * @returns {File[]}
     */
    function localFileSelection() {
        return local_file_selection ||= [];
    }

    /**
     * Include a local file.
     *
     * @param {File} file
     */
    function addLocalFile(file) {
        _debug(`Queueing local file "${file.name}":`, file);
        localFileSelection().push(file);
    }

    /**
     * Clear any previous file selection.
     */
    function clearLocalFileSelection() {
        $file_input.val(null);
        local_file_selection = undefined;
    }

    /**
     * Respond before the file chooser is invoked.
     *
     * @param {jQuery.Event|Event} event
     */
    function beforeLocalFilesSelected(event) {
        _debug('*** beforeLocalFilesSelected: event =', event);
        clearLocalFileSelection();
    }

    /**
     * Respond after the file chooser returns.
     *
     * @param {jQuery.Event|Event} event
     */
    function afterLocalFilesSelected(event) {
        const func  = 'afterLocalFilesSelected';
        const files = event.currentTarget?.files || event.target?.files;
        //_debug(`*** ${func}: event =`, event);
        if (!files) {
            console.warn(`${func}: no event target`);
        } else if (isEmpty(files)) {
            console.warn(`${func}: no files selected`);
        } else {
            _debug(`${func}: ${files.length} files`);
            queueLocalFiles(files);
            preProcessLocalFiles();
        }
    }

    /**
     * Replace the current list of selected files.
     *
     * @param {File[]|FileList} files
     */
    function queueLocalFiles(files) {
        _debug(`queueLocalFiles: ${files.length} files =`, files);
        const count = files?.length || 0;
        for (let i = 0; i < count; i++) {
            const file = files[i];
            const name = file?.name;
            if (!name) {
                _debug(`IGNORING nameless file[${i}]:`, file);
            } else if (!local_files.includes(name)) {
                _debug(`IGNORING unrequested file "${name}":`, file);
            } else if (!local_to_go.includes(name)) {
                _debug(`IGNORING already handled file "${name}":`, file);
            } else {
                addLocalFile(file);
            }
        }
    }

    /**
     * Update submission statuses and report the result of pre-processing local
     * files.
     *
     * @param {File[]} [files]
     */
    function preProcessLocalFiles(files = localFileSelection()) {
        const func = 'preProcessLocalFiles';
        _debug(`${func}: ${files.length} files =`, files);
        const lines = [];
        const names = [];
        const good  = [];
        const bad   = []; // TODO: are there "badness" criteria at this stage?
        files.forEach(file => {
            const fr   = new FileReaderExt(file);
            const name = fr.file.name;
            const size = fr.file.size;
            const item = `${name} : ${size} bytes`;
            if (!removeFrom(local_to_go, name)) {
                _debug(`${func}: ${item} -- ALREADY PROCESSED`);
            } else {
                _debug(`${func}: ${item}`);
            }
            addLocalFileReader(fr, func);
            names.push(name);
            good.push(item);
        });
        const resolved    = good.length;
        const problematic = bad.length;
        const remaining   = local_to_go.length;

        if (resolved) {
            let sel_changed = false;
            const fulfilled = new Set(names);
            $submissions.each((_, item) => {
                const $item   = $(item);
                const $status = $item.find(FILE_STATUS);
                const missing = $status.is(FILE_MISSING);
                const name    = missing && $status.find('.name').text();
                if (name && fulfilled.has(name)) {
                    setStatusFor($item, FILE_STATUS, SUCCEEDED);
                    sel_changed = updateItemSelect($item) || sel_changed;
                }
            });
            if (sel_changed) {
                updateGroupSelect();
            }
            lines.push(resolvedLabel(resolved), ...good, '');
        }

        if (problematic) {
            lines.push(problematicLabel(problematic), ...bad, '');
        }

        if (remaining) {
            lines.push(remainingLabel(remaining), ...local_to_go);
        } else {
            updateSubmitReady();
            lines.push(allResolvedLabel());
        }

        flashMessage(lines.join("\n"));
    }

    /**
     * resolvedLabel # TODO: I18n
     *
     * @param {number} [count]
     *
     * @returns {string}
     */
    function resolvedLabel(count) {
        const files = (count === 1) ? 'FILE' : 'FILES';
        return `RESOLVED ${files}:`;
    }

    /**
     * problematicLabel # TODO: I18n
     *
     * @param {number} [count]
     *
     * @returns {string}
     */
    function problematicLabel(count) {
        const files = (count === 1) ? 'FILE' : 'FILES';
        return `PROBLEM ${files}:`;
    }

    /**
     * remainingLabel # TODO: I18n
     *
     * @param {number} [count]
     *
     * @returns {string}
     */
    function remainingLabel(count) {
        const num   = Number(count || 0);
        const files = (num === 1) ? 'FILE' : 'FILES';
        return `${num} ${files} STILL NEEDED:`;
    }

    /**
     * allResolvedLabel # TODO: I18n
     *
     * @returns {string}
     */
    function allResolvedLabel() {
        return 'ALL FILES RESOLVED - READY FOR SUBMISSION';
    }

    // ========================================================================
    // Functions - file resolution - local
    // ========================================================================

    /**
     * Make use of the file readers stored in {@link preProcessLocalFiles}.
     *
     * @param {jQuery.Event|UIEvent} [event]
     */
    function processLocalFiles(event) {
        const func     = 'processLocalFiles';
        _debug(`${func}: event =`, event);
        _debug(`${func}: local_readers =`, local_readers);
        const readers  = local_readers && Object.values(local_readers);
        /** @type {Promise<FileReaderExt>[]} */
        const promises = readers?.map(reader => asyncLocalFileRead(reader));
        if (!promises) {
            console.warn(`${func}: No files have ever been selected`);
        } else if (isEmpty(promises)) {
            console.warn(`${func}: No files to read`);
        } else {
            Promise.all(promises).then(processFulfilled);
        }
    }

    /**
     * Generate a new Promise for accessing a file.
     *
     * @param {File|FileReaderExt} f
     *
     * @returns {Promise<FileReaderExt>}
     */
    function asyncLocalFileRead(f) {
        // NOTE: maybe this should have a callback that is run when the file
        //  has been read -- this callback could perform the next step of
        //  uploaded the FileReader content, then progressing with the
        //  submission of that ManifestItem.
        _debug('asyncLocalFileRead', f);
        return new Promise((resolve, reject) => {
            /** @param {ProgressEvent} ev */
            const fr_log = (ev) => {
                const state = ev.target?.stateLabel || '???';
                console.log(`*** FR ${ev.type} | ${state} | ev =`, ev);
                return true;
            };
            const fr = (f instanceof FileReader) ? f : new FileReaderExt(f);
            fr.onabort     = ev => fr_log(ev);
            fr.onerror     = ev => fr_log(ev) && reject(fr);
            fr.onload      = ev => fr_log(ev) && resolve(fr);
            fr.onloadend   = ev => fr_log(ev);
            fr.onloadstart = ev => fr_log(ev);
            fr.onprogress  = ev => fr_log(ev);
            fr.read();
        });
    }

    /**
     * Called after the content from all FileReaders has been acquired.
     *
     * @param {FileReaderExt[]} readers
     */
    function processFulfilled(readers) {
        const func = 'processFulfilled';
        _debug(`${func}: readers =`, readers);
        // NOTE: This gets run after all selected files have been read.
        //  Maybe this is the place to batch up FileReader content for upload
        //  and then progressing with batch submission of related ManifestItems
    }

    // ========================================================================
    // Functions - file resolution - remote
    // ========================================================================

    /**
     * @type {File[]|undefined}
     */
    let remote_file_selection;

    /**
     * Setup for acquiring files from cloud-based storage.
     */
    function initializeRemoteFilesResolution() {
        const func = 'initializeRemoteFilesResolution'; _debug(func);
        clearSelectedRemoteFiles();
        // TODO: cloud-based storage
        _debug(`${func}: remote_selected =`, remote_file_selection);
        _debug(`${func}: remote_to_go    =`, remote_to_go);
    }

    /**
     * Clear any previous file selection.
     */
    function clearSelectedRemoteFiles() {
        remote_file_selection = undefined;
    }

    // ========================================================================
    // Functions - database - Manifest
    // ========================================================================

    let manifest_id;

    /**
     * The Manifest ID associated with these manifest rows.
     *
     * @note Currently this is *only* associated with the $grid element.
     *
     * @returns {string|undefined}
     */
    function manifestId() {
        return manifest_id ||= manifestFor();
    }

    /**
     * The Manifest ID associated with the target.
     *
     * @param {Selector} [target]     Default: {@link $start}.
     *
     * @returns {string|undefined}
     */
    function manifestFor(target) {
        const func = 'manifestFor'; //_debug(`${func}: target =`, target);
        let id;
        if (target) {
            (id = attribute(target, MANIFEST_ATTR)) ||
            console.error(`${func}: no ${MANIFEST_ATTR} for`, target);
        } else {
            (id = attribute($start, MANIFEST_ATTR)) ||
            _debug(`${func}: no manifest ID`);
        }
        return id || manifest_id;
    }

    // ========================================================================
    // Functions - diagnostics
    // ========================================================================

    /**
     * Indicate whether console debugging is active.
     *
     * @returns {boolean}
     */
    function _debugging() {
        return AppDebug.activeFor(MODULE, DEBUG);
    }

    /**
     * Emit a console message if debugging.
     *
     * @param {...*} args
     */
    function _debug(...args) {
        _debugging() && console.log(`${MODULE}:`, ...args);
    }

    /**
     * Emit a console error and display as a flash error if debugging.
     *
     * @param {string} caller
     * @param {string} [message]
     */
    function _error(caller, message) {
        const tag = `${MODULE}: ${caller}`
        const msg = isDefined(message) ? `${tag}: ${message}` : tag;
        console.error(msg);
        _debugging() && flashError(msg);
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleClickAndKeypress($start,  onSubmissionStart);
    handleClickAndKeypress($stop,   onSubmissionStop);
    handleClickAndKeypress($pause,  onSubmissionPause);
    handleClickAndKeypress($resume, onSubmissionResume);

    handleEvent($group_checkbox,  'change', onGroupCheckboxChange);
    handleEvent($item_checkboxes, 'change', onItemCheckboxChange);

    // ========================================================================
    // Actions
    // ========================================================================

    initializeSubmissionForm();

});
