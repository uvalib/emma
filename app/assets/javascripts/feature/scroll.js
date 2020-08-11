// app/assets/javascripts/feature/scroll.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    /**
     * CSS class indicating the "scroll-to-top" button.
     *
     * @constant
     * @type {Selector}
     */
    var SCROLL_BUTTON_SELECTOR = '.' + Emma.Scroll.button.class;

    /** @type {jQuery} */
    var $scroll_button = $(SCROLL_BUTTON_SELECTOR).not('.for-help');

    // Only perform these actions on the appropriate pages.
    if (isMissing($scroll_button)) { return; }

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Flag controlling console debug output.
     *
     * @constant
     * @type {boolean}
     */
    var DEBUGGING = false;

    /**
     * Selector for the element which is scrolled to the top.
     *
     * @constant
     * @type {string}
     */
    var SCROLL_TARGET_SELECTOR = '.' + Emma.Scroll.target.class;

    /**
     * Selector(s) for scroll target with fall-backs.
     *
     * @constant
     * @type {string[]}
     */
    var SCROLL_TARGET_SELECTORS = [SCROLL_TARGET_SELECTOR, '#main', 'body'];

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * The element that will be scrolled to the top.
     *
     * @type {jQuery}
     */
    var $scroll_target;
    $.each(SCROLL_TARGET_SELECTORS, function(_, selector) {
        $scroll_target = $(selector);
        return isMissing($scroll_target);
    });

    // ========================================================================
    // Function definitions
    // ========================================================================

    /**
     * Set visibility of the scroll-to-top button.
     *
     * @param {Event|boolean} [event]
     */
    function toggleScrollButton(event) {
        var visible;
        if (notDefined(event)) {
            visible = false;
        } else if (typeof event === 'boolean') {
            visible = event;
        } else {
            var $container  = $(window);
            var scroll_pos  = $container.scrollTop();
            var visible_pos = $container.height() / 2;
            visible = (scroll_pos > visible_pos);
        }
        $scroll_button.toggleClass('hidden', !visible);
    }

    /**
     * Scroll so that the top of the target element is visible.
     */
    function scrollToTop() {
        $scroll_target[0].scrollIntoView();
        //focusableIn($scroll_target).first().focus();
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleEvent($(window), 'scroll', toggleScrollButton);
    handleClickAndKeypress($scroll_button, scrollToTop);

    // ========================================================================
    // Actions
    // ========================================================================

    // Button should start hidden initially and only appear after scrolling.
    toggleScrollButton();

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
