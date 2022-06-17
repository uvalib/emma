// app/assets/javascripts/shared/modal-base.js
// noinspection LocalVariableNamingConventionJS


import { Emma }                                from '../shared/assets'
import { BaseClass }                           from '../shared/base-class'
import { elementSelector, selector }           from '../shared/css'
import { decodeObject }                        from '../shared/decode'
import { handleClickAndKeypress, handleEvent } from '../shared/events'
import { findTabbable, scrollIntoView }        from '../shared/html'
import { ModalHideHooks, ModalShowHooks }      from '../shared/modal_hooks'
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
    notDefined,
    presence
} from '../shared/definitions'


// ============================================================================
// Type definitions
// ============================================================================

/**
 * The signature of a callback function that can be provided via
 * `.data('ModalShowHooks') on the popup toggle button.
 *
 * If the function returns *false* then {@link showPopup} will not allow the
 * popup to open (and will avoid fetching any related deferred content if
 * applicable).
 *
 * @typedef {CallbackChainFunction} onShowModalHook
 */

/**
 * The signature of a callback function that can be provided via
 * `.data('ModalHideHooks') on the popup toggle button.
 *
 * If then function returns *false* then {@link hidePopup} will not allow the
 * popup to close.
 *
 * @typedef {CallbackChainFunction} onHideModalHook
 */

// ============================================================================
// Class ModalBase
// ============================================================================

export class ModalBase extends BaseClass {

    static CLASS_NAME = 'ModalBase';
    static DEBUGGING  = false;

    // ========================================================================
    // Constants
    // ========================================================================

    static HIDDEN_MARKER   = Emma.Popup.hidden.class;
    static COMPLETE_MARKER = 'complete';
    static Z_ORDER_MARKER  = 'z-order-capture';
    static PANEL_CLASS     = Emma.Popup.panel.class;
    static CLOSER_CLASS    = Emma.Popup.closer.class;

