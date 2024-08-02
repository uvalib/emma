// app/assets/javascripts/shared/uploader.js


import { AppDebug }                              from '../application/debug';
import { arrayWrap, uniq }                       from './arrays';
import { Emma }                                  from './assets';
import { BaseClass }                             from './base-class';
import { pageAction }                            from './controller';
import { isHidden, selector, toggleHidden }      from './css';
import { isDefined, isMissing, isPresent }       from './definitions';
import { extractFlashMessage }                   from './flash';
import { percent }                               from './math';
import { CONTROL_GROUP }                         from './nav-group';
import { compact, deepFreeze, fromJSON, hasKey } from './objects';
import { camelCase }                             from './strings';
import { MINUTES, SECONDS }                      from './time';
import { makeUrl }                               from './url';
import { Rails }                                 from '../vendor/rails';
import {
    toggleVisibility,
    handleClickAndKeypress,
} from './accessibility';
import {
    ID_ATTRIBUTES,
    selfOrDescendents,
    uniqAttrs,
} from './html';
import {
    Uppy,
    AwsS3,
    Box,
    Dashboard,
    DragDrop,
    Dropbox,
    FileInput,
    GoogleDrive,
    Informer,
    OneDrive,
    ProgressBar,
    StatusBar,
    ThumbnailGenerator,
    Url,
    XHRUpload,
} from '../vendor/uppy';


const MODULE = 'BaseUploader';
const DEBUG  = true;

AppDebug.file('shared/uploader', MODULE, DEBUG);

// ============================================================================
// Temporary (?) type definitions for Uppy
//
// NOTE: As of Uppy 4.0.0, which is implemented in TypeScript, JSDoc type
//  comments relating to Uppy do not resolve in a way that's helpful, so they
//  are explicitly defined here.  (It's not clear whether this is the fault of
//  RubyMine, Uppy, or my own misunderstanding.)
// ============================================================================

/**
 * @typedef FileProcessingInfo
 *
 * @property {'determinate'|'indeterminate'} mode
 * @property {string}                        [message]
 * @property {number}                        [value]
 *
 * @see file://${PROJ_DIR}/node_modules/@uppy/utils/src/FileProgress.ts
 */

/**
 * @typedef FileProgress
 *
 * @property {boolean}              [uploadComplete]
 * @property {number}               [percentage]
 * @property {number|null}          bytesTotal
 * @property {FileProcessingInfo}   [preprocess]
 * @property {FileProcessingInfo}   [postprocess]
 * @property {number}               uploadStarted
 * @property {number}               bytesUploaded
 *
 * @see file://${PROJ_DIR}/node_modules/@uppy/utils/src/FileProgress.ts
 */

/**
 * @typedef UppyFileRemote
 *
 * @property {Object.<string,*>}    [body]
 * @property {string}               companionUrl
 * @property {string}               [host]
 * @property {string}               [provider]
 * @property {string}               [providerName]
 * @property {string}               requestClientId
 * @property {string}               url
 */

/**
 * @typedef UppyFileResponse
 *
 * @property {object}   [body]
 * @property {number}   status
 * @property {number}   [bytesUploaded]
 * @property {string}   [uploadURL]
 */

/**
 * @typedef {Uppy.UppyFile} UppyFile
 *
 * @property {Blob|File}        data
 * @property {string|null}      [error]
 * @property {string}           extension
 * @property {string}           id
 * @property {boolean}          [isPaused]
 * @property {boolean}          [isRestored]
 * @property {boolean}          isRemote
 * @property {boolean}          isGhost
 * @property {object}           meta
 * @property {string}           [name]
 * @property {string}           [preview]
 * @property {FileProgress}     progress
 * @property {string[]}         [missingRequiredMetaFields]
 * @property {UppyFileRemote}   [remote]
 * @property {string|null}      [serverToken]
 * @property {number|null}      size
 * @property {string}           [source]
 * @property {string}           type
 * @property {string}           [uploadURL]
 * @property {UppyFileResponse} [response]
 *
 * @see file://${PROJ_DIR}/node_modules/@uppy/utils/src/UppyFile.ts
 */

/**
 * @typedef {Object.<string,UppyFile>} UppyFiles
 */

/**
 * @typedef UppyOptions
 *
 * @property {string}                       [id]
 * @property {boolean}                      [autoProceed]
 * @property {boolean}                      [allowMultipleUploads] Deprecated
 * @property {boolean}                      [allowMultipleUploadBatches]
 * @property {object}                       [logger]
 * @property {boolean}                      [debug]
 * @property {object}                       [restrictions]
 * @property {object}                       [meta]
 * @property {function(UppyFile,UppyFiles)} [onBeforeFileAdded]
 * @property {function(UppyFiles)}          [onBeforeUpload]
 * @property {object}                       [locale]
 * @property {object}                       [store]
 * @property {number}                       [infoTimeout]
 */

/**
 * @typedef {
 *  function(xhr: XMLHttpRequest, retryCount: number): void|Promise<void>
 * } XhrCallback
 */

/**
 * @typedef {function(xhr: XMLHttpRequest): boolean} XhrRetryCallback
 */

/**
 * @typedef XhrUploadOpts
 *
 * @property {object}                       [locale]
 * @property {string}                       [id]
 * @property {string}                       endpoint
 * @property {string}                       [method]
 * @property {boolean}                      [formData]
 * @property {string}                       [fieldName]
 * @property {object}                       [headers]
 * @property {number}                       [timeout]
 * @property {number}                       [limit]
 * @property {XMLHttpRequestResponseType}   [responseType]
 * @property {boolean}                      [withCredentials]
 * @property {XhrCallback}                  [onBeforeRequest]
 * @property {XhrRetryCallback}             [shouldRetry]
 * @property {XhrCallback}                  [onAfterResponse]
 * @property {boolean|string[]}             [allowedMetaFields]
 * @property {boolean}                      [bundle]
 *
 * @see https://uppy.io/docs/xhr-upload/#api
 * @see file://${PROJ_DIR}/node_modules/@uppy/core/src/BasePlugin.ts  "PluginOpts"
 * @see file://${PROJ_DIR}/node_modules/@uppy/xhr-upload/src/index.ts "XhrUploadOpts"
 */

// ============================================================================
// Type definitions
// ============================================================================

/**
 * Uppy plugin selection plus other optional settings.
 *
 * @typedef UppyFeatures
 *
 * @property {boolean} [replace_input]      Hide the `<input type="file">`
 *                                              present in the container. <p/>
 * @property {boolean} [popup_messages]     Popup event/status messages. <p/>
 * @property {boolean} [progress_bar]       Minimal upload progress bar. <p/>
 * @property {boolean} [status_bar]         Heftier progress and control bar. <p/>
 * @property {boolean} [dashboard]          Uppy dashboard. <p/>
 * @property {boolean} [drag_and_drop]      Drag-and-drop file selection enabled. <p/>
 * @property {boolean} [image_preview]      Image preview thumbnail. <p/>
 * @property {boolean} [flash_messages]     Display flash messages. <p/>
 * @property {boolean} [flash_errors]       Display flash error messages. <p/>
 * @property {boolean} [upload_to_aws]      Cloud upload enabled. <p/>
 * @property {boolean} [upload_to_box]      Upload to Box enabled. <p/>
 * @property {boolean} [upload_to_dropbox]  Upload to Dropbox enabled. <p/>
 * @property {boolean} [upload_to_google]   Upload to Google Drive enabled. <p/>
 * @property {boolean} [upload_to_onedrive] Upload to Microsoft OneDrive enabled. <p/>
 * @property {boolean} [url]                TODO: ... <p/>
 * @property {boolean} [xhr]                Upload to server enabled. <p/>
 * @property {boolean} [debugging]          Turn on Uppy debugging. <p/>
 */

