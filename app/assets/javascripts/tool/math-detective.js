// app/assets/javascripts/tool/math-detective.js
//
// Math Detective API
//
// @see https://api.dev.mathdetective.ai/v1   API
// @see https://api-docs.dev.mathdetective.ai Documentation


import { AppDebug }                       from '../application/debug';
import { Api }                            from '../shared/api'
import { selector, toggleHidden }         from '../shared/css';
import { isDefined, isMissing, isPresent} from '../shared/definitions';
import { HTTP }                           from '../shared/http';
import { encodeImageOrUrl }               from '../shared/image';
import { SECONDS }                        from '../shared/time';
import {
    handleClickAndKeypress,
    handleEvent,
    handleHoverAndFocus,
    isEvent,
} from '../shared/events';


const MODULE = 'MathDetectiveApi';
const DEBUG  = false;

AppDebug.file('tool/math-detective', MODULE, DEBUG);

// ============================================================================
// Constants
// ============================================================================

/**
 * Indicate whether the Math Detective API request should be proxied
 * through EMMA in order to avoid CORS.
 *
 * @type {boolean}
 */
const PROXY = true;

const API_KEY           = 'TBD';
const BASE_URL          = 'https://api.dev.mathdetective.ai/v1';
const IMAGE_PATH        = 'image-processing/images';
//const BATCH_PATH      = 'image-processing/batches';
//const TEXT_PATH       = 'text-processing/texts';
//const STRINGS_PATH    = 'text-processing/strings';

const MD_API_KEY        = PROXY ? '' : API_KEY;
const MD_BASE_URL       = PROXY ? '' : BASE_URL;
const MD_IMAGE_PATH     = endpoint(IMAGE_PATH, PROXY);
//const MD_BATCH_PATH   = endpoint(BATCH_PATH, PROXY);
//const MD_TEXT_PATH    = endpoint(TEXT_PATH, PROXY);
//const MD_STRINGS_PATH = endpoint(STRINGS_PATH, PROXY);

const DEF_RECHECK_TIME  = 5 * SECONDS;
const DEF_RECHECK_MAX   = 5; // attempts
const MAX_SIZE          = undefined; // 5 * MB;

// ============================================================================
// Internal functions
// ============================================================================

/**
 * Convert an API endpoint into a path proxied via the server if PROXY is true.
 *
 * @param {string}  path
 * @param {boolean} [proxy]
 *
 * @returns {string}
 */
function endpoint(path, proxy) {
    return proxy ? `tool/md_proxy?path=${path}` : path;
}

// ============================================================================
// Functions
// ============================================================================

/**
 * Setup a page with Math Detective.
 *
 * @param {Selector} [root]
 */
