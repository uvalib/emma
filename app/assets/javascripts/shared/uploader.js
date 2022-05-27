// app/assets/javascripts/shared/uploader.js


import { Rails }                            from '../vendor/rails'
import { Emma }                             from '../shared/assets'
import { BaseClass }                        from '../shared/base-class'
import { toggleVisibility }                 from '../shared/accessibility'
import { selector }                         from '../shared/css'
import { isMissing, isPresent, notDefined } from '../shared/definitions'
import { handleClickAndKeypress }           from '../shared/events'
import { extractFlashMessage }              from '../shared/flash'
import { consoleLog, consoleWarn }          from '../shared/logging'
import { percent }                          from '../shared/math'
import { compact, deepFreeze, fromJSON }    from '../shared/objects'
import { camelCase }                        from '../shared/strings'
import { MINUTES, SECONDS }                 from '../shared/time'
import { makeUrl }                          from '../shared/url'
import {
    Uppy,
    AwsS3,
    Dashboard,
    DragDrop,
    FileInput,
    Informer,
    ProgressBar,
    StatusBar,
    ThumbnailGenerator,
    XHRUpload,
} from '../vendor/uppy'


// ========================================================================
// JSDoc type definitions
// ========================================================================

/**
 * Uppy plugin selection plus other optional settings.
 *
 * replace_input:   Hide the <input type="file"> present in the container.
 * upload_to_aws:   Cloud upload enabled.
 * progress_bar:    Minimal upload progress bar.
 * status_bar:      Heftier progress and control bar.
 * popup_messages:  Popup event/status messages.
 * dashboard:       Uppy dashboard.
 * drag_and_drop:   Drag-and-drop file selection enabled.
 * image_preview:   Image preview thumbnail.
 * flash_messages   Display flash messages.
 * flash_errors     Display flash errors.
 * debugging:       Turn on Uppy debugging.
 *
 * @typedef {{
 *      replace_input?:  boolean,
 *      upload_to_aws?:  boolean,
 *      popup_messages?: boolean,
 *      progress_bar?:   boolean,
 *      status_bar?:     boolean,
 *      dashboard?:      boolean,
 *      drag_and_drop?:  boolean,
 *      image_preview?:  boolean,
 *      flash_messages?: boolean,
 *      flash_errors?:   boolean,
 *      debugging?:      boolean,
 * }} UppyFeatures
 */

/**
 * A live copy of Uppy features.
 *
 * @typedef {{
 *      replace_input:  boolean,
 *      upload_to_aws:  boolean,
 *      progress_bar:   boolean,
 *      status_bar:     boolean,
 *      popup_messages: boolean,
 *      dashboard:      boolean,
 *      drag_and_drop:  boolean|HTMLElement|undefined,
 *      image_preview:  boolean|HTMLElement|undefined,
 *      flash_messages: boolean,
 *      flash_errors:   boolean,
 *      debugging:      boolean,
 * }} UppyFeatureSettings
 */

/**
 * Shrine upload response message.
 *
 * @typedef { EmmaData | {error: string} } EmmaDataOrError
 */

/**
 * Shrine upload response message.
 *
 * @typedef {{
 *      emma_data?: EmmaDataOrError,
 *      id:         string,
 *      storage:    string,
 *      metadata:   FileDataMetadata,
 * }} ShrineResponseBody
 */

/**
 * Shrine upload response message.
 *
 * @typedef {{
 *      status:     number,
 *      body:       ShrineResponseBody,
 *      uploadURL:  string,
 * }} ShrineResponseMessage
 */

// ============================================================================
// Constants
// ============================================================================

/**
 * Flag controlling overall console debug output.
 *
 * @readonly
 * @type {boolean|undefined}
 */
const DEBUGGING = true;

/**
 * Uppy plugin selection plus other optional settings.
 *
 * @readonly
 * @type {UppyFeatures}
 */
const FEATURES = deepFreeze({
    replace_input:  true,   // Requires '@uppy/file-input'
    upload_to_aws:  false,  // Requires '@uppy/aws-s3'
    popup_messages: true,   // Requires '@uppy/informer'
    progress_bar:   true,   // Requires '@uppy/progress-bar'
    status_bar:     false,  // Requires '@uppy/status-bar'
    dashboard:      false,  // Requires '@uppy/dashboard'
    drag_and_drop:  false,  // Requires '@uppy/drag-drop'
    image_preview:  false,  // Requires '@uppy/thumbnail-generator'
});

