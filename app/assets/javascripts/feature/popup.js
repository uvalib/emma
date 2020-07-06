// app/assets/javascripts/feature/popup.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    /** @const {string} */ var POPUP_CLASS    = 'popup-container';
    /** @const {string} */ var POPUP_SELECTOR = '.' + POPUP_CLASS;

    /** @type {jQuery} */
    var $popup_containers = $(POPUP_SELECTOR);

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
     * @constant {boolean}
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
     * All popup control buttons on the page.
     *
     * @type {jQuery}
     */
    var $popup_buttons = $popup_containers.children(BUTTON_SELECTOR);

    /**
     * All popup panel elements on the page.
     *
     * @type {jQuery}
     */
    var $popup_panels = $popup_containers.children(PANEL_SELECTOR);

    /**
     * All popup panel close buttons.
     *
     * @type {jQuery}
     */
    var $popup_closers = $popup_containers.find(CLOSER_SELECTOR);

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
        var $panel;

        // Locate the panel associated with the event target element.
        if ($target.hasClass(PANEL_CLASS)) {
            $panel  = $target;
        } else if ($target.hasClass(BUTTON_CLASS)) {
            $panel  = $target.siblings(PANEL_SELECTOR);
        } else if ($target.hasClass(POPUP_CLASS)) {
            $panel  = $target.children(PANEL_SELECTOR);
        } else {
            $target = $target.parents(POPUP_SELECTOR);
            $panel  = $target.children(PANEL_SELECTOR);
        }
        $panel.toggleClass(HIDDEN_MARKER);

        // Fetch deferred content when the panel is unhidden the first time.
        if (!$panel.hasClass(HIDDEN_MARKER)) {
            $panel.find(DEFERRED_SELECTOR).each(fetchContent);
        }
    }

    /**
     * Fetch deferred content as indicated by the placeholder element.
     *
     * @param {Selector} [placeholder]  Default: *this*.
     */
    function fetchContent(placeholder) {
        var $placeholder = $(placeholder || this);
        var path = $placeholder.data('path');
        var type;
        if (isMissing(path)) {
            console.warn('fetchContent:', 'no path');
        } else if ($placeholder.hasClass('iframe')) {
            type = 'iframe';
        } else if ($placeholder.hasClass('img')) {
            type = 'img';
        } else {
            console.warn('fetchContent:', 'no type');
        }
        if (type) {
            var $content = $('<' + type + '>');
            $content.attr(Emma.to_object($placeholder.data('attr')));
            $content.addClass('hidden');
            $content.insertAfter($placeholder);
            $content.on('error', function() {
                console.warn('fetchContent:', type, 'FAILED');
                $placeholder.text('Could not load content.');
                $content.remove();
            });
            $content.on('load', function() {
                $placeholder.remove();
                $content.removeClass('hidden');
            });
            $content.attr('src', path);
        }
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleClickAndKeypress($popup_buttons, togglePopup);
    handleClickAndKeypress($popup_closers, togglePopup);

    // ========================================================================
    // Actions
    // ========================================================================

    // Make sure all panels start hidden.
    $popup_panels.toggleClass(HIDDEN_MARKER, true);

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
