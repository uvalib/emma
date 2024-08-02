// app/assets/javascripts/feature/download.js
//
// A small portion of this module involves displaying the inline message that
// indicates sign-in is required on download links in an anonymous session.
// The rest involves the UI for managing the download of Internet Archive items
// via their Printdisabled Unencrypted Ebook API.


import { AppDebug }                         from "../application/debug";
import { appSetup }                         from "../application/setup";
import { handleClickAndKeypress }           from "../shared/accessibility";
import { Emma }                             from "../shared/assets";
import { isHidden, selector, toggleHidden } from "../shared/css";
import { isMissing }                        from "../shared/definitions";
import { deepFreeze }                       from "../shared/objects";
import { SECONDS, secondsSince }            from "../shared/time";


const MODULE = "Download";
const DEBUG  = true;

AppDebug.file("feature/download", MODULE, DEBUG);

appSetup(MODULE, function() {

    /** @type {jQuery} */
    const $download_links = $('.retrieval').children('.probe, .download');

    // Only perform these actions on the appropriate pages.
    if (isMissing($download_links)) { return }

    /**
     * Console output functions for this module.
     */
    const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

    // ========================================================================
    // Type definitions
    // ========================================================================

    /**
     * The format of the response from the "/probe_retrieval" endpoint.
     *
     * @typedef {object} ProbeResponse
     *
     * @property {number}  status
     * @property {string}  message
     * @property {boolean} ready
     * @property {boolean} waiting
     * @property {boolean} error
     *
     * @see "IaDownload::Message::ProbeResponse"
     */

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Polling interval.
     *
     * @readonly
     * @type {number}
     */
    const RETRY_PERIOD = 10 * SECONDS;

    /**
     * Polling interval value which indicates the end of polling.
     *
     * @readonly
     * @type {number}
     */
    const NO_RETRY = -1;

    /**
     * Probing state.  Each key represents a state and each value is the CSS
     * class indicating that state on the link element.
     *
     * READY:   A direct link to the item is available.
     * PROBING: The request to locate the item is in progress.
     * FAILED:  The request to locate the item failed.
     *
     * @readonly
     * @type {StringTable}
     */
    const DOWNLOAD_STATE = deepFreeze({
        READY:   "complete",
        PROBING: "probing",
        FAILED:  "failed",
    });

    /**
     * Progress indicator element selector.
     *
     * @readonly
     * @type {string}
     */
    const PROGRESS = selector(Emma.Download.progress.class);

    /**
     * Failure message element selector.
     *
     * @readonly
     * @type {string}
     */
    const FAILURE = selector(Emma.Download.failure.class);

    /**
     * Download button element selector.
     *
     * @readonly
     * @type {string}
     */
    const BUTTON = selector(Emma.Download.button.class);

    /**
     * Selector for links which are not currently enabled.
     *
     * @type {string}
     */
    const UNAUTHORIZED = ".sign-in-required";

    // ========================================================================
    // Variables
    // ========================================================================

    const $no_auth_links  = $download_links.filter(UNAUTHORIZED);
    const $probe_controls = $download_links.not(`.download, ${UNAUTHORIZED}`);

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Generate a download button when an item is ready for download.
     *
     * @param {ElementEvt} event
     *
     * @returns {boolean}             Always *false* to end event propagation.
     */
    function initiateDownload(event) {
        const func  = "initiateDownload";
        const $link = $(event.currentTarget || event.target);
        //OUT.debug(`${func}: event =`, event, "; $link=", $link);
        if ($link.hasClass(DOWNLOAD_STATE.PROBING)) {
            OUT.debug(`${func}: already probing`);
        } else if ($link.hasClass(DOWNLOAD_STATE.READY)) {
            probeEnded($link);
        } else {
            probeStarted($link);
            probeForDownload($link);
        }
        return false;
    }

    /**
     * Asynchronously probe for availability of the requested item.
     *
     * While the probe returns with "waiting", this indicates that the item is
     * being generated on-the-fly at Internet Archive.
     *
     * When the probe returns with "ready", the actual download button is
     * displayed.
     *
     * @param {jQuery} $link
     */
    function probeForDownload($link) {
        const func  = "probeForDownload";
        const url   = $link.attr("data-path");

        OUT.debug(`${func}: AT`, url);

        const start = Date.now();
        let delay   = undefined;
        let ready   = false;
        let error   = "";

        $.ajax({
            url:      url,
            type:     "GET",
            dataType: "json",
            success:  onSuccess,
            error:    onError,
            complete: onComplete
        });

        /**
         * Parse the reply to determine availability of the requested item.
         *
         * @param {object}         data
         * @param {string}         _status
         * @param {XMLHttpRequest} _xhr
         */
        function onSuccess(data, _status, _xhr) {
            //OUT.debug(`${func}: received data:`, data);
            if (isMissing(data)) {
                error = "no data";
            } else if (typeof(data) !== "object") {
                error = `unexpected data type ${typeof data}`;
            } else if ((delay = getRetryPeriod($link)) === NO_RETRY) {
                error = Emma.Download.failure.canceled;
            } else {
                // The actual data may be inside '{ "response" : { ... } }'.
                /** @type {ProbeResponse} */
                const info = data.response || data;
                if (info.ready) {
                    ready = true;
                } else if (info.waiting) {
                    OUT.debug(`${func}:`, info.message);
                } else {
                    error = `reported error: "${info.message}" (${info.status})`;
                }
            }
        }

        /**
         * Accumulate the status failure message.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         * @param {string}         message
         */
        function onError(xhr, status, message) {
            error = `${status}: ${xhr.status} ${message}`;
        }

        /**
         * Actions after the probe is completed.  If the requested item is
         * available then the download button is displayed.  If there was an
         * error condition a failure message is displayed.  Otherwise, another
         * probe is scheduled to be performed after a delay.
         *
         * @param {XMLHttpRequest} _xhr
         * @param {string}         _status
         */
        function onComplete(_xhr, _status) {
            OUT.debug(`${func}: completed in`, secondsSince(start), "sec.");
            if (error) { OUT.warn(`${func}: ${url}:`, error) }
            if (ready || error) {
                probeEnded($link, error);
            } else {
                setTimeout(retryProbe, delay);
            }
        }

        /**
         * Poll for completion of the artifact being generated unless the
         * current browser tab is not visible.  In that case, do nothing but
         * reschedule another polling attempt.
         */
        function retryProbe() {
            //OUT.debug(`${func}: retryProbe`);
            if (document.hidden) {
                setTimeout(retryProbe, delay);
            } else {
                probeForDownload($link);
            }
        }
    }

    /**
     * Update state and display to indicate that probing is in progress.
     *
     * @param {jQuery} $link
     */
    function probeStarted($link) {
        //OUT.debug("probeStarted: $link =", $link);
        setRetryPeriod($link);
        showProgressIndicator($link);
        hideFailureMessage($link);
        hideDownloadButton($link);
        setState($link, DOWNLOAD_STATE.PROBING);
    }

    /**
     * Update state and display to indicate that probing is finished.
     *
     * @param {jQuery} $link
     * @param {string} [error]
     */
    function probeEnded($link, error) {
        //OUT.debug(`probeEnded: error = "${error}"; $link =`, $link);
        clearRetryPeriod($link);
        hideProgressIndicator($link);
        if (error) {
            let message = [error];
            if (!error.match(/cancell?ed/i)) {
                message.unshift(Emma.Download.failure.prefix);
            }
            showFailureMessage($link, message.join(": "));
            hideDownloadButton($link);
            setState($link, DOWNLOAD_STATE.FAILED);
        } else {
            hideFailureMessage($link);
            showDownloadButton($link);
            setState($link, DOWNLOAD_STATE.READY);
        }
    }

    /**
     * Stop probing for a downloadable item.
     *
     * @param {ElementEvt} event
     */
    function cancelProbing(event) {
        //OUT.debug("cancelProbing: event =", event);
        const state = selector(DOWNLOAD_STATE.PROBING);
        let $link   = $(event.currentTarget || event.target);
        if (!$link.is(state)) {
            $link = $link.siblings(state).first();
        }
        if (!$link.is(state)) {
            $link = $link.parents(state).first();
        }
        probeEnded($link, Emma.Download.failure.canceled);
        setRetryPeriod($link, NO_RETRY);
    }

    // ========================================================================
    // Functions - progress indicator
    // ========================================================================

    /**
     * Display a "probing" progress indicator.
     *
     * @param {jQuery} $link
     */
    function showProgressIndicator($link) {
        //OUT.debug("showProgressIndicator: $link =", $link);
        const $indicator = $link.siblings(PROGRESS);
        if (isHidden($indicator)) {
            toggleHidden($indicator, false).on("click", cancelProbing);
        }
    }

    /**
     * Stop displaying the "probing" progress indicator.
     *
     * @param {jQuery} $link
     */
    function hideProgressIndicator($link) {
        //OUT.debug("hideProgressIndicator: $link =", $link);
        const $indicator = $link.siblings(PROGRESS);
        toggleHidden($indicator, true).off("click", cancelProbing);
    }

    // ========================================================================
    // Functions - failure message
    // ========================================================================

    /**
     * Display a failure message for an unauthorized link.
     *
     * @param {ElementEvt} event
     */
    function showNotAuthorized(event) {
        //OUT.debug("showNotAuthorized: event =", event);
        event.preventDefault();
        const $link = $(event.currentTarget || event.target);
        showFailureMessage($link, Emma.Download.failure.sign_in);
    }

    /**
     * Display a download failure message after the download link.
     *
     * @param {jQuery} $link
     * @param {string} [error]
     */
    function showFailureMessage($link, error) {
        //OUT.debug(`showFailureMessage: error = "${error}"; $link =`, $link);
        const message  = error || Emma.Download.failure.unknown;
        const $failure = $link.siblings(FAILURE);
        $failure.text(message);
        $failure.attr("title", message);
        toggleHidden($failure, false);
    }

    /**
     * Stop displaying a download failure message.
     *
     * @param {jQuery} $link
     */
    function hideFailureMessage($link) {
        //OUT.debug("hideFailureMessage: $link =", $link);
        const $failure = $link.siblings(FAILURE);
        toggleHidden($failure, true);
    }

    // ========================================================================
    // Functions - download button
    // ========================================================================

    /**
     * Reveal the button for the actual item download.
     *
     * @param {jQuery} $link
     */
    function showDownloadButton($link) {
        const func    = "showDownloadButton";
        const $button = $link.siblings(BUTTON);
        const new_tip = $link.attr("data-complete-tooltip");
        const url     = $button.attr("href");

        OUT.debug(`${func}: FOR`, url);

        if (new_tip) {
            const old_tip = $link.attr("title");
            $link.attr("data-tooltip", old_tip);
            $link.attr("title",        new_tip);
        }
        $link.addClass("disabled").attr("tabindex", -1);
        toggleHidden($button, false);
        $button.trigger("focus");
    }

    /**
     * Hide the download link button.
     *
     * @param {jQuery} $link
     */
    function hideDownloadButton($link) {
        //OUT.debug("hideDownloadButton: link =", link);
        const $button = $link.siblings(BUTTON);
        const old_tip = $link.attr("data-tooltip");
        if (old_tip) {
            $link.attr("title", old_tip);
        }
        $link.removeClass("disabled").attr("tabindex", 0);
        toggleHidden($button, true);
        $link.trigger("focus");
    }

    // ========================================================================
    // Functions - download link state
    // ========================================================================

    /**
     * Set the state of a download link.
     *
     * @param {jQuery} $link
     * @param {string} new_state
     */
    function setState($link, new_state) {
        //OUT.debug(`setState: new_state = "${new_state}"; $link =`, $link);
        const other_states = Object.values(DOWNLOAD_STATE);
        delete other_states[new_state];
        $link.removeClass(other_states);
        $link.toggleClass(new_state, true);
    }

    // ========================================================================
    // Functions - polling
    // ========================================================================

    /**
     * The data() item holding the probe retry period.
     *
     * @readonly
     * @type {string}
     */
    const RETRY_DATA = "retry";

    /**
     * Get the polling period for probing availability of an item.
     *
     * @param {jQuery} $link
     *
     * @returns {number|undefined}
     */
    function getRetryPeriod($link) {
        return $link.data(RETRY_DATA);
    }

    /**
     * Set the polling period for probing availability of an item.
     *
     * @param {jQuery} $link
     * @param {number} [value]
     */
    function setRetryPeriod($link, value = RETRY_PERIOD) {
        //OUT.debug(`setRetryPeriod: value = "${value}"; $link =`, $link);
        $link.data(RETRY_DATA, value);
    }

    /**
     * Clear the polling period for probing availability of an item.
     *
     * @param {jQuery} $link
     */
    function clearRetryPeriod($link) {
        //OUT.debug("clearRetryPeriod: $link =", $link);
        $link.removeData(RETRY_DATA);
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    // Display failure message if not authorized.
    handleClickAndKeypress($no_auth_links, showNotAuthorized);

    // Override probe links in order to get the item asynchronously.
    handleClickAndKeypress($probe_controls, initiateDownload);

});