export function setupFor(root) {

    const COPY_NOTE_CLASS    = 'copy-note';
    const COPY_NOTE_SELECTOR = selector(COPY_NOTE_CLASS);

    const COPY_TIP  = 'Copy this output to clipboard'; // TODO: I18n

    // ========================================================================
    // Variables
    // ========================================================================

    /** @type {ClipboardItem|undefined} */
    let clip_item;
    let $clip_input, $clip_note, clip_type, $file_input;

    const $root        = root ? $(root) : $('body');
    const $clip_prompt = $root.find('.clipboard-prompt');
    const $file_prompt = $root.find('.file-prompt');
    const $containers  = $root.find('.container');
    const $status      = $containers.filter('.status-container');
    const $preview     = $containers.filter('.preview-container');
    const $error       = $containers.filter('.error-container');
    const $mathml      = $containers.filter('.mathml-container');
    const $latex       = $containers.filter('.latex-container');
    const $spoken      = $containers.filter('.spoken-container');
    const $results     = $containers.filter('.api-container');
    const $copy_icons  = $containers.find('.clipboard-icon');

    // ========================================================================
    // Actions
    // ========================================================================

    if (isPresent($clip_prompt)) {
        $clip_input = $clip_prompt.find('.clipboard-input');
        $clip_note  = $clip_prompt.find('.clipboard-note');
        setupClipboardInput();
    }

    if (isPresent($file_prompt)) {
        $file_input = $file_prompt.find('.file-input');
        handleEvent($file_input, 'change', onNewFile);
    }

    $copy_icons.each(function() {
        setupClipboardIcon(this);
    });

    // ========================================================================
    // Internal functions - processing from clipboard
    // ========================================================================

    /**
     * Prepare the clipboard input button if the current environment allows
     * reading image data from the clipboard, or hiding it if not.
     */
    function setupClipboardInput() {
        const func = 'setupClipboardInput';
        // noinspection JSValidateTypes
        /** @type {PermissionDescriptor} */
        const permission = { name: 'clipboard-read' };
        navigator.permissions.query(permission).then(result => {
            let click = true, hover = true, note;
            switch (result.state) {
                case 'granted':
                    break;
                case 'prompt':
                    check(); // Force the permissions prompt to appear.
                    break;
                default:
                    hover = false;
                    note  = 'Change settings to allow clipboard access';
                    break;
            }
            click && handleClickAndKeypress($clip_input, processClipboard);
            hover && handleHoverAndFocus($clip_input, check, forget);
            showClipboardNote(note, func);
        }).catch(reason => {
            let message = (reason instanceof Error) ? reason.message : reason;
            if (message?.includes('PermissionName')) {
                console.log(`${func}: not available for this browser`);
            } else {
                console.warn(`${func}:`, (message || 'unknown error'));
            }
            toggleHidden($clip_prompt, true);
        });

        function check() {
            document.hasFocus() && checkClipboard(func);
            return true;
        }

        function forget() {
            clip_item = clip_type = undefined;
            resetClipboardNote();
            return true;
        }
    }

    /**
     * Look for an image on the clipboard.  When found, update clip_item and
     * clip_type, and execute the callback if provided.
     *
     * @param {string}                           [caller]
     * @param {function(ClipboardItem?,string?)} [callback]
     */
    function checkClipboard(caller, callback) {
        const func = caller || 'checkClipboard';
        clip_item = clip_type = undefined;
        navigator.clipboard.read().then(items => {
            items.forEach(item => {
                clip_item = item;
                if (!clip_type) {
                    const types = item.types;
                    clip_type = types.filter(t => t.startsWith('image'))[0];
                    if (clip_type) {
                        callback?.(clip_item, clip_type);
                    }
                }
            });
            let data;
            if (clip_type && callback) {
                // Processing has started.
            } if (clip_type) {
                data = 'Image';
            } else if (clip_item) {
                data = 'No image';
            } else {
                data = 'Nothing';
            }
            data && showClipboardNote(`${data} saved in the clipboard`, func);
        }).catch(reason => {
            let message = (reason instanceof Error) ? reason.message : reason;
            if (message?.includes('permission')) {
                setupClipboardInput();
            } else {
                message ||= 'unknown error';
                console.warn(`${func}:`, message);
                showClipboardNote(message, func);
            }
        });
    }

    /**
     * Process file data from the clipboard through the Math Detective API and
     * render the results.
     *
     * @param {jQuery.Event|Event} event
     */
    function processClipboard(event) {
        const func = 'processClipboard';
        processClipboardItem() || checkClipboard(func, processClipboardItem);
    }

    /**
     * Process image data from the clipboard.
     *
     * @param {ClipboardItem} [item]
     * @param {string}        [type]
     *
     * @returns {Promise|undefined}
     */
    function processClipboardItem(item, type) {
        const i = item || clip_item || undefined;
        const t = type || clip_type || undefined;
        return i && t && i.getType(t).then(blob => processFile(blob));
    }

    /**
     * Display a note next to the clipboard select button.
     *
     * @param {string} note
     * @param {string} [_caller]
     */
    function showClipboardNote(note, _caller) {
        if ($clip_note) {
            if (note) {
                $clip_note.text(note);
                toggleHidden($clip_note, false);
            } else {
                resetClipboardNote();
            }
        }
    }

    /**
     * Hide the note next to the clipboard select button.
     */
    function resetClipboardNote() {
        if ($clip_note) {
            $clip_note.text('');
            toggleHidden($clip_note, true);
        }
    }

    // ========================================================================
    // Internal functions - processing from file
    // ========================================================================

    /**
     * Process an image file when it is selected.
     *
     * @param {jQuery.Event|Event} event
     */
    function onNewFile(event) {
        const func = 'onNewFile';
        let input, file;
        if (!(input = $file_input[0])) {
            console.error(`${func}: no $file_input element`);
        } else if (!(file = input.files[0])) {
            console.log(`${func}: no file selected`);
        } else {
            processFile(file);
        }
    }

    /**
     * Read an image file and process it.
     *
     * @param {File|Blob} file
     */
    function processFile(file) {
        clearDisplay();
        const file_name = (file instanceof File) ? file.name : '(clipboard)';
        const reader    = new FileReader();
        reader.readAsDataURL(file);
        reader.onloadend = (event) => process(file_name, event.target.result);
    }

    // ========================================================================
    // Internal functions - processing
    // ========================================================================

    /**
     * Process file data through the Math Detective API and render the results.
     *
     * @param {string} file_name
     * @param {string} file_data
     */
    function process(file_name, file_data) {
        showPreview(file_data);
        showStatus('STARTING');
        const options = { on_fetch: onComplete, on_status: showStatus };
        new MathDetectiveApi(options).submitImage(file_name, file_data);
    }

    /**
     * Invoked when results have been retrieved from the Math Detective API.
     *
     * @param {MathDetectiveApi} md
     */
    function onComplete(md) {
        const response = md.formattedResults || md.xhr?.response;
        const error    = md.error || md.noResults;

        error     && showError(md.error, md.noResults);
        md.mathml && showContainer($mathml, md.mathml);
        md.latex  && showContainer($latex,  md.latex);
        md.spoken && showContainer($spoken, md.spoken);
        response  && showApiResults(response);
    }

    // ========================================================================
    // Internal functions - display
    // ========================================================================

    /**
     * Update the display of the Math Detective request status.
     *
     * @param {string} value
     */
    function showStatus(value) {
        const text = value?.trim()?.toUpperCase();
        showContainer($status, text, '.status');
    }

    /**
     * Show the preview of the selected file.
     *
     * @param {string} [file_data]      New image data.
     */
    function showPreview(file_data) {
        file_data && $preview.find('.file-preview').attr('src', file_data);
        showContainer($preview);
    }

    /**
     * Display the error output container.
     *
     * @param {string}  message?
     * @param {boolean} no_equations?
     */
    function showError(message, no_equations) {
        const $message      = $error.find('.error-message');
        const $no_equations = $error.find('.no-equations');
        toggleHidden($message,      true);
        toggleHidden($no_equations, true);
        if (message) {
            $message.text(message);
            toggleHidden($message,      false);
        } else if (no_equations) {
            toggleHidden($no_equations, false);
        }
        showContainer($error);
    }

    /**
     * Display the API results container.
     *
     * @param {string} [response]
     */
    function showApiResults(response) {
        const body = response || {};
        const json = JSON.stringify(body, null, 2);
        showContainer($results, json);
    }

    /**
     * Display an output container.
     *
     * @param {Selector} container
     * @param {string}   [output]
     * @param {string}   [selector]
     */
    function showContainer(container, output, selector = '.output') {
        const $container = toggleHidden(container, false);
        if (output) {
            const $output = $container.find(selector);
            $output.text(output);
            $output.removeAttr('style'); // Undo manual resizing.
            $output.scrollTop(0);        // Forget previous scroll position.
        }
    }

    /**
     * Hide output container(s)
     *
     * @param {Selector} [container]    If missing, all containers are hidden.
     */
    function hideContainers(container) {
        const $target = container ? $(container) : $containers;
        toggleHidden($target, true);
    }

    /**
     * Hide elements that may have been displayed for a previous run.
     */
    function clearDisplay() {
        hideContainers();
        resetCopyNotes();
        resetClipboardNote();
    }

    // ========================================================================
    // Internal functions - copy to clipboard
    // ========================================================================

    /**
     * Setup a clipboard icon to act as a button.
     *
     * @param {Selector} icon
     */
    function setupClipboardIcon(icon) {
        const $icon = $(icon);
        isDefined($icon.attr('title'))    || $icon.attr('title',    COPY_TIP);
        isDefined($icon.attr('role'))     || $icon.attr('role',     'button');
        isDefined($icon.attr('tabindex')) || $icon.attr('tabindex', 0);
        addCopyNote($icon);
        handleClickAndKeypress($icon, copyOutput);
    }

    /**
     * Create an annotation element near the icon if it is not already there.
     *
     * @param {Selector} icon
     *
     * @returns {jQuery}
     */
    function addCopyNote(icon) {
        const $icon = $(icon);
        let $note   = $icon.siblings(COPY_NOTE_SELECTOR);
        if (isMissing($note)) {
            $note = $('<span>').addClass(COPY_NOTE_CLASS);
            toggleHidden($note, true);
            $note.insertBefore($icon);
        }
        return $note;
    }

    /**
     * Copy text from the output area associated with the given button.
     *
     * @param {SelectorOrEvent} tgt
     *
     * @returns {boolean}
     */
    function copyOutput(tgt) {
        resetCopyNotes();
        let $btn   = $(isEvent(tgt) ? (tgt.currentTarget || tgt.target) : tgt);
        let $note  = $btn.siblings(COPY_NOTE_SELECTOR);
        const text = $btn.parents('.container').first().find('.output').text();
        navigator.clipboard.writeText(text).then(
            () => toggleHidden($note.text('(copied)'), false),
            () => toggleHidden($note.text('(failed)'), false),
        );
        return true;
    }

    /**
     * Hide any dynamically created "(copied)" notes that may have been
     * inserted after .clipboard-icon elements.
     */
    function resetCopyNotes() {
        const $notes = $copy_icons.siblings(COPY_NOTE_SELECTOR);
        toggleHidden($notes, true).text('');
    }
}

