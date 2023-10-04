// app/assets/javascripts/shared/modal-base.js
//
// noinspection LocalVariableNamingConventionJS, JSUnusedGlobalSymbols


import { AppDebug }                       from '../application/debug';
import { Emma }                           from './assets';
import { BaseClass }                      from './base-class';
import { decodeObject }                   from './decode';
import { handleEvent }                    from './events';
import { scrollIntoView }                 from './html';
import { keyCombo }                       from './keyboard';
import { ModalHideHooks, ModalShowHooks } from './modal_hooks';
import { NavGroup }                       from './nav-group';
import {
    currentFocusablesIn,
    handleClickAndKeypress,
    neutralizeFocusables,
    restoreFocusables,
} from './accessibility';
import {
    elementName,
    isHidden,
    selector,
    toggleHidden,
} from './css';
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
    notDefined,
    presence,
} from './definitions';


const MODULE = 'ModalBase';
const DEBUG  = true;

AppDebug.file('shared/modal-base', MODULE, DEBUG);

// ============================================================================
// Type definitions
// ============================================================================

/**
 * @typedef {CallbackChainFunction} onShowModalHook
 *
 * The signature of a callback function that can be provided via
 * `.data('ModalShowHooks')` on the modal popup activation toggle control. <p/>
 *
 * If the function returns **false** then {@link _showModal} will not allow the
 * popup to open (and will avoid fetching any related deferred content if
 * applicable).
 */

/**
 * @typedef {CallbackChainFunction} onHideModalHook
 *
 * The signature of a callback function that can be provided via
 * `.data('ModalHideHooks')` on the modal popup activation toggle control. <p/>
 *
 * If then function returns **false** then {@link _hideModal} will not allow
 * the popup to close.
 */

// ============================================================================
// Constants
// ============================================================================

export const COMPLETE_MARKER = 'complete';
export const Z_ORDER_MARKER  = 'z-order-capture';

export const COMPLETE = selector(COMPLETE_MARKER);
export const PANEL    = selector(Emma.Popup.panel.class);
export const TOGGLE   = selector(Emma.Popup.button.class);
export const DEFERRED = selector(Emma.Popup.deferred.class);
export const CLOSER   = `.${Emma.Popup.closer.class}, [type="submit"]`;

/**
 * The .data() value assigned to a modal which is overtaking z-order on the
 * page by neutralizing the z-index for elements outside its stacking context.
 * This value holds the set of elements which have been affected.
 *
 * @readonly
 * @type {string}
 */
const Z_CAPTURES_DATA = 'z-captured-elements';

/**
 * The .data() value assigned to an element whose z-index has been neutralized
 * which holds the original z-index value to be restored.
 *
 * @readonly
 * @type {string}
 */
const Z_RESTORE_DATA = 'current-z-index';

// ============================================================================
// Class ModalBase
// ============================================================================

/**
 * ModalBase
 *
 * @extends BaseClass
 */
export class ModalBase extends BaseClass {

    static CLASS_NAME = 'ModalBase';
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * The .data() name on modal toggles and/or modal panels with a link to an
     * instance of this class.
     *
     * @readonly
     * @type {string}
     */
    static INSTANCE_DATA = 'modalInstance';

    // ========================================================================
    // Fields
    // ========================================================================

    /**
     * The activation control which currently "owns" this instance (and the
     * associated modal popup element).
     *
     * @type {jQuery|undefined}
     */
    $toggle;

    /**
     * The modal popup element managed by this instance.
     *
     * @type {jQuery|undefined}
     */
    $modal;

    // ========================================================================
    // Fields - internal
    // ========================================================================

    // Tab sequencing for accessibility.

    /** @type {jQuery|undefined} */ _tab_cycle_start;
    /** @type {jQuery|undefined} */ _tab_cycle_first;
    /** @type {jQuery|undefined} */ _tab_cycle_last;

    // ========================================================================
    // Constructor
    // ========================================================================

