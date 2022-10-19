// app/assets/javascripts/feature/scroll.js


import { Emma }                                from '../shared/assets'
import { selector }                            from '../shared/css'
import { isMissing }                           from '../shared/definitions'
import { handleClickAndKeypress, handleEvent } from '../shared/events'
import { deepFreeze }                          from '../shared/objects'


$(document).on('turbolinks:load', function() {

    /**
     * CSS class indicating the "scroll-to-top" button.
     *
     * @readonly
     * @type {string}
     */
    const SCROLL_BUTTON_CLASS = Emma.Scroll.button.class;
    const SCROLL_BUTTON = selector(SCROLL_BUTTON_CLASS);

    /** @type {jQuery} */
    const $scroll_button = $(SCROLL_BUTTON).not('.for-example');

    // Only perform these actions on the appropriate pages.
    if (isMissing($scroll_button)) { return; }

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Flag controlling console debug output.
     *
     * @readonly
     * @type {boolean}
     */
    const DEBUGGING = false;

    /**
     * CSS class for the element which is scrolled to the top.
     *
     * @readonly
     * @type {string}
     */
    const SCROLL_TARGET_CLASS = Emma.Scroll.target.class;
    const SCROLL_TARGET = selector(SCROLL_TARGET_CLASS);

    /**
     * Selector(s) for scroll target with fall-backs.
     *
     * @readonly
     * @type {string[]}
     */
    const SCROLL_TARGETS = deepFreeze([SCROLL_TARGET, '#main', 'body']);

    /**
     * Selector for previous-list-item controls.
     *
     * @readonly
     * @type {string}
     */
    const PREV = '.prev-next .prev';

    /**
     * Selector for next-list-item controls.
     *
     * @readonly
     * @type {string}
     */
    const NEXT = '.prev-next .next';

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * The element that will be scrolled to the top.
     *
     * @type {jQuery}
     */
    let $scroll_target;
    $.each(SCROLL_TARGETS, (_, tgt) => isMissing(($scroll_target = $(tgt))));

    const $prev_buttons = $(PREV).not('.forbidden');
    const $next_buttons = $(NEXT).not('.forbidden');

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
            const $container  = $(window);
            const scroll_pos  = $container.scrollTop();
            const visible_pos = $container.height() / 3;
            visible = (scroll_pos > visible_pos);
        }
        $scroll_button.toggleClass('hidden', !visible);
    }

    /**
     * Scroll so that the top of the target element is visible.
     */
    function scrollToTop() {
        _debug('scrollToTop');
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
     * @see "SearchDecorator#prev_next_controls"
     */
    function scrollToPrev(event) {
        _debug('scrollToPrev');
        return scrollToRecord(event, PREV);
    }

    /**
     * Scroll so that the next list entry is fully displayed at the top of the
     * screen.
     *
     * @param {jQuery.Event} event
     *
     * @returns {boolean}             Always *false* to end event propagation.
     *
     * @see "SearchDecorator#prev_next_controls"
     */
    function scrollToNext(event) {
        _debug('scrollToNext');
        return scrollToRecord(event, NEXT);
    }

    /**
     * Scroll so that the indicated list entry is fully displayed at the top of
     * the screen.
     *
     * @param {jQuery.Event} event
     * @param {Selector}     button_selector
     *
     * @returns {boolean}             Always *false* to end event propagation.
     *
     * @see "SearchDecorator#prev_next_controls"
     */
    function scrollToRecord(event, button_selector) {
        const $button = $(event.currentTarget || event.target);
        if (!$button.hasClass('disabled') && !$button.hasClass('forbidden')) {
            const record_id = $button.attr('href');

            const $title    = $(record_id);
            const $t_pair   = $title.parents('.pair').first();
            const $f_pair   = $t_pair.siblings(':not(.field-Title)').first();
            const $format   = $f_pair.children('.value');
            const t_height  = $title[0].scrollHeight;
            const t_pos     = $title[0].offsetTop;
            const f_height  = $format[0].scrollHeight;
            const f_pos     = $format[0].offsetTop;
            const y_delta   = t_height + f_height + (t_pos - f_pos);

            // Scroll to the indicated entry then scroll up more so that the
            // first metadata label is visible below the title.
            $title[0].scrollIntoView(true);
            window.scrollBy(0, -y_delta);

            // The item number is at the same Y position as the entry for
            // desktop and mobile ($wide-screen and $medium-width), but it is
            // above the entry for the hand-held ($narrow-screen) form-factor.
            // (For Firefox n_pos < e_pos, but for Chrome n_pos > e_pos.)
            // This requires an additional adjustment.
            const $entry  = $t_pair.parent();
            const $number = $entry.prev('.number');
            const e_pos   = $entry[0].offsetTop;
            const n_pos   = $number[0].offsetTop;
            if (n_pos !== e_pos) {
                window.scrollBy(0, -$number[0].scrollHeight);
            }

            // Set focus to the button which matches the original action.
            $title.find(button_selector).focus();
        }
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
    function _debug(...args) {
        if (DEBUGGING) { console.log(...args); }
    }

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

});
