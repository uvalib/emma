// app/assets/javascripts/feature/popup.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    /** @const {string} */ var POPUP_CLASS    = 'popup-container';
    /** @const {string} */ var POPUP_SELECTOR = '.' + POPUP_CLASS;

    /** @type {jQuery} */
    var $popup_containers = $(POPUP_SELECTOR).not('.for-help');

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
    var DEBUGGING = true;

    /** @const {string} */ var BUTTON_CLASS      = Emma.Popup.button.class;
    /** @const {string} */ var PANEL_CLASS       = Emma.Popup.panel.class;
    /** @const {string} */ var CLOSER_CLASS      = Emma.Popup.closer.class;
    /** @const {string} */ var CONTROLS_CLASS    = Emma.Popup.controls.class;
    /** @const {string} */ var DEFERRED_CLASS    = Emma.Popup.deferred.class;
    /** @const {string} */ var BUTTON_SELECTOR   = '.' + BUTTON_CLASS;
    /** @const {string} */ var PANEL_SELECTOR    = '.' + PANEL_CLASS;
    /** @const {string} */ var CLOSER_SELECTOR   = '.' + CLOSER_CLASS;
    /** @const {string} */ var CONTROLS_SELECTOR = '.' + CONTROLS_CLASS;
    /** @const {string} */ var DEFERRED_SELECTOR = '.' + DEFERRED_CLASS;
    /** @const {string} */ var HIDDEN_MARKER     = 'hidden';

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * All popup elements on the page.
     *
     * @type {jQuery}
     */
    var $all_popups = $popup_containers.children(PANEL_SELECTOR);

    /**
     * All popup close buttons.
     *
     * @type {jQuery}
     */
    var $popup_closers = $popup_containers.find(CLOSER_SELECTOR);

    /**
     * All popup control buttons on the page.
     *
     * @type {jQuery}
     */
    var $popup_buttons = $popup_containers.children(BUTTON_SELECTOR);

    // ========================================================================
    // Function definitions
    // ========================================================================

    /**
     * Toggle visibility of a button and its popup element.
     *
     * @param {Event} event
     */
    function togglePopup(event) {
        var $target = $(event && event.target || this);
        var $popup  = findPopup($target);

        // Toggle the popup element state.
        $popup.toggleClass(HIDDEN_MARKER);

        // Fetch deferred content when the popup is unhidden the first time.
        // Subsequently, ensure that the popup is fully visible within the
        // viewport when it is opened.
        if (!$popup.hasClass(HIDDEN_MARKER)) {
            if ($popup.hasClass('complete')) {
                showPopup($popup);
            } else {
                $popup.find(DEFERRED_SELECTOR).each(fetchContent);
            }
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
        var $target = $(target);
        var $popup;
        if ($target.hasClass(PANEL_CLASS)) {
            $popup  = $target;
        } else if ($target.hasClass(BUTTON_CLASS)) {
            $popup  = $target.siblings(PANEL_SELECTOR);
        } else if ($target.hasClass(POPUP_CLASS)) {
            $popup  = $target.children(PANEL_SELECTOR);
        } else {
            $target = $target.parents(POPUP_SELECTOR);
            $popup  = $target.children(PANEL_SELECTOR);
        }
        return $popup;
    }

    /**
     * Close the indicated popup element.
     *
     * @param {Selector} popup
     */
    function hidePopup(popup) {
        $(popup).addClass(HIDDEN_MARKER);
    }

    /**
     * Open the indicated popup element.
     *
     * @param {Selector} popup
     */
    function showPopup(popup) {
        var $popup = $(popup);
        $popup.removeClass(HIDDEN_MARKER);
        scrollIntoView($popup);
    }

    // noinspection FunctionWithMultipleReturnPointsJS
    /**
     * Fetch deferred content as indicated by the placeholder element, which
     * may be either an <iframe> or an <img>.
     *
     * @param {Selector} [placeholder]  Default: *this*.
     */
    function fetchContent(placeholder) {

        var $placeholder = $(placeholder || this);
        var $popup       = $placeholder.parents(PANEL_SELECTOR).first();
        var source_url   = $placeholder.data('path');

        // Validate parameters and return if there is missing information.
        var error, type;
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
            console.warn('fetchContent:', error);
            return;
        }

        // Setup the element that will actually contain the received content
        // then fetch it.  The element will appear only if successfully loaded.
        var $content = $('<' + type + '>');
        $content.attr(Emma.to_object($placeholder.data('attr')));
        $content.addClass('hidden');
        $content.insertAfter($placeholder);
        handleEvent($content, 'error', onError);
        handleEvent($content, 'load',  onLoad);
        $content.attr('src', source_url);

        /**
         * If there was a problem with loading the popup content, display
         * a message in the popup placeholder element.
         *
         * @param {Event} event
         */
        function onError(event) {
            console.warn('fetchContent:', type, 'FAILED', event);
            $placeholder.text('Could not load content.');
            $content.remove();
        }

        /**
         * When the popup content is loaded replace the placeholder <iframe>
         * with the content <iframe>.  If an anchor (initial element ID) was
         * specified by the 'data-top' attribute in the placeholder, scroll the
         * <iframe> to bring that element to the top of the panel display.
         *
         * @param {Event} event
         */
        function onLoad(event) {
            console.log('fetchContent:', type, 'LOAD', event);

            // Replace the placeholder with the downloaded content and prepare
            // to handle key presses that are directed to the <iframe>.
            $placeholder.remove();
            $content.removeClass('hidden');
            handleEvent($content.contents(), 'keyup', handleInnerEscapeKey);

            // Make sure the associated popup element is displayed.
            showPopup($popup);

            // Scroll the <iframe> content to the indicated anchor.  For some
            // reason, this is also causing the root window to scroll too, so
            // its Y position is restored after the <iframe> is scrolled in
            // order to nullify that effect.
            var top = $placeholder.data('top');
            if (top) {
                var saved_y = window.parent.scrollY;
                var iframe  = $content[0].contentWindow.document;
                var section = iframe.getElementById(top);
                section.scrollIntoView(true);
                window.parent.scrollTo(0, saved_y);
            }

            $popup.addClass('complete');
        }

        // noinspection FunctionWithMultipleReturnPointsJS, FunctionWithInconsistentReturnsJS
        /**
         * Allow "Escape" key from within the <iframe> to close the popup.
         *
         * @param {KeyboardEvent} event
         */
        function handleInnerEscapeKey(event) {
            var key = event && event.key;
            if (key === 'Escape') {
                hidePopup($popup);
                return false;
            }
        }
    }

    // noinspection FunctionWithMultipleReturnPointsJS, FunctionWithInconsistentReturnsJS
    /**
     * Allow "Escape" key to close an open popup.
     *
     * If the event originates from outside of an open popup, then close all
     * open popups.
     *
     * @param {KeyboardEvent} event
     */
    function handleEscapeKey(event) {
        var key = event && event.key;
        if (key === 'Escape') {
            var $target = $(event.target || this);
            var $popup  = findPopup($target);
            if (isPresent($popup) && !$popup.hasClass(HIDDEN_MARKER)) {
                hidePopup($popup);
            } else {
                hidePopup($all_popups);
            }
            return false;
        }
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleEvent($(window), 'keyup', handleEscapeKey);

    handleClickAndKeypress($popup_buttons, togglePopup);
    handleClickAndKeypress($popup_closers, togglePopup);

    // ========================================================================
    // Actions
    // ========================================================================

    // Make sure popups start hidden.
    $all_popups.toggleClass(HIDDEN_MARKER, true);

    // ========================================================================
    // Internal functions
    // ========================================================================

    /**
     * Emit a console message if debugging.
     */
    function debug() {
        if (DEBUGGING) {
            consoleLog.apply(null, arguments);
        }
    }

});
