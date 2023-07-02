// app/assets/javascripts/feature/iframe.js


import { AppDebug }               from '../application/debug';
import { appSetup }               from '../application/setup';
import { isMissing }              from '../shared/definitions';
import { handleClickAndKeypress } from '../shared/events';


const MODULE = 'Iframe';
const DEBUG  = true;

AppDebug.file('feature/iframe', MODULE, DEBUG);

appSetup(MODULE, function() {

    const $iframe_body = $('body.modal');

    // Only proceed if this is being run from within an `<iframe>`.
    if (isMissing($iframe_body)) {
        return;
    }

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * Clickable elements within the `<iframe>` contents.
     *
     * @type {jQuery}
     */
    const $iframe_links = $iframe_body.find('[href]');

    /**
     * Clickable elements within `<iframe>` contents which are in-page links.
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
     * `<iframe>`.
     *
     * @param {jQuery.Event|UIEvent} [event]
     *
     * @returns {boolean}   False to indicate that the event has been handled.
     */
    function scrollToAnchor(event) {
        const func   = 'IFRAME scrollToAnchor';
        const $link  = $(event ? event.target : this);
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
     * Indicate whether console debugging is active.
     *
     * @returns {boolean}
     */
    function _debugging() {
        return AppDebug.activeFor(MODULE, DEBUG);
    }

    /**
     * Emit a console message if debugging.
     *
     * @param {...*} args
     */
    function _debug(...args) {
        _debugging() && console.log(`${MODULE}:`, ...args);
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    handleClickAndKeypress($anchor_links, scrollToAnchor);
});
