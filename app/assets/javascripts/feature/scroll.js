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

    /**
     * Selector(s) for previous-list-item controls.
     *
     * @constant
     * @type {string}
     */
    const PREV_SELECTOR = '.prev-next .prev';

    /**
     * Selector(s) for next-list-item controls.
     *
     * @constant
     * @type {string}
     */
    const NEXT_SELECTOR = '.prev-next .next';

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
    let $prev_buttons = $(PREV_SELECTOR);
    let $next_buttons = $(NEXT_SELECTOR);

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleEvent($(window), 'scroll', toggleScrollButton);
    handleClickAndKeypress($scroll_button, scrollToTop);
    handleClickAndKeypress($prev_buttons,  scrollToPrev);
    handleClickAndKeypress($next_buttons,  scrollToNext);

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

    /**
     * Scroll so that the previous list entry is fully displayed at the top of
     * the screen.
     *
     * @param {jQuery.Event} event
     *
     * @returns {boolean}             Always *false* to end event propagation.
     *
     * @see "SearchHelper#prev_next_controls"
     */
    function scrollToPrev(event) {
        debug('scrollToPrev');
        let $button    = $(event.currentTarget || event.target);
        const selector = $button.attr('href');
        let $title     = $(selector);
        const t_height = $title[0].scrollHeight;
        const t_pos    = $title[0].offsetTop;
        let $format    = $title.siblings('.field-Format').first();
        const f_height = $format[0].scrollHeight;
        const f_pos    = $format[0].offsetTop;
        const y_delta  = t_height + f_height + t_pos - f_pos;
        $title[0].scrollIntoView(true);
        window.scrollBy({ top: -y_delta });
        return false;
    }

    /**
     * Scroll so that the next list entry is fully displayed at the top of the
     * screen.
     *
     * @param {jQuery.Event} event
     *
     * @returns {boolean}             Always *false* to end event propagation.
     *
     * @see "SearchHelper#prev_next_controls"
     */
    function scrollToNext(event) {
        debug('scrollToNext');
        let $button    = $(event.currentTarget || event.target);
        const selector = $button.attr('href');
        let $title     = $(selector);
        let $format    = $title.siblings('.field-Format').first();
        const y_delta  = $format[0].scrollHeight;
        $title[0].scrollIntoView(true);
        window.scrollBy({ top: -y_delta });
        return false;
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
