// app/assets/javascripts/feature/iframe.js


import { isMissing }              from '../shared/definitions'
import { handleClickAndKeypress } from '../shared/events'


$(document).on('turbolinks:load', function() {

    const $iframe_body = $('body.modal');

    // Only proceed if this is being run from within an <iframe>.
    if (isMissing($iframe_body)) {
        return;
    }

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

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * Clickable elements within the <iframe> contents.
     *
     * @type {jQuery}
     */
    const $iframe_links = $iframe_body.find('[href]');

    /**
     * Clickable elements within the <iframe> contents which are in-page links.
     *
     * @type {jQuery}
     */
    const $anchor_links = $iframe_links.filter((_, link) => link.hash);

    // ========================================================================
    // Functions
    // ========================================================================

    // noinspection FunctionWithInconsistentReturnsJS
    /**
     * Intercept anchor links to scroll to the element on the page inside the
     * <iframe>.
     *
     * @param {jQuery.Event|UIEvent} [event]
     *
     * @returns {boolean}   False to indicate that the event has been handled.
     */
    function scrollToAnchor(event) {
        const func   = 'IFRAME scrollToAnchor';
        let $link    = $(event ? event.target : this);
        const anchor = $link[0].hash;
        let $anchor  = anchor && $(anchor);
        if ($anchor) {
            event.preventDefault();
            const top = $anchor.offset().top;
            _debug(`${func}: ${anchor} AT y =`, top);
            window.scrollTo(0, top);
            return false;
        } else {
            console.error(`${func}: NON ANCHOR LINK`, $link);
        }
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

    handleClickAndKeypress($anchor_links, scrollToAnchor);
});