// ============================================================================
// Class
// ============================================================================

export class MathDetectiveApi extends Api {

    static CLASS_NAME = 'MathDetectiveApi';
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Type definitions
    // ========================================================================

    /**
     * @typedef {object} MD_ImageProcessingRequest
     *
     * @property {string}  [name]
     * @property {string}  url
     * @property {boolean} [skip_ocr]
     * @property {boolean} [force_reprocess]
     */

    /**
     * @typedef {object} MD_Label
     *
     * @property {string}  name
     * @property {number}  confidence
     */

    /**
     * @typedef {object} MD_ImageProcessingResponse
     *
     * @property {string}      name
     * @property {string}      sha256_sum
     * @property {MD_Label[]}  labels
     * @property {number}      ocr_confidence
     * @property {string}      mathml
     * @property {string}      latex
     * @property {string}      error
     * @property {string}      status
     * @property {string}      spokentext
     */

    /**
     * @typedef {object} MD_HttpCallback - NOT USED
     *
     * @property {string}      url
     * @property {StringTable} headers
     */

    /**
     * @typedef {object} MD_BatchSubmissionRequest - NOT USED
     *
     * @property {MD_ImageProcessingRequest[]}  images
     * @property {MD_HttpCallback}              [callback]
     * @property {boolean}                      [smoke_test_flag]
     * @property {boolean}                      [skip_ocr]
     * @property {boolean}                      [force_reprocess]
     */