/**
 * How long to wait for the server to confirm the upload.
 *
 * The default is 30 seconds but that has been seen to be too short for
 * certain files (either because of size or because of complexity when
 * parsing for metadata).
 *
 * @readonly
 * @type {number}
 */
const UPLOAD_TIMEOUT = 5 * MINUTES;

/**
 * How long to display transient Uppy popup messages.
 *
 * @readonly
 * @type {number}
 */
const MESSAGE_DURATION = 30 * SECONDS;

/**
 * Base message displayed if Uppy encounters an error when uploading the
 * file.
 *
 * @readonly
 * @type {string}
 */
const UPLOAD_ERROR_MESSAGE = 'FILE UPLOAD ERROR'; // TODO: I18n

// ============================================================================
// Class Uploader
// ============================================================================

// noinspection LocalVariableNamingConventionJS
/**
 * An uploader using Uppy and Shrine.
 */
export class Uploader extends BaseClass {

    static CLASS_NAME = 'Uploader';

    /**
     * Create a new instance.
     *
     * @param {Selector}            form
     * @param {String}              model
     * @param {UppyFeatures|object} features
     * @param {Object<boolean>}     state
     * @param {{
     *     onSelect:  ?Callback,
     *     onStart:   ?Callback,
     *     onError:   ?Callback,
     *     onSuccess: ?Callback,
     * }} [callbacks]
     */
    constructor(form, model, features, state, callbacks) {
        super();

        this.model      = model;
        this.$form      = $(form);
        this.$container = this.$form.parent();
        this.state      = state || {};

        this.onSelect   = callbacks?.onSelect;
        this.onStart    = callbacks?.onStart;
        this.onError    = callbacks?.onError;
        this.onSuccess  = callbacks?.onSuccess;

        this.upload_timeout   = UPLOAD_TIMEOUT;
        this.message_duration = MESSAGE_DURATION;
        this.upload_error     = UPLOAD_ERROR_MESSAGE;

        /** @type {ModelProperties} */
        this.property = Emma[camelCase(model)] || {};

        /** @type {UppyFeatureSettings} */
        this.feature = $.extend({ debugging: DEBUGGING }, FEATURES, features);

        /** @type {Uppy.Uppy} */
        this.uppy = undefined;
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get controller()   { return this.model }
    get record()       { return this.model }

    /** @returns {boolean} */ get isCreateForm() { return this.state.new  }
    /** @returns {boolean} */ get isUpdateForm() { return this.state.edit }
    /** @returns {boolean} */ get isBulkOpForm() { return this.state.bulk }

    /** @returns {boolean} */ get debugging() { return this.feature.debugging }

    // ========================================================================
    // Methods - actions
    // ========================================================================

    /**
     * Invoked by the originating form to indicate that it is in a canceling
     * state.
     */
    cancel() {
        this.hideProgressBar();
    }

    // ========================================================================
    // Methods - initialization
    // ========================================================================

    /**
     * Initialize if not already initialized.
     *
     * @param {boolean} [force]
     *
     * @returns {Uploader}
     */
    initialize(force) {
        const marked = this.isUppyInitialized();
        const loaded = !!this.uppy;
        let warn, init = force;
        if (!marked && !loaded) {
            init = true;
        } else if (marked) {
            warn = 'container has .uppy-Root but this.uppy is missing';
        } else if (loaded) {
            warn = 'this.uppy is present but container missing .uppy-Root';
        }
        if (warn) {
            console.warn(`${this.className}: re-initializing: ${warn}`);
            init = true;
        }
        if (init) {
            this.initializeUppy();
        }
        return this;
    }

    /**
     * Indicate whether Uppy already appears to be set up.
     *
     * @returns {boolean}
     */
    isUppyInitialized() {
        return isPresent(this.$container.find('.uppy-Root'));
    }

    /**
     * Initialize Uppy file uploader.
     */
    initializeUppy() {

        // Get targets for these features; disable the feature if its target is
        // not present.
        this.feature.drag_and_drop &&= this.#dragTarget();
        this.feature.image_preview &&= this.#previewTarget();

        // === Initialization ===

        this.uppy = this.buildUppy();

        // Events for these features are also applicable to Uppy.Dashboard.
        if (this.feature.dashboard) {
            this.feature.replace_input = true;
            this.feature.drag_and_drop = true;
            this.feature.progress_bar  = true;
            this.feature.status_bar    = true;
        }

        // === Event handlers ===

        this.#setupHandlers();

        if (this.feature.popup_messages) { this.#setupMessages() }
        if (this.feature.debugging)      { this.#setupDebugging() }

        // === Display cleanup ===

        if (this.feature.replace_input) {
            this.#initializeFileSelectContainer();
        }

        this.#initializeFileSelectButton();
        this.#initializeProgressBar();
    }

    /**
     * Build an Uppy instance with specified plugins.
     *
     * @returns {Uppy.Uppy}
     */
    buildUppy() {
        let form      = this.$form[0];
        let container = form.parentElement;

        let uppy =
            new Uppy({
                id:          form.id,
                autoProceed: true,
                debug:       this.feature.debugging
            });

        if (this.feature.dashboard) {
            uppy.use(Dashboard, { target: container, inline: true });
        } else {
            if (this.feature.replace_input) {
                const fi_target = this.buttonTray()[0]; // NOTE: not container
                const fi_label  = this.fileSelectLabel();
                uppy.use(FileInput, {
                    target: fi_target,
                    locale: {
                        strings: {
                            chooseFiles: fi_label
                        }
                    }
                });
            }
            if (this.feature.drag_and_drop) {
                const dd_target = this.feature.drag_and_drop;
                uppy.use(DragDrop, { target: dd_target });
            }
            if (this.feature.progress_bar) {
                uppy.use(ProgressBar, { target: container });
            }
            if (this.feature.status_bar) {
                uppy.use(StatusBar, {
                    target: container,
                    showProgressDetails: true
                });
            }
        }
        if (this.feature.popup_messages) {
            uppy.use(Informer, { target: container });
        }
        if (this.feature.image_preview) {
            uppy.use(ThumbnailGenerator, { thumbnailWidth: 400 });
        }
        if (this.feature.upload_to_aws) {
            const aws_timeout = this.upload.timeout;
            uppy.use(AwsS3, {
                // limit:     2,
                timeout:      aws_timeout,
                companionUrl: 'https://companion.myapp.com/' // TODO: ???
            });
        }

        const endpoint    = this.#path.endpoint;
        const def_message = this.upload_error;

        // noinspection JSUnusedGlobalSymbols
        uppy.use(XHRUpload, {
            endpoint:         endpoint,
            fieldName:        'file',
            timeout:          0, // this.upload_timeout, // NOTE: none for now
            // limit:         1,
            headers:          { 'X-CSRF-Token': Rails.csrfToken() },
            getResponseError: function(body, xhr) {
                let result  = fromJSON(body) || {};
                let message = (result.message || body)?.trim() || def_message;
                let flash   = compact(extractFlashMessage(xhr));
                if (isPresent(flash)) {
                    message = message.replace(/([^:])$/, '$1:');
                    if (flash.length > 1) {
                        message += "\n" + flash.join("\n");
                    } else {
                        message += ' ' + flash[0];
                    }
                } else {
                    message = message.replace(/:$/, '');
                }
                return new Error(message);
            }
        });

        return uppy;
    }

    // ========================================================================
    // Protected methods - initialization
    // ========================================================================

    /**
     * Setup handlers for Uppy events that drive the workflow of uploading
     * a file and creating a database entry from it.
     */
    #setupHandlers() {

        const debugUppy       = this.#debugUppy.bind(this);
        const uppyInfoClear   = this.#uppyInfoClear.bind(this);
        const showProgressBar = this.showProgressBar.bind(this);

        const onStart   = this.onStart   || (() => debugUppy('onStart'));
        const onError   = this.onError   || (() => debugUppy('onError'));
        const onSuccess = this.onSuccess || (() => debugUppy('onSuccess'));

        let uppy        = this.uppy;
        let feature     = this.feature;

        uppy.on('upload',         onFileUploadStart);
        uppy.on('upload-error',   onFileUploadError);
        uppy.on('upload-success', onFileUploadSuccess);

        if (feature.image_preview) {
            uppy.on('thumbnail:generated', onThumbnailGenerated);
        }

        // ====================================================================
        // Handlers
        // ====================================================================

        /**
         * This event occurs between the 'file-added' and 'upload-started'
         * events.
         *
         * The current value of the submission's database ID applied to the
         * upload endpoint URL in order to correlate the upload with the
         * appropriate workflow.
         *
         * @param {{id: string, fileIDs: string[]}} data
         */
        function onFileUploadStart(data) {
            debugUppy('upload', data);
            const params = onStart(data);
            const upload = uppy.getPlugin('XHRUpload');
            // noinspection JSUnresolvedFunction
            const url    = upload.getOptions({}).endpoint;
            if (isMissing(url)) {
                console.error('No endpoint for upload');
            } else {
                if (isPresent(params)) {
                    // noinspection JSCheckFunctionSignatures
                    upload.setOptions({ endpoint: makeUrl(url, params) });
                }
                showProgressBar();
            }
        }

        /**
         * This event occurs when the response from POST /entry/endpoint is
         * received with a failure status (4xx).
         *
         * @param {Uppy.UppyFile}                  file
         * @param {Error}                          error
         * @param {{status: number, body: string}} [response]
         */
        function onFileUploadError(file, error, response) {
            consoleWarn('Uppy:', 'upload-error', file, error, response);
            onError(file, error, response);
            uppy.getFiles().forEach(file => uppy.removeFile(file.id));
        }

        /**
         * This event occurs when the response from POST /entry/endpoint is
         * received with success status (200).  At this point, the file has
         * been uploaded by Shrine, but has not yet been validated.
         *
         * @param {Uppy.UppyFile}         file
         * @param {ShrineResponseMessage} response
         *
         * @see "Shrine::UploadEndpointExt#make_response"
         *
         * == Implementation Notes
         * The normal Shrine response has been augmented to include an
         * 'emma_data' object in addition to the fields associated with
         * 'file_data'.
         */
        function onFileUploadSuccess(file, response) {
            debugUppy('upload-success', file, response);
            if (feature.popup_messages) {
                uppyInfoClear();
            }
            onSuccess(file, response);
        }

        /**
         * This event occurs when a thumbnail of an uploaded image is
         * available.
         *
         * @param {Uppy.UppyFile} file
         * @param {string}        image
         */
        function onThumbnailGenerated(file, image) {
            debugUppy('thumbnail:generated', file, image);
            feature.image_preview.src = image;
        }
    }

    /**
     * Setup handlers for Uppy events that should trigger popup messages.
     */
    #setupMessages() {

        const debugUppy = this.#debugUppy.bind(this);
        const error     = this.#uppyError.bind(this);
        const warn      = this.#uppyWarn.bind(this);
        const popup     = this.#uppyPopup.bind(this);
        const info      = this.#uppyInfo.bind(this);

        this.uppy.on('upload-started', function(file) {
            consoleWarn('Uppy:', 'upload-started', file);
            info(`Uploading "${file.name || file}"`); // TODO: I18n
        });

        this.uppy.on('upload-pause', function(file_id, is_paused) {
            debugUppy('upload-pause', file_id, is_paused);
            if (is_paused) {
                info('PAUSED');   // TODO: I18n
            } else {
                popup('RESUMED'); // TODO: I18n
            }
        });

        this.uppy.on('upload-retry', function(file_id) {
            debugUppy('upload-retry', file_id);
            warn('Retrying...'); // TODO: I18n
        });

        this.uppy.on('retry-all', function(files) {
            debugUppy('retry-all', files);
            const count   = files ? files.length : 0;
            const uploads = (count === 1) ? 'upload' : `${count} uploads`;
            warn(`Retrying ${uploads}...`); // TODO: I18n
        });

        this.uppy.on('pause-all', function() {
            debugUppy('pause-all');
            info('Uploading PAUSED'); // TODO: I18n
        });

        this.uppy.on('cancel-all', function() {
            debugUppy('cancel-all');
            warn('Uploading CANCELED'); // TODO: I18n
        });

        this.uppy.on('resume-all', function() {
            debugUppy('resume-all');
            warn('Uploading RESUMED'); // TODO: I18n
        });

        this.uppy.on('restriction-failed', function(file, msg) {
            consoleWarn('Uppy:', 'restriction-failed', file, msg);
            error(msg);
        });

        this.uppy.on('error', function(msg) {
            consoleWarn('Uppy:', 'error', msg);
            error(msg);
        });

    }

    /**
     * Set up console debugging messages for other Uppy events.
     */
    #setupDebugging() {

        const debugUppy = this.#debugUppy.bind(this);

        // This event occurs after 'upload-success' or 'upload-error'.
        this.uppy.on('complete', function(result) {
            debugUppy('complete', result);
        });

        // This event is observed concurrent with the 'progress' event.
        this.uppy.on('upload-progress', function(file, progress) {
            const bytes = progress.bytesUploaded;
            const total = progress.bytesTotal;
            const pct   = percent(bytes, total);
            debugUppy('uploading', bytes, 'of', total, `(${pct}%)`);
        });

        // This event is observed concurrent with the 'upload-progress' event.
        this.uppy.on('progress', function(percent) {
            debugUppy('progress', percent);
        });

        this.uppy.on('reset-progress', function() {
            debugUppy('reset-progress');
        });

        this.uppy.on('file-added', function(file) {
            debugUppy('file-added', file);
        });

        this.uppy.on('file-removed', function(file) {
            debugUppy('file-removed', file);
        });

        this.uppy.on('preprocess-progress', function(file, status) {
            debugUppy('preprocess-progress', file, status);
        });

        this.uppy.on('preprocess-complete', function(file) {
            debugUppy('preprocess-complete', file);
        });

        this.uppy.on('is-offline', function() {
            debugUppy('OFFLINE');
        });

        this.uppy.on('is-online', function() {
            debugUppy('ONLINE');
        });

        this.uppy.on('back-online', function() {
            debugUppy('BACK ONLINE');
        });

        this.uppy.on('info-visible', function() {
            debugUppy('info-visible');
        });

        this.uppy.on('info-hidden', function() {
            debugUppy('info-hidden');
        });

        this.uppy.on('plugin-remove', function(instance) {
            debugUppy('plugin-remove', (instance.id || instance));
        });

        if (this.feature.dashboard) {
            this.uppy.on('dashboard:modal-open', function() {
                debugUppy('dashboard:modal-open');
            });
            this.uppy.on('dashboard:modal-closed', function() {
                debugUppy('dashboard:modal-closed');
            });
            this.uppy.on('dashboard:file-edit-start', function() {
                debugUppy('dashboard:file-edit-start');
            });
            this.uppy.on('dashboard:file-edit-complete', function() {
                debugUppy('dashboard:file-edit-complete');
            });
        }

        if (this.feature.image_preview) {
            this.uppy.on('thumbnail:request', function(file) {
                debugUppy('thumbnail:request', file);
            });
            this.uppy.on('thumbnail:cancel', function(file) {
                debugUppy('thumbnail:cancel', file);
            });
            this.uppy.on('thumbnail:error', function(file, error) {
                debugUppy('thumbnail:error', file, error);
            });
            this.uppy.on('thumbnail:all-generated', function() {
                debugUppy('thumbnail:all-generated');
            });
        }

        if (this.feature.upload_to_aws) {
            this.uppy.on('s3-multipart:part-uploaded', function(file, pt) {
                debugUppy('s3-multipart:part-uploaded', file, pt);
            });
        }

/*
        this.uppy.on('state-update', function(prev_state, next_state, patch) {
            debugUppy('state-update', prev_state, next_state, patch);
        });
*/
    }

