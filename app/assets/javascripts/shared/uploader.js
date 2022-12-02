// app/assets/javascripts/shared/uploader.js


import { toggleVisibility }                            from './accessibility'
import { Emma }                                        from './assets'
import { BaseClass }                                   from './base-class'
import { pageAction }                                  from './controller'
import { selector }                                    from './css'
import { isDefined, isMissing, isPresent, notDefined } from './definitions'
import { handleClickAndKeypress }                      from './events'
import { extractFlashMessage }                         from './flash'
import { ID_ATTRIBUTES, uniqAttrs }                    from './html'
import { percent }                                     from './math'
import { compact, deepFreeze, fromJSON }               from './objects'
import { camelCase }                                   from './strings'
import { MINUTES, SECONDS }                            from './time'
import { makeUrl }                                     from './url'
import { Rails }                                       from '../vendor/rails'
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


// ============================================================================
// Type definitions
// ============================================================================

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
 * @see "Shrine::UploadEndpointExt#make_response"
 *
 * @typedef {{
 *      emma_data?: EmmaDataOrError,
 *      id:         string,
 *      storage:    string,
 *      metadata:   FileDataMetadata,
 * }} ShrineResponseBody
 */

/**
 * Uppy upload response message.
 *
 * @typedef {{
 *      status:     number,
 *      body:       ShrineResponseBody,
 *      uploadURL:  string,
 * }} UppyResponseMessage
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
//const UPLOAD_TIMEOUT = 5 * MINUTES;

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
// Class BaseUploader
// ============================================================================

// noinspection LocalVariableNamingConventionJS
/**
 * An uploader using Uppy and Shrine.
 */
class BaseUploader extends BaseClass {

    static CLASS_NAME = 'BaseUploader';
    static DEBUGGING  = DEBUGGING;

    // ========================================================================
    // Type definitions
    // ========================================================================

    /**
     * UppyCallbacks
     *
     * @typedef {{
     *     onSelect?:   Callback,
     *     onStart?:    Callback,
     *     onError?:    Callback,
     *     onSuccess?:  Callback,
     * }} UppyCallbacks
     */

    /**
     * UppyPluginOptions
     *
     * @typedef {{
     *     db_target?:  Selector,
     *     fi_target?:  Selector,
     *     dd_target?:  Selector,
     *     pb_target?:  Selector,
     *     sb_target?:  Selector,
     *     pm_target?:  Selector,
     *     db_opt?:     object,
     *     fi_opt?:     object,
     *     dd_opt?:     object,
     *     pb_opt?:     object,
     *     sb_opt?:     object,
     *     pm_opt?:     object,
     *     ip_opt?:     object,
     *     aws_opt?:    object,
     *     xhr_opt?:    object,
     *     xhr_hdr?:    object,
     *     fi_string?:  StringTable,
     * }} UppyPluginOptions
     */

    /**
     * @typedef {{
     *     force?:      boolean,
     *     controller?: string,
     *     action?:     string,
     *     uppy?:       Uppy.UppyOptions,
     *     plugin?:     UppyPluginOptions,
     *     added?:      function(Selector),
     * }} UploaderOptions
     */

    // ========================================================================
    // Constants
    // ========================================================================

    static UPLOADER_CLASS       = 'file-uploader';
    static FILE_SELECT_CLASS    = 'uppy-FileInput-container';
    static FILE_INPUT_CLASS     = 'uppy-FileInput-input';
    static FILE_BUTTON_CLASS    = 'uppy-FileInput-btn';
    static PROGRESS_BAR_CLASS   = 'uppy-ProgressBar';
    static FILE_NAME_CLASS      = 'uploaded-filename';
    static HIDDEN_MARKER        = 'hidden';

    static UPLOADER     = selector(this.UPLOADER_CLASS);
    static FILE_SELECT  = selector(this.FILE_SELECT_CLASS);
    static FILE_INPUT   = selector(this.FILE_INPUT_CLASS);
    static FILE_BUTTON  = selector(this.FILE_BUTTON_CLASS);
    static PROGRESS_BAR = selector(this.PROGRESS_BAR_CLASS);
    static FILE_NAME    = selector(this.FILE_NAME_CLASS);
    static HIDDEN       = selector(this.HIDDEN_MARKER);

    // ========================================================================
    // Fields
    // ========================================================================

    /** @type {string}              */ model;
    /** @type {string}              */ controller;
    /** @type {string}              */ action;
    /** @type {Callback|undefined}  */ onSelect
    /** @type {Callback|undefined}  */ onStart
    /** @type {Callback|undefined}  */ onError
    /** @type {Callback|undefined}  */ onSuccess
    /** @type {number}              */ //upload_timeout = UPLOAD_TIMEOUT;
    /** @type {number}              */ message_duration = MESSAGE_DURATION;
    /** @type {string}              */ upload_error     = UPLOAD_ERROR_MESSAGE;
    /** @type {ModelProperties}     */ property         = {};
    /** @type {UppyFeatureSettings} */ feature          = FEATURES;

