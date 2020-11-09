// app/assets/javascripts/feature/popup.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    /** @const {string}   */ const POPUP_CLASS    = 'popup-container';
    /** @const {Selector} */ const POPUP_SELECTOR = selector(POPUP_CLASS);

    /** @type {jQuery} */
    let $popup_containers = $(POPUP_SELECTOR).not('.for-help');

    // Only perform these actions on the appropriate pages.
    if (isMissing($popup_containers)) {
        return;
    }

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Flag controlling console debug output.
     *
     * @constant
     * @type {boolean}
     */
    const DEBUGGING = false;

    /** @const {string} */ const BUTTON_CLASS    = Emma.Popup.button.class;
    /** @const {string} */ const PANEL_CLASS     = Emma.Popup.panel.class;
    /** @const {string} */ const CLOSER_CLASS    = Emma.Popup.closer.class;
    /** @const {string} */ const DEFERRED_CLASS  = Emma.Popup.deferred.class;
    /** @const {string} */ const HIDDEN_MARKER   = Emma.Popup.hidden.class;
    /** @const {string} */ const COMPLETE_MARKER = 'complete';
    /** @const {string} */ const BUTTON          = selector(BUTTON_CLASS);
    /** @const {string} */ const PANEL           = selector(PANEL_CLASS);
    /** @const {string} */ const CLOSER          = selector(CLOSER_CLASS);
    /** @const {string} */ const DEFERRED        = selector(DEFERRED_CLASS);
    /** @const {string} */ const HIDDEN          = selector(HIDDEN_MARKER);

    // ========================================================================
    // Constants - z-order
    // ========================================================================

    /**
     * The property assigned to a popup which is overtaking z-order on the page
     * by neutralizing the z-index for elements outside its stacking context.
     * This property holds the set of elements which have been affected.
     *
     * @const
     * @type {string}
     */
    const Z_CAPTURES_PROP = 'z-captured-elements';

    /**
     * The property assigned to an element whose z-index has been neutralized
     * which holds the original z-index value to be restored.
     *
     * @const
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

    // noinspection FunctionTooLongJS
    /**
     * Toggle visibility of a button and its popup element.
     *
     * @param {Selector} [target]     Default: *this*.
     */
    function togglePopup(target) {
        let func         = 'togglePopup:';
        let $target      = $(target || this);
        let $popup       = findPopup($target);
        let $iframe      = $popup.children('iframe');
        let $placeholder = $popup.children(DEFERRED);

        // Include the ID of the iframe for logging.
        if (DEBUGGING) {
            let id = $popup.data('id');
            id = id || $iframe.attr('id');
            id = id || ($placeholder.data('attr') || {}).id;
            func += ` ${id || 'unknown'}:`;
        }

        // Restore placeholder text if necessary.
        const placeholder_text = $placeholder.data('text');
        if (placeholder_text) {
            $placeholder.text(placeholder_text);
        }
        if (isDefined(placeholder_text)) {
            $placeholder.removeData('text');
        }

        const opening  = $popup.hasClass(HIDDEN_MARKER);
        const complete = $popup.hasClass(COMPLETE_MARKER);
        if (opening && complete) {
            // If the existing hidden popup can be re-used, ensure that it is
            // fully visible and the contents are scrolled to the indicated
            // anchor.
            debug(func, 'RE-OPENING');
            showPopup($popup);
            scrollIntoView($popup);
            scrollFrameDocument($iframe, $popup.data('topic'));

        } else if (opening) {
            // Fetch deferred content when the popup is unhidden the first time
            // (or after being deleted below after closing).
            debug(func, 'LOADING');
            showPopup($popup);
            $placeholder.each(fetchContent);

        } else if (complete) {
            // If the <iframe> exists and contains a different page than the
            // original then remove it in order to re-fetch the original the
            // next time it is opened.
            const refetch       = $popup.hasClass('refetch');
            const expected_page = $popup.data('page');
            const content       = $iframe[0] && $iframe[0].contentDocument;
            const current_page  = content    && content.location.pathname;
            if (!refetch && (expected_page === current_page)) {
                debug(func, 'CLOSING', current_page);
            } else {
                debug(func, 'CLOSING', '-', 'REMOVING', current_page);
                $placeholder.removeClass(HIDDEN_MARKER);
                $iframe.remove();
                $popup.removeClass(COMPLETE_MARKER);
            }
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
        let $target = $(target);
        let $popup;
        if ($target.hasClass(PANEL_CLASS)) {
            $popup  = $target;
        } else if ($target.hasClass(BUTTON_CLASS)) {
            $popup  = $target.siblings(PANEL);
        } else if ($target.hasClass(POPUP_CLASS)) {
            $popup  = $target.children(PANEL);
        } else {
            $target = $target.parents(POPUP_SELECTOR);
            $popup  = $target.children(PANEL);
        }
        return $popup;
    }

    /**
     * All popups which are currently open.
     *
     * @returns {jQuery}
     */
    function findOpenPopups() {
        return $all_popups.not(HIDDEN);
    }

    // noinspection FunctionWithMultipleReturnPointsJS
    /**
     * Fetch deferred content as indicated by the placeholder element, which
     * may be either an <iframe> or an <img>.
     *
     * @param {Selector} [placeholder]  Default: *this*.
     */
    function fetchContent(placeholder) {

        const func       = 'fetchContent:';
        let $placeholder = $(placeholder || this);
        let $popup       = $placeholder.parents(PANEL).first();
        const source_url = $placeholder.data('path');

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
        // noinspection HtmlUnknownTag
        let $content = $(`<${type}>`);
        $content.attr(Emma.to_object($placeholder.data('attr')));
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
                const topic  = $placeholder.data('topic');

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
                showPopup($popup);
                scrollIntoView($popup);
                scrollFrameDocument($content, topic);
            }
        }

        // noinspection FunctionWithMultipleReturnPointsJS, FunctionWithInconsistentReturnsJS
        /**
         * Allow "Escape" key from within the <iframe> to close the popup.
         *
         * Re-focus on the parent window so that the hidden popup does not
         * continue to intercept keypress events.
         *
         * @param {jQuery.Event|KeyboardEvent} event
         */
        function onIframeKeyUp(event) {
            const key = event && event.key;
            if (key === 'Escape') {
                debug('ESC pressed in popup', $popup.data('id'));
                hidePopup($popup);
                window.parent.focus();
                return false;
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
        let doc     = $iframe[0] && $iframe[0].contentDocument;
        let anchor  = topic  && topic.replace(/^#/, '');
        let section = anchor && doc && doc.getElementById(anchor);
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

    /**
     * Open the indicated popup element.
     *
     * @param {Selector} popup
     */
    function showPopup(popup) {
        let $popup = $(popup);
        debugPopups('showPopup', $popup);
        if ($popup.hasClass('z-order-capture')) {
            zOrderCapture($popup);
        }
        $popup.removeClass(HIDDEN_MARKER);
    }

    /**
     * Close the indicated popup element.
     *
     * @param {Selector} popup
     */
    function hidePopup(popup) {
        let $popup = $(popup);
        debugPopups('hidePopup', $popup);
        $popup.addClass(HIDDEN_MARKER);
        if ($popup.hasClass('z-order-capture')) {
            zOrderRelease($popup);
        }
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

    // ========================================================================
    // Functions - z-order
    // ========================================================================

    // noinspection FunctionWithMultipleReturnPointsJS
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

    // noinspection FunctionWithMultipleReturnPointsJS, FunctionWithInconsistentReturnsJS
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
        const key = event && event.key;
        if (key === 'Escape') {
            // debug('> ESC pressed outside of popup controls or panels');
            let $target = $(event.target || this);
            let $popup  = findPopup($target).not(HIDDEN);
            let $popups = isMissing($popup) && findOpenPopups();
            if (isPresent($popup)) {
                debug('> ESC pressed in window; closing single open popup');
                hidePopup($popup);
                return false;
            } else if (isPresent($popups)) {
                debug('> ESC pressed in window; closing all open popups');
                hideAllOpenPopups($popups);
                return false;
            }
        }
    }

    // noinspection FunctionWithMultipleReturnPointsJS, FunctionWithInconsistentReturnsJS
    /**
     * Close all popups that are not hidden.
     *
     * @param {jQuery.Event|MouseEvent} event
     */
    function onClick(event) {
        // debugEvent('onClick', event);
        let $target = $(event.target);
        let $parent = $target.parents().first();
        if ($parent.hasClass(PANEL_CLASS)) {
            debug('> CLICK within open panel');
        } else if ($target.hasClass(PANEL_CLASS)) {
            debug('> CLICK on open panel');
        } else if ($parent.hasClass(POPUP_CLASS)) {
            debug('> CLICK popup control');
        } else if ($target.hasClass(POPUP_CLASS)) {
            debug('> CLICK within popup control');
        } else {
            debug('> CLICK outside of popup controls or panels');
            let $popups = findOpenPopups();
            if (isPresent($popups)) {
                hideAllOpenPopups($popups);
            }
        }
    }

    /**
     * Toggle visibility of a button and its popup element.
     *
     * @param {jQuery.Event} event
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
                const id    = $popup.data('id')    || '-';
                const page  = $popup.data('page')  || '-';
                const topic = $popup.data('topic') || '-';
                consoleLog(func, 'id =', id, 'page =', page, 'topic =', topic);
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
     */
    function debug(...args) {
        if (DEBUGGING) { consoleLog(...args); }
    }

});
