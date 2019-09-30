// app/assets/javascripts/feature/download.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    /** @type {jQuery} */
    var $artifact_links = $('.artifact .link');

    // Only perform these actions on the appropriate pages.
    if (isMissing($artifact_links)) { return; }

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Flag controlling console debug output.
     *
     * @constant {boolean}
     */
    var DEBUGGING = true;

    /**
     * Frequency for re-requesting a download link.
     *
     * @constant {number}
     */
    var RETRY_PERIOD = 1 * SECOND;

    /**
     * Frequency for re-requesting a download link for DAISY_AUDIO.
     *
     * @constant {number}
     */
    var RETRY_DAISY_AUDIO = 5 * RETRY_PERIOD;

    /**
     * Retry period value which indicates the end of retrying.
     *
     * @constant {number}
     */
    var NO_RETRY = -1;

    /**
     * Download link state.  Each key represents a state and each value is the
     * CSS class indicating that state on the link element.
     *
     * FAILED:     The request to generate an artifact failed.
     * REQUESTING: The request to generate an artifact is in progress.
     * READY:      A direct link to the generated artifact is available.
     *
     * @constant {{FAILED: string, REQUESTING: string, READY: string}}
     */
    var STATE = {
        FAILED:     'failed',
        REQUESTING: 'requesting',
        READY:      'complete'
    };

    // ========================================================================
    // Event handlers
    // ========================================================================

    // Override download links in order to get the artifact asynchronously.
    $artifact_links.click(function(event) {
        var $link = $(this || event.target);
        if ($link.hasClass(STATE.READY)) {
            endRequesting($link);
        } else if (!$link.hasClass(STATE.REQUESTING)) {
            beginRequesting($link);
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

        var func  = 'requestArtifact: ';
        var $link = $(link);
        var url   = $link.attr('href');
        var start = Date.now();

        debug(func, 'VIA', url);
        var err, delay, target;
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
            debug(func, 'received data: |', data, '|');
            if (isMissing(data)) {
                err = 'no data';
            } else if (typeof(data) !== 'object') {
                err = 'unexpected data type ' + typeof(data);
            } else if ((delay = getRetryPeriod($link)) === NO_RETRY) {
                err = REQUEST_CANCELLED;
            } else {
                // The actual data may be inside '{ "response" : { ... } }'.
                var info = data.response || data;
                target = info.url;
                if (!target) {
                    if (info.error) {
                        err = 'reported error: "' + info.error + '"';
                    } else if (info.state !== 'SUBMITTED') {
                        err = 'unexpected state: "' + info.state + '"';
                    }
                }
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
        var state = STATE.REQUESTING;
        var $link = $(this || event.target);
        if (!$link.hasClass(state)) {
            var selector = '.' + state;
            var $e = $link.siblings(selector);
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
     * @constant {string}
     */
    var PROGRESS_SELECTOR = '.' + DOWNLOAD_PROGRESS_CLASS;

    /**
     * Display a "downloading" progress indicator.
     *
     * @param {jQuery} $link
     */
    function showProgressIndicator($link) {
        var $indicator = $link.siblings(PROGRESS_SELECTOR);
        if ($indicator.hasClass('hidden')) {
            $indicator.removeClass('hidden').on('click', cancelRequest);
        }
    }

    /**
     * Stop displaying a "downloading" progress indicator.
     *
     * @param {jQuery} $link
     */
    function hideProgressIndicator($link) {
        var $indicator = $link.siblings(PROGRESS_SELECTOR);
        $indicator.addClass('hidden').off('click', cancelRequest);
    }

    // ========================================================================
    // Internal functions - failure message
    // ========================================================================

    /**
     * Failure message element selector.
     *
     * @constant {string}
     */
    var FAILURE_SELECTOR = '.' + DOWNLOAD_FAILURE_CLASS;

    /**
     * Display a download failure message after the download link.
     *
     * @param {jQuery} $link
     * @param {string} [error]
     */
    function showFailureMessage($link, error) {
        var content = error || '';
        if (!content.match(/cancelled/)) {
            content = FAILURE_PREFIX + (error || UNKNOWN_ERROR);
        }
        var $failure = $link.siblings(FAILURE_SELECTOR);
        $failure.attr('title', content).text(content).removeClass('hidden');
    }

    /**
     * Stop displaying a download failure message.
     *
     * @param {jQuery} $link
     */
    function hideFailureMessage($link) {
        var $failure = $link.siblings(FAILURE_SELECTOR);
        $failure.addClass('hidden');
    }

    // ========================================================================
    // Internal functions - download button
    // ========================================================================

    /**
     * Download button element selector.
     *
     * @constant {string}
     */
    var BUTTON_SELECTOR = '.' + DOWNLOAD_BUTTON_CLASS;

    /**
     * Show the button to download the artifact.
     *
     * @param {Selector}      link
     * @param {string|jQuery} [target]
     */
    function showDownloadButton(link, target) {
        var $link = $(link);
        var url   = target || $link.data('path');
        if (target) {
            $link.data('path', url);
        }
        debug('showDownloadButton: FROM', url);
        var new_tip = $link.data('complete_tooltip');
        if (new_tip) {
            var original_tip = $link.attr('title');
            $link.data('tooltip', original_tip);
            $link.attr('title', new_tip);
        }
        $link.addClass('disabled').attr('tabindex', -1);
        var $button = $link.siblings(BUTTON_SELECTOR);
        $button.attr('href', url).removeClass('hidden');
    }

    /**
     * Hide the button to download the artifact.
     *
     * @param {Selector} link
     */
    function hideDownloadButton(link) {
        var $link = $(link);
        var original_tip = $link.data('tooltip');
        if (original_tip) {
            $link.attr('title', original_tip);
        }
        $link.removeData('path');
        $link.removeClass('disabled').removeAttr('tabindex');
        var $button = $link.siblings(BUTTON_SELECTOR);
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
        for (var key in STATE) {
            var state = STATE[key];
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
     * @constant {string}
     */
    var RETRY_ATTRIBUTE = 'retry';

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
        var period = value || defaultRetryPeriod($link);
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
     * @returns {number}
     */
    function defaultRetryPeriod($link) {
        var href = $link.attr('href') || '';
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
            consoleLog.apply(null, arguments);
        }
    }

});
