// app/assets/javascripts/feature/scroll.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

$(document).on('turbolinks:load', function() {

    /**
     * CSS class indicating the "scroll-to-top" button.
     *
     * @constant
     * @type {Selector}
     */
    const SCROLL_BUTTON_SELECTOR = selector(Emma.Scroll.button.class);

    /** @type {jQuery} */
    let $scroll_button = $(SCROLL_BUTTON_SELECTOR).not('.for-help');

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
    const DEBUGGING = false;

    /**
     * Selector for the element which is scrolled to the top.
     *
     * @constant
     * @type {string}
     */
    const SCROLL_TARGET_SELECTOR = selector(Emma.Scroll.target.class);

    /**
     * Selector(s) for scroll target with fall-backs.
     *
     * @constant
     * @type {string[]}
     */
    const SCROLL_TARGET_SELECTORS =
        deepFreeze([SCROLL_TARGET_SELECTOR, '#main', 'body']);

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * The element that will be scrolled to the top.
     *
     * @type {jQuery}
     */
    let $scroll_target;
    $.each(SCROLL_TARGET_SELECTORS, function(_, selector) {
        $scroll_target = $(selector);
        return isMissing($scroll_target);
    });

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleEvent($(window), 'scroll', toggleScrollButton);
    handleClickAndKeypress($scroll_button, scrollToTop);

    // ========================================================================
    // Actions
    // ========================================================================

    // Button should start hidden initially and only appear after scrolling.
    // However, if the page is refreshed with the window already scrolled, then
    // button should appear immediately.
    toggleScrollButton();

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Set visibility of the scroll-to-top button.
     *
     * @param {Event|boolean} [event]
     */
    function toggleScrollButton(event) {
        let visible;
        if (typeof event === 'boolean') {
            visible = event;
        } else {
            let $container    = $(window);
            const scroll_pos  = $container.scrollTop();
            const visible_pos = $container.height() / 2;
            visible = (scroll_pos > visible_pos);
        }
        $scroll_button.toggleClass('hidden', !visible);
    }

    /**
     * Scroll so that the top of the target element is visible.
     */
    function scrollToTop() {
        debug('scrollToTop');
        $scroll_target[0].scrollIntoView();
        //focusableIn($scroll_target).first().focus();
    }

    // ========================================================================
    // Functions - other
    // ========================================================================

    /**
     * Emit a console message if debugging.
     *
     * @param {...*} args
     */
    function debug(...args) {
        if (DEBUGGING) { consoleLog(...args); }
    }

});