/**
 * A live copy of Uppy features.
 *
 * @typedef {UppyFeatures} UppyFeatureSettings
 *
 * @property {boolean}             replace_input
 * @property {boolean}             popup_messages
 * @property {boolean}             progress_bar
 * @property {boolean}             status_bar
 * @property {boolean}             dashboard
 * @property {boolean|HTMLElement} [drag_and_drop]
 * @property {boolean|HTMLElement} [image_preview]
 * @property {boolean}             flash_messages
 * @property {boolean}             flash_errors
 * @property {boolean}             upload_to_aws
 * @property {boolean}             upload_to_box
 * @property {boolean}             upload_to_dropbox
 * @property {boolean}             upload_to_google
 * @property {boolean}             upload_to_onedrive
 * @property {boolean}             url
 * @property {boolean}             xhr
 * @property {boolean}             debugging
 */

/**
 * Shrine upload response message.
 *
 * @typedef { EmmaData | {error: string} } EmmaDataOrError
 */

/**
 * Shrine upload response message.
 *
 * @typedef {object} ShrineResponseBody
 *
 * @property {EmmaDataOrError}  [emma_data]
 * @property {string}           id
 * @property {string}           storage
 * @property {FileDataMetadata} metadata
 *
 * @see "Shrine::UploadEndpointExt#make_response"
 */

/**
 * Uppy upload response message.
 *
 * @typedef {object} UppyResponseMessage
 *
 * @property {number}             status
 * @property {ShrineResponseBody} body
 * @property {string}             uploadURL
 */

// ============================================================================
// Constants
// ============================================================================

/**
 * Uppy plugin selection plus other optional settings.
 *
 * @readonly
 * @type {UppyFeatures}
 */
const FEATURES = deepFreeze({
    replace_input:      true  && !!FileInput,
    popup_messages:     true  && !!Informer,
    progress_bar:       true  && !!ProgressBar,
    status_bar:         false && !!StatusBar,
    dashboard:          false && !!Dashboard,
    drag_and_drop:      false && !!DragDrop,
    image_preview:      false && !!ThumbnailGenerator,
    upload_to_aws:      false && !!AwsS3,
    upload_to_box:      false && !!Box,
    upload_to_dropbox:  false && !!Dropbox,
    upload_to_google:   false && !!GoogleDrive,
    upload_to_onedrive: false && !!OneDrive,
    url:                false && !!Url,
    xhr:                true  && !!XHRUpload, // NOTE: Always used.
});

/**
 * How long to wait for the server to confirm the upload. <p/>
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
const UPLOAD_ERROR_MESSAGE = Emma.Messages.uploader.error;

/**
 * Indicate whether UppyFile should be overridden to force its "Content-Type"
 * to include an explicit ";charset=utf-8".
 *
 * @type {boolean}
 */
const FORCE_CHARSET = false;

const UPLOADER_CLASS        = 'file-uploader';
const UPPY_ROOT_CLASS       = 'uppy-Root';
const FILE_SELECT_CLASS     = 'uppy-FileInput-container';
const FILE_INPUT_CLASS      = 'uppy-FileInput-input';
const FILE_BUTTON_CLASS     = 'uppy-FileInput-btn';
const INFORMER_CLASS        = 'uppy-Informer';
const PROGRESS_BAR_CLASS    = 'uppy-ProgressBar';
const FILE_NAME_CLASS       = 'uploaded-filename';
const UPLOADED_NAME_CLASS   = 'uploaded-filename';

export const UPLOADER       = selector(UPLOADER_CLASS);
export const UPPY_ROOT      = selector(UPPY_ROOT_CLASS);
export const FILE_SELECT    = selector(FILE_SELECT_CLASS);
export const FILE_INPUT     = selector(FILE_INPUT_CLASS);
export const FILE_BUTTON    = selector(FILE_BUTTON_CLASS);
export const INFORMER       = selector(INFORMER_CLASS);
export const PROGRESS_BAR   = selector(PROGRESS_BAR_CLASS);
export const FILE_NAME      = selector(FILE_NAME_CLASS);
export const UPLOADED_NAME  = selector(UPLOADED_NAME_CLASS);

const STATE     = Emma.Messages.uploader.state;
const PAUSED    = Emma.Messages.uploader.paused.toUpperCase();
const RESUMED   = Emma.Messages.uploader.resumed.toUpperCase();

/**
 * The names of events defined by Uppy.
 *
 * @type {string[]}
 *
 * @see file://${PROJ_DIR}/node_modules/@uppy/core/src/Uppy.ts "_UppyEventMap"
 * @see file://${PROJ_DIR}/node_modules/@uppy/core/src/Uppy.ts "UppyEventMap"
 */
const UPPY_EVENTS = [
    'back-online',
    'cancel-all',
    'complete',
    'error',
    'file-added',
    'file-removed',
    'files-added',
    'info-hidden',
    'info-visible',
    'is-offline',
    'is-online',
    'pause-all',
    'plugin-added',
    'plugin-remove',
    'postprocess-complete',
    'postprocess-progress',
    'preprocess-complete',
    'preprocess-progress',
    'progress',
    'restored',
    'restore-confirmed',
    'restore-canceled',
    'restriction-failed',
    'resume-all',
    'retry-all',
  //'state-update',         // Redundant and too frequent to be useful.
    'upload',
    'upload-error',
    'upload-pause',
    'upload-progress',
    'upload-retry',
    'upload-stalled',
    'upload-start',
    'upload-success',
];

// ============================================================================
// Class BaseUploader
// ============================================================================

// noinspection LocalVariableNamingConventionJS
/**
 * An uploader using Uppy and Shrine.
 *
 * @extends BaseClass
 */
class BaseUploader extends BaseClass {

    static CLASS_NAME = 'BaseUploader';
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Type definitions
    // ========================================================================

    /**
     * @typedef UppyCallbacks
     *
     * @property {function} [onSelect]
     * @property {function} [onStart]
     * @property {function} [onProgress]
     * @property {function} [onError]
     * @property {function} [onSuccess]
     */

    /**
     * @typedef {Uppy.BasePlugin|false|undefined} UppyPluginTableEntry
     */