    static HIDDEN          = selector(this.HIDDEN_MARKER);
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
    static MODAL_INSTANCE = 'modalInstance';

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
        this.$toggle = control && this.associate(control);
        this.$modal  = modal   && this.setupPanel(modal);
    }

    // ========================================================================
    // Properties
    // ========================================================================

    get isOpen()   { return !this.isClosed }
    get isClosed() { return this.$modal.is(this.constructor.HIDDEN) }
    get closers()  { return this.$modal.find(this.constructor.CLOSER) }

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
        if (this.isClosed) {
            return this.showPopup(undefined, no_halt);
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
        if (this.isOpen) {
            return this.hidePopup(undefined, no_halt);
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
        this._debugEvent('onToggleModal', event);
        this.toggleModal(event.target);
        return false;
    }

    /**
     * Toggle visibility of the associated popup.
     *
     * @param {Selector} [target]     Default: {@link $toggle}.
     */
    toggleModal(target) {
        const func  = 'toggleModal:';
        let $target = target ? $(target) : this.$toggle;
        if (this.$modal.children().is('.iframe, .img')) {
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
        let func         = caller ? `${caller} IFRAME` : '_togglePopupIframe';
        let $target      = $(target);
        let $iframe      = this.$modal.children('iframe');
        let $placeholder = this.$modal.children(this.constructor.DEFERRED);
        const opening    = this.$modal.is(this.constructor.HIDDEN);
        const complete   = this.$modal.is(this.constructor.COMPLETE);

        // Include the ID of the iframe for logging.
        if (this.DEBUGGING) {
            let id = this.$modal.data('id') || $iframe.attr('id');
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
            if (this.showPopup($target)) {
                this.scrollIntoView();
                this.scrollFrameDocument($iframe, this.$modal.data('topic'));
            }

        } else if (opening) {
            // Fetch deferred content when the popup is unhidden the first time
            // (or after being deleted below after closing).
            this._debug(`${func}: LOADING`);
            if (this.showPopup($target)) {
                $placeholder.each((_, p) => this._loadDeferredContent(p));
            }

        } else if (complete) {
            // If the <iframe> exists and contains a different page than the
            // original then remove it in order to re-fetch the original the
            // next time it is opened.
            if (this._checkHidePopup($target)) {
                const refetch       = this.$modal.hasClass('refetch');
                const expected_page = this.$modal.data('page');
                const content       = $iframe[0].contentDocument;
                const current_page  = content?.location?.pathname;
                if (!refetch && (expected_page === current_page)) {
                    this._debug(`${func}: CLOSING`, current_page);
                } else {
                    this._debug(`${func}: CLOSING - REMOVING`, current_page);
                    $placeholder.removeClass(this.constructor.HIDDEN_MARKER);
                    $iframe.remove();
                    this.$modal.removeClass(this.constructor.COMPLETE_MARKER);
                }
                this.hidePopup($target, true);
            }

        } else {
            this._warn(`${func}: CLOSING - INCOMPLETE POPUP`);
            this.hidePopup($target);
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
        const showPopup       = this.showPopup.bind(this);
        const hidePopup       = this.hidePopup.bind(this);
        const scrollIntoView  = this.scrollIntoView.bind(this);
        const scrollFrame     = this.scrollFrameDocument.bind(this);
        const HIDDEN_MARKER   = this.constructor.HIDDEN_MARKER;
        const COMPLETE_MARKER = this.constructor.COMPLETE_MARKER;
        let $modal            = this.$modal;
        let $placeholder      = $(placeholder);
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
        let $content = $(`<${type}>`);
        if (isPresent(attributes)) { $content.attr(decodeObject(attributes)) }
        $content.addClass(HIDDEN_MARKER);
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
                $placeholder.addClass(HIDDEN_MARKER);
                $content.removeClass(HIDDEN_MARKER);

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
        const func       = caller || '_togglePopupContent';
        let $target      = $(target);
        let $placeholder = this.$modal.children('.placeholder');
        const opening    = this.$modal.is(this.constructor.HIDDEN);
        const complete   = this.$modal.is(this.constructor.COMPLETE);

        if (opening && complete) {
            // If the existing hidden popup can be re-used, ensure that it is
            // fully visible.
            this._debug(`${func}: RE-OPENING`);
            if (this.showPopup($target)) {
                this.scrollIntoView();
            }

        } else if (opening && isPresent($placeholder)) {
            // Initialize content when the popup is unhidden the first time
            // (or after being deleted below after closing).
            this._debug(`${func}: INITIALIZING`);
            if (this.showPopup($target)) {
                const load_direct = this._loadDirectContent.bind(this);
                $placeholder.each((_, p) => load_direct(p));
            }

        } else if (opening) {
            this._debug(`${func}: OPENING`);
            if (this.showPopup($target)) {
                this.$modal.addClass(this.constructor.COMPLETE_MARKER);
            }

        } else if (complete) {
            this._debug(`${func}: CLOSING`);
            this.hidePopup($target);

        } else {
            this._warn(`${func}: CLOSING - INCOMPLETE POPUP`);
            this.hidePopup($target);
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
        const showPopup       = this.showPopup.bind(this);
        const scrollIntoView  = this.scrollIntoView.bind(this);
        const HIDDEN_MARKER   = this.constructor.HIDDEN_MARKER;
        const COMPLETE_MARKER = this.constructor.COMPLETE_MARKER;
        let $modal            = this.$modal;
        let $placeholder      = $(placeholder);
        const source_url      = $placeholder.attr('data-path');
        const attributes      = $placeholder.attr('data-attr');

        // Validate parameters and return if there is missing information.
        if (isMissing(source_url)) {
            _warn(`${func}: no source URL`);
            return;
        }

        // Setup the element that will actually contain the received content
        // then fetch it.  The element will appear only if successfully loaded.
        let $content = $('<embed>');
        if (isPresent(attributes)) { $content.attr(decodeObject(attributes)) }
        $content.addClass(HIDDEN_MARKER);
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
                $placeholder.addClass(HIDDEN_MARKER);
                $content.removeClass(HIDDEN_MARKER);

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
        return scrollIntoView(this.$modal);
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
        let $iframe = $(iframe);
        const id    = $iframe.attr('id') || '???';
        const func  = `scrollFrameDocument: popup ${id}`;
        let doc     = $iframe[0]?.contentDocument;
        let anchor  = topic?.replace(/^#/, '');
        let section = anchor && doc?.getElementById(anchor);
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
     */
    showPopup(target, no_halt) {
        const func = 'showPopup';
        this._debugPopups(func);
        if ((this._invokeOnShowPopup(target) !== false) || no_halt) {
            this._zOrderCapture();
            this._toggleHidden(false);
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
     */
    hidePopup(target, no_halt) {
        const func = 'hidePopup';
        this._debugPopups(func);
        if ((this._invokeOnHidePopup(target) !== false) || no_halt) {
            this._toggleHidden(true);
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
     * @param {boolean} [hide]        If *true*, un-hide.
     *
     * @protected
     */
    _toggleHidden(hide) {
        const hidden = notDefined(hide) || hide;
        this.$modal.attr('aria-hidden', hidden);
        this.$modal.toggleClass(this.constructor.HIDDEN_MARKER, hidden);
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
        let $toggle = this.$toggle;
        const chain = $toggle?.data(data_name);
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
        return this.$modal.hasClass(this.constructor.Z_ORDER_MARKER)
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
        if (!this._zOrderCapturing || this.$modal.data(Z_CAPTURES_DATA)) {
            return;
        }
        let z_captures = [];
        $('*:visible').not(this.$modal).each((_, element) => {
            let $element = $(element);
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
        this.$modal.data(Z_CAPTURES_DATA, z_captures);
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
        const z_captures      = this.$modal.data(Z_CAPTURES_DATA);
        if (isPresent(z_captures)) {
            z_captures.forEach($element => {
                const z = $element.data(Z_RESTORE_DATA);
                $element.css('z-index', z);
                this._debug(
                    `RELEASE z-index = ${z} to ${elementSelector($element)}`
                );
            });
        }
        this.$modal.data(Z_CAPTURES_DATA, false);
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
        let $items = $tabbables || findTabbable(this.$modal);
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
        let $item = $target || this.tabCycleFirst;
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
        let $items = $tabbables || findTabbable(this.$modal);
        let $item  = presence($items.first());
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
        let $items = $tabbables || findTabbable(this.$modal);
        let $item  = presence($items.last());
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
        this._debugEvent(`_onKeydownTabCycleFirst | key = ${key}`, event);
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
        this._debugEvent(`_onKeydownTabCycleLast | key = ${key}`, event);
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
     * @return {jQuery}
     */
    associate(toggle) {
        const name   = this.constructor.MODAL_INSTANCE;
        let $toggle  = $(toggle);
        let instance = $toggle.data(name);
        if (instance) {
            this._warn('toggle', toggle);
            this._warn('already associated with', instance);
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
        const name  = this.constructor.MODAL_INSTANCE;
        this.$modal = $(panel);
        if (this.$modal.data(name)) {
            this._error('modal panel already linked', this.$modal);
        } else {
            this.$modal.data(name, this);
            this._toggleHidden(true);
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
     */
    _handleClickAndKeypress($element, method) {
        const func = method.bind(this);
        return handleClickAndKeypress($element, func);
    }

    // ========================================================================
    // Class methods
    // ========================================================================

    /**
     * Create new instance of the current class.
     *
     * @returns {ModalBase}
     */
    static new(...args) {
        return new this(...args);
    }

    /**
     * Extract the associated ModalBase instance.
     *
     * @param {Selector} target
     *
     * @returns {ModalBase|undefined}
     */
    static instanceFor(target) {
        return $(target).data(this.MODAL_INSTANCE);
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
    _debugPopups(label, popup) {
        if (this.DEBUGGING) {
            const func    = label.endsWith(':') ? label : `${label}:`;
            const $modal  = this.$modal;
            const $toggle = this.$toggle;
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

    /**
     * Report on an event.
     *
     * @param {string}             label
     * @param {jQuery.Event|Event} event
     *
     * @returns {undefined}
     * @protected
     */
    _debugEvent(label, event) {
        this._debug(`*** ${label} ***`, event);
    }

}
