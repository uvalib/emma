// app/assets/javascripts/feature/popup.js


import { Emma }                                  from '../shared/assets'
import { elementSelector, selector }             from '../shared/css'
import { decodeObject }                          from '../shared/decode'
import { handleClickAndKeypress, handleEvent }   from '../shared/events'
import { scrollIntoView }                        from '../shared/html'
import { consoleError, consoleLog, consoleWarn } from '../shared/logging'
import {
    isDefined,
    isEmpty,
    isMissing,
    isPresent,
    notDefined,
} from '../shared/definitions'


$(document).on('turbolinks:load', function() {

    const POPUP_CLASS = 'popup-container';
    const POPUP       = selector(POPUP_CLASS);

    /** @type {jQuery} */
    let $popup_containers = $(POPUP).not('.for-example');

    // Only perform these actions on the appropriate pages.
    if (isMissing($popup_containers)) {
        return;
    }

    /**
     * The general signature of a callback function to respond to a popup state
     * event.
     *
     * @typedef {
     *      function(
     *          $popup:     jQuery,
     *          $button:    jQuery,
     *          check_only: boolean
     *      ): boolean|undefined
     * } PopupHook
     */

    /**
     * The signature of a callback function provided via `.data('onShowPopup')
     * on the popup toggle button.  If this function returns *false* then
     * {@link showPopup} will not allow the popup to open (and will avoid
     * fetching any related deferred content if applicable).
     *
     * @typedef {PopupHook} onShowPopupHook
     */

    /**
     * The signature of a callback function provided via `.data('onHidePopup')
     * on the popup toggle button.  If this function returns *false* then
     * {@link hidePopup} will not allow the popup to close.
     *
     * @typedef {PopupHook} onHidePopupHook
     */

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Flag controlling console debug output.
     *
     * @readonly
     * @type {boolean}
     */
    const DEBUGGING = true;

    const HIDDEN_MARKER   = Emma.Popup.hidden.class;
    const COMPLETE_MARKER = 'complete';

    const HIDDEN   = selector(HIDDEN_MARKER);
    const COMPLETE = selector(COMPLETE_MARKER);
    const BUTTON   = selector(Emma.Popup.button.class);
    const PANEL    = selector(Emma.Popup.panel.class);
    const CLOSER   = selector(Emma.Popup.closer.class);
    const DEFERRED = selector(Emma.Popup.deferred.class);

    const TOGGLE_DATA = 'toggle';

    // ========================================================================
    // Constants - z-order
    // ========================================================================

    /**
     * The property assigned to a popup which is overtaking z-order on the page
     * by neutralizing the z-index for elements outside its stacking context.
     * This property holds the set of elements which have been affected.
     *
     * @readonly
     * @type {string}
     */
    const Z_CAPTURES_PROP = 'z-captured-elements';

    /**
     * The property assigned to an element whose z-index has been neutralized
     * which holds the original z-index value to be restored.
     *
     * @readonly
     * @type {string}
     */
    const Z_RESTORE_PROP = 'current-z-index';

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * All popup elements on the page.
     *
     * @type {jQuery}
     */
    let $all_popups = $popup_containers.children(PANEL);

    /**
     * All popup close buttons.
     *
     * @type {jQuery}
     */
    let $popup_closers = $popup_containers.find(CLOSER);

    /**
     * All popup control buttons on the page.
     *
     * @type {jQuery}
     */
    let $popup_buttons = $popup_containers.children(BUTTON);

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleEvent($(window), 'keyup', onKeyUp);
    handleEvent($(window), 'click', onClick);

    handleClickAndKeypress($popup_buttons, onTogglePopup);
    handleClickAndKeypress($popup_closers, onTogglePopup);

    // ========================================================================
    // Actions
    // ========================================================================

    // Make sure popups start hidden.
    $all_popups.toggleClass(HIDDEN_MARKER, true);

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Toggle visibility of a button and its popup element.
     *
     * @param {Selector} [target]     Default: *this*.
     */
    function togglePopup(target) {
        let func    = 'togglePopup:';
        let $target = $(target || this);
        let $popup  = findPopup($target);

        // On any given cycle, the first occurrence of this function will be
        // due to the toggle button, which is remembered here.
        if (!getToggleControl($popup)) {
            setToggleControl($popup, $target);
        }

        if ($popup.children().is('.iframe, .img')) {
            togglePopupIframe($popup, func);
        } else {
            togglePopupContent($popup, func);
        }
    }

    /**
     * Toggle visibility of an <iframe> or <img> popup.
     *
     * @param {jQuery} $popup
     * @param {string} [caller]
     */
    function togglePopupIframe($popup, caller) {
        let func         = caller ? `${caller} IFRAME` : 'togglePopupIframe:';
        let $iframe      = $popup.children('iframe');
        let $placeholder = $popup.children(DEFERRED);
        const opening    = $popup.is(HIDDEN);
        const complete   = $popup.is(COMPLETE);

        // Include the ID of the iframe for logging.
        if (DEBUGGING) {
            let id = $popup.data('id') || $iframe.attr('id');
            // noinspection JSUnresolvedVariable
            id ||= decodeObject($placeholder.attr('data-attr')).id;
            id ||= 'unknown';
            func += ` ${id}:`;
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
            debug(func, 'RE-OPENING');
            if (showPopup($popup)) {
                scrollIntoView($popup);
                scrollFrameDocument($iframe, $popup.data('topic'));
            }

        } else if (opening) {
            // Fetch deferred content when the popup is unhidden the first time
            // (or after being deleted below after closing).
            debug(func, 'LOADING');
            showPopup($popup) && $placeholder.each(loadDeferredContent);

        } else if (complete) {
            // If the <iframe> exists and contains a different page than the
            // original then remove it in order to re-fetch the original the
            // next time it is opened.
            if (checkHidePopup($popup)) {
                const refetch       = $popup.hasClass('refetch');
                const expected_page = $popup.data('page');
                const content       = $iframe[0].contentDocument;
                const current_page  = content?.location?.pathname;
                if (!refetch && (expected_page === current_page)) {
                    debug(func, 'CLOSING', current_page);
                } else {
                    debug(func, 'CLOSING', '-', 'REMOVING', current_page);
                    $placeholder.removeClass(HIDDEN_MARKER);
                    $iframe.remove();
                    $popup.removeClass(COMPLETE_MARKER);
                }
                hidePopup($popup, true);
            }

        } else {
            consoleWarn(func, 'CLOSING', '-', 'INCOMPLETE POPUP');
            hidePopup($popup);
        }
    }

    /**
     * Toggle visibility of a generic content popup.
     *
     * @param {jQuery} $popup
     * @param {string} [caller]
     */
    function togglePopupContent($popup, caller) {
        const func       = caller || 'togglePopupContent:';
        let $placeholder = $popup.children('.placeholder');
        const opening    = $popup.is(HIDDEN);
        const complete   = $popup.is(COMPLETE);

        if (opening && complete) {
            // If the existing hidden popup can be re-used, ensure that it is
            // fully visible.
            debug(func, 'RE-OPENING');
            showPopup($popup) && scrollIntoView($popup);

        } else if (opening && isPresent($placeholder)) {
            // Initialize content when the popup is unhidden the first time
            // (or after being deleted below after closing).
            debug(func, 'INITIALIZING');
            showPopup($popup) && $placeholder.each(loadDirectContent);

        } else if (opening) {
            debug(func, 'OPENING');
            showPopup($popup) && $popup.addClass(COMPLETE_MARKER);

        } else if (complete) {
            debug(func, 'CLOSING');
            hidePopup($popup);

        } else {
            consoleWarn(func, 'CLOSING', '-', 'INCOMPLETE POPUP');
            hidePopup($popup);
        }
    }

    /**
     * Find the associated popup element.
     *
     * @param {Selector} target
     *
     * @returns {jQuery}
     */
    function findPopup(target) {
        let $tgt = $(target);
        if ($tgt.is(PANEL))  { return $tgt }
        if ($tgt.is(BUTTON)) { return $tgt.siblings(PANEL) }
        if ($tgt.is(POPUP))  { return $tgt.children(PANEL) }
        return $tgt.parents(POPUP).first().children(PANEL);
    }

    /**
     * All popups which are currently open.
     *
     * @returns {jQuery}
     */
    function findOpenPopups() {
        return $all_popups.not(HIDDEN);
    }

    /**
     * Fetch content.
     *
     * @param {Selector} [placeholder]  Default: *this*.
     */
    function loadDirectContent(placeholder) {

        const func       = 'loadDirectContent:';
        let $placeholder = $(placeholder || this);
        let $popup       = $placeholder.parents(PANEL).first();
        const source_url = $placeholder.attr('data-path');
        const attributes = $placeholder.attr('data-attr');

        // Validate parameters and return if there is missing information.
        if (isMissing(source_url)) {
            consoleWarn(func, 'no source URL');
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
            consoleWarn(func, 'FAILED', event);
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
            if ($popup.hasClass(COMPLETE_MARKER)) {

                // The user has clicked on a link within the <dev> and a new
                // page has been loaded into it.
                debug(func, 'PAGE REPLACED');

            } else {

                // The initial load of the popup target content.
                debug(func, 'LOAD');
                $popup.data('id', $content[0].id); // For logging.
                $popup.addClass(COMPLETE_MARKER);

                // Replace the placeholder with the downloaded content.
                $placeholder.addClass(HIDDEN_MARKER);
                $content.removeClass(HIDDEN_MARKER);

                // Make sure the associated popup element is displayed and
                // scrolled into position.
                showPopup($popup, true);
                scrollIntoView($popup);
            }
        }
    }

    /**
     * Fetch deferred content as indicated by the placeholder element, which
     * may be either an <iframe> or an <img>.
     *
     * @param {Selector} [placeholder]  Default: *this*.
     */
    function loadDeferredContent(placeholder) {

        const func       = 'loadDeferredContent:';
        let $placeholder = $(placeholder || this);
        let $popup       = $placeholder.parents(PANEL).first();
        const source_url = $placeholder.attr('data-path');
        const attributes = $placeholder.attr('data-attr');

        // Validate parameters and return if there is missing information.
        let error = undefined;
        let type;
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
            consoleWarn(func, error);
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
            consoleWarn(func, type, 'FAILED', event);
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
            if ($popup.hasClass(COMPLETE_MARKER)) {

                // The user has clicked on a link within the <iframe> and a new
                // page has been loaded into it.
                debug(func, type, 'PAGE REPLACED');

            } else {

                // The initial load of the popup target page.
                debug(func, type, 'LOAD');
                const iframe = $content[0].contentDocument;
                const topic  = $placeholder.attr('data-topic');

                // Record the initial page and anchor displayed in the <iframe>
                $popup.data('id',    $content[0].id); // For logging.
                $popup.data('page',  iframe.location.pathname);
                $popup.data('topic', topic);
                $popup.addClass(COMPLETE_MARKER);

                // Replace the placeholder with the downloaded content.
                $placeholder.addClass(HIDDEN_MARKER);
                $content.removeClass(HIDDEN_MARKER);

                // Prepare to handle key presses that are directed to the
                // <iframe>.
                handleEvent($content.contents(), 'keyup', onIframeKeyUp);

                // Make sure the associated popup element is displayed and
                // scrolled into position.
                showPopup($popup, true);
                scrollIntoView($popup);
                scrollFrameDocument($content, topic);
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
            const key = event?.key;
            if (key === 'Escape') {
                debug('ESC pressed in popup', $popup.data('id'));
                if (hidePopup($popup)) {
                    window.parent.focus();
                    return false;
                }
            }
        }
    }

    /**
     * Scroll the <iframe> content to the indicated anchor.
     *
     * @param {Selector} iframe
     * @param {string}   [topic]      Default: top of document.
     */
    function scrollFrameDocument(iframe, topic) {
        let $iframe = $(iframe);
        const id    = $iframe.attr('id') || '???';
        const func  = `scrollFrameDocument: popup ${id}:`;
        let doc     = $iframe[0]?.contentDocument;
        let anchor  = topic?.replace(/^#/, '');
        let section = anchor && doc?.getElementById(anchor);
        let error   = undefined;
        let warn    = undefined;
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
            consoleError(func, error);
        } else if (warn) {
            consoleWarn(func, warn);
        } else {
            // For some reason, scrollIntoView is also causing the root window
            // to scroll, so the Y position is restored to nullify that effect.
            debug(func, 'anchor =', anchor);
            const saved_y = window.parent.scrollY;
            section.scrollIntoView(true);
            window.parent.scrollTo(0, saved_y);
        }
    }

    // ========================================================================
    // Functions - show/hide
    // ========================================================================

    /**
     * Open the indicated popup element.
     *
     * @param {Selector} popup
     * @param {boolean}  [skip_check]
     *
     * @returns {boolean}
     */
    function showPopup(popup, skip_check) {
        const func = 'showPopup';
        let $popup = $(popup);
        debugPopups(func, $popup);
        if ((invokeOnShowPopup($popup) === false) && !skip_check) {
            consoleWarn(`${func}: rejected by onShowPopup`);
            return false;
        }
        if ($popup.hasClass('z-order-capture')) {
            zOrderCapture($popup);
        }
        $popup.removeClass(HIDDEN_MARKER);
        return true;
    }

    /**
     * Close the indicated popup element.
     *
     * @param {Selector} popup
     * @param {boolean}  [skip_check]
     *
     * @returns {boolean}
     */
    function hidePopup(popup, skip_check) {
        const func = 'hidePopup';
        let $popup = $(popup);
        debugPopups(func, $popup);
        if ((invokeOnHidePopup($popup) === false) && !skip_check) {
            consoleWarn(`${func}: rejected by onHidePopup`);
            return false;
        }
        $popup.addClass(HIDDEN_MARKER);
        if ($popup.hasClass('z-order-capture')) {
            zOrderRelease($popup);
        }
        clearToggleControl($popup);
        return true;
    }

    /**
     * Close all popups that are not hidden.
     *
     * @param {Selector} [popups]     Default: `{@link findOpenPopups()}`.
     */
    function hideAllOpenPopups(popups) {
        debug('hideAllOpenPopups');
        let $popups = popups ? $(popups) : findOpenPopups();
        $popups.each(function() { togglePopup(this); });
    }

    /**
     * Pre-clear the ability to open the popup.
     *
     * @param {jQuery} $popup
     *
     * @returns {boolean}
     */
    function checkShowPopup($popup) {
        return (invokeOnShowPopup($popup, true) !== false);
    }

    /**
     * Pre-clear the ability to close the popup.
     *
     * @param {jQuery} $popup
     *
     * @returns {boolean}
     */
    function checkHidePopup($popup) {
        return (invokeOnHidePopup($popup, true) !== false);
    }

    // ========================================================================
    // Functions - popup control
    // ========================================================================

    /**
     * getToggleControl
     *
     * @param {jQuery} $popup
     *
     * @returns {jQuery|undefined}
     */
    function getToggleControl($popup) {
        return $popup.data(TOGGLE_DATA);
    }

    /**
     * setToggleControl
     *
     * @param {jQuery} $popup
     * @param {jQuery} $button
     */
    function setToggleControl($popup, $button) {
        $popup.data(TOGGLE_DATA, $button);
    }

    /**
     * clearToggleControl
     *
     * @param {jQuery} $popup
     */
    function clearToggleControl($popup) {
        $popup.removeData(TOGGLE_DATA);
    }

    /**
     * invokeOnShowPopup
     *
     * @param {jQuery}  $popup
     * @param {boolean} [check_only]
     *
     * @returns {boolean|undefined}
     */
    function invokeOnShowPopup($popup, check_only) {
        return invokePopupHook($popup, 'onShowPopup', check_only);
    }

    /**
     * invokeOnHidePopup
     *
     * @param {jQuery}  $popup
     * @param {boolean} [check_only]
     *
     * @returns {boolean|undefined}
     */
    function invokeOnHidePopup($popup, check_only) {
        return invokePopupHook($popup, 'onHidePopup', check_only);
    }

    /**
     * invokePopupHook
     *
     * @param {jQuery}  $popup
     * @param {string}  data_name
     * @param {boolean} [check_only]
     *
     * @returns {boolean|undefined}
     */
    function invokePopupHook($popup, data_name, check_only) {
        let $button  = getToggleControl($popup);
        let callback = $button?.data(data_name);
        return callback && callback($popup, $button, check_only);
    }

    // ========================================================================
    // Functions - z-order
    // ========================================================================

    /**
     * Cheat working out the proper stacking context hierarchy by causing all
     * elements with a non-zero z-index to be neutralized.
     *
     * The function returns early if it has already been run for this popup.
     *
     * @param {Selector} by_popup
     */
    function zOrderCapture(by_popup) {
        let $popup = $(by_popup);
        if ($popup.prop(Z_CAPTURES_PROP)) {
            return;
        }
        let z_captures = [];
        $('*:visible').not($popup).each(function() {
            let $this = $(this);
            const z   = $this.css('z-index');
            if (z > 0) {
                debug(`CAPTURE z-index = ${z} from ${elementSelector(this)}`);
                $this.prop(Z_RESTORE_PROP, z);
                $this.css('z-index', -1);
                z_captures.push($this);
            }
        });
        if (isEmpty(z_captures)) {
            z_captures = false;
        }
        $popup.prop(Z_CAPTURES_PROP, z_captures);
    }

    /**
     * Reverses the effect of {@link zOrderCapture} by restoring the original
     * z-index to the affected elements.
     *
     * @param {Selector} by_popup
     */
    function zOrderRelease(by_popup) {
        let $popup     = $(by_popup);
        let z_captures = $popup.prop(Z_CAPTURES_PROP);
        if (isPresent(z_captures)) {
            z_captures.forEach(function($e) {
                const z = $e.prop(Z_RESTORE_PROP);
                $e.css('z-index', z);
                debug(`RELEASE z-index = ${z} to ${elementSelector($e)}`);
            });
        }
        $popup.prop(Z_CAPTURES_PROP, false);
    }

    // ========================================================================
    // Functions - event handlers
    // ========================================================================

    // noinspection FunctionWithInconsistentReturnsJS
    /**
     * Allow "Escape" key to close an open popup.
     *
     * If the event originates from outside of a popup control or open popup,
     * then close all open popups.
     *
     * @param {jQuery.Event|KeyboardEvent} event
     */
    function onKeyUp(event) {
        // debugEvent('onKeyUp', event);
        const key = event?.key;
        if (key === 'Escape') {
            // debug('> ESC pressed outside of popup controls or panels');
            let $target = $(event.target || this);
            let $popup  = findPopup($target).not(HIDDEN);
            let $popups = isMissing($popup) && findOpenPopups();
            if (isPresent($popup)) {
                debug('> ESC pressed in window; closing single open popup');
                if (hidePopup($popup)) {
                    return false;
                }
            } else if (isPresent($popups)) {
                debug('> ESC pressed in window; closing all open popups');
                hideAllOpenPopups($popups);
                return false;
            }
        }
    }

    /**
     * Close all popups that are not hidden.
     *
     * @param {jQuery.Event|MouseEvent} event
     *
     * @returns {undefined}
     */
    function onClick(event) {
        // debugEvent('onClick', event);

        // Clicked directly on a popup control or panel.
        let $tgt = $(event.target);
        if ($tgt.is(PANEL)) { return debug('> CLICK on open panel') }
        if ($tgt.is(POPUP)) { return debug('> CLICK within popup control') }

        // Clicked inside a popup control or panel.
        let $par = $tgt.parents();
        if ($par.is(PANEL)) { return debug('> CLICK within open panel') }
        if ($par.is(POPUP)) { return debug('> CLICK popup control') }

        // Otherwise.
        debug('> CLICK outside of popup controls or panels');
        let $popups = findOpenPopups();
        if (isPresent($popups)) {
            hideAllOpenPopups($popups);
        }
    }

    /**
     * Toggle visibility of a button and its popup element.
     *
     * @param {jQuery.Event} event
     *
     * @returns {boolean}
     */
    function onTogglePopup(event) {
        debugEvent('onTogglePopup', event);
        event.stopPropagation();
        togglePopup(event.target);
        return false;
    }

    // ========================================================================
    // Functions - other
    // ========================================================================

    /**
     * Report on 0 or more popups.
     *
     * @param {string} label
     * @param {jQuery} $popup
     */
    function debugPopups(label, $popup) {
        if (DEBUGGING) {
            const func = label.endsWith(':') ? label : `${label}:`;
            if ($popup.length === 0) {
                consoleLog(func, 'NO POPUPS');
            } else if ($popup.length === 1) {
                const $toggle = getToggleControl($popup);
                consoleLog(func,
                    '| id',          ($popup.data('id')            || '-'),
                    '| page',        ($popup.data('page')          || '-'),
                    '| topic',       ($popup.data('topic')         || '-'),
                    '| onShowPopup', ($toggle?.data('onShowPopup') || '-'),
                    '| onHidePopup', ($toggle?.data('onHidePopup') || '-'),
                    '| $toggle',     ($toggle                      || '-')
                );
            } else {
                consoleLog(func, 'all', $popup.length, 'popups');
            }
        }
    }

    /**
     * Report on an event.
     *
     * @param {string}             label
     * @param {jQuery.Event|Event} event
     */
    function debugEvent(label, event) {
        if (DEBUGGING) {
            console.log('***', label, '***');
            console.log(event);
        }
    }

    /**
     * Emit a console message if debugging.
     *
     * @param {...*} args
     *
     * @returns {undefined}
     */
    function debug(...args) {
        if (DEBUGGING) { consoleLog(...args); }
    }

});
