// app/assets/javascripts/tool/math-detective.js
//
// Math Detective API
//
// @see https://api.dev.mathdetective.ai/v1   API
// @see https://api-docs.dev.mathdetective.ai Documentation


import { Api }                                 from '../shared/api'
import { selector }                            from '../shared/css'
import { isDefined, isMissing, isPresent}      from '../shared/definitions'
import { HTTP }                                from '../shared/http'
import { encodeImageOrUrl }                    from '../shared/image'
//import { MB }                                from '../shared/math'
import { SECOND, SECONDS }                     from '../shared/time'
import {
    handleClickAndKeypress,
    handleEvent,
    handleHoverAndFocus,
    isEvent
} from '../shared/events'


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
export function setup(root) {

    const HIDDEN_MARKER      = 'hidden';
    const COPY_NOTE_CLASS    = 'copy-note';
    const COPY_NOTE_SELECTOR = selector(COPY_NOTE_CLASS);

    const COPY_TIP  = 'Copy this output to clipboard'; // TODO: I18n

    // ========================================================================
    // Variables
    // ========================================================================

    let $root        = root ? $(root) : $('body');

    let $clip_prompt = $root.find('.clipboard-prompt');
    let $clip_input, $clip_label, $clip_note, clip_type;
    /** @type {ClipboardItem|undefined} */ let clip_item;

    let $file_prompt = $root.find('.file-prompt');
    let $file_input;

    let $containers  = $root.find('.container');
    let $status      = $containers.filter('.status-container');
    let $preview     = $containers.filter('.preview-container');
    let $error       = $containers.filter('.error-container');
    let $mathml      = $containers.filter('.mathml-container');
    let $latex       = $containers.filter('.latex-container');
    let $spoken      = $containers.filter('.spoken-container');
    let $results     = $containers.filter('.api-container');
    let $copy_icons  = $containers.find('.clipboard-icon');

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
            $clip_prompt.addClass(HIDDEN_MARKER);
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
                        callback && callback(clip_item, clip_type);
                    }
                }
            });
            let data;
            if (clip_type && callback) {
                data = undefined; // Processing has started.
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
     * @param {Event|jQuery.Event} event
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
     * @param {string} [caller]
     */
    function showClipboardNote(note, caller) {
        if ($clip_note) {
            if (note) {
                $clip_note.text(note).removeClass(HIDDEN_MARKER);
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
            $clip_note.text('').addClass(HIDDEN_MARKER);
        }
    }

    // ========================================================================
    // Internal functions - processing from file
    // ========================================================================

    /**
     * Process an image file when it is selected.
     *
     * @param {Event|jQuery.Event} event
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
        let reader = new FileReader();
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
        let $message = $error.find('.error-message').addClass(HIDDEN_MARKER);
        let $no_eqs  = $error.find('.no-equations').addClass(HIDDEN_MARKER);
        if (message) {
            $message.text(message).removeClass(HIDDEN_MARKER);
        } else if (no_equations) {
            $no_eqs.removeClass(HIDDEN_MARKER);
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
        let $container = $(container);
        $container.removeClass(HIDDEN_MARKER);
        if (output) {
            let $output = $container.find(selector);
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
        let $target = container ? $(container) : $containers;
        $target.addClass(HIDDEN_MARKER);
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
        let $icon = $(icon);
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
        let $icon = $(icon);
        let $note = $icon.siblings(COPY_NOTE_SELECTOR);
        if (isMissing($note)) {
            $note = $(`<span class="${COPY_NOTE_CLASS} ${HIDDEN_MARKER}">`);
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
            () => $note.text('(copied)').removeClass(HIDDEN_MARKER),
            () => $note.text('(failed)').removeClass(HIDDEN_MARKER)
        );
        return true;
    }

    /**
     * Hide any dynamically created "(copied)" notes that may have been
     * inserted after .clipboard-icon elements.
     */
    function resetCopyNotes() {
        let $notes = $copy_icons.siblings(COPY_NOTE_SELECTOR);
        $notes.addClass(HIDDEN_MARKER);
        $notes.text('');
    }
}

// ============================================================================
// Class
// ============================================================================

export class MathDetectiveApi extends Api {

    /**
     * MD_ImageProcessingRequest
     *
     * @typedef {{
     *     name?:            string,
     *     url:              string,
     *     skip_ocr?:        boolean,
     *     force_reprocess?: boolean,
     * }} MD_ImageProcessingRequest
     */

    /**
     * MD_Label
     *
     * @typedef {{
     *     name:       string,
     *     confidence: number
     * }} MD_Label
     */

    /**
     * MD_ImageProcessingResponse
     *
     * @typedef {{
     *     name:           string,
     *     sha256_sum:     string,
     *     labels:         MD_Label[],
     *     ocr_confidence: number,
     *     mathml:         string,
     *     latex:          string,
     *     error:          string,
     *     status:         string,
     *     spokentext:     string,
     * }} MD_ImageProcessingResponse
     */

    /**
     * MD_HttpCallback - NOT USED
     *
     * @typedef {{
     *    url:     string,
     *    headers: Object.<String>
     * }} MD_HttpCallback
     */

    /**
     * MD_BatchSubmissionRequest - NOT USED
     *
     * @typedef {{
     *     images:           MD_ImageProcessingRequest[],
     *     callback?:        MD_HttpCallback,
     *     smoke_test_flag?: boolean,
     *     skip_ocr?:        boolean,
     *     force_reprocess?: boolean,
     * }} MD_BatchSubmissionRequest
     */

    /**
     * MD_BatchSubmissionResponse - NOT USED
     *
     * @typedef {{
     *     batch_uuid: string,
     *     status:     string,
     *     output:     MD_ImageProcessingResponse[],
     * }} MD_BatchSubmissionResponse
     */

    /**
     * MD_TextProcessingRequest - NOT USED
     *
     * @typedef {{
     *     url:       string,
     *     wrap_tag?: string,
     * }} MD_TextProcessingRequest
     */

    /**
     * MD_TextProcessingResponse - NOT USED
     *
     * @typedef {{
     *     text_sha256sum: string,
     * }} MD_TextProcessingResponse
     */

    /**
     * MD_StringEquationResponseItem - NOT USED
     *
     * @typedef {{
     *     element:    string,
     *     bounds:     number[],
     *     conf_score: number,
     *     mathml:     string,
     *     spokentext: string,
     *     tag_id:     string,
     * }} MD_StringEquationResponseItem
     */

    /**
     * MD_TextStatusResponseItem - NOT USED
     *
     * @typedef {{
     *     original_string: string,
     *     equations:       MD_StringEquationResponseItem[],
     *     sha256_sum:      string,
     * }} MD_TextStatusResponseItem
     */

    /**
     * MD_TextStatusResponse - NOT USED
     *
     * @typedef {{
     *     status: string,
     *     output: MD_TextStatusResponseItem[],
     * }} MD_TextStatusResponse
     */

    /**
     * MD_StringProcessingRequest - NOT USED
     *
     * @typedef {{
     *     math_string: string,
     * }} MD_StringProcessingRequest
     */

    /**
     * MD_StringProcessingResponse - NOT USED
     *
     * @typedef {{
     *     status:          string,
     *     original_string: string,
     *     equations:       MD_StringEquationResponseItem[],
     *     sha256_sum:      string,
     * }} MD_StringProcessingResponse
     */

    /** @typedef {function(MathDetectiveApi)} MathDetectiveApiCallback */

    /**
     * MathDetectiveOptions
     *
     * @typedef {{
     *     on_fetch?:   MathDetectiveApiCallback,
     *     on_status?:  function(string),
     *     recheck?:    number,
     *     max_cycles?: number,
     * }} MathDetectiveOptions
     */

    // ========================================================================
    // Constructor
    // ========================================================================

    static CLASS_NAME = 'MathDetectiveApi';

    /**
     * Create a new instance.
     *
     * @param {MathDetectiveOptions|Api_Options} [opt]
     */
    constructor(opt) {
        /** @type {MathDetectiveOptions|Api_Options} */
        const options = $.extend({ api_key: MD_API_KEY }, opt);
        super(MD_BASE_URL, options);
        /** @type {MD_ImageProcessingResponse} */
        this.result    = {};
        this.md_status = undefined;
        this._onFetch  = options.on_fetch;
        this._onStatus = options.on_status;
        this._recheck  = options.recheck    || DEF_RECHECK_TIME;
        this._maxCycle = options.max_cycles || DEF_RECHECK_MAX;
        this._cycle    = 0;
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get started()   { return isPresent(this.md_status) }
    get running()   { return (this.md_status === 'running') }
    get completed() { return this.started && !this.running }

    get handle()    { return this.result.sha256_sum; }
    get mathml()    { return this.result.mathml; }
    get latex()     { return this.result.latex; }
    get spoken()    { return this.result.spokentext; }
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
    // Internal properties
    // ========================================================================

    get _errorMessage() {
        let response = this.response;
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
    submitImage(name, image, cb = this._onFetch) {
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
            cb && cb(this);
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
    fetchImage(cb = this._onFetch) {
        if (isMissing(this.handle)) {
            this._showStatus('FAILED');
            this.error = 'Missing request identifier to check';
            cb && cb(this);
        } else {
            this._showStatus('FETCHING');
            const callback = (...a) => this._fetchImageOnComplete(...a, cb);
            this.get(`${MD_IMAGE_PATH}/${this.handle}`, undefined, callback);
        }
    }

    // ========================================================================
    // Internal methods
    // ========================================================================

    _submitImageOnComplete(result, warning, error, xhr, cb = this._onFetch) {
        const func  = 'submitImage';
        this.result = result || {};
        this._updateStatus(xhr.status, func);
        this._showStatus();
        if (this.running) {
            this._fetchLoop(cb);
        } else {
            cb && cb(this);
        }
    }

    _fetchLoop(cb = this._onFetch) {
        if (this.running) {
            if (this.#nextCycle()) {
                this.fetchImage(cb);
                const next_cycle = () => this._fetchLoop(cb);
                this._retryTimer = setTimeout(next_cycle, this._recheck);
            } else {
                this.#clearRetryTimer();
                this._showStatus('TIMEOUT');
                cb && cb(this);
            }
        }
    }

    _fetchImageOnComplete(result, warning, error, xhr, cb = this._onFetch) {
        const func  = 'submitImage';
        this.result = result || {};
        this._updateStatus(xhr.status, func);
        this._showStatus();
        if (!this.running) {
            cb && cb(this);
        }
    }

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

    _showStatus(value) {
        if (value) {
            this.md_status = value;
        }
        this._onStatus && this._onStatus(this.md_status || 'INITIALIZING');
    }

    // ========================================================================
    // Private methods
    // ========================================================================

    #nextCycle() {
        const cycle      = ++(this._cycle);
        const continuing = (cycle <= this._maxCycle);
        if (!continuing) {
            this._cycle = 0;
        }
        return continuing;
    }

    #clearRetryTimer() {
        this._retryTimer && clearTimeout(this._retryTimer);
        this._retryTimer = undefined;
    }

}