    /**
     * @typedef {object} MD_BatchSubmissionResponse - NOT USED
     *
     * @property {string}                       batch_uuid
     * @property {string}                       status
     * @property {MD_ImageProcessingResponse[]} output
     */

    /**
     * @typedef {object} MD_TextProcessingRequest - NOT USED
     *
     * @property {string}   url
     * @property {string}   [wrap_tag]
     */

    /**
     * @typedef {object} MD_TextProcessingResponse - NOT USED
     *
     * @property {string}   text_sha256sum
     */

    /**
     * @typedef {object} MD_StringEquationResponseItem - NOT USED
     *
     * @property {string}   element
     * @property {number[]} bounds
     * @property {number}   conf_score
     * @property {string}   mathml
     * @property {string}   spokentext
     * @property {string}   tag_id
     */

    /**
     * @typedef {object} MD_TextStatusResponseItem - NOT USED
     *
     * @property {string}                           original_string
     * @property {MD_StringEquationResponseItem[]}  equations
     * @property {string}                           sha256_sum
     */

    /**
     * @typedef {object} MD_TextStatusResponse - NOT USED
     *
     * @property {string}                           status
     * @property {MD_TextStatusResponseItem[]}      output
     */

    /**
     * @typedef {object} MD_StringProcessingRequest - NOT USED
     *
     * @property {string} math_string
     */

    /**
     * @typedef {object} MD_StringProcessingResponse - NOT USED
     *
     * @property {string}                           status
     * @property {string}                           original_string
     * @property {MD_StringEquationResponseItem[]}  equations
     * @property {string}                           sha256_sum
     */

    /** @typedef {function(MathDetectiveApi)} MathDetectiveApiCallback */