    /**
     * Table of keys whose value is the activation setting of the related
     * Uppy plugin.  If active, the table value is the plugin class.
     *
     * @typedef UppyPluginTable
     *
     * @property {UppyPluginTableEntry} db      dashboard
     * @property {UppyPluginTableEntry} fi      replace_input
     * @property {UppyPluginTableEntry} dd      drag_and_drop
     * @property {UppyPluginTableEntry} pb      progress_bar
     * @property {UppyPluginTableEntry} pm      progress_bar
     * @property {UppyPluginTableEntry} sb      status_bar
     * @property {UppyPluginTableEntry} ip      image_preview
     * @property {UppyPluginTableEntry} aws     upload_to_aws
     * @property {UppyPluginTableEntry} box     upload_to_box
     * @property {UppyPluginTableEntry} dbx     upload_to_dropbox
     * @property {UppyPluginTableEntry} gdr     upload_to_google
     * @property {UppyPluginTableEntry} odr     upload_to_onedrive
     * @property {UppyPluginTableEntry} url     url
     * @property {UppyPluginTableEntry} xhr     xhr
     */

    /**
     * @typedef UppyPluginOptions
     *
     * @property {Selector}     [db_target]
     * @property {Selector}     [fi_target]
     * @property {Selector}     [dd_target]
     * @property {Selector}     [pb_target]
     * @property {Selector}     [sb_target]
     * @property {Selector}     [pm_target]
     * @property {object}       [db_opt]
     * @property {object}       [fi_opt]
     * @property {object}       [dd_opt]
     * @property {object}       [pb_opt]
     * @property {object}       [sb_opt]
     * @property {object}       [pm_opt]
     * @property {object}       [ip_opt]
     * @property {object}       [aws_opt]
     * @property {object}       [box_opt]
     * @property {object}       [dbx_opt]
     * @property {object}       [gdr_opt]
     * @property {object}       [odr_opt]
     * @property {object}       [url_opt]
     * @property {object}       [xhr_opt]
     * @property {object}       [xhr_hdr]
     * @property {StringTable}  [fi_string]
     */

    /**
     * @typedef UploaderOptions
     *
     * @property {boolean}              [force]
     * @property {string}               [controller]
     * @property {string}               [action]
     * @property {UppyOptions}          [uppy]
     * @property {UppyPluginOptions}    [plugin]
     * @property {function(Selector)}   [added]
     */

    // ========================================================================
    // Fields
    // ========================================================================

    /** @type {string}              */ model;
    /** @type {string}              */ controller;
    /** @type {string}              */ action;
    /** @type {function|undefined}  */ onSelect;
    /** @type {function|undefined}  */ onStart;
    /** @type {function|undefined}  */ onProgress;
    /** @type {function|undefined}  */ onError;
    /** @type {function|undefined}  */ onSuccess;
    /** @type {number}              */ //upload_timeout = UPLOAD_TIMEOUT;
    /** @type {number}              */ message_duration = MESSAGE_DURATION;
    /** @type {string}              */ upload_error     = UPLOAD_ERROR_MESSAGE;
    /** @type {ModelProperties}     */ property         = {};
    /** @type {UppyFeatureSettings} */ feature          = FEATURES;

    /** @type {jQuery}              */ _root;
    /** @type {jQuery}              */ _display;
    /** @type {Uppy.Uppy}           */ _uppy;

    /**
     * Default options for the Uppy instance.
     *
     * @type {UppyOptions}
     */
    _options = {
        debug:       this.feature.debugging,
        autoProceed: true,
    };

    /**
     * Used to track the handling of known Uppy events.
     *
     * @type {string[]}
     * @private
     */
    _unhandled_events = [...UPPY_EVENTS];

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
        this._root      = this._locateUploader(root) || $(root);
        this.model      = model;
        this.controller = model;
        this.action     = pageAction();
        this.onSelect   = callbacks?.onSelect;
        this.onStart    = callbacks?.onStart;
        this.onProgress = callbacks?.onProgress;
        this.onError    = callbacks?.onError;
        this.onSuccess  = callbacks?.onSuccess;
        this.property   = Emma[camelCase(model)] || {};
        this.feature    = { ...FEATURES, debugging: DEBUG, ...features };
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

    // ========================================================================
    // Properties - internal
    // ========================================================================

    /**
     * Table of keys whose value is the activation setting of the related
     * Uppy plugin.  If active, the table value is the plugin class.
     *
     * @returns {UppyPluginTable}
     * @protected
     */
    get _plugin() {
        return {
            db:  this.feature.dashboard             && Dashboard,
            fi:  this.feature.replace_input         && FileInput,
            dd:  this.feature.drag_and_drop         && DragDrop,
            pb:  this.feature.progress_bar          && ProgressBar,
            sb:  this.feature.status_bar            && StatusBar,
            pm:  this.feature.popup_messages        && Informer,
            ip:  this.feature.image_preview         && ThumbnailGenerator,
            aws: this.feature.upload_to_aws         && AwsS3,
            box: this.feature.upload_to_box         && Box,
            dbx: this.feature.upload_to_dropbox     && Dropbox,
            gdr: this.feature.upload_to_google      && GoogleDrive,
            odr: this.feature.upload_to_onedrive    && OneDrive,
            url: this.feature.url                   && Url,
            xhr: this.feature.xhr                   && XHRUpload,
        };
    }

    /** @returns {boolean} */
    get _debugging() {
        return (this.feature?.debugging !== false) && super._debugging;
    }