    // ========================================================================
    // Methods - Uppy informer
    // ========================================================================

    /**
     * Invoke `uppy.info` with an error message.
     *
     * @param {string} text
     * @param {number} [duration]
     */
    #uppyError(text, duration) {
        this.#uppyPopup(text, duration, 'error');
    }

    /**
     * Invoke `uppy.info` with a warning message.
     *
     * @param {string} text
     * @param {number} [duration]
     */
    #uppyWarn(text, duration) {
        this.#uppyPopup(text, duration, 'warning');
    }

    /**
     * Invoke `uppy.info` with a temporary message.
     *
     * @param {string}                   text
     * @param {number}                   [duration]
     * @param {'info'|'warning'|'error'} [info_level]
     */
    #uppyPopup(text, duration, info_level) {
        const time = duration || this.message_duration;
        this.#uppyInfo(text, time, info_level);
    }

    /**
     * Invoke `uppy.info`.
     *
     * If no duration is given the information bubble will remain until
     * intentionally cleared.
     *
     * @param {string}                   text
     * @param {number}                   [duration]
     * @param {'info'|'warning'|'error'} [info_level]
     */
    #uppyInfo(text, duration, info_level) {
        const level = info_level || 'info';
        const time  = duration   || 1000 * MINUTES;
        this.uppy.info(text, level, time);
    }

    /**
     * Invoke `uppy.info` with an empty string and very short duration.
     */
    #uppyInfoClear() {
        this.#uppyInfo('', 1);
    }

    // ========================================================================
    // Methods - Uppy progress bar
    // ========================================================================

    /**
     * The element starts with 'aria-hidden="true"' (so that attribute alone
     * alone isn't sufficient for conditional styling), however the element
     * (and its children) are not invisible.
     *
     * @see file:app/assets/stylesheets/vendor/_uppy.scss .uppy-ProgressBar
     */
    #initializeProgressBar() {
        this.hideProgressBar();
    }

    /**
     * Start displaying the Uppy progress bar.
     */
    showProgressBar() {
        this.toggleProgressBar(true);
    }

    /**
     * Stop displaying the Uppy progress bar.
     *
     * Note that the 'hideAfterFinish' option for ProgressBar *only* sets
     * 'aria-hidden' -- it doesn't actually hide the control itself.
     */
    hideProgressBar() {
        this.toggleProgressBar(false);
    }

    /**
     * Hide/show the .uppy-ProgressBar element by adding/removing the CSS
     * "invisible" class.
     *
     * @param {boolean} [visible]
     */
    toggleProgressBar(visible) {
        let $control = this.$container.find('.uppy-ProgressBar');
        toggleVisibility($control, visible);
    }

    // ========================================================================
    // Methods - container
    // ========================================================================

    /**
     * Initialize the Uppy-provided file select button container.
     */
    #initializeFileSelectContainer() {
        let $element   = this.fileSelectContainer();
        const input_id = `${this.model}_file`;

        // Uppy will replace <input type="file"> with its own mechanisms so
        // the original should not be displayed.
        this.$form.find(`input#${input_id}`).css('display', 'none');

        // Reposition it so that it comes before the display of the uploaded
        // filename.
        $element.insertBefore(this.uploadedFilenameDisplay());

        // This hidden element is inappropriately part of the tab order.
        let $uppy_file_input = $element.find('.uppy-FileInput-input');
        $uppy_file_input.attr('tabindex',        -1);
        $uppy_file_input.attr('aria-hidden',     true);
        $uppy_file_input.attr('aria-labelledby', 'fi_label');

        // Set the tooltip for the file select button.
        $element.find('button,label').attr('title', this.fileSelectTooltip());
    }

    /**
     * The Uppy-generated element containing the file select button.
     *
     * @returns {jQuery}
     */
    fileSelectContainer() {
        return this.$form.find('.uppy-FileInput-container');
    }

    /**
     * The file select input control.
     *
     * @returns {jQuery}
     */
    fileSelectInput() {
        return this.fileSelectContainer().children('input[type="file"]');
    }

    /**
     * The control button container.
     *
     * @returns {jQuery}
     *
     * @see file:../feature/model-form.js buttonTray
     */
    buttonTray() {
        return this.$form.find('.button-tray');
    }

    // ========================================================================
    // Methods - file selection
    // ========================================================================

    /**
     * Initialize the state of the file select button if applicable to the
     * current form.
     */
    #initializeFileSelectButton() {
        let $button = this.fileSelectContainer().children('button');
        const label = this.fileSelectLabel();
        const tip   = this.fileSelectTooltip();
        $button.text(label);
        $button.attr('title', tip).siblings('label').attr('title', tip);
        $button.addClass('file-select-button');
        if (this.isCreateForm) {
            $button.addClass('best-choice');
        }
        let handler = this.onSelect;
        if (!handler) {
            const debug = this.#debugUppy.bind(this);
            handler = () => debug('file-select-button');
        }
        handleClickAndKeypress($button, handler);
    }

    /**
     * Disable the file select button.
     *
     * @returns {jQuery}              The file select button.
     */
    disableFileSelectButton() {
        const label = this.fileSelectDisabledLabel();
        const tip   = this.fileSelectDisabledTooltip();
        return this.fileSelectButton()
            .removeClass('best-choice')
            .addClass('forbidden')
            .attr('title', tip)
            .text(label);
    }

    /**
     * Display the name of the uploaded file.
     *
     * @param {FileData} file_data
     */
    displayUploadedFilename(file_data) {
        const metadata = file_data?.metadata;
        const filename = metadata?.filename;
        this.displayFilename(filename);
    }

    /**
     * Display the name of the file selected by the user.
     *
     * @param {String} filename
     *
     * @returns {boolean}
     */
    displayFilename(filename) {
        const displayed = isPresent(filename);
        if (displayed) {
            let $element = this.uploadedFilenameDisplay();
            if (isPresent($element)) {
                let $filename = $element.find('.filename');
                if (isPresent($filename)) {
                    $filename.text(filename);
                } else {
                    $element.text(filename);
                }
                $element.addClass('complete');
            }
            this.hideProgressBar();
        }
        return displayed;
    }

    /**
     * The element displaying the uploaded file.
     *
     * @returns {jQuery}
     */
    uploadedFilenameDisplay() {
        return this.$form.find('.uploaded-filename');
    }

    /**
     * The Uppy-generated file select button.
     *
     * @returns {jQuery}
     */
    fileSelectButton() {
        return this.fileSelectContainer().children('.file-select-button');
    }

    // ========================================================================
    // Methods - Uppy elements
    // ========================================================================

    /**
     * Uppy drag-and-drop target element (if any).
     *
     * @returns {HTMLElement|undefined}
     */
    #dragTarget() {
        const target = this.#uploaderProperty.drag_target;
        return target && this.$container.find(selector(target))[0];
    }

    /**
     * Thumbnail display of the selected file (if any).
     *
     * @returns {HTMLElement|undefined}
     */
    #previewTarget() {
        const target = this.#uploaderProperty.preview;
        return target && this.$container.find(selector(target))[0];
    }

    // ========================================================================
    // Methods - form status
    // ========================================================================

    /**
     * Indicate whether file select is enabled.
     *
     * @returns {boolean}
     */
    canSelect() {
        return !this.fileSelected();
    }

    /**
     * Indicate whether the user has selected a file (which implies that the
     * file has been uploaded for validation).
     *
     * @returns {boolean}
     */
    fileSelected() {
        return this.uploadedFilenameDisplay().css('display') !== 'none';
    }

    // ========================================================================
    // Methods - data properties
    // ========================================================================

    /**
     * The current label for the file select button.
     *
     * @param {boolean} [can_select]    Default: `canSelect()`.
     *
     * @returns {string}
     */
    fileSelectLabel(can_select) {
        return this.selectProperties('label', can_select) || 'SELECT';
    }

    /**
     * The current tooltip for the file select button.
     *
     * @param {boolean} [can_select]    Default: `canSelect()`.
     *
     * @returns {string|undefined}
     */
    fileSelectTooltip(can_select) {
        return this.selectProperties('tooltip', can_select);
    }

    /**
     * The label for the file select button when disabled.
     *
     * @returns {string}
     */
    fileSelectDisabledLabel() {
        return this.fileSelectLabel(false);
    }

    /**
     * The tooltip for the file select button when disabled.
     *
     * @returns {string}
     */
    fileSelectDisabledTooltip() {
        return this.fileSelectTooltip(false);
    }

    /**
     * Get label/tooltip properties for file select.
     *
     * @param {string}  value
     * @param {boolean} [can_select]    Default: `this.canSelect()`.
     *
     * @returns {*}
     */
    selectProperties(value, can_select) {
        const op     = this.#endpointProperties.select || {};
        const select = notDefined(can_select) ? this.canSelect() : can_select;
        const status = select ? op.enabled : op.disabled;
        return status && status[value] || op[value];
    }

    // ========================================================================
    // Protected properties
    // ========================================================================

    /** @returns {PathProperties|{}} */
    get #path() { return this.property.Path || {} }

    /** @returns {UploaderProperties|{}} */
    get #uploaderProperty() { return this.property.Upload || {} }

    /**
     * Get the configuration properties for the current form action.
     *
     * @returns {EndpointProperties}
     *
     * @see file:../feature/model-form.js endpointProperties
     */
    get #endpointProperties() {
        const action = this.property.Action;
        if (this.isBulkOpForm) {
            return this.isUpdateForm ? action.bulk_edit : action.bulk_new;
        } else {
            return this.isUpdateForm ? action.edit      : action.new;
        }
    }

    // ========================================================================
    // Methods - other
    // ========================================================================

    // noinspection JSMethodCanBeStatic
    /**
     * Emit a console message if debugging file uploads.
     *
     * @param {...*} args
     */
    #debugUppy(...args) {
        if (this.debugging) { consoleLog('Uppy:', ...args); }
    }

}
