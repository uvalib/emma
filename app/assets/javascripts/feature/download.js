// app/assets/javascripts/feature/download.js

//= require shared/assets
//= require shared/definitions

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    /** @type {jQuery} */
    const $artifact_links = $('.artifact .link');

    // Only perform these actions on the appropriate pages.
    if (isMissing($artifact_links)) { return; }

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Flag controlling console debug output.
     *
     * @type {boolean}
     */
    const DEBUGGING = true;

    /**
     * Frequency for re-requesting a download link.
     *
     * @type {number}
     */
    const RETRY_PERIOD = 1 * SECOND;

    /**
     * Frequency for re-requesting a download link for DAISY_AUDIO.
     *
     * @type {number}
     */
    const RETRY_DAISY_AUDIO = 5 * RETRY_PERIOD;

    /**
     * Retry period value which indicates the end of retrying.
     *
     * @type {number}
     */
    const NO_RETRY = -1;

    /**
     * Download link state.  Each key represents a state and each value is the
     * CSS class indicating that state on the link element.
     *
     * FAILED:     The request to generate an artifact failed.
     * REQUESTING: The request to generate an artifact is in progress.
     * READY:      A direct link to the generated artifact is available.
     *
     * @type {{FAILED: string, REQUESTING: string, READY: string}}
     */
    const STATE = {
        FAILED:     'failed',
        REQUESTING: 'requesting',
        READY:      'complete',
    };

    // ========================================================================
    // Event handlers
    // ========================================================================

    // Override download links in order to get the artifact asynchronously.
    $artifact_links.click(function(event) {
        const $link = $(this || event.target);
        if ($link.hasClass(STATE.READY)) {
            endRequesting($link);
        } else if (!$link.hasClass(STATE.REQUESTING)) {
            requestArtifact($link);
        }
        return false;
    });

    // ========================================================================
    // Internal functions
    // ========================================================================

    /**
     * Asynchronously request an artifact download URL.
     *
     * @param {Selector} link
     */
    function requestArtifact(link) {

        const func  = 'requestArtifact: ';
        const $link = $(link);
        const url   = $link.attr('href');
        const start = Date.now();

        debug(func, 'VIA', url);
        let err, delay, target;
        $.ajax({
            url:      url,
            type:     'GET',
            dataType: 'json',
            success:  onSuccess,
            error:    onError,
            complete: onComplete
        });

        /**
         * Parse the reply to acquire the URL from which the file can be
         * downloaded.  If the artifact is not yet ready then the reply should
         * specify a state of 'SUBMITTED'.
         *
         * @param {object}         data
         * @param {string}         status
         * @param {XMLHttpRequest} xhr
         */
        function onSuccess(data, status, xhr) {
            debug(func, 'received', data.length, 'bytes.');
            if (isMissing(data)) {
                err = 'no data';
            } else if (typeof(data) !== 'object') {
                err = 'unexpected data type ' + typeof(data);
            } else if ((delay = getRetryPeriod($link)) === NO_RETRY) {
                err = REQUEST_CANCELLED;
            } else if (!(target = data.url) && (data.state !== 'SUBMITTED')) {
                err = 'unexpected data.state "' + data.state + '"';
            }
        }

        /**
         * Accumulate the status failure message.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         * @param {string}         error
         */
        function onError(xhr, status, error) {
            err = status + ': ' + error;
        }

        /**
         * Actions after the request is completed.  If the target URL was made
         * available then the download button is displayed.  If there was an
         * error condition a failure message is displayed.  Otherwise, another
         * request is scheduled to be performed after a delay.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         */
        function onComplete(xhr, status) {
            if (target) {
                $link.data('path', target);
                endRequesting($link);
            } else if (err) {
                consoleWarn(func, (url + ':'), err);
                endRequesting($link, err);
            } else {
                beginRequesting($link);
                setTimeout(function() { requestArtifact($link); }, delay);
            }
            debug(func, 'complete', secondsSince(start), 'sec.');
        }
    }

    /**
     * Update state and display to indicate that an artifact download URL
     * request is in progress.
     *
     * @param {jQuery} $link
     */
    function beginRequesting($link) {
        showProgressIndicator($link);
        hideFailureMessage($link);
        hideDownloadButton($link);
        set(STATE.REQUESTING, $link);
        setRetryPeriod($link);
    }

    /**
     * Update state and display to indicate that an artifact download URL
     * request is no longer in progress.
     *
     * @param {jQuery} $link
     * @param {string} [error]
     */
    function endRequesting($link, error) {
        hideProgressIndicator($link);
        if (error) {
            showFailureMessage($link, error);
            hideDownloadButton($link);
            set(STATE.FAILED, $link);
        } else {
            hideFailureMessage($link);
            showDownloadButton($link);
            set(STATE.READY, $link);
        }
        clearRetryPeriod($link);
    }

    /**
     * Stop polling with "download" requests.
     *
     * @param {Event} event
     */
    function cancelRequest(event) {
        const state = STATE.REQUESTING;
        let $link = $(this || event.target);
        if (!$link.hasClass(state)) {
            const selector = '.' + state;
            let $e = $link.siblings(selector);
            if (!$e.hasClass(state)) {
                $e = $link.parents(selector);
            }
            $link = $e.first();
        }
        endRequesting($link, REQUEST_CANCELLED);
        setRetryPeriod($link, NO_RETRY);
    }

    // ========================================================================
    // Internal functions - progress indicator
    // ========================================================================

    /**
     * Progress indicator element selector.
     *
     * @type {string}
     */
    const PROGRESS_SELECTOR = '.' + ARTIFACT_PROGRESS_CLASS; // '.progress';

    /**
     * Display a "downloading" progress indicator.
     *
     * @param {jQuery} $link
     */
    function showProgressIndicator($link) {
        const $indicator = $link.siblings(PROGRESS_SELECTOR);
        $indicator.removeClass('hidden').on('click', cancelRequest);
    }

    /**
     * Stop displaying a "downloading" progress indicator.
     *
     * @param {jQuery} $link
     */
    function hideProgressIndicator($link) {
        const $indicator = $link.siblings(PROGRESS_SELECTOR);
        $indicator.addClass('hidden').off('click', cancelRequest);
    }

    // ========================================================================
    // Internal functions - failure message
    // ========================================================================

    /**
     * Failure message element selector.
     *
     * @type {string}
     */
    const FAILURE_SELECTOR = '.' + ARTIFACT_FAILURE_CLASS; // '.failure';

    /**
     * Display a download failure message after the download link.
     *
     * @param {jQuery} $link
     * @param {string} [error]
     */
    function showFailureMessage($link, error) {
        let content = error || '';
        if (!content.match(/cancelled/)) {
            content = FAILURE_PREFIX + (error || UNKNOWN_ERROR);
        }
        const $failure = $link.siblings(FAILURE_SELECTOR);
        $failure.attr('title', content).text(content).removeClass('hidden');
    }

    /**
     * Stop displaying a download failure message.
     *
     * @param {jQuery} $link
     */
    function hideFailureMessage($link) {
        const $failure = $link.siblings(FAILURE_SELECTOR);
        $failure.addClass('hidden');
    }

    // ========================================================================
    // Internal functions - download button
    // ========================================================================

    /**
     * Download button element selector.
     *
     * @type {string}
     */
    const BUTTON_SELECTOR = '.' + ARTIFACT_BUTTON_CLASS; // '.button';

    /**
     * Show the button to download the artifact.
     *
     * @param {Selector}      link
     * @param {string|jQuery} [target]
     */
    function showDownloadButton(link, target) {
        const $link = $(link);
        const url   = target || $link.data('path');
        if (target) {
            $link.data('path', url);
        }
        debug('showDownloadButton: FROM', url);
        const new_tip = $link.data('complete_tooltip');
        if (new_tip) {
            const original_tip = $link.attr('title');
            $link.data('tooltip', original_tip);
            $link.attr('title', new_tip);
        }
        $link.addClass('disabled').attr('tabindex', -1);
        const $button = $link.siblings(BUTTON_SELECTOR);
        $button.attr('href', url).removeClass('hidden');
    }

    /**
     * Hide the button to download the artifact.
     *
     * @param {Selector} link
     */
    function hideDownloadButton(link) {
        const $link = $(link);
        const original_tip = $link.data('tooltip');
        if (original_tip) {
            $link.attr('title', original_tip);
        }
        $link.removeData('path');
        $link.removeClass('disabled').removeAttr('tabindex');
        const $button = $link.siblings(BUTTON_SELECTOR);
        $button.addClass('hidden');
    }

    // ========================================================================
    // Internal functions - download link state
    // ========================================================================

    /**
     * Set the state of a download link.
     *
     * @param {string} new_state
     * @param {jQuery} $link
     */
    function set(new_state, $link) {
        for (const key in STATE) {
            const state = STATE[key];
            if (state === new_state) {
                $link.addClass(state);
            } else {
                clear(state, $link);
            }
        }
    }

    /**
     * Clear the state of a download link.
     *
     * @param {string} old_state
     * @param {jQuery} $link
     */
    function clear(old_state, $link) {
        $link.removeClass(old_state);
    }

    // ========================================================================
    // Internal functions - retry period
    // ========================================================================

    /**
     * Name of the data attribute holding the link's retry period.
     *
     * @type {string}
     */
    const RETRY_ATTRIBUTE = 'retry';

    /**
     * Get the retry period for a download link.
     *
     * @param {jQuery} $link
     *
     * @returns {number|undefined}
     */
    function getRetryPeriod($link) {
        return $link.data(RETRY_ATTRIBUTE);
    }

    /**
     * Set the retry period for a download link.
     *
     * @param {jQuery} $link
     * @param {number} [value]        Default: RETRY_PERIOD.
     */
    function setRetryPeriod($link, value) {
        let period = value || defaultRetryPeriod($link);
        $link.data(RETRY_ATTRIBUTE, period);
    }

    /**
     * Clear the retry period for a download link.
     *
     * @param {jQuery} $link
     */
    function clearRetryPeriod($link) {
        $link.removeData(RETRY_ATTRIBUTE);
    }

    /**
     * Determine the retry period for this download link.
     *
     * @param {jQuery} $link
     *
     * @return {number}
     */
    function defaultRetryPeriod($link) {
        const href = $link.attr('href') || '';
        return href.match(/DAISY_AUDIO/) ? RETRY_DAISY_AUDIO : RETRY_PERIOD;
    }

    // ========================================================================
    // Internal functions - other
    // ========================================================================

    /**
     * Emit a console message if debugging.
     */
    function debug() {
        if (DEBUGGING) {
            consoleLog(arguments);
        }
    }

});