    // ========================================================================
    // Methods - internal
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
        this._debug('_locateDisplay ->', $result);
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
        const $result = this._selfOrDescendent(tgt, UPLOADER);
        this._debug('_locateUploader ->', $result);
        return $result;
    }

    /**
     * The target or the first matching descendent.
     *
     * @param {Selector} target
     * @param {string}   match
     *
     * @returns {jQuery|undefined}
     * @protected
     */
    _selfOrDescendent(target, match) {
        const $result = selfOrDescendents(target, match).first();
        return isPresent($result) ? $result : undefined;
    }

    /**
     * The target or the first matching descendent.
     *
     * @param {Selector} target
     * @param {string}   match
     *
     * @returns {HTMLElement|undefined}
     * @protected
     */
    _selfOrDescendentElement(target, match) {
        const $result = this._selfOrDescendent(target, match);
        return $result && $result[0];
    }

    // ========================================================================
    // Methods - actions
    // ========================================================================

    /**
     * Invoked by the originating form to indicate that it is in a canceling
     * state.
     */
    cancel() {
        this._debug('cancel');
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
        this._debug('initialize: options =', options);
        const marked = this.isUppyInitialized();
        const loaded = !!this._uppy;
        let init, warn;
        if (!marked && !loaded) {
            init = true;
        } else if (marked) {
            warn = 'container has SELECTOR but this._uppy is missing';
        } else if (loaded) {
            warn = 'this._uppy is present but container missing SELECTOR';
        } else {
            init = options?.force;
        }
        if (warn) {
            init = true;
            warn = warn.replaceAll('SELECTOR', UPPY_ROOT);
            this._warn(`re-initializing: ${warn}`);
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
        const $uppy_added = this._selfOrDescendent(this.$display, UPPY_ROOT);
        this._debug('isUppyInitialized ->', $uppy_added);
        return isPresent($uppy_added);
    }

    /**
     * Initialize Uppy file uploader.
     *
     * @param {UploaderOptions} [options]
     */
    initializeUppy(options) {
        this._debug('initializeUppy: options =', options);

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
        this._debug('buildUppy: options =', options);

        /** @type {UppyPluginOptions} */
        const opt  = { ...options?.plugin };
        const uppy = new Uppy.Uppy(this._uppyOptions(options));

        const load_plugin = (p_key, p_opt = {}) => {
            const plugin = this._plugin[p_key];
            if (!plugin) { return false }
            const [tgt, tgt_opt] = [`${p_key}_target`, `${p_key}_opt`];
            const plugin_opt = { target: opt[tgt], ...p_opt, ...opt[tgt_opt] };
            plugin_opt.target &&= this._locateTarget(plugin_opt.target);
            plugin_opt.target ||= this._defaultTarget(p_key);
            uppy.use(plugin, plugin_opt);
            return true;
        };

        if (this._plugin.db) {
            load_plugin('db', { inline: true });
        } else {
            if (this._plugin.fi) {
                const fi_label  = this.fileSelectLabel(true);
                const fi_string = { chooseFiles: fi_label, ...opt.fi_string };
                load_plugin('fi', { locale: { strings: fi_string } });
            }
            load_plugin('dd');
            load_plugin('pb');
            load_plugin('sb', { showProgressDetails: true });
        }
        load_plugin('pm');
        load_plugin('ip', { thumbnailWidth: 400 });

        if (this._plugin.aws) {
            const aws_opt = {
              //limit:      2,
                timeout:    this.upload.timeout,
                endpoint:   'https://companion.myapp.com/', // TODO: ???
            };
            load_plugin('aws', aws_opt);
        }
        load_plugin('box');
        load_plugin('dbx');
        load_plugin('gdr');
        load_plugin('odr');
        load_plugin('url');

        if (this._plugin.xhr) {
            const xhr_opt = this._xhrOptions(opt.xhr_opt, opt.xhr_hdr);
            delete opt.xhr_opt;
            load_plugin('xhr', xhr_opt);
        }

        return uppy;
    }

    // ========================================================================
    // Methods - initialization - options - internal
    // ========================================================================

    /**
     * Options for Uppy.
     *
     * @param {UploaderOptions} [options]
     *
     * @returns {UppyOptions}
     * @protected
     */
    _uppyOptions(options) {
        /** @type {UppyOptions} */
        const opt = { ...this._options, ...options?.uppy };
        opt.id                ||= `uppy-${this.$root.attr('id') || 0}`;
        opt.onBeforeFileAdded ||= this._onBeforeFileAdded.bind(this);
        opt.onBeforeUpload    ||= this._onBeforeUpload.bind(this);
        return opt;
    }

    /**
     * Called at the start of {@link Uppy.addFile} and {@link Uppy.addFiles}.
     *
     * If it returns *false* the file will be rejected and won't be part of the
     * upload.  If it returns an UppyFile, that is assumed to be a replacement
     * for the original in the Uppy #checkAndUpdateFileState method.  Any other
     * return indicates that the file should be uploaded as-is.
     *
     * @param {UppyFile}  file
     * @param {UppyFiles} files  Table of already-added files.
     *
     * @returns {UppyFile|boolean}
     *
     * @protected
     */
    _onBeforeFileAdded(file, files) {
        const func = '_onBeforeFileAdded';
        this._debug(`${func}:`, file, '; files =', files);
        if (this._debugging && (file.data instanceof Blob)) {
            file.data.text().then(text => {
                const data_text   = `${func}: data.text()`;
                const well_formed = text.isWellFormed();
                const normalized  = text.normalize();
                this._debug(`${data_text}.isWellFormed() =`, well_formed);
                this._debug(`${data_text}.length =`, text.length);
                //this._debug(`${data_text} =`, v);
                if (normalized.length !== text.length) {
                    const data_norm = `${data_text}.normalize()`;
                    this._debug(`${data_norm}.length =`, normalized.length);
                    //this._debug(`${data_norm} =`, normalized);
                }
                if (!well_formed) {
                    const data_wf = `${data_text}.toWellFormed()`;
                    const val     = text.toWellFormed();
                    const nrm     = val.normalize();
                    this._debug(`${data_wf}.length =`, val.length);
                    //this._debug(`${data_wf} =`, val);
                    if (nrm.length !== val.length) {
                        const data_nrm_wf = `${data_wf}.normalize()`;
                        const nrm_wf      = nrm.isWellFormed();
                        this._debug(`${data_nrm_wf}.isWellFormed() =`, nrm_wf);
                        this._debug(`${data_nrm_wf}.length =`, nrm.length);
                        //this._debug(`${data_nrm_wf} =`, nrm);
                    }
                }
            });
            file.data.arrayBuffer().then(ab => {
                const data_array = `${func}: data.arrayBuffer()`;
                this._debug(`${data_array} =`, ab);
            });
        }
        return !Object.hasOwn(files, file.id);
    }

    /**
     * Called in {@link Uppy.upload} before the 'upload' event.
     *
     * If it returns *false* the upload will be aborted.  If it returns an
     * Object, that is assumed to be a replacement for the original file table.
     * Any other return indicates that the upload should proceed as-is.
     *
     * @param {UppyFiles} files
     *
     * @returns {UppyFiles|boolean}
     *
     * @protected
     */
    _onBeforeUpload(files) {
        const func = '_onBeforeUpload';
        this._debug(`${func}: files =`, files);
        if (FORCE_CHARSET) {
            for (const [_id, file] of Object.entries(files)) {
                this._forceCharset(file);
            }
        }
        return files;
    }

    /**
     * Force transmission of the file as UTF-8.
     *
     * This requires supplanting Uppy's normal generation of a FormData
     * in {@link XHRUpload.createFormDataUpload} by constructing it here so
     * that "multipart/form-data" has an explicit ";charset=utf-8" modifier in
     * this file's form data part.
     *
     * @param {UppyFile} file         The file to modify.
     * @param {string}   [charset]
     *
     * @returns {UppyFile}            The *file* with modified data entry.
     *
     * @protected
     *
     * @see XHRUpload.createFormDataUpload
     * @see  * @see file://${PROJ_DIR}/node_modules/@uppy/xhr-upload/src/index.ts "XHRUpload#uploadLocalFile"
     */
    _forceCharset(file, charset = 'utf-8') {
        const func = `_forceCharset(${charset})`;
        if (file.data instanceof Blob) {
            this._debug(`${func}: file =`, file);
            const xhr  = this._uppy.getPlugin('XHRUpload');
            const size = file.data.size;
            const meta = file.meta || {};
            const name = meta.name;
            const type = meta.type || 'application/octet-stream';
            const cset = `charset=${charset}`;
            const data = file.data.slice(0, size, `${type};${cset}`);
            // noinspection JSUnresolvedReference
            const opts = xhr.getOptions(file);
            const post = new FormData();
            // noinspection JSUnresolvedReference
            xhr.addMetadata(post, meta, opts);
            if (name) {
                post.append(opts.fieldName, data, name);
            } else {
                post.append(opts.fieldName, data);
            }
            // noinspection JSValidateTypes
            file.data = post;
        } else {
            this._debug(`${func}: SKIPPED FOR file =`, file);
        }
        return file;
    }

    // ========================================================================
    // Methods - initialization - XHR - internal
    // ========================================================================

    /**
     * Options for the XHRUpload plugin.
     *
     * @param {XhrUploadOpts} [opt]
     * @param {object}        [headers]
     *
     * @returns {XhrUploadOpts}
     * @protected
     *
     * @see https://uppy.io/docs/xhr-upload/#api
     */
    _xhrOptions(opt, headers) {
        /** @type {XhrUploadOpts} */
        const xhr_opt = { ...opt };

        xhr_opt.headers  = { ...xhr_opt.headers, ...headers };
        xhr_opt.headers['X-CSRF-Token'] ||= Rails.csrfToken();

        xhr_opt.endpoint        ||= this._pathProperty.upload;
        xhr_opt.fieldName       ||= 'file';
        xhr_opt.limit           ||= 1; // NOTE: just to silence warning
        xhr_opt.timeout         ||= 0; // this.upload_timeout; // NOTE: for now
        xhr_opt.onBeforeRequest ||= this._xhrBeforeRequest.bind(this);

        if (FORCE_CHARSET && !Object.hasOwn(xhr_opt, 'formData')) {
            xhr_opt.formData = false;
        }

        return xhr_opt;
    }

    /**
     * Called before the upload action is started.
     *
     * Prior to Uppy 4.0.0, the "getResponseError" callback supported the
     * ability to replace the default NetworkError with an Error instance that
     * contained the flash message generated by the server.  Now, with that
     * callback removed, this function must override the "onload" handler set
     * within the Uppy "fetcher" function in order to add the flash message to
     * the response object for {@link _onFileUploadError} to use.
     *
     * @param {XMLHttpRequest} xhr
     * @param {number}         retry_count
     *
     * @protected
     *
     * @see https://uppy.io/docs/xhr-upload/#onafterresponse
     * @see file://${PROJ_DIR}/node_modules/@uppy/utils/src/fetcher.ts
     */
    _xhrBeforeRequest(xhr, retry_count) {
        this._debug('_xhrBeforeRequest; xhr =', xhr, 'retry =', retry_count);
        const uppy_onload = xhr.onload;
        xhr.onload = async () => {
            this._debug('_xhrBeforeRequest | onload | init xhr =', xhr);
            const status  = xhr.status;
            const state   = xhr.readyState;
            const net_err = !status || ((state !== 0) && (state !== 4));
            const ok      = !net_err && (200 <= status) && (status < 300);
            if (!ok && !net_err) {
                const resp  = fromJSON(xhr.response, 'Uppy.XHRUpload');
                const text  = resp?.message || xhr.response;
                let msg     = text?.trim() || this.upload_error;
                const flash = compact(extractFlashMessage(xhr));
                if (isPresent(flash)) {
                    const nl = (flash.length > 1) ? "\n" : ' ';
                    msg = msg.replace(/([^:])$/, '$1:') + nl + flash.join(nl);
                } else {
                    msg = msg.replace(/:$/, '');
                }
                xhr['flash-message'] = msg;
                this._debug('_xhrBeforeRequest | onload | now xhr =', xhr);
            }
            await uppy_onload(undefined);
        }
    }

    // ========================================================================
    // Methods - initialization - handlers - internal
    // ========================================================================

    /**
     * Add a handler for an Uppy event.
     *
     * @param {string}   event
     * @param {function} callback
     *
     * @protected
     */
    _uppyEvent(event, callback) {
        this._uppy.on(event, callback);
        delete this._unhandled_events[event];
    }

    /**
     * Setup handlers for Uppy events that drive the workflow of uploading
     * a file and creating a database entry from it.
     *
     * @protected
     */
    _setupHandlers() {
        this._debug('_setupHandlers');

        const onFileUploadStart    = this._onFileUploadStart.bind(this);
        const onFileUploadProgress = this._onFileUploadProgress.bind(this);
        const onFileUploadError    = this._onFileUploadError.bind(this);
        const onFileUploadSuccess  = this._onFileUploadSuccess.bind(this);
        const onThumbnailGenerated = this._onThumbnailGenerated.bind(this);

        // Events for these features are also applicable to Uppy.Dashboard.
        if (this.feature.dashboard) {
            this.feature.replace_input = true;
          //this.feature.drag_and_drop = true; // NOTE: not currently using d&d
            this.feature.progress_bar  = true;
            this.feature.status_bar    = true;
        }

        this._uppyEvent('upload',          onFileUploadStart);
        this._uppyEvent('upload-progress', onFileUploadProgress);
        this._uppyEvent('upload-error',    onFileUploadError);
        this._uppyEvent('upload-success',  onFileUploadSuccess);

        if (this.feature.image_preview) {
            // noinspection JSCheckFunctionSignatures
            this._uppyEvent('thumbnail:generated', onThumbnailGenerated);
        }
    }

    /**
     * @typedef UppyFileUploadStartData
     *
     * @property {string}   id          For the overall upload session.
     * @property {string[]} fileIDs
     */

    /**
     * This event occurs between the "file-added" and "upload-start" events.
     * <p/>
     *
     * The current value of the submission's database ID applied to the upload
     * endpoint URL in order to correlate the upload with the appropriate
     * workflow.
     *
     * @param {UppyFileUploadStartData} data
     *
     * @protected
     */
    _onFileUploadStart(data) {
        this._debugUppy('upload START', data);
        // noinspection JSValidateTypes
        const params = this.onStart?.(data);
        const upload = this._uppy.getPlugin('XHRUpload');
        // noinspection JSUnresolvedFunction
        const url    = upload.getOptions({}).endpoint;
        if (isMissing(url)) {
            this._error('_onFileUploadStart: No endpoint for upload');
        } else {
            if (isPresent(params)) {
                // noinspection JSCheckFunctionSignatures
                upload.setOptions({ endpoint: makeUrl(url, params) });
            }
            this._uppyInfoClear();
            this.showProgressBar();
        }
    }

    /**
     * Uppy generates this event one or more times for each file as it is
     * uploaded. <p/>
     *
     * This event is observed concurrent with the "progress" event (which
     * indicates the total percentage complete over all files being uploaded).
     *
     * @param {UppyFile}     file
     * @param {FileProgress} progress
     *
     * @protected
     */
    _onFileUploadProgress(file, progress) {
        const bytes = progress.bytesUploaded;
        const total = progress.bytesTotal;
        const pct   = percent(bytes, total);
        const parts = [bytes, 'of', total, `bytes (${pct}%)`];
        if (progress.uploadComplete) { parts.push('[DONE]') }
        this._debugUppy('upload-progress:', ...parts);
        // noinspection JSValidateTypes
        if (this.onProgress?.(file, progress) === false) {
            this._uppy.removeFile(file.id);
            this._debugUppy('upload-progress: canceled', file.id);
        }
    }

    /**
     * This event occurs when the response from POST /upload/upload is
     * received with a failure status (4xx).
     *
     * @param {UppyFile}                       file
     * @param {Error}                          error
     * @param {{status: number, body: string}} [response]
     *
     * @protected
     *
     * @see _xhrBeforeRequest
     */
    _onFileUploadError(file, error, response) {
        this._warn('_onFileUploadError', file, error, response);

        // If _xhrBeforeRequest has added 'flash-message' to the response, then
        // replace the Uppy-generated message so that the "onError" callback
        // can display the server-generated message to the user.
        // noinspection JSUnresolvedReference
        const req   = error?.request || {};
        const flash = req['flash-message'];
        if (flash) {
            error.message = flash;
        }

        this._uppyInfoClear();
        // noinspection JSValidateTypes
        this.onError?.(file, error, response);
        // noinspection JSUnresolvedReference
        this._uppy.getFiles().forEach(file => this._uppy.removeFile(file.id));
    }

    /**
     * This event occurs when the response from POST /upload/upload is
     * received with success status (200).  At this point, the file has
     * been uploaded by Shrine, but has not yet been validated. <p/>
     *
     * **Implementation Notes** <p/>
     * The normal Shrine response has been augmented to include an "emma_data"
     * object in addition to the fields associated with "file_data".
     *
     * @param {UppyFile}            file
     * @param {UppyResponseMessage} response
     *
     * @protected
     *
     * @see "Shrine::UploadEndpointExt#make_response"
     */
    _onFileUploadSuccess(file, response) {
        this._debugUppy('upload-success', file, response);
        this._uppyInfoClear();
        // noinspection JSValidateTypes
        this.onSuccess?.(file, response);
    }

    /**
     * This event occurs when a thumbnail of an uploaded image is
     * available.
     *
     * @param {UppyFile} file
     * @param {string}   image
     *
     * @protected
     */
    _onThumbnailGenerated(file, image) {
        this._debugUppy('thumbnail:generated', file, image);
        this.feature.image_preview.src = image;
    }

    // ========================================================================
    // Methods - initialization - output - internal
    // ========================================================================

    /**
     * Setup handlers for Uppy events that should trigger popup messages.
     *
     * @protected
     */
    _setupMessages() {
        this._debug('_setupMessages');
        let evt;
        const show_info  = this._uppyInfo.bind(this);
        const show_popup = this._uppyPopup.bind(this);
        const show_warn  = this._uppyWarn.bind(this);
        const show_error = this._uppyError.bind(this);
        const debug      = this._debugUppy.bind(this);
        const warn       = this._warn.bind(this);

        this._uppyEvent((evt = 'upload-start'), function(files) {
            warn(`${evt}`, files);
            files.forEach(file => {
                const name = file.name || file;
                show_info(`${STATE.uploading} "${name}"`);
            });
        });

        this._uppyEvent((evt = 'upload-pause'), function(file_id, is_paused) {
            debug(`${evt}`, file_id, is_paused);
            if (is_paused) {
                show_info(PAUSED);
            } else {
                show_popup(RESUMED);
            }
        });

        this._uppyEvent((evt = 'upload-retry'), function(file_id) {
            debug(`${evt}`, file_id);
            show_warn(`${STATE.retrying}...`);
        });

        this._uppyEvent((evt = 'retry-all'), function(files) {
            debug(`${evt}`, files);
            const count   = files ? files.length : 0;
            const uploads = (count === 1) ? 'upload' : `${count} uploads`;
            show_warn(`${STATE.retrying} ${uploads}...`);
        });

        this._uppyEvent((evt = 'pause-all'), function() {
            debug(`${evt}`);
            show_info(STATE.paused);
        });

        this._uppyEvent((evt = 'cancel-all'), function(reason) {
            debug(`${evt}`, reason);
            show_warn(STATE.canceled);
        });

        this._uppyEvent((evt = 'resume-all'), function() {
            debug(`${evt}`);
            show_warn(STATE.resumed);
        });

        this._uppyEvent((evt = 'restriction-failed'), function(file, msg) {
            warn(`${evt}`, file, msg);
            show_error(msg);
        });

        this._uppyEvent((evt = 'error'), function(msg) {
            warn(`${evt}`, msg);
            show_error(msg);
        });

    }

    /**
     * Set up console debugging messages for other Uppy events.
     *
     * @protected
     */
    _setupDebugging() {
        this._debug('_setupDebugging');
        const debug  = this._debugUppy.bind(this);
        const events = [...this._unhandled_events];

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

        // Echo the included Uppy events on the console.
        uniq(events).forEach(event => {
            const evt = event.toUpperCase().replace(':', ': ');
            const tag = '*** ' + evt.replaceAll('-', ' ');
            const fun = (...args) => debug(tag, ...compact(args));
            this._uppyEvent(event, fun);
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
     * Invoke `uppy.info`. <p/>
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
        this._debug(`_uppyInfo: ${level}:`, text);
        if (!this.feature.popup_messages) { return }
        const time  = duration   || 1000 * MINUTES;
        this._uppy.info(text, level, time);
        this.showInfo();
    }

    /**
     * Invoke `uppy.info` with an empty string and very short duration.
     *
     * @protected
     */
    _uppyInfoClear() {
        if (!this.feature.popup_messages) { return }
        this._debug('_uppyInfoClear');
        this.hideInfo();
    }

    /**
     * Allow display of Uppy Informer.
     */
    showInfo() {
        this._debug('showInfo');
        this._toggleInfo(true);
    }

    /**
     * Prevent display of Uppy Informer.
     */
    hideInfo() {
        this._debug('hideInfo');
        this._uppy.hideInfo();
        this._toggleInfo(false);
    }

    /**
     * Hide/show the {@link INFORMER} element by adding/removing the
     * {@link INVISIBLE_MARKER}.
     *
     * @param {boolean} [visible]
     *
     * @protected
     */
    _toggleInfo(visible) {
        //this._debug('toggleInfo: visible =', visible);
        const $control = this.$display.find(INFORMER);
        toggleVisibility($control, visible);
    }

    // ========================================================================
    // Methods - Uppy progress bar
    // ========================================================================

    /**
     * The element starts with *aria-hidden="true"* (so that attribute alone
     * alone isn't sufficient for conditional styling), however the element
     * (and its children) are not invisible.
     *
     * @protected
     *
     * @see file:app/assets/stylesheets/vendor/_uppy.scss .uppy-ProgressBar
     */
    _initializeProgressBar() {
        if (!this.feature.progress_bar) { return }
        this._debug('_initializeProgressBar');
        this.hideProgressBar();
    }

    /**
     * Start displaying the Uppy progress bar.
     */
    showProgressBar() {
        this._debug('showProgressBar');
        this._toggleProgressBar(true);
    }

    /**
     * Stop displaying the Uppy progress bar. <p/>
     *
     * Note that the "hideAfterFinish" option for ProgressBar *only* sets
     * *aria-hidden* -- it doesn't actually hide the control itself.
     */
    hideProgressBar() {
        this._debug('hideProgressBar');
        this._toggleProgressBar(false);
    }

    /**
     * Hide/show the .uppy-ProgressBar element by adding/removing the CSS
     * "invisible" class.
     *
     * @param {boolean} [visible]
     *
     * @protected
     */
    _toggleProgressBar(visible) {
        this._debug('toggleProgressBar: visible =', visible);
        if (!this.feature.progress_bar) { return }
        const $control = this.$display.find(PROGRESS_BAR);
        toggleVisibility($control, visible);
    }

    // ========================================================================
    // Methods - file selection
    // ========================================================================

    /**
     * @typedef {object} InitializeFileSelectOptions
     *
     * @property {string}           [input_id]
     * @property {string}           [label_id]
     * @property {function(jQuery)} [added]
     */

    /**
     * Initialize the Uppy-provided file select button container.
     *
     * @param {InitializeFileSelectOptions} [options]
     *
     * @protected
     */
    _initializeFileSelectContainer(options) {
        this._debug('_initializeFileSelectContainer: options =', options);
        const $container = this.fileSelectContainer();
        const tooltip    = this.fileSelectTooltip();
        const label_id   = options?.label_id;
        const input_id   = options?.input_id;
        const OLD_INPUT  = input_id && `input#${input_id}`;
        const NEW_INPUT  = FILE_INPUT;

        // Uppy will replace `<input type="file">` with its own mechanisms so
        // the original should not be displayed.
        if (OLD_INPUT) { this.$root.find(OLD_INPUT).css('display', 'none') }

        // This hidden element is inappropriately part of the tab order.
        const input_attr = { tabindex: -1, 'aria-hidden': true };
        if (label_id) { input_attr['aria-labelledby'] = label_id }
        $container.find(NEW_INPUT).attr(input_attr);

        // Set the tooltip for the file select button.
        $container.find('button,label').attr('title', tooltip);

        // Reposition it so that it comes before the display of the uploaded
        // filename.
        $container.insertBefore(this.uploadedFilenameDisplay());
        $container.addClass('initialized');
    }

    /**
     * The Uppy-generated element containing the file select button.
     *
     * @returns {jQuery}
     */
    fileSelectContainer() {
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
        this._debug('_initializeFileSelectButton');
        const $button = this.fileSelectButton();
        const tooltip = this.fileSelectTooltip();
        const label   = false && this.fileSelectLabel();
        const debug   = this._debugUppy.bind(this);
        const handler = this.onSelect || (() => debug(FILE_BUTTON_CLASS));
        handleClickAndKeypress($button, handler);
        if (tooltip) { $button.siblings('label').attr('title', tooltip) }
        if (tooltip) { $button.attr('title', tooltip) }
        if (label)   { $button.text(label) } // The plugin will initialize this
        return $button.addClass(FILE_BUTTON_CLASS);
    }

    /**
     * Disable the file select button.
     *
     * @returns {jQuery}              The file select button.
     */
    disableFileSelectButton() {
        this._debug('disableFileSelectButton');
        const marker  = 'forbidden';
        const $button = this.fileSelectButton();
        const tooltip = this.fileSelectDisabledTooltip();
        const label   = false && this.fileSelectDisabledLabel();
        if (tooltip) { $button.attr('title', tooltip) }
        if (label)   { $button.text(label) }
        return $button.toggleClass(marker, true);
    }

    /**
     * Display the name of the uploaded file.
     *
     * @param {FileData} file_data
     */
    displayUploadedFilename(file_data) {
        this._debug('displayUploadedFilename: file_data =', file_data);
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
        this._debug('displayFilename: filename =', filename);
        if (!this._filenameUpdate(filename)) { return false }
        this.hideFilename(false);
        this.hideProgressBar();
        return true;
    }

    /**
     * Update the element containing the selected file name based on its type.
     *
     * @param {string} filename
     *
     * @returns {boolean}
     * @protected
     */
    _filenameUpdate(filename) {
        this._debug('_filenameUpdate: filename =', filename);
        if (isMissing(filename)) { return false }
        this._uploadedFilenameElement().text(filename);
        this.uploadedFilenameDisplay().toggleClass('complete', true);
        return true;
    }

    /**
     * Hide the selected file name.
     *
     * @param {boolean} [hide]        If **false**, un-hide.
     */
    hideFilename(hide) {
        this._debug('hideFilename: hide =', hide);
        const hidden = (hide !== false);
        toggleHidden(this.uploadedFilenameDisplay(), hidden);
    }

    /**
     * Indicate whether a selected file name is being displayed.
     *
     * @returns {boolean}
     */
    isFilenameDisplayed() {
        if (!this._filenameValue()) { return false }
        return !isHidden(this.uploadedFilenameDisplay());
    }

    /**
     * The element displaying the uploaded file.
     *
     * @returns {jQuery}
     */
    uploadedFilenameDisplay() {
        return this.$root.find(FILE_NAME);
    }

    /**
     * Get the element that holds the selected file name.
     *
     * @param {string} [inner]        Interior element holding the name.
     *
     * @returns {jQuery}
     * @protected
     */
    _uploadedFilenameElement(inner = '.filename') {
        const $element = this.uploadedFilenameDisplay();
        const $inner   = $element.find(inner);
        return isPresent($inner) ? $inner : $element;
    }

    /**
     * Get the value of the selected file name.
     *
     * @returns {string|undefined}
     * @protected
     */
    _filenameValue() {
        return this._uploadedFilenameElement().text() || undefined;
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
     * Uppy plugin, with {@link $display} as a fall-back.
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
        return this._filenameValue();
    }

    // ========================================================================
    // Methods - file selection display values
    // ========================================================================

    /**
     * The current label for the file select button.
     *
     * @param {boolean} [can_select]    Default: {@link canSelect}.
     *
     * @returns {string}
     */
    fileSelectLabel(can_select) {
        return this._selectProperties('label', can_select) || 'SELECT';
    }

    /**
     * The current tooltip for the file select button.
     *
     * @param {boolean} [can_select]    Default: {@link canSelect}.
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
     * @param {boolean} [can_select]    Default: {@link canSelect}.
     *
     * @returns {*}
     * @protected
     */
    _selectProperties(value, can_select) {
        const op     = this._endpointProperties.select || {};
        const select = isDefined(can_select) ? can_select : this.canSelect();
        const status = select ? op.if_enabled : op.if_disabled;
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
        this._debugging && console.log('Uppy:', ...args);
    }

}

/**
 * An uploader for an individual item form.
 *
 * @extends BaseUploader
 */
export class SingleUploader extends BaseUploader {

    static CLASS_NAME = 'SingleUploader';

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
    // Methods - initialization
    // ========================================================================

    /**
     * Initialize Uppy file uploader.
     *
     * @param {UploaderOptions} [options]
     */
    initializeUppy(options) {
        // If re-initializing a Turbolinks-cached page, this will already exist
        // and Uppy will create a new one unless it's discarded now.
        this.fileSelectContainer().remove();
        super.initializeUppy(options);
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
            $button.toggleClass(this.constructor.BEST_CHOICE_MARKER, true);
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
        return $button.toggleClass(this.constructor.BEST_CHOICE_MARKER, false);
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
 *
 * @extends BaseUploader
 */
export class MultiUploader extends BaseUploader {

    static CLASS_NAME = 'MultiUploader';

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * If **false** then defer assignment of {@link _display} to
     * {@link initialize} since it may result in render changes.
     *
     * @note Currently manifest-edit.js relies upon this being **true**.
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
    // Methods - internal
    // ========================================================================

    /**
     * Find or create the popup element for containing Uppy plugin output
     * elements.
     *
     * @param {Selector} [target]     Default: {@link $root}.
     *
     * @returns {jQuery}
     * @protected
     */
    _locateDisplay(target) {
        const match   = this.constructor.DISPLAY;
        const css     = this.constructor.DISPLAY_CLASS;
        let $result   = target && this._selfOrDescendent(target, match);
            $result ||= this._selfOrDescendent(this.$root, match);
            $result ||= $(match);
        if (isMissing($result)) {
            $result = $('<div>').addClass(css).appendTo('body');
            this._debug('_locateDisplay append to body ->', $result);
        } else {
            this._debug('_locateDisplay ->', $result);
        }
        return $result;
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
    // Methods - initialization - handlers - internal
    // ========================================================================

    /**
     * Setup handlers for Uppy events that drive the workflow of uploading
     * a file and creating a database entry from it.
     *
     * @protected
     */
    _setupHandlers() {
        super._setupHandlers();
        this._uppyEvent('upload',   () => this.openDisplay());
        this._uppyEvent('complete', () => this.closeDisplay());
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

        // Re-arrange so that fileSelectContainer() is included within the
        // control group.
        const $group = this.$root.find(CONTROL_GROUP);
        if (isPresent($group)) {
            const $container = this.fileSelectContainer();
            $group.insertBefore($container);
            $container.prependTo($group);
        }

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
     * Add controls to {@link fileSelectContainer}. <p/>
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
        toggleHidden($element, true);
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
     * @param {string} filename
     *
     * @returns {boolean}
     * @protected
     */
    _filenameUpdate(filename) {
        if (!super._filenameUpdate(filename)) { return false }
        const uploader_type = this.constructor.FILE_TYPE;
        this.uploadedFilenameDisplay().children().each((_, line) => {
            /** @type {jQuery} */
            const $line  = $(line);
            const active = $line.is(uploader_type);
            $line.attr('aria-hidden', !active);
            $line.toggleClass('active', active);
        });
        return true;
    }

    /**
     * Get the element that holds the selected file name.
     *
     * @param {string} [inner]        Interior element holding the name.
     *
     * @returns {jQuery}
     * @protected
     */
    _uploadedFilenameElement(inner = this.constructor.FILE_TYPE) {
        return super._uploadedFilenameElement(inner);
    }

    // ========================================================================
    // Methods
    // ========================================================================

    openDisplay()  { this._toggleDisplay(true) }
    closeDisplay() { this._toggleDisplay(false) }

    /**
     * Toggle the state of the informational display elements.
     *
     * @param {boolean} [open]
     *
     * @protected
     */
    _toggleDisplay(open) {
        this._debug('toggleDisplay open =', open);
        this.$display.toggleClass(this.constructor.VISIBLE_MARKER, open);
    }
}

/**
 * An uploader for uploading multiple items in parallel.
 *
 * @extends BaseUploader
 */
export class BulkUploader extends BaseUploader {

    static CLASS_NAME = 'BulkUploader';

    // ========================================================================
    // Type definitions
    // ========================================================================

    /**
     * A File object augmented with Uppy metadata.
     *
     * @typedef {File} FileExt
     *
     * @property {object} meta
     */

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * The number of uploads that Uppy will perform simultaneously.
     *
     * @type {number}
     *
     * @see "SubmissionService::DEF_BATCH"
     *
     * TODO: pass in via assets.js.erb.
     */
    static DEF_BATCH = 6;

    // ========================================================================
    // Fields
    // ========================================================================

    _batch_size  = this.constructor.DEF_BATCH;
    _in_progress = false;

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
        this.feature.replace_input  = false;
        this.feature.popup_messages = false;
        this.feature.progress_bar   = false;
        this._options.autoProceed   = false;
    }

    // ========================================================================
    // Methods - initialization - XHR - internal
    // ========================================================================

    /**
     * Options for the XHRUpload plugin, including the "X-Update-FileData-Only"
     * header to specify that the record's **:file_data** column should be
     * updated without modifying **:update_time** or other columns.
     *
     * @param {XhrUploadOpts} [opt]
     * @param {object}        [headers]
     *
     * @returns {XhrUploadOpts}
     * @protected
     *
     * @see "ManifestItemController#upload"
     */
    _xhrOptions(opt, headers) {
        const xhr_opt = super._xhrOptions(opt, headers);
        xhr_opt.limit = this.batchSize;
        xhr_opt.headers['X-Update-FileData-Only'] = true;
        return xhr_opt;
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get inProgress() { return this._in_progress }
    get batchSize()  { return this._batch_size }
  //set batchSize(v) { this._batch_size = Number(v) || this.batch_size }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Queue one or more file objects.
     *
     * @param {FileExt|FileExt[]} files
     */
    addFiles(files) {
        this._debug('addFiles', files);
        arrayWrap(files).forEach(file_item => {
            let file = file_item;
            if ((file instanceof File) && hasKey(file, 'meta')) {
                file = {
                    meta: file.meta,
                    name: file.name,
                    type: file.type,
                    size: file.size,
                    data: file,
                };
            }
            this._uppy.addFile(file);
        });
    }

    /**
     * De-queue one or more file objects.
     *
     * @param {FileExt|FileExt[]} [files]
     */
    removeFiles(files) {
        this._debug('removeFiles', files);
        let ids = Object.keys(this._uppy.getState()?.files || {});
        if (files) {
            ids = arrayWrap(files).filter(file => ids.includes(file));
        }
        ids.forEach(id => this._uppy.removeFile(id));
    }

    /**
     * Transmit the file object(s) queued since the last upload.
     */
    upload() {
        const files = this._uppy.getFiles();
        if (this._in_progress) {
            this._debug('upload - ignored; already uploading');
        } else if (isMissing(files)) {
            this._debug('upload - ignored; no files queued');
        } else {
            this._debug(`upload - ${files.length} files:`, files);
            this._in_progress = true;
            this._uppy.upload().then(
                result => {
                    this._debug('Uppy.upload final result:', result);
                    const log = [];
                    const err = [];
                    if (result) {
                        const succeeded = result.successful?.length;
                        const failed    = result.failed?.length;
                        if (succeeded && failed) {
                            log.push(`${succeeded} uploads succeeded`);
                            log.push(`${failed} uploads failed:`);
                        } else if (succeeded) {
                            log.push(`all ${succeeded} uploads succeeded`);
                        } else if (failed) {
                            log.push(`all ${failed} uploads failed:`);
                        }
                        if (failed) {
                            err.push(...result.failed);
                        }
                    } else {
                        log.push('server failure');
                    }
                    log.forEach(line => this._log(line));
                    err.forEach(fail => this._warn(fail.error));
                    this._in_progress = false;
                },
                error => {
                    this._debug('upload - error:', error);
                    this._in_progress = false;
                },
            );
        }
    }

    // ========================================================================
    // Methods - actions
    // ========================================================================

    /**
     * Actively cancel the current upload.
     */
    cancel() {
        if (this.inProgress) {
            this._debug('cancel');
            this._uppy.cancelAll();
        } else {
            this._debug('cancel - ignored; not uploading');
        }
    }

    /**
     * Pause uploading.
     *
     * @note Not clear whether/how this works.
     */
    pause() {
        if (this.inProgress) {
            this._debug('pause');
            this._uppy.pauseAll();
        } else {
            this._debug('pause - ignored; not uploading');
        }
    }

    /**
     * Resume uploading.
     *
     * @note Not clear whether/how this works.
     */
    resume() {
        if (this.inProgress) {
            this._debug('resume');
            this._uppy.resumeAll();
        } else {
            this._debug('resume - ignored; not uploading');
        }
    }
}
