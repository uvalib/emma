// app/assets/javascripts/shared/analytics.js
//
// This module involves working with the Matomo tracker.
// The Matomo script is loaded via the <head> section of the page.
//
// noinspection JSUnresolvedReference


import { AppDebug }                         from '../application/debug';
import { Emma }                             from './assets';
import { selector }                         from './css';
import { isMissing, isPresent, notDefined } from './definitions';
import { handleEvent }                      from './events';


AppDebug.file('shared/analytics');

/**
 * @external Matomo
 * @see https://github.com/matomo-org/matomo/blob/5.x-dev/js/piwik.js
 */

/**
 * Add Matomo analytics to the page.
 *
 * Each top-level (layout) script should run `Analytics.updatePage()` as the
 * final action of the .ready() handler.  Functions which load asynchronous
 * content into the Virgo page should `Analytics.updatePage($new_element)`,
 * where $new_element is the root of the hierarchy of added content.
 *
 * @type {object}
 *
 * @property {function} updatePage
 * @property {function} defaultRoot
 * @property {function} defaultSelector
 * @property {function} suppress
 * @property {function} enabled
 */
export const Analytics = (function() {

    /**
     * @constant
     * @type {string}
     */
    const TRACKER = Emma.Analytics.tracker_url;

    /**
     * @constant
     * @type {string}
     */
    const SITE = Emma.Analytics.site;

    /**
     * @constant
     * @type {boolean}
     */
    const ENABLED = TRACKER && SITE && Emma.Analytics.enabled;

    /**
     * If *true*, add LINK_CLASS to any links which are being tracked.
     *
     * @constant
     * @type {boolean}
     */
    const MARK_LINKS = true;

    /**
     * CSS class to identify a link which is being tracked.
     *
     * @constant
     * @type {string}
     */
    const LINK_CLASS = 'matomo_link';

    /**
     * Elements with these CSS classes aren't tracked.
     *
     * @constant
     * @type {string[]}
     */
    const IGNORE_CLASSES = [
        'submit-form'       // Don't track star/unstar links.
    ];

    /**
     * Elements with these CSS classes should be noted as downloads.
     *
     * @constant
     * @type {string[]}
     */
    const DOWNLOAD_CLASSES = [
        'download'
    ];

    // ========================================================================
    // Variables
    // ========================================================================

    /** @type {boolean} */
    let suppressed = !ENABLED;

    /** @type {Matomo} */
    let tracker;

    // ========================================================================
    // Internal function definitions
    // ========================================================================

    /**
     * Track links on the page, even if they are within invisible elements.
     *
     * Although, normally, repeated calls to `enableLinkTracking()` is
     * sufficient to incorporate new links as they are added to the page, this
     * function allows for two extensions that Matomo does not seem to support
     * natively:
     *
     * - Handling of links which are in invisible elements (needed for virtual
     *    shelf browse).
     *
     * - Allowing '[data-path]' elements to be treated as links.  (Matomo's own
     *    code ignores elements unless they have '[href]' element, but many
     *    virtual shelf browse "links" are actually non-anchor elements with
     *    a "data-path" attribute instead of an "href" attribute.)
     *
     * @param {Selector} [root]       Default: {@link defaultRoot}()
     * @param {Selector} [sel]        Default: {@link defaultSelector}()
     */
    function addListener(root, sel) {
        if (!tracker) { return }
        const $root   = root ? $(root) : defaultRoot();
        const $links  = $root.find(sel || defaultSelector());
        const ignored = selector(IGNORE_CLASSES);
        $links.not(ignored).each((_, link) => {
            const $link = $(link);
            const href  = $link.attr('href') || $link.attr('data-path');
            if (href && !href.match(/^javascript:/)) {
                if (MARK_LINKS) { $link.addClass(LINK_CLASS) }
                // noinspection JSUnresolvedReference
                tracker.addListener(link);
            }
        });
    }

    // ========================================================================
    // Internal function definitions -- special trackers
    // ========================================================================

    /**
     * Track events on specific items.
     *
     * @param {Selector} [root]       Default: {@link defaultRoot}()
     */
    function trackSpecial(root) {
        const $rt = root ? $(root) : defaultRoot();
        trackPage($rt);
    }

    /**
     * Track events within a generic page.
     *
     * @param {jQuery} $root
     * @param {string} [topic]        Event category; default: 'OtherPage'
     */
    function trackPage($root, topic) {
        const t = topic || 'OtherPage';
        if (skipTracking($root, t)) { return }
        trackPageControls($root, t);
    }

    /**
     * Track events within a generic page.
     *
     * @param {jQuery} $root
     * @param {string} [_topic]       Event category; unused.
     */
    function trackPageControls($root, _topic) {
        trackHeader($root);
        trackFooter($root);
    }

    /**
     * Track events on page header items.
     *
     * @param {jQuery} $root
     * @param {string} [topic]        Event category.
     */
    function trackHeader($root, topic = 'Header') {
        const $elem = $root.find('.layout-banner');
        if (isMissing($elem)) { return }
        const track = (name, sel) => trackClick($elem, sel, topic, name);

        // noinspection SpellCheckingInspection
        track('Home',    'a[href="/"]');
        track('SignIn',  'a[href$="/sign_in"]');
        track('SignOut', 'a[href$="/sign_out"]');
    }

    /**
     * Track events on page footer items.
     *
     * @param {jQuery} $root
     * @param {string} [topic]        Event category.
     */
    function trackFooter($root, topic = 'Footer') {
        const $elem = $root.find('.layout-footer');
        if (isMissing($elem)) { return }
        const track = (name, sel) => trackClick($elem, sel, topic, name);

        // noinspection SpellCheckingInspection
        track('Website', 'a[href*="uvacreate"]');
        track('Contact', 'a[href^="mailto:"]');
    }

    /**
     * Track click events on a specific item.
     *
     * @param {jQuery}   $root
     * @param {Selector} selector
     * @param {string}   cat          Matomo event category.
     * @param {string}   act          Matomo event action.
     * @param {function} [condition]  Evaluated in the handler.
     *
     * @return {number}               The number of items found.
     */
    function trackClick($root, selector, cat, act, condition) {
        return trackEvent('click', $root, selector, cat, act, condition);
    }

    /**
     * Track hover events on a specific item.
     *
     * @param {jQuery}   $root
     * @param {Selector} selector
     * @param {string}   cat          Matomo event category.
     * @param {string}   act          Matomo event action.
     * @param {function} [condition]  Evaluated in the handler.
     *
     * @return {number}               The number of items found.
     */
    function trackHover($root, selector, cat, act, condition) {
        return trackEvent('mouseover', $root, selector, cat, act, condition);
    }

    /**
     * Track an event on a specific item.
     *
     * @param {string}   event_type
     * @param {jQuery}   $root
     * @param {Selector} selector
     * @param {string}   cat          Matomo event category.
     * @param {string}   act          Matomo event action.
     * @param {function} [condition]  Evaluated in the handler.
     *
     * @return {number}               The number of items found.
     */
    function trackEvent(event_type, $root, selector, cat, act, condition) {
        const $elements = $root.find(selector);
        if (isPresent($elements)) {
            const track = function() { _paq.push(['trackEvent', cat, act]) };
            let handler = track;
            if (condition) {
                handler = function(event) { condition(event) && track() };
            }
            handleEvent($elements, event_type, handler);
        }
        return $elements.length;
    }

    /**
     * Indicate whether the element should be tracked.
     *
     * @param {jQuery} $root
     * @param {string} [_topic]       Event category; unused.
     *
     * @return {boolean}
     */
    function skipTracking($root, _topic) {
        return isMissing($root);
    }

    // ========================================================================
    // Function definitions
    // ========================================================================

    /**
     * Disable this feature temporarily.
     *
     * @param {boolean} [setting]     Default: true.
     */
    function suppress(setting) {
        suppressed = notDefined(setting) || !!setting;
    }

    /**
     * Indicate whether this feature is (currently) enabled.
     *
     * @return {boolean}
     */
    function enabled() {
        return ENABLED && !suppressed;
    }

    /**
     * defaultRoot
     *
     * @return {jQuery}
     */
    function defaultRoot() {
        return $('body');
    }

    /**
     * defaultSelector
     *
     * @return {string}
     */
    function defaultSelector() {
        return '[href], [data-path]';
    }

    /**
     * Initiate Matomo tracking for the current page and setup Matomo click
     * handlers on page links.
     *
     * This will be called automatically when the page is ready.  If DOM
     * element(s) are added asynchronously, this must be called again to track
     * any added links.
     *
     * @param {Selector} [root]       Default: {@link defaultRoot}()
     * @param {Selector} [selector]   Default: {@link defaultSelector}()
     */
    function updatePage(root, selector) {
        const func = 'Analytics.updatePage';
        if (!enabled()) {
            //console.log(`${func} skipped - not enabled`);
        } else if (tracker) {
            // Subsequent calls (explicitly as `Analytics.updatePage()`).
            addListener(root, selector);
            trackSpecial(root);
        } else {
            // First call (via the ready() handler).
            try {
                tracker = Matomo.addTracker(TRACKER, SITE);
                tracker.trackPageView();
                tracker.setIgnoreClasses(IGNORE_CLASSES);
                tracker.setDownloadClasses(DOWNLOAD_CLASSES);
                addListener(root, selector);
                trackSpecial(root);
            } catch (err) {
                console.error(`${func}:`, err);
                tracker = null;
            }
        }
    }

    // ========================================================================
    // Exposed definitions
    // ========================================================================

    return {
        updatePage: updatePage,
        suppress:   suppress,
        enabled:    enabled
    };

})();
