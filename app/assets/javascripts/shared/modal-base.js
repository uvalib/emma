// app/assets/javascripts/shared/modal-base.js
//
// noinspection LocalVariableNamingConventionJS, JSUnusedGlobalSymbols


import { AppDebug }                            from '../application/debug';
import { Emma }                                from './assets';
import { BaseClass }                           from './base-class';
import { decodeObject }                        from './decode';
import { handleClickAndKeypress, handleEvent } from './events';
import { findTabbable, scrollIntoView }        from './html';
import { ModalHideHooks, ModalShowHooks }      from './modal_hooks';
import {
    elementSelector,
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
    presence
} from './definitions';


const MODULE = 'ModalBase';
const DEBUG  = true;

AppDebug.file('shared/modal-base', MODULE, DEBUG);

// ============================================================================
// Type definitions
// ============================================================================

/**
 * The signature of a callback function that can be provided via
 * `.data('ModalShowHooks') on the popup toggle button.
 *
 * If the function returns *false* then {@link _showPopup} will not allow the
 * popup to open (and will avoid fetching any related deferred content if
 * applicable).
 *
 * @typedef {CallbackChainFunction} onShowModalHook
 */

/**
 * The signature of a callback function that can be provided via
 * `.data('ModalHideHooks') on the popup toggle button.
 *
 * If then function returns *false* then {@link _hidePopup} will not allow the
 * popup to close.
 *
 * @typedef {CallbackChainFunction} onHideModalHook
 */

// ============================================================================
// Class ModalBase
// ============================================================================

export class ModalBase extends BaseClass {

    static CLASS_NAME = 'ModalBase';
    static DEBUGGING  = DEBUG;

    // ========================================================================
    // Constants
    // ========================================================================

    static COMPLETE_MARKER = 'complete';
    static Z_ORDER_MARKER  = 'z-order-capture';
    static PANEL_CLASS     = Emma.Popup.panel.class;
    static CLOSER_CLASS    = Emma.Popup.closer.class;

    static COMPLETE        = selector(this.COMPLETE_MARKER);
    static PANEL           = selector(this.PANEL_CLASS);
    static DEFERRED        = selector(Emma.Popup.deferred.class);
    static TOGGLE          = selector(Emma.Popup.button.class);
    static CLOSER          = `.${this.CLOSER_CLASS}, [type="submit"]`;

    /**
     * The .data() name on modal toggles and/or modal panels with a link to an
     * instance of this class.
     *
     * @readonly
     * @type {string}
     */
    static MODAL_INSTANCE_DATA = 'modalInstance';

    // ========================================================================
    // Constants - z-order
    // ========================================================================

    /**
     * The .data() value assigned to a popup which is overtaking z-order on the
     * page by neutralizing the z-index for elements outside its stacking
     * context. This value holds the set of elements which have been affected.
     *
     * @readonly
     * @type {string}
     */
    static Z_CAPTURES_DATA = 'z-captured-elements';

    /**
     * The .data() value assigned to an element whose z-index has been
     * neutralized which holds the original z-index value to be restored.
     *
     * @readonly
     * @type {string}
     */
    static Z_RESTORE_DATA = 'current-z-index';

    // ========================================================================
    // Fields
    // ========================================================================

    /**
     * The control which currently "owns" this instance (and the associated
     * modal popup element).
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
        this._debug(`ModalBase ctor: control =`, control);
        this._debug(`ModalBase ctor: modal =`, modal);
        this.$toggle = control && this.associate(control);
        this.$modal  = modal   && this.setupPanel(modal);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get modalPanel()         { return this.$modal }
    get modalControl()       { return this.$toggle }
    set modalControl(toggle) { this.$toggle = toggle ? $(toggle) : undefined }

    get isOpen()   { return !this.isClosed }
    get isClosed() { return isHidden(this.modalPanel) }
    get closers()  { return this.modalPanel.find(this.constructor.CLOSER) }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Open the popup element.
     *
     * @param {boolean} [no_halt]     If *true*, hooks cannot halt the chain.
     *
     * @returns {boolean}
     */
    open(no_halt) {
        this._debug('open: no_halt =', no_halt);
        if (this.isClosed) {
            return this._showPopup(undefined, no_halt);
        } else {
            this._warn('modal popup already open');
            return true;
        }
    }