    /** @type {jQuery}              */ _root;
    /** @type {jQuery}              */ _display;
    /** @type {Uppy.Uppy}           */ _uppy;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {Selector}            root
     * @param {string}              model
     * @param {UppyFeatures|object} features
     * @param {UppyCallbacks}       [callbacks]
     */
    constructor(root, model, features, callbacks) {
        super();
        this._root      = this._locateUploader(root);
        this.model      = model;
        this.controller = model;
        this.action     = pageAction();
        this.onSelect   = callbacks?.onSelect;
        this.onStart    = callbacks?.onStart;
        this.onError    = callbacks?.onError;
        this.onSuccess  = callbacks?.onSuccess;
        this.property   = Emma[camelCase(model)] || {};
        this.feature    = { debugging: DEBUGGING, ...FEATURES, ...features };
    }

    // ========================================================================
    // Properties
    // ========================================================================

    /**
     * @returns {jQuery}
     */
    get $root() {
        return this._root ||= this._locateUploader(this._display);
    }

    /**
     * Generic default container for element(s) added by Uppy plugins.
     *
     * @returns {jQuery}
     */
    get $display() {
        return this._display ||= this._locateDisplay(this._root);
    }

    /** @returns {boolean} */
    get debugging() {
        return this.feature.debugging && super.debugging;
    }

    // ========================================================================
    // Protected methods
    // ========================================================================

    /**
     * _locateDisplay
     *
     * @param {Selector} [target]     Default: `this._root`.
     *
     * @returns {jQuery|undefined}
     * @protected
     */
    _locateDisplay(target) {
        const $target = target ? $(target) : this._root;
        const $result = $target?.parent();
        return isPresent($result) ? $result : undefined;
    }

    /**
     * _locateUploader
     *
     * @param {Selector} [target]     Default: `this._root`.
     *
     * @returns {jQuery|undefined}
     * @protected
     */
    _locateUploader(target) {
        const tgt     = target || this._root;
        const $result = this._selfOrDescendent(tgt, this.constructor.UPLOADER);
        return isPresent($result) ? $result : undefined;
    }

    /**
     * _selfOrDescendent
     *
     * @param {Selector} target
     * @param {string}   match
     *
     * @returns {jQuery|undefined}
     * @protected
     */
    _selfOrDescendent(target, match) {
        const $target = target && $(target);
        if ($target?.is(match)) { return $target }
        const $result = $target.find(match).first();
        return isPresent($result) ? $result : undefined;
    }

    /**
     * _selfOrDescendentElement
     *
     * @param {Selector} target
     * @param {string}   match
     *
     * @returns {HTMLElement|undefined}
     * @protected
     */
    _selfOrDescendentElement(target, match) {
        const result = this._selfOrDescendent(target, match);
        return result && result[0];
    }

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
     * @param {UploaderOptions} [options]
     *
     * @returns {BaseUploader}
     */
    initialize(options) {
        const marked = this.isUppyInitialized();
        const loaded = !!this._uppy;
        let warn, init = options?.force;
        if (!marked && !loaded) {
            init = true;
        } else if (marked) {
            warn = 'container has .uppy-Root but this._uppy is missing';
        } else if (loaded) {
            warn = 'this._uppy is present but container missing .uppy-Root';
        }
        if (warn) {
            this._warn(`re-initializing: ${warn}`);
            init = true;
        }
        if (init) {
            this.initializeUppy(options);
        }
        return this;
    }

    /**
     * Indicate whether Uppy already appears to be set up.
     *
     * @returns {boolean}
     */
    isUppyInitialized() {
        const match       = '.uppy';
        const $uppy_added = this._selfOrDescendent(this.$display, match);
        return isPresent($uppy_added);
    }

    /**
     * Initialize Uppy file uploader.
     *
     * @param {UploaderOptions} [options]
     */
    initializeUppy(options) {

        // === Initialization ===

        this.controller = options?.controller || this.controller;
        this.action     = options?.action     || this.action;

        this._uppy = this.buildUppy(options);

        // === Event handlers ===

        this._setupHandlers();
        if (this.feature.popup_messages) { this._setupMessages() }
        if (this.feature.debugging)      { this._setupDebugging() }

        // === Display setup ===

        if (this.feature.replace_input) {
            this._initializeFileSelectContainer(options);
        }
        this._initializeFileSelectButton();
        this._initializeProgressBar();
    }

