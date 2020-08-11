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
    // JSDoc type definitions
    // ========================================================================

    /**
     * Member
     *
     * @typedef {{ href: string, rel: string }} Linkage
     *
     * @typedef {{
     *       firstName: string,
     *       lastName:  string,
     *       middle:    string,
     *       prefix:    string,
     *       suffix:    string
     * }} MemberName
     *
     * @typedef {{
     *       allowAdultContent:         boolean,
     *       canDownload:               boolean,
     *       dateOfBirth:               string,
     *       emailAddress:              string,
     *       hasAgreement:              boolean,
     *       language:                  string,
     *       links:                     Linkage[],
     *       locked:                    boolean,
     *       name:                      MemberName,
     *       phoneNumber:               string,
     *       proofOfDisabilityStatus:   string,
     *       roles:                     string[],
     *       site:                      string,
     *       subscriptionStatus:        string,
     *       userAccountId              string,
     * }} Member
     *
     * @typedef {{member: Member}} MemberEntry
     *
     * @typedef {{
     *      total: number,
     *      limit: number|undefined,
     *      links: Linkage[]
     * }} MessageProperties
     *
     * @typedef {{
     *      members: {
     *          list:       MemberEntry[],
     *          properties: MessageProperties
     *      }
     * }} MemberMessage
     */

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Flag controlling console debug output.
     *
     * @constant {boolean}
     */
    var DEBUGGING = true;

    //noinspection PointlessArithmeticExpressionJS
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

    /**
     * Properties for the elements of the member selection popup panel.
     *
     * @type {{
     *  url:        string,
     *  name:       string,
     *  panel:      ElementProperties,
     *  title:      ElementProperties,
     *  note:       ElementProperties,
     *  fields:  {
     *      tag:        string|null|undefined,
     *      type:       string|null|undefined,
     *      class:      string|null|undefined,
     *      tooltip:    string|null|undefined,
     *      text:       string|null|undefined
     *      input:      ElementProperties,
     *      label:      ElementProperties,
     *  },
     *  buttons:    ElementProperties,
     *  submit:     ActionProperties,
     *  cancel:     ActionProperties
     * }}
     */
    var MEMBER_POPUP = {
        url:     '/member.json',
        name:    'member-select',
        panel: {
            tag:     'form',
            class:   'member-select popup-panel',
            tooltip: ''
        },
        title: {
            tag:     'label',
            class:   '',
            text:    'Select a member', // TODO: I18n
            tooltip: ''
        },
        note: {
            tag:     'div',
            class:   'note',
            text:    'Bookshare requires that downloads be made on behalf ' +
                     'of a member with a qualifying disability.', // TODO: I18n
            tooltip: ''
        },
        fields: {
            tag:   'div',
            class: 'fields',
            input: {
                tag:     'input',
                type:    'radio',
                class:   '',
                tooltip: ''
            },
            label: {
                tag:     'label',
                class:   '',
                tooltip: ''
            }
        },
        buttons: {
            tag:     'div',
            class:   'tray',
            tooltip: ''
        },
        submit: {
            tag:     'button',
            type:    'submit',
            class:   '',
            text:    'Submit', // TODO: I18n
            enabled: {
                class:   '',
                tooltip: ''
            },
            disabled: {
                class:   'forbidden',
                tooltip: 'Make a selection to proceed' // TODO: I18n
            }
        },
        cancel: {
            tag:     'button',
            class:   '',
            text:    'Cancel', // TODO: I18n
            tooltip: ''
        }
    };

    // ========================================================================
    // Event handlers
    // ========================================================================

    // Override download links in order to get the artifact asynchronously.
    $artifact_links.click(function(event) {
        var $link  = $(this || event.target);
        var $panel = $link.siblings('.popup-panel');
        var url    = $link.attr('href');
        var params = urlParameters(url);
        var member = params['member'] || params['forUser'];
        member = member || $link.data('member') || $link.data('forUser');
        if (isPresent(member)) {
            manageDownloadState($link);
        } else if (isPresent($panel)) {
            hideFailureMessage($link);
            $panel.removeClass('hidden');
            scrollIntoView($panel);
        } else {
            hideFailureMessage($link);
            getMembers(function(member_table) {
                var $panel = createMemberPopup(member_table);
                $panel.submit(function(event) {
                    event.preventDefault();
                    var members = [];
                    $panel.find(':checked').each(function() {
                        members.push(this.value);
                        this.checked = false; // Reset for later iteration.
                    });
                    $panel.addClass('hidden');
                    if (isPresent(members)) {
                        $link.data('member', members.join(','));
                        manageDownloadState($link);
                    } else {
                        set(STATE.FAILED, $link);
                        endRequesting($link, Emma.Download.failure.cancelled);
                    }
                });
                $panel.insertAfter($link);
                scrollIntoView($panel);
            });
        }
        return false;
    }).each(handleKeypressAsClick);

    // ========================================================================
    // Internal functions
    // ========================================================================

    /**
     * Fetch the Bookshare members associated with the current user and pass
     * them to the callback function.
     *
     * @param {function(object)} callback
     */
    function getMembers(callback) {
        var func  = 'getMembers: ';
        var url   = MEMBER_POPUP.url;
        var start = Date.now();

        debug(func, 'VIA', url);
        var err, result = {};
        $.ajax({
            url:      url,
            type:     'GET',
            dataType: 'json',
            success:  onSuccess,
            error:    onError,
            complete: onComplete
        });

        /**
         * Parse the reply to create the table of member account IDs and member
         * names.
         *
         * @param {object}         data
         * @param {string}         status
         * @param {XMLHttpRequest} xhr
         */
        function onSuccess(data, status, xhr) {
            debug(func, 'received data: |', data, '|');
            // noinspection AssignmentResultUsedJS
            if (isMissing(data)) {
                err = 'no data';
            } else if (typeof(data) !== 'object') {
                err = 'unexpected data type ' + typeof(data);
            } else {
                // The actual data may be inside '{ "response" : { ... } }'.
                var info = data.response || data;
                /** @type {MemberEntry[]} members */
                var members = info.members && info.members.list || [];
                members.forEach(function(entry) {
                    var member = entry.member;
                    var part   = member.name || {};
                    var name   = '' + part.prefix + ' ';
                    name += part.lastName + ' ';
                    name += part.suffix + ',';
                    name += part.firstName + ' ';
                    name += part.middle;
                    name = name.replace(/\s+/g, ' ');
                    name = name.replace(/\s?,\s?/g, ', ');
                    name = name.trim();
                    name = name || ('id: ' + member.userAccountId);
                    result[member.userAccountId] = name;
                });
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
         * Actions after the request is completed.  Invoke the callback with
         * the member selection table unless there was an error.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         */
        function onComplete(xhr, status) {
            debug(func, 'complete', secondsSince(start), 'sec.');
            if (err) {
                consoleWarn(func, (url + ':'), err);
            } else {
                callback(result);
            }
        }
    }

    /**
     * Create a popup for displaying a selection of Bookshare members which
     * invokes the callback with the selected member(s) when the enclosed form
     * is submitted.
     *
     * @param {object} member_table
     *
     * @return {jQuery}
     */
    function createMemberPopup(member_table) {

        var $panel = create(MEMBER_POPUP.panel).attr('href', '#0');

        // Start with a title.
        var form_id = randomizeClass(MEMBER_POPUP.name);
        var $title  = create(MEMBER_POPUP.title).attr('for', form_id);
        $panel.attr('id', form_id);

        // Follow with an explanatory note.
        var $note = create(MEMBER_POPUP.note);

        // Construct the member selection group.
        var $fields = create(MEMBER_POPUP.fields);
        var $radio  = create(MEMBER_POPUP.fields.input).attr('name', form_id);
        var row     = 0;
        $.each(member_table, function(account_id, full_name) {
            var $input = $radio.clone().attr('value', account_id);
            var $label = create(MEMBER_POPUP.fields.label).text(full_name);
            var row_id = form_id + '-row' + row.toString();
            $input.attr('id',  row_id).appendTo($fields);
            $label.attr('for', row_id).appendTo($fields);
            row += 1;
        });

        // Construct the button tray for the bottom of the panel.
        var $tray   = create(MEMBER_POPUP.buttons);
        var $submit = create(MEMBER_POPUP.submit);
        var $cancel = create(MEMBER_POPUP.cancel);
        $tray.append($submit).append($cancel);

        // Implement the cancel button.
        $cancel.click(function() {
            resetMemberPopup($panel);
            $panel.submit();
        });

        // The caller is responsible for making use of the panel.
        $title.appendTo($panel);
        $note.appendTo($panel);
        $fields.appendTo($panel);
        $tray.appendTo($panel);
        return resetMemberPopup($panel);
    }

    /**
     * Reset the state of the popup member panel form.
     *
     * @param {Selector} panel
     *
     * @return {jQuery}
     */
    function resetMemberPopup(panel) {
        var disabled = MEMBER_POPUP.submit.disabled.class;
        var $panel   = $(panel);
        var $submit  = $panel.find('[type="submit"]').addClass(disabled);
        var $fields  = $panel.find('.fields input');
        $fields.change(function() {
            if ($fields.is(':checked')) {
                $submit.removeClass(disabled);
                $submit.attr('title', MEMBER_POPUP.submit.enabled.tooltip);
            } else {
                $submit.addClass(disabled);
                $submit.attr('title', MEMBER_POPUP.submit.disabled.tooltip);
            }
        });
        $panel[0].reset();
        return $panel;
    }

    /**
     * Perform the appropriate action depending on the state of the link.
     *
     * @param {Selector} link
     */
    function manageDownloadState(link) {
        var $link = $(link);
        if ($link.hasClass(STATE.READY)) {
            endRequesting($link);
        } else if (!$link.hasClass(STATE.REQUESTING)) {
            beginRequesting($link);
            requestArtifact($link);
        }
    }

    /**
     * Asynchronously request an artifact download URL.
     *
     * @param {Selector} link
     */
    function requestArtifact(link) {

        var func   = 'requestArtifact: ';
        var $link  = $(link);
        var url    = $link.attr('href');
        var params = urlParameters(url);

        // Update URL with Bookshare member if not already present.
        if (!params['member'] && !params['forUser']) {
            var member = $link.data('member') || $link.data('forUser');
            var append = (url.indexOf('?') > 0) ? '&' : '?';
            url += append + 'member=' + member;
        }

        debug(func, 'VIA', url);
        var start = Date.now();
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
            // noinspection AssignmentResultUsedJS
            if (isMissing(data)) {
                err = 'no data';
            } else if (typeof(data) !== 'object') {
                err = 'unexpected data type ' + typeof(data);
            } else if ((delay = getRetryPeriod($link)) === NO_RETRY) {
                err = Emma.Download.failure.cancelled;
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
        endRequesting($link, Emma.Download.failure.cancelled);
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
    var PROGRESS_SELECTOR = '.' + Emma.Download.progress.class;

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
    var FAILURE_SELECTOR = '.' + Emma.Download.failure.class;

    /**
     * Display a download failure message after the download link.
     *
     * @param {jQuery} $link
     * @param {string} [error]
     */
    function showFailureMessage($link, error) {
        var content = error || '';
        if (!content.match(/cancelled/)) {
            var error_message = error || Emma.Download.failure.unknown;
            content = '' + Emma.Download.failure.prefix + error_message;
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
    var BUTTON_SELECTOR = '.' + Emma.Download.button.class;

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
     * @return {number|undefined}
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
     * @return {number}
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