    /**
     * Close the popup element.
     *
     * @param {boolean}  [no_halt]    If *true*, hooks cannot halt the chain.
     *
     * @returns {boolean}
     */
    close(no_halt) {
        this._debug('close: no_halt =', no_halt);
        if (this.isOpen) {
            return this._hidePopup(undefined, no_halt);
        } else {
            this._warn('modal popup already closed');
            return true;
        }
    }

    // ========================================================================
    // Methods
    // ========================================================================

    /**
     * Toggle visibility of the modal element.
     *
     * @param {jQuery.Event} event
     *
     * @returns {boolean}
     */
    onToggleModal(event) {
        event.stopPropagation();
        this._debug('onToggleModal', event);
        this.toggleModal(event.currentTarget || event.target);
        return false;
    }

    /**
     * Toggle visibility of the associated popup.
     *
     * On any given cycle, the first execution of this method should be due to
     * the user pressing a toggle button.  That button is set here as the
     * current "owner" of the modal dialog.
     *
     * @param {Selector} [target]     Default: {@link modalControl}.
     */
    toggleModal(target) {
        const func  = 'toggleModal';
        this._debug(`${func}: target =`, target);
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
            this._togglePopupIframe($target, func);
        } else {
            this._togglePopupContent($target, func);
        }
    }

    /**
     * Toggle visibility of an <iframe> or <img> popup.
     *
     * @param {Selector} target       Event target causing the action.
     * @param {string}   [caller]
     *
     * @protected
     */
    _togglePopupIframe(target, caller) {
        let func = caller ? `${caller}: IFRAME` : '_togglePopupIframe';

        const $target      = target ? $(target) : this.modalControl;
        const $modal       = this.modalPanel;
        const $iframe      = $modal.children('iframe');
        const $placeholder = $modal.children(this.constructor.DEFERRED);
        const complete     = $modal.is(this.constructor.COMPLETE);
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
            this._debug(`${func}: RE-OPENING`);
            if (this._showPopup($target)) {
                this.scrollIntoView();
                this.scrollFrameDocument($iframe, $modal.data('topic'));
            }

        } else if (opening) {
            // Fetch deferred content when the popup is unhidden the first time
            // (or after being deleted below after closing).
            this._debug(`${func}: LOADING`);
            if (this._showPopup($target)) {
                $placeholder.each((_, p) => this._loadDeferredContent(p));
            }

        } else if (complete) {
            // If the <iframe> exists and contains a different page than the
            // original then remove it in order to re-fetch the original the
            // next time it is opened.
            if (this._checkHidePopup($target)) {
                const refetch       = $modal.hasClass('refetch');
                const expected_page = $modal.data('page');
                const content       = $iframe[0].contentDocument;
                const current_page  = content?.location?.pathname;
                if (!refetch && (expected_page === current_page)) {
                    this._debug(`${func}: CLOSING`, current_page);
                } else {
                    this._debug(`${func}: CLOSING - REMOVING`, current_page);
                    toggleHidden($placeholder, false);
                    $iframe.remove();
                    $modal.removeClass(this.constructor.COMPLETE_MARKER);
                }
                this._hidePopup($target, true);
            }

        } else {
            this._warn(`${func}: CLOSING - INCOMPLETE POPUP`);
            this._hidePopup($target);
        }
    }

    /**
     * Fetch deferred content as indicated by the placeholder element, which
     * may be either an <iframe> or an <img>.
     *
     * @param {Selector} placeholder
     *
     * @protected
     */
    _loadDeferredContent(placeholder) {

        const func            = '_loadDeferredContent';
        const _warn           = this._warn.bind(this);
        const _debug          = this._debug.bind(this);
        const showPopup       = this._showPopup.bind(this);
        const hidePopup       = this._hidePopup.bind(this);
        const scrollIntoView  = this.scrollIntoView.bind(this);
        const scrollFrame     = this.scrollFrameDocument.bind(this);
        const COMPLETE_MARKER = this.constructor.COMPLETE_MARKER;
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

        /**
         * If there was a problem with loading the popup content, display
         * a message in the popup placeholder element.
         *
         * @param {jQuery.Event} event
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
         * When the popup content is loaded replace the placeholder <iframe>
         * with the content <iframe>.  If an anchor (initial element ID) was
         * specified by the 'data-topic' attribute in the placeholder, scroll
         * the <iframe> to bring the element with that ID to the top of the
         * panel display.
         *
         * @param {jQuery.Event} event
         */
        function onLoad(event) {
            if ($modal.hasClass(COMPLETE_MARKER)) {

                // The user has clicked on a link within the <iframe> and a new
                // page has been loaded into it.
                _debug(`${func}: ${type} PAGE REPLACED`);

            } else {

                // The initial load of the popup target page.
                _debug(`${func}: ${type} LOAD`);
                const iframe = $content[0].contentDocument;
                const topic  = $placeholder.attr('data-topic');

                // Record the initial page and anchor displayed in the <iframe>
                $modal.data('id',    $content[0].id); // For logging.
                $modal.data('page',  iframe.location.pathname);
                $modal.data('topic', topic);
                $modal.addClass(COMPLETE_MARKER);

                // Replace the placeholder with the downloaded content.
                toggleHidden($placeholder, true);
                toggleHidden($content, false);

                // Prepare to handle key presses that are directed to the
                // <iframe>.
                handleEvent($content.contents(), 'keyup', onIframeKeyUp);

                // Make sure the associated popup element is displayed and
                // scrolled into position.
                showPopup(undefined, true);
                scrollIntoView();
                scrollFrame($content, topic);
            }
        }

        // noinspection FunctionWithInconsistentReturnsJS
        /**
         * Allow "Escape" key from within the <iframe> to close the popup.
         *
         * Re-focus on the parent window so that the hidden popup does not
         * continue to intercept keypress events.
         *
         * @param {jQuery.Event|KeyboardEvent} event
         */
        function onIframeKeyUp(event) {
            const key = event.key;
            if (key === 'Escape') {
                _debug('ESC pressed in popup', $modal.data('id'));
                if (hidePopup(event.target)) {
                    window.parent.focus();
                    return false;
                }
            }
        }
    }

    /**
     * Toggle visibility of a generic content popup.
     *
     * @param {Selector} target       Event target causing the action.
     * @param {string}   [caller]
     *
     * @protected
     */
    _togglePopupContent(target, caller) {
        const func         = caller || '_togglePopupContent';
        const $target      = target ? $(target) : this.modalControl;
        const $modal       = this.modalPanel;
        const $placeholder = $modal.children('.placeholder');
        const complete     = $modal.is(this.constructor.COMPLETE);
        const opening      = this.isClosed;

        if (opening && complete) {
            // If the existing hidden popup can be re-used, ensure that it is
            // fully visible.
            this._debug(`${func}: RE-OPENING`);
            if (this._showPopup($target)) {
                this.scrollIntoView();
            }

        } else if (opening && isPresent($placeholder)) {
            // Initialize content when the popup is unhidden the first time
            // (or after being deleted below after closing).
            this._debug(`${func}: INITIALIZING`);
            if (this._showPopup($target)) {
                $placeholder.each((_, p) => this._loadDirectContent(p));
            }

        } else if (opening) {
            this._debug(`${func}: OPENING`);
            if (this._showPopup($target)) {
                $modal.addClass(this.constructor.COMPLETE_MARKER);
            }

        } else if (complete) {
            this._debug(`${func}: CLOSING`);
            this._hidePopup($target);

        } else {
            this._warn(`${func}: CLOSING - INCOMPLETE POPUP`);
            this._hidePopup($target);
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
        const _debug          = this._debug.bind(this);
        const showPopup       = this._showPopup.bind(this);
        const scrollIntoView  = this.scrollIntoView.bind(this);
        const COMPLETE_MARKER = this.constructor.COMPLETE_MARKER;
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
         * If there was a problem with loading the popup content, display
         * a message in the popup placeholder element.
         *
         * @param {jQuery.Event} event
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
         * When the popup content is loaded replace the placeholder <div>
         * with the content <div>.
         *
         * @param {jQuery.Event} event
         */
        function onLoad(event) {
            if ($modal.hasClass(COMPLETE_MARKER)) {

                // The user has clicked on a link within the <dev> and a new
                // page has been loaded into it.
                _debug(`${func}: PAGE REPLACED`);

            } else {

                // The initial load of the popup target content.
                _debug(`${func}: LOAD`);
                $modal.data('id', $content[0].id); // For logging.
                $modal.addClass(COMPLETE_MARKER);

                // Replace the placeholder with the downloaded content.
                toggleHidden($placeholder, true);
                toggleHidden($content, false);

                // Make sure the associated popup element is displayed and
                // scrolled into position.
                showPopup(undefined, true);
                scrollIntoView();
            }
        }
    }

    /**
     * Scroll popup into view.
     *
     * @returns {jQuery}
     */
    scrollIntoView() {
        return scrollIntoView(this.modalPanel);
    }

    /**
     * Scroll the <iframe> content to the indicated anchor.
     *
     * @note Move outside of class?
     *
     * @param {Selector} iframe
     * @param {string}   [topic]      Default: top of document.
     */
    scrollFrameDocument(iframe, topic) {
        const $iframe = $(iframe);
        const id      = $iframe.attr('id') || '???';
        const func    = `scrollFrameDocument: popup ${id}`;
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
     * Open the popup element.
     *
     * @param {Selector} [target]     Event target causing the action.
     * @param {boolean}  [no_halt]    If *true*, hooks cannot halt the chain.
     *
     * @returns {boolean}
     * @protected
     */
    _showPopup(target, no_halt) {
        const func = '_showPopup';
        this._debugPopup(func);
        if ((this._invokeOnShowPopup(target) !== false) || no_halt) {
            this._zOrderCapture();
            this._setPopupHidden(false);
            this.setTabCycle();
            return true;
        } else {
            this._warn(`${func}: chain halted`);
            return false;
        }
    }

    /**
     * Close the popup element.
     *
     * @param {Selector} [target]     Event target causing the action.
     * @param {boolean}  [no_halt]    If *true*, hooks cannot halt the chain.
     *
     * @returns {boolean}
     * @protected
     */
    _hidePopup(target, no_halt) {
        const func = '_hidePopup';
        this._debugPopup(func);
        if ((this._invokeOnHidePopup(target) !== false) || no_halt) {
            this._setPopupHidden(true);
            this._zOrderRelease();
            this.clearTabCycle();
            return true;
        } else {
            this._warn(`${func}: chain halted`);
            return false;
        }
    }

    /**
     * Show/hide the popup element.
     *
     * @param {boolean} [hide]        If *false*, un-hide.
     *
     * @protected
     */
    _setPopupHidden(hide) {
        const hidden = (hide !== false);
        toggleHidden(this.modalPanel, hidden);
    }

    // ========================================================================
    // Methods - event hooks
    // ========================================================================

    /**
     * Pre-clear the ability to open the popup.
     *
     * @param {Selector} [target]     Event target causing the action.
     *
     * @returns {boolean}
     * @protected
     */
    _checkShowPopup(target) {
        return (this._invokeOnShowPopup(target, true) !== false);
    }

    /**
     * Pre-clear the ability to close the popup.
     *
     * @param {Selector} [target]     Event target causing the action.
     *
     * @returns {boolean}
     * @protected
     */
    _checkHidePopup(target) {
        return (this._invokeOnHidePopup(target, true) !== false);
    }

    /**
     * _invokeOnShowPopup
     *
     * @param {Selector} [target]     Event target causing the action.
     * @param {boolean}  [check_only]
     *
     * @returns {boolean|undefined}
     * @protected
     */
    _invokeOnShowPopup(target, check_only) {
        const name = ModalShowHooks.dataName;
        return this._invokePopupHook(name, target, check_only);
    }

    /**
     * _invokeOnHidePopup
     *
     * @param {Selector} [target]     Event target causing the action.
     * @param {boolean}  [check_only]
     *
     * @returns {boolean|undefined}
     * @protected
     */
    _invokeOnHidePopup(target, check_only) {
        const name = ModalHideHooks.dataName;
        return this._invokePopupHook(name, target, check_only);
    }

    /**
     * _invokePopupHook
     *
     * @param {string}   data_name
     * @param {Selector} [target]     Event target causing the action.
     * @param {boolean}  [check_only]
     *
     * @returns {boolean|undefined}
     * @protected
     */
    _invokePopupHook(data_name, target, check_only) {
        const $toggle = this.modalControl;
        const chain   = $toggle?.data(data_name);
        return chain?.invoke((target || $toggle), check_only);
    }

    // ========================================================================
    // Methods - z-order
    // ========================================================================

    /**
     * Indicate whether the popup is intended to stack above all other
     * elements.
     *
     * @returns {boolean}
     * @protected
     */
    get _zOrderCapturing() {
        return this.modalPanel.hasClass(this.constructor.Z_ORDER_MARKER)
    }

    /**
     * Cheat working out the proper stacking context hierarchy by causing all
     * elements with a non-zero z-index to be neutralized.
     *
     * The function returns early if it has already been run for this popup.
     *
     * @protected
     */
    _zOrderCapture() {
        const Z_CAPTURES_DATA = this.constructor.Z_CAPTURES_DATA;
        const Z_RESTORE_DATA  = this.constructor.Z_RESTORE_DATA;
        if (!this._zOrderCapturing || this.modalPanel.data(Z_CAPTURES_DATA)) {
            return;
        }
        let z_captures = [];
        $('*:visible').not(this.modalPanel).each((_, element) => {
            const $element = $(element);
            const z = $element.css('z-index');
            if (z > 0) {
                $element.data(Z_RESTORE_DATA, z);
                $element.css('z-index', -1);
                z_captures.push($element);
                this._debug(
                    `CAPTURE z-index = ${z} from ${elementSelector($element)}`
                );
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
        const Z_CAPTURES_DATA = this.constructor.Z_CAPTURES_DATA;
        const Z_RESTORE_DATA  = this.constructor.Z_RESTORE_DATA;
        const z_captures      = this.modalPanel.data(Z_CAPTURES_DATA);
        if (isPresent(z_captures)) {
            z_captures.forEach($element => {
                const z = $element.data(Z_RESTORE_DATA);
                $element.css('z-index', z);
                this._debug(
                    `RELEASE z-index = ${z} to ${elementSelector($element)}`
                );
            });
        }
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
     * Set the first element to tab to after {@link tabCycleLast}.
     *
     * @param {jQuery} $items
     */
    set tabCycleFirst($items) {
        this._setTabCycleFirst($items);
    }

    /**
     * Get the last tabbable element in the modal dialog.
     *
     * @returns {jQuery|undefined}
     */
    get tabCycleLast() {
        return this._tab_cycle_last || this._setTabCycleLast();
    }

    /**
     * Set the last tabbable element in the modal dialog.
     *
     * @param {jQuery} $items
     */
    set tabCycleLast($items) {
        this._setTabCycleLast($items);
    }

    // ========================================================================
    // Methods - tab sequence
    // ========================================================================

    /**
     * Wipe all tabbable element references.
     */
    clearTabCycle() {
        this._tab_cycle_start = undefined;
        this._tab_cycle_first = undefined;
        this._tab_cycle_last  = undefined;
    }

    /**
     * Set the first and last tabbable element in the modal dialog.
     *
     * @param {jQuery} [$tabbables]
     */
    setTabCycle($tabbables) {
        const $items = $tabbables || findTabbable(this.modalPanel);
        this._setTabCycleFirst($items);
        this._setTabCycleLast($items);
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
        $item?.focus();
        return this._tab_cycle_start = $item;
    }

    /**
     * Set the first element to tab to after {@link tabCycleLast}.
     *
     * @param {jQuery} [$tabbables]
     *
     * @returns {jQuery|undefined}
     * @protected
     */
    _setTabCycleFirst($tabbables) {
        const $items = $tabbables || findTabbable(this.modalPanel);
        const $item  = presence($items.first());
        if ($item) {
            this._handleEvent($item, 'keydown', this._onKeydownTabCycleFirst);
        }
        return this._tab_cycle_first = $item;
    }

    /**
     * Set the last tabbable element in the modal dialog.
     *
     * @param {jQuery} [$tabbables]
     *
     * @returns {jQuery|undefined}
     * @protected
     */
    _setTabCycleLast($tabbables) {
        const $items = $tabbables || findTabbable(this.modalPanel);
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
        const key = event.key;
        this._debug(`_onKeydownTabCycleFirst: key = ${key}`, event);
        if ((key === 'Tab') && event.shiftKey) { // Shift-TAB
            event.preventDefault();
            this.tabCycleLast?.focus();
            this._debug('TAB BACKWARD TO', this.tabCycleLast);
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
        const key = event.key;
        this._debug(`_onKeydownTabCycleLast: key = ${key}`, event);
        if ((key === 'Tab') && !event.shiftKey) { // TAB
            event.preventDefault();
            this.tabCycleFirst?.focus();
            this._debug('TAB FORWARD TO', this.tabCycleFirst);
        }
    }

    // ========================================================================
    // Methods - toggle controls
    // ========================================================================

    /**
     * Set up a modal toggle to operate with this instance.
     *
     * @param {Selector} toggle
     *
     * @return {jQuery|undefined}
     */
    associate(toggle) {
        this._debug('associate: toggle =', toggle);
        let $toggle = $(toggle);
        const name  = this.constructor.MODAL_INSTANCE_DATA;
        const modal = $toggle.data(name);
        if (modal === this) {
            this._debug('this modal already associated with toggle', toggle);
        } else if (modal) {
            this._warn('toggle', toggle, 'already associated with', modal);
            $toggle = undefined;
        } else {
            $toggle.data(name, this);
            this._handleClickAndKeypress($toggle, this.onToggleModal);
        }
        return $toggle;
    }

    /**
     * Set up a modal popup panel to operate with this instance.
     *
     * @param {Selector} panel
     *
     * @return {jQuery}
     */
    setupPanel(panel) {
        this._debug('setupPanel: panel =', panel);
        const name  = this.constructor.MODAL_INSTANCE_DATA;
        this.$modal = $(panel);
        if (this.$modal.data(name)) {
            this._error('modal panel already linked', this.$modal);
        } else {
            this.$modal.data(name, this);
            this._setPopupHidden(true); // Just in case...
            this._handleClickAndKeypress(this.closers, this.onToggleModal);
        }
        return this.$modal;
    }

    // ========================================================================
    // Methods - internal
    // ========================================================================

    /**
     * Set a class method as an event handler.
     *
     * @param {jQuery}             $element
     * @param {string}             name         Event name.
     * @param {jQueryEventHandler} method       Event handler method.
     *
     * @returns {jQuery}
     * @protected
     */
    _handleEvent($element, name, method) {
        const func = method.bind(this);
        return handleEvent($element, name, func);
    }

    /**
     * Set a class method as a click and keypress event handler.
     *
     * @param {jQuery}             $element
     * @param {jQueryEventHandler} method       Event handler method.
     *
     * @returns {jQuery}
     * @protected
     */
    _handleClickAndKeypress($element, method) {
        const func = method.bind(this);
        return handleClickAndKeypress($element, func);
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
        return target && $(target).data(this.MODAL_INSTANCE_DATA);
    }

    // ========================================================================
    // Methods - diagnostics
    // ========================================================================

    /**
     * Report on the popup.
     *
     * @param {string}   label
     * @param {Selector} [popup]
     *
     * @protected
     */
    _debugPopup(label, popup) {
        if (!this._debugging) { return }
        const func    = label.endsWith(':') ? label : `${label}:`;
        const $modal  = this.modalPanel;
        const $toggle = this.modalControl;
        this._debug(func,
            '| id',             ($modal?.data('id')              || '-'),
            '| page',           ($modal?.data('page')            || '-'),
            '| topic',          ($modal?.data('topic')           || '-'),
            '| ModalShowHooks', ($toggle?.data('ModalShowHooks') || '-'),
            '| ModalHideHooks', ($toggle?.data('ModalHideHooks') || '-'),
            '| $toggle',        ($toggle                         || '-')
        );
    }

}