    /**
     * @typedef {object} MathDetectiveOptions
     *
     * @property {MathDetectiveApiCallback} [on_fetch]
     * @property {function(string)}         [on_status]
     * @property {number}                   [recheck]
     * @property {number}                   [max_cycles]
     */

    // ========================================================================
    // Fields
    // ========================================================================

    /** @type {MD_ImageProcessingResponse} */ result = {};
    /** @type {string} */ md_status;

    // ========================================================================
    // Fields - internal
    // ========================================================================

    /** @type {MathDetectiveApiCallback|undefined} */ _on_fetch;
    /** @type {function(string)|undefined}         */ _on_status;

    /** @type {number} */ _cycle = 0;
    /** @type {number} */ _max_cycle;
    /** @type {number} */ _recheck;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {MathDetectiveOptions|Api_Options} [opt]
     */
    constructor(opt) {
        /** @type {MathDetectiveOptions|Api_Options} */
        const options = { api_key: MD_API_KEY, ...opt };
        super(MD_BASE_URL, options);
        this._on_fetch  = options.on_fetch;
        this._on_status = options.on_status;
        this._max_cycle = options.max_cycles || DEF_RECHECK_MAX;
        this._recheck   = options.recheck    || DEF_RECHECK_TIME;
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get started()   { return isPresent(this.md_status) }
    get running()   { return (this.md_status === 'running') }
    get completed() { return this.started && !this.running }

    get handle()    { return this.result.sha256_sum }
    get mathml()    { return this.result.mathml }
    get latex()     { return this.result.latex }
    get spoken()    { return this.result.spokentext }
    get noResults() { return !(this.mathml || this.latex || this.spoken) }

    /**
     * If results are present, re-arrange output fields for display.
     *
     * @returns {MD_ImageProcessingResponse|undefined}
     */
    get formattedResults() {
        let output;
        if (isPresent(this.result)) {
            output = {
                name:   '', status: '', ocr_confidence: '' , labels: '',
                mathml: '', latex:  '', spokentext: ''
            };
            $.extend(output, this.result);
        }
        return output;
    }

    // ========================================================================
    // Properties - internal
    // ========================================================================

    /**
     * Error message.
     *
     * @returns {string|undefined}
     * @protected
     */
    get _errorMessage() {
        const response = this.response;
        return response['Message'] || response['message'];
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Post an image file to the Math Detective API.
     *
     * If it's sufficiently small, the result will be returned directly
     * (with HTTP 200).  Otherwise, HTTP 201 will indicate that the result
     * must be fetched later.
     *
     * @param {string}                   name
     * @param {string}                   [image]
     * @param {MathDetectiveApiCallback} [cb]
     */
    submitImage(name, image, cb = this._on_fetch) {
        let data;
        // ... encoded using base64. In the worst case this encoding can cause
        // the binary body to be inflated up to 4/3 its original size.
        if (MAX_SIZE && ((3 * image.length) > (4 * MAX_SIZE))) {
            this.error = 'API only accepts images <= 5 megabytes';
        } else if (isMissing((data = encodeImageOrUrl(image)))) {
            this.error = 'No image data supplied';
        }
        if (this.error) {
            this._showStatus('FAILED');
            cb?.(this);
        } else {
            this._showStatus('SUBMITTING');
            /** @type {MD_ImageProcessingRequest} */
            const params   = { name: name, url: data };
            const callback = (...a) => this._submitImageOnComplete(...a, cb);
            this.post(MD_IMAGE_PATH, params, callback);
        }
    }

    /**
     * Get the status of a previous image request.
     *
     * @param {MathDetectiveApiCallback} [cb]
     */
    fetchImage(cb = this._on_fetch) {
        if (isMissing(this.handle)) {
            this._showStatus('FAILED');
            this.error = 'Missing request identifier to check';
            cb?.(this);
        } else {
            this._showStatus('FETCHING');
            const callback = (...a) => this._fetchImageOnComplete(...a, cb);
            this.get(`${MD_IMAGE_PATH}/${this.handle}`, undefined, callback);
        }
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * _submitImageOnComplete
     *
     * @param {MD_ImageProcessingResponse|undefined} result
     * @param {string|undefined}                     _warn
     * @param {string|undefined}                     _err
     * @param {XMLHttpRequest}                       xhr
     * @param {MathDetectiveApiCallback}             [cb]
     *
     * @protected
     */
    _submitImageOnComplete(result, _warn, _err, xhr, cb = this._on_fetch) {
        // noinspection JSValidateTypes
        this.result = result || {};
        this._updateStatus(xhr.status, 'submitImage');
        this._showStatus();
        if (this.running) {
            this._fetchLoop(cb);
        } else {
            cb?.(this);
        }
    }

    /**
     * _fetchLoop
     *
     * @param {MathDetectiveApiCallback} [cb]
     *
     * @protected
     */
    _fetchLoop(cb = this._on_fetch) {
        if (this.running) {
            if (this.#nextCycle()) {
                this.fetchImage(cb);
                const next_cycle = () => this._fetchLoop(cb);
                this._retryTimer = setTimeout(next_cycle, this._recheck);
            } else {
                this.#clearRetryTimer();
                this._showStatus('TIMEOUT');
                cb?.(this);
            }
        }
    }

    /**
     * _fetchImageOnComplete
     *
     * @param {MD_ImageProcessingResponse|undefined} result
     * @param {string|undefined}                     _warn
     * @param {string|undefined}                     _err
     * @param {XMLHttpRequest}                       xhr
     * @param {MathDetectiveApiCallback}             [cb]
     *
     * @protected
     */
    _fetchImageOnComplete(result, _warn, _err, xhr, cb = this._on_fetch) {
        // noinspection JSValidateTypes
        this.result = result || {};
        this._updateStatus(xhr.status, 'submitImage');
        this._showStatus();
        if (!this.running) {
            cb?.(this);
        }
    }

    /**
     * _updateStatus
     *
     * @param {number} xhr_status
     * @param {string} [caller]
     *
     * @protected
     */
    _updateStatus(xhr_status, caller) {
        const func = caller || '_updateStatus';
        let warn, err;
        /*
         * NOTE: [1] Image has completed processing
         *  Only _fetchImage but also seen with _submitImage (undocumented).
         *
         * NOTE: [2] Image processing started
         *  Only _submitImage (but never actually seen).
         *
         * NOTE: [3] Image is still being processed
         *  Only _fetchImage.
         *
         * NOTE: [4] Seen for _submitImage but undocumented.
         */
        switch (xhr_status) {
            case HTTP.ok:                   // NOTE: [1]
            case HTTP.created:              // NOTE: [2]
            case HTTP.accepted:             // NOTE: [3]
                this.md_status    = this.result.status;
                warn = this.error = this.result.error;
                break;

            case HTTP.bad_request:          // NOTE: [4]
            case HTTP.forbidden:
                this.md_status    = this.result.error  || 'ERROR';
                warn = this.error = this._errorMessage || 'unknown error';
                break;

            case HTTP.not_found:            // NOTE: only for _fetchImage
                this.md_status    = this.result.error  || 'ERROR';
                warn = this.error = this._errorMessage ||
                    `could not find item ${this.handle}`;
                break;

            case HTTP.payload_too_large:    // NOTE: only for _submitImage
            case HTTP.bad_gateway:          // NOTE: only for _submitImage
                this.md_status    = this.result.error  || 'ERROR';
                warn = this.error = 'API limited to images <= 5 MB';
                break;

            default:
                this.md_status    = this.result.error  || 'FATAL';
                err = this.error  = this._errorMessage ||
                    `unexpected HTTP ${xhr_status}`;
                break;
        }
        warn && console.log(`${func}: WARNING: ${warn}`);
        err  && console.error(`${func}: ERROR: ${err}`);
    }

    /**
     * _showStatus
     *
     * @param {string}                     [value]
     * @param {function(string)|undefined} [cb]
     *
     * @protected
     */
    _showStatus(value, cb = this._on_status) {
        if (value) {
            this.md_status = value;
        }
        cb?.(this.md_status || 'INITIALIZING');
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * #nextCycle
     *
     * @returns {boolean}
     * @protected
     */
    #nextCycle() {
        const cycle      = ++(this._cycle);
        const continuing = (cycle <= this._max_cycle);
        if (!continuing) {
            this._cycle = 0;
        }
        return continuing;
    }

    /**
     * #clearRetryTimer
     *
     * @protected
     */
    #clearRetryTimer() {
        this._retryTimer && clearTimeout(this._retryTimer);
        this._retryTimer = undefined;
    }

}