    /**
     * Create a new instance.
     *
     * @param {Selector} [control]
     * @param {Selector} [modal]
     */
    constructor(control, modal) {
        super();
        this._debug('ModalBase CTOR: control =', control);
        this._debug('ModalBase CTOR: modal   =', modal);
        this.$toggle = control && this.associate(control);
        this.$modal  = modal   && this.setupPanel(modal);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get modalPanel()         { return this.$modal }
    get modalControl()       { return this.$toggle }
    set modalControl(toggle) { this.$toggle = toggle ? $(toggle) : undefined }

    get isOpen()             { return !this.isClosed }
    get isClosed()           { return isHidden(this.modalPanel) }
    get closers()            { return this.modalPanel.find(CLOSER) }

    // noinspection FunctionNamingConventionJS
    get INSTANCE_DATA()      { return this.constructor.INSTANCE_DATA }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Open the modal popup element.
     *
     * @param {boolean} [no_halt]     If **true**, hooks cannot halt the chain.
     *
     * @returns {boolean}
     */
    open(no_halt) {
        this._debug('open: no_halt =', no_halt);
        if (this.isClosed) {
            return this._showModal(undefined, no_halt);
        } else {
            this._warn('modal popup already open');
            return true;
        }
    }

    /**
     * Close the modal popup element.
     *
     * @param {boolean}  [no_halt]    If **true**, hooks cannot halt the chain.
     *
     * @returns {boolean}
     */
    close(no_halt) {
        this._debug('close: no_halt =', no_halt);
        if (this.isOpen) {
            return this._hideModal(undefined, no_halt);
        } else {
            this._warn('modal popup already closed');
            return true;
        }
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Toggle visibility of the modal popup element.
     *
     * @param {jQuery.Event|Event} event
     *
     * @returns {boolean}
     */
    onToggleModal(event) {
        this._debug('onToggleModal', event);
        this.toggleModal(event.currentTarget || event.target);
        event.stopPropagation();
        return false;
    }

    /**
     * Toggle visibility of the associated modal popup. <p/>
     *
     * On any given cycle, the first execution of this method should be due to
     * the user pressing a toggle button.  That button is set here as the
     * current "owner" of the modal dialog.
     *
     * @param {Selector} [target]     Default: {@link modalControl}.
     */
    toggleModal(target) {
        const func  = 'toggleModal'; this._debug(`${func}: target =`, target);
        let $target = target && $(target);
        if ($target) {
            const instance = this.constructor.instanceFor($target);
            if (instance === this) {
                this.modalControl = $target;
            } else if (instance) {
                this._warn('instanceFor($target) !== this', instance, this);
            }
        }
        $target ||= this.modalControl;
        if (this.modalPanel.children().is('.iframe, .img')) {
            this._toggleIframeModal($target, func);
        } else {
            this._toggleContentModal($target, func);
        }
    }

    /**
     * Toggle visibility of an `<iframe>` or `<img>` modal popup.
     *
     * @param {Selector} target       Event target causing the action.
     * @param {string}   [caller]
     *
     * @protected
     */
    _toggleIframeModal(target, caller) {
        let func = caller ? `${caller}: IFRAME` : '_toggleIframeModal';

        const $target      = target ? $(target) : this.modalControl;
        const $modal       = this.modalPanel;
        const $iframe      = $modal.children('iframe');
        const $placeholder = $modal.children(DEFERRED);
        const complete     = $modal.is(COMPLETE);
        const opening      = this.isClosed;

        // Include the ID of the iframe for logging.
        if (this._debugging) {
            let id = $modal.data('id') || $iframe.attr('id');
            // noinspection JSUnresolvedVariable
            id ||= decodeObject($placeholder.attr('data-attr')).id;
            id ||= 'unknown';
            func += ` ${id}`;
        }

        // Restore placeholder text if necessary.
        const placeholder_text = $placeholder.data('text');
        if (placeholder_text) {
            $placeholder.text(placeholder_text);
        }
        if (isDefined(placeholder_text)) {
            $placeholder.removeData('text');
        }

        if (opening && complete) {
            // If the existing hidden popup can be re-used, ensure that it is
            // fully visible and the contents are scrolled to the indicated
            // anchor.
            this._info(`${func}: RE-OPENING`);
            if (this._showModal($target)) {
                this.scrollIntoView();
                this.scrollFrameDocument($iframe, $modal.data('topic'));
            }

        } else if (opening) {
            // Fetch deferred content when the popup is unhidden the first time
            // (or after being deleted below after closing).
            this._info(`${func}: LOADING`);
            if (this._showModal($target)) {
                $placeholder.each((_, p) => this._loadDeferredContent(p));
            }

        } else if (complete) {
            // If the `<iframe>` exists and contains a different page than the
            // original then remove it in order to re-fetch the original the
            // next time it is opened.
            if (this._checkHideModal($target)) {
                const refetch       = $modal.hasClass('refetch');
                const expected_page = $modal.data('page');
                const content       = $iframe[0].contentDocument;
                const current_page  = content?.location?.pathname;
                if (!refetch && (expected_page === current_page)) {
                    this._info(`${func}: CLOSING`, current_page);
                } else {
                    this._info(`${func}: CLOSING - REMOVING`, current_page);
                    toggleHidden($placeholder, false);
                    $iframe.remove();
                    $modal.removeClass(COMPLETE_MARKER);
                }
                this._hideModal($target, true);
            }

        } else {
            this._warn(`${func}: CLOSING - INCOMPLETE MODAL POPUP`);
            this._hideModal($target);
        }
    }

    /**
     * Fetch deferred content as indicated by the placeholder element, which
     * may be either an `<iframe>` or an `<img>`.
     *
     * @param {Selector} placeholder
     *
     * @protected
     */
    _loadDeferredContent(placeholder) {

        const func            = '_loadDeferredContent';
        const _warn           = this._warn.bind(this);
        const _info           = this._info.bind(this);
        const _debug          = this._debug.bind(this);
        const showModal       = this._showModal.bind(this);
        const hideModal       = this._hideModal.bind(this);
        const scrollIntoView  = this.scrollIntoView.bind(this);
        const scrollFrame     = this.scrollFrameDocument.bind(this);
        const $modal          = this.modalPanel;
        const $placeholder    = $(placeholder);
        const source_url      = $placeholder.attr('data-path');
        const attributes      = $placeholder.attr('data-attr');

        // Validate parameters and return if there is missing information.
        let type, error;
        if (isMissing(source_url)) {
            error = 'no source URL';
        } else if ($placeholder.hasClass('iframe')) {
            type  = 'iframe';
        } else if ($placeholder.hasClass('img')) {
            type  = 'img';
        } else {
            error = 'no type';
        }
        if (error) {
            _warn(`${func}: ${error}`);
            return;
        }

        // Setup the element that will actually contain the received content
        // then fetch it.  The element will appear only if successfully loaded.
        const $content = $(`<${type}>`);
        if (isPresent(attributes)) { $content.attr(decodeObject(attributes)) }
        toggleHidden($content, true);
        $content.insertAfter($placeholder);
        handleEvent($content, 'error', onError);
        handleEvent($content, 'load',  onLoad);
        $content.attr('src', source_url);
        $content.attr('aria-label', $modal.attr('aria-label'));

        /**
         * If there was a problem with loading the content for the modal popup,
         * display a message in the popup placeholder element.
         *
         * @param {jQuery.Event|Event} event
         */
        function onError(event) {
            _warn(`${func}: ${type} FAILED`, event);
            if (!$placeholder.data('text')) {
                $placeholder.data('text', $placeholder.text());
            }
            $placeholder.text('Could not load content.');
            $content.remove();
        }

        /**
         * When the modal popup content is loaded replace the placeholder
         * `<iframe>` with the content `<iframe>`.  If an anchor (initial
         * element ID) was specified by the *data-topic* attribute in the
         * placeholder, scroll the `<iframe>` to bring the element with that ID
         * to the top of the panel display.
         *
         * @param {jQuery.Event|Event} _event
         */
        function onLoad(_event) {
            if ($modal.hasClass(COMPLETE_MARKER)) {

                // The user has clicked on a link within the `<iframe>` and a
                // new page has been loaded into it.
                _info(`${func}: ${type} PAGE REPLACED`);

            } else {

                // The initial load of the modal popup target page.
                _info(`${func}: ${type} LOAD`);
                const iframe = $content[0].contentDocument;
                const topic  = $placeholder.attr('data-topic');

                // Record the initial page and anchor displayed in the
                // `<iframe>`.
                $modal.data('id',    $content[0].id); // For logging.
                $modal.data('page',  iframe.location.pathname);
                $modal.data('topic', topic);
                $modal.addClass(COMPLETE_MARKER);

                // Replace the placeholder with the downloaded content.
                toggleHidden($placeholder, true);
                toggleHidden($content, false);

                // Prepare to handle key presses that are directed to the
                // `<iframe>`.
                handleEvent($content.contents(), 'keyup', onIframeKeyUp);

                // Make sure the associated modal popup element is displayed
                // and scrolled into position.
                showModal(undefined, true);
                scrollIntoView();
                scrollFrame($content, topic);
            }
        }

        // noinspection FunctionWithInconsistentReturnsJS
        /**
         * Allow **Escape** key from within the `<iframe>` to close the modal
         * popup. <p/>
         *
         * Re-focus on the parent window so that the hidden modal does not
         * continue to intercept key press events.
         *
         * @param {jQuery.Event|KeyboardEvent} event
         */
        function onIframeKeyUp(event) {
            const key = keyCombo(event);
            if (key === 'Escape') {
                _debug('ESC pressed in modal popup', $modal.data('id'));
                if (hideModal(event.target)) {
                    window.parent.focus();
                    return false;
                }
            }
        }
    }

    /**
     * Toggle visibility of a generic content modal popup.
     *
     * @param {Selector} target       Event target causing the action.
     * @param {string}   [caller]
     *
     * @protected
     */
    _toggleContentModal(target, caller) {
        const func         = caller || '_toggleContentModal';
        const $target      = target ? $(target) : this.modalControl;
        const $modal       = this.modalPanel;
        const $placeholder = $modal.children('.placeholder');
        const complete     = $modal.is(COMPLETE);
        const opening      = this.isClosed;

        if (opening && complete) {
            // If the existing hidden popup can be re-used, ensure that it is
            // fully visible.
            this._info(`${func}: RE-OPENING`);
            if (this._showModal($target)) {
                this.scrollIntoView();
            }

        } else if (opening && isPresent($placeholder)) {
            // Initialize content when the popup is unhidden the first time
            // (or after being deleted below after closing).
            this._info(`${func}: INITIALIZING`);
            if (this._showModal($target)) {
                $placeholder.each((_, p) => this._loadDirectContent(p));
            }

        } else if (opening) {
            this._info(`${func}: OPENING`);
            if (this._showModal($target)) {
                $modal.addClass(COMPLETE_MARKER);
            }

        } else if (complete) {
            this._info(`${func}: CLOSING`);
            this._hideModal($target);

        } else {
            this._warn(`${func}: CLOSING - INCOMPLETE MODAL POPUP`);
            this._hideModal($target);
        }
    }

    /**
     * Fetch content.
     *
     * @param {Selector} placeholder
     *
     * @protected
     */
    _loadDirectContent(placeholder) {

        const func            = '_loadDirectContent';
        const _warn           = this._warn.bind(this);
        const _info           = this._info.bind(this);
        const showModal       = this._showModal.bind(this);
        const scrollIntoView  = this.scrollIntoView.bind(this);
        const $modal          = this.modalPanel;
        const $placeholder    = $(placeholder);
        const source_url      = $placeholder.attr('data-path');
        const attributes      = $placeholder.attr('data-attr');

        // Validate parameters and return if there is missing information.
        if (isMissing(source_url)) {
            _warn(`${func}: no source URL`);
            return;
        }

        // Setup the element that will actually contain the received content
        // then fetch it.  The element will appear only if successfully loaded.
        const $content = $('<embed>');
        if (isPresent(attributes)) { $content.attr(decodeObject(attributes)) }
        toggleHidden($content, true);
        $content.insertAfter($placeholder);
        handleEvent($content, 'error', onError);
        handleEvent($content, 'load',  onLoad);
        $content.attr('src', source_url);

        /**
         * If there was a problem with loading the modal popup content, display
         * a message in the popup placeholder element.
         *
         * @param {jQuery.Event|Event} event
         */
        function onError(event) {
            _warn(`${func}: FAILED`, event);
            if (!$placeholder.data('text')) {
                $placeholder.data('text', $placeholder.text());
            }
            $placeholder.text('Could not load content.');
            $content.remove();
        }

        /**
         * When the modal popup content is loaded replace the placeholder
         * `<div>` with the content `<div>`.
         *
         * @param {jQuery.Event|Event} _event
         */
        function onLoad(_event) {
            if ($modal.hasClass(COMPLETE_MARKER)) {

                // The user has clicked on a link within the `<div>` and a new
                // page has been loaded into it.
                _info(`${func}: PAGE REPLACED`);

            } else {

                // The initial load of the popup target content.
                _info(`${func}: LOAD`);
                $modal.data('id', $content[0].id); // For logging.
                $modal.addClass(COMPLETE_MARKER);

                // Replace the placeholder with the downloaded content.
                toggleHidden($placeholder, true);
                toggleHidden($content, false);

                // Make sure the associated popup element is displayed and
                // scrolled into position.
                showModal(undefined, true);
                scrollIntoView();
            }
        }
    }

    /**
     * Scroll the modal popup into view.
     *
     * @returns {jQuery}
     */
    scrollIntoView() {
        return scrollIntoView(this.modalPanel);
    }

    /**
     * Scroll the `<iframe>` content to the indicated anchor.
     *
     * @param {Selector} iframe
     * @param {string}   [topic]      Default: top of document.
     *
     * TODO: Move outside of class?
     */
    scrollFrameDocument(iframe, topic) {
        const $iframe = $(iframe);
        const id      = $iframe.attr('id') || '???';
        const func    = `scrollFrameDocument: modal popup ${id}`;
        const doc     = $iframe[0]?.contentDocument;
        let anchor    = topic?.replace(/^#/, '');
        let section   = anchor && doc?.getElementById(anchor);
        let error, warn;
        if (isEmpty($iframe)) {
            error   = 'NO IFRAME';
        } else if (isEmpty(doc)) {
            error   = 'NO DOCUMENT';
        } else if (notDefined(topic)) {
            anchor  = '#TOP'; // For reporting.
            section = doc.body;
        } else if (isMissing(anchor)) {
            error   = 'NO ANCHOR';
        } else if (!section) {
            warn    = `${anchor}: ANCHOR MISSING IN DOCUMENT`;
        }

        if (error) {
            this._error(`${func}: ${error}`);
        } else if (warn) {
            this._warn(`${func}: ${warn}`);
        } else {
            // For some reason, scrollIntoView is also causing the root window
            // to scroll, so the Y position is restored to nullify that effect.
            this._debug(`${func}: anchor =`, anchor);
            const saved_y = window.parent.scrollY;
            section.scrollIntoView(true);
            window.parent.scrollTo(0, saved_y);
        }
    }

    // ========================================================================
    // Methods - show/hide
    // ========================================================================

    /**
     * Open the modal popup element.
     *
     * @param {Selector} [target]     Event target causing the action.
     * @param {boolean}  [no_halt]    If **true**, hooks cannot halt the chain.
     *
     * @returns {boolean}
     * @protected
     */
    _showModal(target, no_halt) {
        const func = '_showModal'; this._debugModal(func, target);
        const $tgt = target ? $(target) : this.modalControl;
        const show = (this._invokeOnShowModal($tgt) !== false) || no_halt;
        if (show) {
            this._zOrderCapture();
            this._setModalHidden(false);
            this._trapFocus(true);
            this._setTabCycle();
        } else {
            this._warn(`${func}: chain halted`);
        }
        return show;
    }

    /**
     * Close the modal popup element.
     *
     * @param {Selector} [target]     Event target causing the action.
     * @param {boolean}  [no_halt]    If **true**, hooks cannot halt the chain.
     *
     * @returns {boolean}
     * @protected
     */
    _hideModal(target, no_halt) {
        const func = '_hideModal'; this._debugModal(func, target);
        const $tgt = target ? $(target) : this.modalControl;
        const hide = (this._invokeOnHideModal($tgt) !== false) || no_halt;
        if (hide) {
            this._clearTabCycle();
            this._trapFocus(false);
            this._setModalHidden(true);
            this._zOrderRelease();
            $tgt.focus();
        } else {
            this._warn(`${func}: chain halted`);
        }
        return hide;
    }

    /**
     * Show/hide the modal popup element.
     *
     * @param {boolean} [hide]        If **false**, un-hide.
     *
     * @protected
     */
    _setModalHidden(hide) {
        const $modal = this.modalPanel;
        if (hide === false) {
            toggleHidden($modal, false);
            restoreFocusables($modal);
        } else {
            neutralizeFocusables($modal);
            toggleHidden($modal, true);
        }
    }

    /**
     * Apply the *inert* attribute to other elements so that the open modal
     * captures events and focus.
     *
     * @param {boolean} [trap]       If **false** remove the *inert* attribute.
     *
     * @protected
     */
    _trapFocus(trap) {
        const $modal  = this.modalPanel;
        const parents = $modal.parents(":not('body,html')").toArray();
        const chain   = [$modal, ...parents];
        if (trap === false) {
            chain.forEach(el => $(el).siblings().removeAttr('inert'));
        } else {
            chain.forEach(el => $(el).siblings().attr('inert', true));
        }
    }

    // ========================================================================
    // Methods - event hooks
    // ========================================================================

    /**
     * Pre-clear the ability to open the modal popup.
     *
     * @param {Selector} [target]     Event target causing the action.
     *
     * @returns {boolean}
     * @protected
     */
    _checkShowModal(target) {
        return (this._invokeOnShowModal(target, true) !== false);
    }

    /**
     * Pre-clear the ability to close the modal popup.
     *
     * @param {Selector} [target]     Event target causing the action.
     *
     * @returns {boolean}
     * @protected
     */
    _checkHideModal(target) {
        return (this._invokeOnHideModal(target, true) !== false);
    }

    /**
     * Execute all {@link ModalShowHooks} associated with the instance.
     *
     * @param {Selector} [target]     Event target causing the action.
     * @param {boolean}  [check_only]
     *
     * @returns {boolean|undefined}
     * @protected
     */
    _invokeOnShowModal(target, check_only) {
        const name = ModalShowHooks.dataName;
        return this._invokeModalHooks(name, target, check_only);
    }

    /**
     * Execute all {@link ModalHideHooks} associated with the instance.
     *
     * @param {Selector} [target]     Event target causing the action.
     * @param {boolean}  [check_only]
     *
     * @returns {boolean|undefined}
     * @protected
     */
    _invokeOnHideModal(target, check_only) {
        const name = ModalHideHooks.dataName;
        return this._invokeModalHooks(name, target, check_only);
    }

    /**
     * Execute a {@link ModalHooks} callback associated with the instance.
     *
     * @param {string}   data_name
     * @param {Selector} [target]     Event target causing the action.
     * @param {boolean}  [check_only]
     *
     * @returns {boolean|undefined}   Not defined if *data_name* is missing.
     * @protected
     */
    _invokeModalHooks(data_name, target, check_only) {
        const $toggle = this.modalControl;
        const chain   = $toggle?.data(data_name);
        return chain?.invoke((target || $toggle), check_only);
    }

    // ========================================================================
    // Methods - z-order
    // ========================================================================

    /**
     * Indicate whether the modal popup is intended to stack above all other
     * elements.
     *
     * @returns {boolean}
     * @protected
     */
    get _zOrderCapturing() {
        return this.modalPanel.hasClass(Z_ORDER_MARKER);
    }

    /**
     * Cheat working out the proper stacking context hierarchy by causing all
     * elements with a non-zero z-index to be neutralized. <p/>
     *
     * The function returns early if it has already been run for this instance.
     *
     * @protected
     */
    _zOrderCapture() {
        if (!this._zOrderCapturing || this.modalPanel.data(Z_CAPTURES_DATA)) {
            return;
        }
        this._debug('_zOrderCapture');
        let z_captures = [];
        $('*:visible').not(this.modalPanel).each((_, element) => {
            const $e = $(element);
            const z  = Number($e.css('z-index'));
            if (z > 0) {
                $e.data(Z_RESTORE_DATA, z);
                $e.css('z-index', -1);
                z_captures.push($e);
                this._debug(`CAPTURE z-index = ${z} from ${elementName($e)}`);
            }
        });
        if (isEmpty(z_captures)) {
            z_captures = false;
        }
        this.modalPanel.data(Z_CAPTURES_DATA, z_captures);
    }

    /**
     * Reverses the effect of {@link _zOrderCapture} by restoring the original
     * z-index to the affected elements.
     *
     * @protected
     */
    _zOrderRelease() {
        if (!this._zOrderCapturing) {
            return;
        }
        this._debug('_zOrderRelease');
        (this.modalPanel.data(Z_CAPTURES_DATA) || []).forEach($element => {
            const z = $element.data(Z_RESTORE_DATA);
            $element.css('z-index', z);
            this._debug(`RELEASE z-index = ${z} to ${elementName($element)}`);
        });
        this.modalPanel.data(Z_CAPTURES_DATA, false);
    }

    // ========================================================================
    // Properties - tab sequence
    // ========================================================================

    /**
     * Get the initial element to focus on when the modal dialog opens.
     * (This must be set explicitly.)
     *
     * @returns {jQuery|undefined}
     */
    get tabCycleStart() {
        return this._tab_cycle_start;
    }

    /**
     * Set the first element to tab to after {@link tabCycleLast}.
     *
     * @param {jQuery} $item
     */
    set tabCycleStart($item) {
        this._setTabCycleStart($item);
    }

    /**
     * Get the first element to tab to after {@link tabCycleLast}.
     *
     * @returns {jQuery|undefined}
     */
    get tabCycleFirst() {
        return this._tab_cycle_first || this._setTabCycleFirst();
    }

    /**
     * Get the last tabbable element in the modal dialog.
     *
     * @returns {jQuery|undefined}
     */
    get tabCycleLast() {
        return this._tab_cycle_last || this._setTabCycleLast();
    }

    // ========================================================================
    // Methods - tab sequence
    // ========================================================================

    /**
     * Wipe all tabbable element references.
     */
    _clearTabCycle() {
        this._debug('_clearTabCycle');
        this._tab_cycle_start = undefined;
        this._tab_cycle_first = undefined;
        this._tab_cycle_last  = undefined;
    }

    /**
     * Set the first and last tabbable element in the modal dialog.
     *
     * @param {jQuery} [$focusables]
     *
     * @returns {jQuery}
     * @protected
     */
    _setTabCycle($focusables) {
        const $items = $focusables || currentFocusablesIn(this.modalPanel);
        this._debug('_setTabCycle:', $focusables, '$items =', $items);
        this._setTabCycleFirst($items);
        this._setTabCycleLast($items);
        this._setTabCycleStart();
        return $items;
    }

    /**
     * Change the starting tabbable element for the modal dialog.
     *
     * @param {jQuery} [$target]
     *
     * @returns {jQuery|undefined}
     * @protected
     */
    _setTabCycleStart($target) {
        const $item = $target || this.tabCycleFirst;
        this._debug('_setTabCycleStart:', $target, '$item =', $item);
        return this._tab_cycle_start = $item?.focus();
    }

    /**
     * Set the first element to tab to after {@link tabCycleLast}.
     *
     * @param {jQuery} [$focusables]
     *
     * @returns {jQuery|undefined}
     * @protected
     */
    _setTabCycleFirst($focusables) {
        const $items = $focusables || currentFocusablesIn(this.modalPanel);
        this._debug('_setTabCycleFirst:', $focusables, '$items =', $items);
        const $item  = presence($items.first());
        if ($item) {
            this._handleEvent($item, 'keydown', this._onKeydownTabCycleFirst);
        }
        return this._tab_cycle_first = $item;
    }

    /**
     * Set the last tabbable element in the modal dialog.
     *
     * @param {jQuery} [$focusables]
     *
     * @returns {jQuery|undefined}
     * @protected
     */
    _setTabCycleLast($focusables) {
        const $items = $focusables || currentFocusablesIn(this.modalPanel);
        this._debug('_setTabCycleLast:', $focusables, '$items =', $items);
        const $item  = presence($items.last());
        if ($item) {
            this._handleEvent($item, 'keydown', this._onKeydownTabCycleLast);
        }
        return this._tab_cycle_last = $item;
    }

    /**
     * Intercept tabbing out of the last control in the dialog (usually the
     * Cancel button) and cause focus to wrap around to the first tabbable
     * element in the dialog.
     *
     * @param {jQuery.Event|KeyboardEvent} event
     *
     * @protected
     */
    _onKeydownTabCycleFirst(event) {
        const key = keyCombo(event);
        this._debug(`_onKeydownTabCycleFirst: key = "${key}";`, event);
        if (key === 'Shift+Tab') {
            event.preventDefault();
            this.tabCycleLast?.focus();
            this._info('TAB BACKWARD TO', this.tabCycleLast);
        }
    }

    /**
     * Intercept tabbing out of the last control in the dialog (usually the
     * Cancel button) and cause focus to wrap around to the first tabbable
     * element in the dialog.
     *
     * @param {jQuery.Event|KeyboardEvent} event
     *
     * @protected
     */
    _onKeydownTabCycleLast(event) {
        const key = keyCombo(event);
        this._debug(`_onKeydownTabCycleLast: key = "${key}";`, event);
        if (key === 'Tab') {
            event.preventDefault();
            this.tabCycleFirst?.focus();
            this._info('TAB FORWARD TO', this.tabCycleFirst);
        }
    }

    // ========================================================================
    // Methods - toggle controls
    // ========================================================================

    /**
     * Set up an activation toggle control to operate with this instance.
     *
     * @param {Selector} toggle
     *
     * @return {jQuery|undefined}
     */
    associate(toggle) {
        const func  = 'associate';
        const $ctrl = $(toggle);
        const name  = this.INSTANCE_DATA;
        const modal = $ctrl.data(name);
        if (modal === this) {
            this._debug(`${func}: modal already associated with`, $ctrl);
        } else if (modal) {
            return this._warn(`${func}: already associated:`, $ctrl, modal);
        } else if (NavGroup.shouldContain($ctrl)) {
            this._debug(`${func}: defer to nav group for toggle =`, $ctrl);
            $ctrl.data(name, this);
        } else {
            this._debug(`${func}: modal with toggle =`, $ctrl);
            this._handleClickAndKeypress($ctrl, this.onToggleModal);
            $ctrl.data(name, this);
        }
        return $ctrl;
    }

    /**
     * Set up a modal popup panel to operate with this instance.
     *
     * @param {Selector} panel
     *
     * @return {jQuery}
     */
    setupPanel(panel) {
        const func     = 'setupPanel'; this._debug(`${func}: panel =`, panel);
        const name     = this.INSTANCE_DATA;
        const $modal   = this.$modal = $(panel);
        const instance = $modal.data(name);
        if (instance) {
            this._debug(`${func}: already linked; panel =`, $modal, instance);
        } else {
            $modal.data(name, this);
            this._setModalHidden(true); // Just in case...
            this._handleClickAndKeypress(this.closers, this.onToggleModal);
        }
        return $modal;
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * Set a class instance method as an event handler.
     *
     * @param {Selector}           element
     * @param {string}             name         Event name.
     * @param {jQueryEventHandler} method       Event handler method.
     *
     * @returns {jQuery}
     * @protected
     */
    _handleEvent(element, name, method) {
        return handleEvent(element, name, method.bind(this));
    }

    /**
     * Set a class instance method as a click and key press event handler.
     *
     * @param {Selector}           element
     * @param {jQueryEventHandler} method       Event handler method.
     *
     * @returns {jQuery}
     * @protected
     */
    _handleClickAndKeypress(element, method) {
        return handleClickAndKeypress(element, method.bind(this));
    }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Extract the associated ModalBase instance.
     *
     * @param {Selector|undefined} target
     *
     * @returns {ModalBase|undefined}
     */
    static instanceFor(target) {
        return target ? $(target).data(this.INSTANCE_DATA) : undefined;
    }

    // ========================================================================
    // Methods - diagnostics
    // ========================================================================

    /**
     * Report on the modal popup instance.
     *
     * @param {string}   label
     * @param {Selector} [target]
     *
     * @protected
     */
    _debugModal(label, target) {
        if (!this._debugging) { return }
        const func    = label.endsWith(':') ? label : `${label}:`;
        const $modal  = this.modalPanel;
        const $toggle = this.modalControl;
        const $target = target && $(target);
        const $ctrl   = $target || $toggle;
        const parts   = [];
        parts.push('| id',             ($modal?.data('id')            || '-'));
        parts.push('| page',           ($modal?.data('page')          || '-'));
        parts.push('| topic',          ($modal?.data('topic')         || '-'));
        parts.push('| ModalShowHooks', ($ctrl?.data('ModalShowHooks') || '-'));
        parts.push('| ModalHideHooks', ($ctrl?.data('ModalHideHooks') || '-'));
        parts.push(`| ${$target ? '$target' : '$toggle'}`, ($ctrl || '-'));
        this._debug(func, ...parts);
    }

}