    /**
     * Build an Uppy instance with specified plugins.
     *
     * @param {UploaderOptions} [options]
     *
     * @returns {Uppy.Uppy}
     */
    buildUppy(options) {
        const uppy_options = {
            id:          `uppy-${this.$root[0].id}`,
            debug:       this.feature.debugging,
            autoProceed: true,
            ...options?.uppy
        };
        const uppy = new Uppy(uppy_options);

        // Table of keys whose value is the activation setting of the related
        // Uppy plugin.
        const plugin = {
            db:  this.feature.dashboard,
            fi:  this.feature.replace_input,
            dd:  this.feature.drag_and_drop,
            pb:  this.feature.progress_bar,
            sb:  this.feature.status_bar,
            pm:  this.feature.popup_messages,
            ip:  this.feature.image_preview,
            aws: this.feature.upload_to_aws,
            xhr: true, // XHRUpload is always used
        };

        /** @type {UppyPluginOptions} */
        const opt = { ...options?.plugin };

        // Determine the target for each plugin.
        Object.keys(plugin).forEach(key => {
            const p_opt = `${key}_opt`;
            const p_tgt = `${key}_target`;
            opt[p_opt]  = opt[p_opt] || {};
            const tgt   = opt[p_tgt] || opt[p_opt].target;
            opt[p_tgt]  = this._locateTarget(tgt) || this._defaultTarget(key);
            delete opt[p_opt].target;
        });

        if (plugin.db) {
            const db_opt = { inline: true, ...opt.db_opt };
            uppy.use(Dashboard, { target: opt.db_target, ...db_opt });
        } else {
            if (plugin.fi) {
                const fi_label  = this.fileSelectLabel();
                const fi_string = { chooseFiles: fi_label, ...opt.fi_string };
                const fi_locale = { locale: { strings: fi_string } };
                const fi_opt    = { ...fi_locale, ...opt.fi_opt };
                uppy.use(FileInput, { target: opt.fi_target, ...fi_opt });
            }
            if (plugin.dd) {
                const dd_opt = opt.dd_opt;
                uppy.use(DragDrop, { target: opt.dd_target, ...dd_opt });
            }
            if (plugin.pb) {
                const pb_opt = opt.pb_opt;
                uppy.use(ProgressBar, { target: opt.pb_target, ...pb_opt });
            }
            if (plugin.sb) {
                const sb_opt = { showProgressDetails: true, ...opt.sb_opt };
                uppy.use(StatusBar, { target: opt.sb_target, ...sb_opt });
            }
        }
        if (plugin.pm) {
            const pm_opt = opt.pm_opt;
            uppy.use(Informer, { target: opt.pm_target, ...pm_opt });
        }
        if (plugin.ip) {
            const ip_opt = { thumbnailWidth: 400, ...opt.ip_opt };
            uppy.use(ThumbnailGenerator, ip_opt);
        }
        if (plugin.aws) {
            const aws_opt = {
                // limit:     2,
                timeout:      this.upload.timeout,
                companionUrl: 'https://companion.myapp.com/', // TODO: ???
                ...opt.aws_opt
            };
            uppy.use(AwsS3, aws_opt);
        }
        if (plugin.xhr) {
            const xhr_tag = 'Uppy.XHRUpload';
            const xhr_msg = this.upload_error;
            const xhr_opt = { ...opt.xhr_opt };
            xhr_opt.endpoint  ||= this._pathProperty.upload;
            xhr_opt.fieldName ||= 'file';
            xhr_opt.timeout   ||= 0; // this.upload_timeout; // NOTE: none for now
            xhr_opt.limit     ||= 1; // NOTE: just to silence warning
            xhr_opt.headers     = { ...xhr_opt.headers, ...opt.xhr_hdr };
            xhr_opt.headers['X-CSRF-Token'] ||= Rails.csrfToken();

            xhr_opt.getResponseData ||=
                function(body, xhr) {
                    const obj = xhr['responseObj'] = fromJSON(body, xhr_tag);
                    return obj || {};
                }

            xhr_opt.getResponseError ||=
                function(body, xhr) {
                    const flash = compact(extractFlashMessage(xhr));
                    const obj   = xhr['responseObj'];
                    const res   = obj || fromJSON(body, xhr_tag);
                    let message = (res?.message || body)?.trim() || xhr_msg;
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
                };

            uppy.use(XHRUpload, xhr_opt);
        }

        return uppy;
    }

    // ========================================================================
    // Protected methods - initialization
    // ========================================================================

