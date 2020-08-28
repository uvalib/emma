// app/assets/javascripts/feature/iframe.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    let $iframe_body = $('body.modal');

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
     * @constant
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
    let $iframe_links = $iframe_body.find('[href]');

    /**
     * Clickable elements within the <iframe> contents which are in-page links.
     *
     * @type {jQuery}
     */
    let $anchor_links = $iframe_links.filter(function() { return this.hash; });

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleClickAndKeypress($anchor_links, scrollToAnchor);

    // ========================================================================
    // Functions
    // ========================================================================

    // noinspection FunctionWithInconsistentReturnsJS, FunctionWithMultipleReturnPointsJS
    /**
     * Intercept anchor links to scroll to the element on the page inside the
     * <iframe>.
     *
     * @param {Event} [event]
     *
     * @returns {boolean}   False to indicate that the event has been handled.
     */
    function scrollToAnchor(event) {
        const func   = 'IFRAME scrollToAnchor:';
        let $link    = $(event ? event.target : this);
        const anchor = $link[0].hash;
        let $anchor  = anchor && $(anchor);
        if ($anchor) {
            event.preventDefault();
            const top = $anchor.offset().top;
            debug(func, anchor, 'AT y =', top);
            window.scrollTo(0, top);
            return false;
        } else {
            consoleError(func, 'NON ANCHOR LINK', $link);
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
    function debug(...args) {
        if (DEBUGGING) { consoleLog(...args); }
    }
});