    /**
     * Setup handlers for Uppy events that drive the workflow of uploading
     * a file and creating a database entry from it.
     *
     * @protected
     */
    _setupHandlers() {

        const uppy            = this._uppy;
        const feature         = this.feature;
        const debugUppy       = this._debugUppy.bind(this);
        const uppyInfoClear   = this._uppyInfoClear.bind(this);
        const showProgressBar = this.showProgressBar.bind(this);

        const onStart   = this.onStart   || (() => debugUppy('onStart'));
        const onError   = this.onError   || (() => debugUppy('onError'));
        const onSuccess = this.onSuccess || (() => debugUppy('onSuccess'));

        // Events for these features are also applicable to Uppy.Dashboard.
        if (feature.dashboard) {
            feature.replace_input = true;
          //feature.drag_and_drop = true; // NOTE: not currently using d&d
            feature.progress_bar  = true;
            feature.status_bar    = true;
        }

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
         * UppyFileUploadStartParams
         *
         * @typedef {{
         *     id:      string,
         *     fileIDs: string[],
         * }} UppyFileUploadStartData
         */

        /**
         * This event occurs between the 'file-added' and 'upload-started'
         * events.
         *
         * The current value of the submission's database ID applied to the
         * upload endpoint URL in order to correlate the upload with the
         * appropriate workflow.
         *
         * @param {UppyFileUploadStartData} data
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
         * This event occurs when the response from POST /entry/upload is
         * received with a failure status (4xx).
         *
         * @param {Uppy.UppyFile}                  file
         * @param {Error}                          error
         * @param {{status: number, body: string}} [response]
         */
        function onFileUploadError(file, error, response) {
            console.warn('Uppy:', 'upload-error', file, error, response);
            onError(file, error, response);
            uppy.getFiles().forEach(file => uppy.removeFile(file.id));
        }

        /**
         * This event occurs when the response from POST /entry/upload is
         * received with success status (200).  At this point, the file has
         * been uploaded by Shrine, but has not yet been validated.
         *
         * **Implementation Notes**
         * The normal Shrine response has been augmented to include an
         * 'emma_data' object in addition to the fields associated with
         * 'file_data'.
         *
         * @param {Uppy.UppyFile}       file
         * @param {UppyResponseMessage} response
         *
         * @see "Shrine::UploadEndpointExt#make_response"
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
     *
     * @protected
     */
    _setupMessages() {

        const show_info  = this._uppyInfo.bind(this);
        const show_popup = this._uppyPopup.bind(this);
        const show_warn  = this._uppyWarn.bind(this);
        const show_error = this._uppyError.bind(this);
        const debug      = this._debugUppy.bind(this);
        const warn       = this._warn.bind(this);
        const uppy       = this._uppy;
        let event;

        uppy.on((event = 'upload-started'), function(file) {
            warn(event, file);
            show_info(`Uploading "${file.name || file}"`); // TODO: I18n
        });

        uppy.on((event = 'upload-pause'), function(file_id, is_paused) {
            debug(event, file_id, is_paused);
            if (is_paused) {
                show_info('PAUSED');   // TODO: I18n
            } else {
                show_popup('RESUMED'); // TODO: I18n
            }
        });

        uppy.on((event = 'upload-retry'), function(file_id) {
            debug(event, file_id);
            show_warn('Retrying...'); // TODO: I18n
        });

        uppy.on((event = 'retry-all'), function(files) {
            debug(event, files);
            const count   = files ? files.length : 0;
            const uploads = (count === 1) ? 'upload' : `${count} uploads`;
            show_warn(`Retrying ${uploads}...`); // TODO: I18n
        });

        uppy.on((event = 'pause-all'), function() {
            debug(event);
            show_info('Uploading PAUSED'); // TODO: I18n
        });

        uppy.on((event = 'cancel-all'), function() {
            debug(event);
            show_warn('Uploading CANCELED'); // TODO: I18n
        });

        uppy.on((event = 'resume-all'), function() {
            debug(event);
            show_warn('Uploading RESUMED'); // TODO: I18n
        });

        uppy.on((event = 'restriction-failed'), function(file, msg) {
            warn(event, file, msg);
            show_error(msg);
        });

        uppy.on((event = 'error'), function(msg) {
            warn(event, msg);
            show_error(msg);
        });

    }

    /**
     * Set up console debugging messages for other Uppy events.
     *
     * @protected
     */
    _setupDebugging() {
        const events = [
            'complete',
            'progress',
            //'upload-progress', // Handled below
            'reset-progress',
            'file-added',
            'file-removed',
            'preprocess-progress',
            'preprocess-complete',
            'is-offline',
            'is-online',
            'back-online',
            'info-visible',
            'info-hidden',
            'plugin-remove',
            //'state-update',
        ];
        if (this.feature.dashboard) {
            events.push(
                'dashboard:modal-open',
                'dashboard:modal-closed',
                'dashboard:file-edit-start',
                'dashboard:file-edit-complete'
            );
        }
        if (this.feature.image_preview) {
            events.push(
                'thumbnail:request',
                'thumbnail:cancel',
                'thumbnail:error',
                'thumbnail:all-generated'
            );
        }
        if (this.feature.upload_to_aws) {
            events.push('s3-multipart:part-uploaded');
        }

        const uppy  = this._uppy;
        const debug = this._debugUppy.bind(this);

        // Echo the included Uppy events on the console.
        events.forEach(event => {
            const evt = event.toUpperCase().replace(/:/, ': ');
            const tag = '*** ' + evt.replaceAll(/-/g, ' ');
            uppy.on(event, (...args) => debug(tag, ...compact(args)));
        });

        // This event is observed concurrent with the 'progress' event.
        uppy.on('upload-progress', (file, progress) => {
            const bytes = progress.bytesUploaded;
            const total = progress.bytesTotal;
            const pct   = percent(bytes, total);
            debug('uploading', bytes, 'of', total, `(${pct}%)`);
        });
    }

    // ========================================================================
    // Methods - Uppy informer
    // ========================================================================

    /**
     * Invoke `uppy.info` with an error message.
     *
     * @param {string} text
     * @param {number} [duration]
     *
     * @protected
     */
    _uppyError(text, duration) {
        this._uppyPopup(text, duration, 'error');
    }

    /**
     * Invoke `uppy.info` with a warning message.
     *
     * @param {string} text
     * @param {number} [duration]
     *
     * @protected
     */
    _uppyWarn(text, duration) {
        this._uppyPopup(text, duration, 'warning');
    }

    /**
     * Invoke `uppy.info` with a temporary message.
     *
     * @param {string}                   text
     * @param {number}                   [duration]
     * @param {'info'|'warning'|'error'} [info_level]
     *
     * @protected
     */
    _uppyPopup(text, duration, info_level) {
        const time = duration || this.message_duration;
        this._uppyInfo(text, time, info_level);
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
     *
     * @protected
     */
    _uppyInfo(text, duration, info_level) {
        const level = info_level || 'info';
        const time  = duration   || 1000 * MINUTES;
        this._uppy.info(text, level, time);
    }

    /**
     * Invoke `uppy.info` with an empty string and very short duration.
     *
     * @protected
     */
    _uppyInfoClear() {
        this._uppyInfo('', 1);
    }

    // ========================================================================
    // Methods - Uppy progress bar
    // ========================================================================

    /**
     * The element starts with 'aria-hidden="true"' (so that attribute alone
     * alone isn't sufficient for conditional styling), however the element
     * (and its children) are not invisible.
     *
     * @protected
     *
     * @see file:app/assets/stylesheets/vendor/_uppy.scss .uppy-ProgressBar
     */
    _initializeProgressBar() {
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
        const $control = this.$display.find(this.constructor.PROGRESS_BAR);
        toggleVisibility($control, visible);
    }

    // ========================================================================
    // Methods - file selection
    // ========================================================================

    /**
     * InitializeFileSelectOptions
     *
     * @typedef {{
     *     input_id?: string,
     *     label_id?: string,
     *     added?:    function(jQuery),
     * }} InitializeFileSelectOptions
     */

    /**
     * Initialize the Uppy-provided file select button container.
     *
     * @param {InitializeFileSelectOptions} [options]
     *
     * @protected
     */
    _initializeFileSelectContainer(options) {
        const $container = this.fileSelectContainer();
        const tooltip    = this.fileSelectTooltip();
        const label_id   = options?.label_id;
        const input_id   = options?.input_id;
        const OLD_INPUT  = input_id && `input#${input_id}`;
        const NEW_INPUT  = this.constructor.FILE_INPUT;

        // Uppy will replace <input type="file"> with its own mechanisms so
        // the original should not be displayed.
        if (OLD_INPUT) { this.$root.find(OLD_INPUT).css('display', 'none') }

        // Reposition it so that it comes before the display of the uploaded
        // filename.
        $container.insertBefore(this.uploadedFilenameDisplay());

        // This hidden element is inappropriately part of the tab order.
        const input_attr = { tabindex: -1, 'aria-hidden': true };
        if (label_id) { input_attr['aria-labelledby'] = label_id }
        $container.find(NEW_INPUT).attr(input_attr);

        // Set the tooltip for the file select button.
        $container.find('button,label').attr('title', tooltip);
    }

    /**
     * The Uppy-generated element containing the file select button.
     *
     * @returns {jQuery}
     */
    fileSelectContainer() {
        const FILE_SELECT = this.constructor.FILE_SELECT;
        return this.$root.find(FILE_SELECT);
    }

    /**
     * The file select input control.
     *
     * @returns {jQuery}
     */
    fileSelectInput() {
        const FILE_INPUT = 'input[type="file"]';
        return this.fileSelectContainer().children(FILE_INPUT);
    }

    /**
     * The Uppy-generated button standing in for the native file chooser.
     *
     * @returns {jQuery}
     */
    fileSelectButton() {
        const FILE_BUTTON = this.constructor.FILE_BUTTON;
        return this.fileSelectContainer().children(FILE_BUTTON);
    }

    // ========================================================================
    // Methods - file selection controls
    // ========================================================================

    /**
     * Initialize the state of the file select button if applicable to the
     * current form.
     *
     * @returns {jQuery}              The file select button.
     * @protected
     */
    _initializeFileSelectButton() {
        const $button = this.fileSelectButton();
        const label   = this.fileSelectLabel();
        const tip     = this.fileSelectTooltip();
        const cls     = this.constructor.FILE_BUTTON_CLASS;
        const debug   = this._debugUppy.bind(this);
        const handler = this.onSelect || (() => debug(cls));
        handleClickAndKeypress($button, handler);
        $button.siblings('label').attr('title', tip);
        $button.text(label).attr('title', tip).addClass(cls);
        return $button;
    }

    /**
     * Disable the file select button.
     *
     * @returns {jQuery}              The file select button.
     */
    disableFileSelectButton() {
        const $button = this.fileSelectButton();
        const label   = this.fileSelectDisabledLabel();
        const tip     = this.fileSelectDisabledTooltip();
        return $button.text(label).attr('title', tip).addClass('forbidden');
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
     * @param {string} filename
     *
     * @returns {boolean}
     */
    displayFilename(filename) {
        if (!this._updateFilename(filename)) { return false }
        this.hideFilename(false);
        this.hideProgressBar();
        return true;
    }

    /**
     * Update the element containing the selected file name based on its type.
     *
     * @param {String} filename
     * @param {String} [inner]        Interior element holding the name.
     *
     * @returns {boolean}
     * @protected
     */
    _updateFilename(filename, inner = '.filename') {
        if (isMissing(filename)) { return false }
        const $element = this.uploadedFilenameDisplay();
        if (isPresent($element)) {
            const $inner = $element.find(inner);
            if (isPresent($inner)) {
                $inner.text(filename);
            } else {
                $element.text(filename);
            }
            $element.addClass('complete');
        }
        return true;
    }

    /**
     * Hide the selected file name.
     *
     * @param {boolean} [hidden]      If *false*, un-hide.
     */
    hideFilename(hidden) {
        const marker = this.constructor.HIDDEN_MARKER;
        const hide   = notDefined(hidden) || hidden;
        this.uploadedFilenameDisplay().toggleClass(marker, hide);
    }

    /**
     * Indicate whether a selected file name is being displayed.
     *
     * @returns {boolean}
     */
    isFilenameDisplayed() {
        const $element = this.uploadedFilenameDisplay();
        const hidden   = this.constructor.HIDDEN;
        return isPresent($element.text()) && !$element.is(hidden);
    }

    /**
     * The element displaying the uploaded file.
     *
     * @returns {jQuery}
     */
    uploadedFilenameDisplay() {
        return this.$root.find(this.constructor.FILE_NAME);
    }

    // ========================================================================
    // Properties - Uppy plugin targets
    // ========================================================================

    /**
     * Target element to which {@link fileSelectContainer} will be appended by
     * Uppy.
     *
     * @returns {HTMLElement|undefined}
     */
    get fileInputTarget() {
        const $target = this._locateUploader();
        return $target && $target[0];
    }

    /**
     * Uppy drag-and-drop target element (if any).
     *
     * @returns {HTMLElement|undefined}
     */
    get dragTarget() {
        return this._locateTarget(this._uploaderProperty.drag_target);
    }

    /**
     * Thumbnail display of the selected file (if any).
     *
     * @returns {HTMLElement|undefined}
     */
    get previewTarget() {
        return this._locateTarget(this._uploaderProperty.preview);
    }

    // ========================================================================
    // Methods - Uppy plugin targets
    // ========================================================================

    /**
     * Locate target within $enclosure or $root unless it's already an element.
     *
     * @param {Selector} target
     *
     * @returns {HTMLElement|undefined}
     * @protected
     */
    _locateTarget(target) {
        if (!target)                       { return }
        if (target instanceof HTMLElement) { return target }
        if (target instanceof jQuery)      { return target[0] }
        const match = selector(target);
        return this._selfOrDescendentElement(this.$display, match) ||
               this._selfOrDescendentElement(this.$root,    match)
    }

    /**
     * Return the specified target container based on the key signifying an
     * Uppy plugin, with `this.$display` as a fall-back.
     *
     * @param {string} key
     *
     * @returns {HTMLElement}
     * @protected
     */
    _defaultTarget(key) {
        let target;
        switch (key) {
            case 'fi':  target = this.fileInputTarget;  break;
            case 'dd':  target = this.dragTarget;       break;
            case 'ip':  target = this.previewTarget;    break;
        }
        return target || this.$display[0];
    }

    // ========================================================================
    // Methods - file selection status
    // ========================================================================

    /**
     * Indicate whether file select is enabled.
     *
     * @returns {boolean}
     */
    canSelect() {
        return true;
    }

    /**
     * Indicate whether the user has selected a file (which implies that the
     * file has been uploaded for validation).
     *
     * @returns {string|undefined}
     */
    fileSelected() {
        const file_name = this.uploadedFilenameDisplay().text();
        return isPresent(file_name) ? file_name : undefined;
    }

    // ========================================================================
    // Methods - file selection display values
    // ========================================================================

    /**
     * The current label for the file select button.
     *
     * @param {boolean} [can_select]    Default: `canSelect()`.
     *
     * @returns {string}
     */
    fileSelectLabel(can_select) {
        return this._selectProperties('label', can_select) || 'SELECT';
    }

    /**
     * The current tooltip for the file select button.
     *
     * @param {boolean} [can_select]    Default: `canSelect()`.
     *
     * @returns {string|undefined}
     */
    fileSelectTooltip(can_select) {
        return this._selectProperties('tooltip', can_select);
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
     * @protected
     */
    _selectProperties(value, can_select) {
        const op     = this._endpointProperties.select || {};
        const select = isDefined(can_select) ? can_select : this.canSelect();
        const status = select ? op.enabled : op.disabled;
        return status && status[value] || op[value];
    }

    // ========================================================================
    // Properties - configuration
    // ========================================================================

    /**
     * @returns {PathProperties|{}}
     * @protected
     */
    get _pathProperty() {
        return this.property.Path || {};
    }

    /**
     * @returns {UploaderProperties|{}}
     * @protected
     */
    get _uploaderProperty() {
        return this.property.Uploader || {};
    }

    /**
     * Get the configuration properties for the current form action.
     *
     * @returns {EndpointProperties}
     * @protected
     *
     * @see file:../feature/model-form.js endpointProperties
     */
    get _endpointProperties() {
        const config = this.property.Action;
        return this.action && config[this.action] || config.new || {};
    }

    // ========================================================================
    // Methods - diagnostics
    // ========================================================================

    // noinspection JSMethodCanBeStatic
    /**
     * Emit a console message if debugging file uploads.
     *
     * @param {...*} args
     *
     * @protected
     */
    _debugUppy(...args) {
        if (this.debugging) { console.log('Uppy:', ...args) }
    }

}

/**
 * An uploader for an individual item form.
 */
export class SingleUploader extends BaseUploader {

    static CLASS_NAME = 'SingleUploader';
    static DEBUGGING  = DEBUGGING;

    // ========================================================================
    // Type definitions
    // ========================================================================

    /** @typedef {Object.<string,boolean>} States */

    // ========================================================================
    // Constants
    // ========================================================================

    static BUTTON_TRAY_CLASS  = 'button-tray';
    static BEST_CHOICE_MARKER = 'best-choice';

    static BUTTON_TRAY = selector(this.BUTTON_TRAY_CLASS);

    // ========================================================================
    // Fields
    // ========================================================================

    /** @type {States} */ state = {};

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {Selector}            form
     * @param {string}              model
     * @param {UppyFeatures|object} features
     * @param {States}              state
     * @param {UppyCallbacks}       [callbacks]
     */
    constructor(form, model, features, state, callbacks) {
        super(form, model, features, callbacks);
        this.state = { ...this.state, ...state };
    }

    // ========================================================================
    // Properties
    // ========================================================================

    /** @returns {boolean} */ get isCreateForm() { return this.state.new  }
    /** @returns {boolean} */ get isUpdateForm() { return this.state.edit }
    /** @returns {boolean} */ get isBulkOpForm() { return this.state.bulk }

    // ========================================================================
    // Methods - file selection
    // ========================================================================

    /**
     * Initialize the Uppy-provided file select button container.
     *
     * @param {InitializeFileSelectOptions} [options]
     *
     * @protected
     */
    _initializeFileSelectContainer(options) {
        const input_id = `${this.model}_file`;
        const label_id = 'fi_label';
        const opt      = { input_id, label_id, ...options };
        super._initializeFileSelectContainer(opt);
    }

    // ========================================================================
    // Methods - file selection controls
    // ========================================================================

    /**
     * Initialize the state of the file select button if applicable to the
     * current form.
     *
     * @returns {jQuery}              The file select button.
     * @protected
     */
    _initializeFileSelectButton() {
        const $button = super._initializeFileSelectButton();
        if (this.isCreateForm) {
            $button.addClass(this.constructor.BEST_CHOICE_MARKER);
        }
        return $button;
    }

    /**
     * Disable the file select button.
     *
     * @returns {jQuery}              The file select button.
     */
    disableFileSelectButton() {
        const $button = super.disableFileSelectButton();
        $button.removeClass(this.constructor.BEST_CHOICE_MARKER);
        return $button;
    }

    // ========================================================================
    // Properties - Uppy plugin targets
    // ========================================================================

    /**
     * Target element to which {@link fileSelectContainer} will be appended by
     * Uppy.
     *
     * @returns {HTMLElement|undefined}
     */
    get fileInputTarget() {
        const BUTTON_TRAY = this.constructor.BUTTON_TRAY;
        return this._selfOrDescendentElement(this.$root, BUTTON_TRAY);
    }

    // ========================================================================
    // Methods - file selection status
    // ========================================================================

    /**
     * Indicate whether file select is enabled.
     *
     * @returns {boolean}
     */
    canSelect() {
        return !this.fileSelected();
    }

    // ========================================================================
    // Properties - configuration
    // ========================================================================

    /**
     * Get the configuration properties for the current form action.
     *
     * @returns {EndpointProperties}
     * @protected
     *
     * @see file:../feature/model-form.js endpointProperties
     */
    get _endpointProperties() {
        const action = this.property.Action;
        if (this.isBulkOpForm) {
            return this.isUpdateForm ? action.bulk_edit : action.bulk_new;
        } else {
            return this.isUpdateForm ? action.edit      : action.new;
        }
    }

}

/**
 * An uploader intended to have multiple instances on the page.
 */
export class MultiUploader extends BaseUploader {

    static CLASS_NAME = 'MultiUploader';
    static DEBUGGING  = DEBUGGING;

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * If *false* then defer assignment of this._display to initialize() since
     * it may result in render changes.
     *
     * @note Currently manifest-edit.js relies upon this being *true*.
     *
     * @type {boolean}
     */
    static DISPLAY_IN_CTOR = true;

    static VISIBLE_MARKER         = 'visible';
    static DISPLAY_CLASS          = 'uploader-feedback';
    static FILE_TYPE_CLASS        = 'from-uploader';
    static PREPEND_CONTROLS_CLASS = 'uppy-FileInput-container-prepend';
    static APPEND_CONTROLS_CLASS  = 'uppy-FileInput-container-append';

    static DISPLAY          = selector(this.DISPLAY_CLASS);
    static FILE_TYPE        = selector(this.FILE_TYPE_CLASS);
    static PREPEND_CONTROLS = selector(this.PREPEND_CONTROLS_CLASS);
    static APPEND_CONTROLS  = selector(this.APPEND_CONTROLS_CLASS);

    // ========================================================================
    // Fields
    // ========================================================================

    /**
     * Additional input controls added next to the usual file input control.
     *
     * @type {jQuery}
     */
    $added_controls = $(null);

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {Selector}            root
     * @param {string}              model
     * @param {UppyFeatures|object} features
     * @param {UppyCallbacks}       [callbacks]
     */
    constructor(root, model, features, callbacks) {
        super(root, model, features, callbacks);
        if (this.constructor.DISPLAY_IN_CTOR) {
            this._display = this._locateDisplay();
        }
    }

    // ========================================================================
    // Protected methods
    // ========================================================================

    /**
     * Find or create the popup element for containing Uppy plugin output
     * elements.
     *
     * @param {Selector} [target]     Default: `this.$root`.
     *
     * @returns {jQuery}
     * @protected
     */
    _locateDisplay(target) {
        const match   = this.constructor.DISPLAY;
        const $target = target ? $(target) : this.$root;
        let $display  = this._selfOrDescendent($target, match);
        if (isPresent($display)) { return $display }
        $display = $(match);
        if (isPresent($display)) { return $display }
        $display = $('<div>').addClass(this.constructor.DISPLAY_CLASS);
        $('body').append($display);
        return $display;
    }

    // ========================================================================
    // Methods - actions
    // ========================================================================

    /**
     * Invoked by the originating form to indicate that it is in a canceling
     * state.
     */
    cancel() {
        super.cancel();
        this.closeDisplay();
    }

    // ========================================================================
    // Protected methods - initialization
    // ========================================================================

    /**
     * Setup handlers for Uppy events that drive the workflow of uploading
     * a file and creating a database entry from it.
     *
     * @protected
     */
    _setupHandlers() {
        super._setupHandlers();
        this._uppy.on('upload',   () => this.openDisplay());
        this._uppy.on('complete', () => this.closeDisplay());
    }

    // ========================================================================
    // Methods - file selection
    // ========================================================================

    /**
     * Initialize the Uppy-provided file select button container.
     *
     * @param {InitializeFileSelectOptions} [options]
     *
     * @protected
     */
    _initializeFileSelectContainer(options) {
        const $elements = this.$root.children('[aria-labelledby]');
        const label_id  = $elements.first().attr('aria-labelledby');
        const opt       = { label_id, ...options };
        super._initializeFileSelectContainer(opt);

        // Inject copies of additional controls if present.
        const pre  = this.constructor.PREPEND_CONTROLS;
        const app  = this.constructor.APPEND_CONTROLS;
        const $pre = this._addFileSelectControls(pre, true);
        const $app = this._addFileSelectControls(app, false);
        this.$added_controls = $([...$pre.toArray(), ...$app.toArray()]);
        if (options?.added && isPresent(this.$added_controls)) {
            options.added(this.$added_controls);
        }
    }

    // ========================================================================
    // Methods - file selection controls
    // ========================================================================

    /**
     * Add controls to {@link fileSelectContainer}.
     *
     * (The originals are preserved so that they will be there if the
     * associated item is cloned.)
     *
     * @param {Selector} selector
     * @param {boolean}  [prepend]
     *
     * @returns {jQuery}
     * @protected
     */
    _addFileSelectControls(selector, prepend) {
        const $element = this.$root.find(selector);
        const $clones  = $element.children().clone();
        if (isPresent($clones)) {
            const tag   = '0';
            const attrs = [...ID_ATTRIBUTES, 'data-id'];
            $clones.each((_, element) => uniqAttrs(element, tag, attrs, true));
            if (prepend) {
                this.fileSelectContainer().prepend($clones);
            } else {
                this.fileSelectContainer().append($clones);
            }
        }
        // Just to be sure (although this should already be the case):
        $element.toggleClass(this.constructor.HIDDEN_MARKER, true);
        return $clones;
    }

    /**
     * Initialize the state of the file select button.
     *
     * @returns {jQuery}              The file select button.
     * @protected
     */
    _initializeFileSelectButton() {
        const file_type = this.constructor.FILE_TYPE_CLASS;
        return super._initializeFileSelectButton().addClass(file_type);
    }

    /**
     * Update the element containing the selected file name based on its type.
     *
     * @param {String} filename
     * @param {String} [inner]        Interior element holding the name.
     *
     * @returns {boolean}
     * @protected
     */
    _updateFilename(filename, inner = this.constructor.FILE_TYPE) {
        if (!super._updateFilename(filename, inner)) { return false }
        this.uploadedFilenameDisplay().children().each((_, line) => {
            const $line  = $(line);
            const active = $line.is(inner);
            $line.attr('aria-hidden', !active);
            $line.toggleClass('active', active);
        });
        return true;
    }

    // ========================================================================
    // Methods
    // ========================================================================

    openDisplay()  { this.toggleDisplay(true) }
    closeDisplay() { this.toggleDisplay(false) }

    /**
     * Toggle the state of the informational display elements.
     *
     * @param {boolean} [open]
     */
    toggleDisplay(open) {
        this._debug('toggleDisplay open =', open);
        this.$display.toggleClass(this.constructor.VISIBLE_MARKER, open);
    }
}
