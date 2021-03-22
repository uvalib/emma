// app/assets/javascripts/feature/download.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

$(document).on('turbolinks:load', function() {

    /** @type {jQuery} */
    let $artifact_links = $('.artifact .link');

    // Only perform these actions on the appropriate pages.
    if (isMissing($artifact_links)) { return; }

    // ========================================================================
    // JSDoc type definitions
    // ========================================================================

    /**
     * Linkage
     *
     * @typedef {{
     *      href:   string,
     *      rel:    string
     * }} Linkage
     */

    /**
     * MemberName
     *
     * @typedef {{
     *      firstName:  string,
     *      lastName:   string,
     *      middle:     [string],
     *      prefix:     [string],
     *      suffix:     [string]
     * }} MemberName
     */

    /**
     * Member
     *
     * @typedef {{
     *      allowAdultContent:          boolean,
     *      canDownload:                boolean,
     *      dateOfBirth:                string,
     *      deleted:                    boolean,
     *      emailAddress:               [string],
     *      hasAgreement:               boolean,
     *      language:                   string,
     *      links:                      Linkage[],
     *      locked:                     boolean,
     *      name:                       MemberName,
     *      phoneNumber:                string,
     *      proofOfDisabilityStatus:    string,
     *      roles:                      string[],
     *      site:                       string,
     *      subscriptionStatus:         string,
     *      userAccountId               string,
     * }} Member
     */

    /**
     * MemberEntry
     *
     * @typedef {{
     *      member: Member
     * }} MemberEntry
     */

    /**
     * MessageProperties
     *
     * @typedef {{
     *      total:  number,
     *      limit:  number|undefined,
     *      links:  Linkage[]
     * }} MessageProperties
     */

    /**
     * MemberMessage
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
     * @constant
     * @type {boolean}
     */
    const DEBUGGING = true;

    // noinspection PointlessArithmeticExpressionJS
    /**
     * Frequency for re-requesting a download link.
     *
     * @constant
     * @type {number}
     */
    const RETRY_PERIOD = 1 * SECOND;

    /**
     * Frequency for re-requesting a download link for DAISY_AUDIO.
     *
     * @constant
     * @type {number}
     */
    const RETRY_DAISY_AUDIO = 5 * RETRY_PERIOD;

    /**
     * Retry period value which indicates the end of retrying.
     *
     * @constant
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
     * @constant
     * @type {{FAILED: string, REQUESTING: string, READY: string}}
     */
    const STATE = deepFreeze({
        FAILED:     'failed',
        REQUESTING: 'requesting',
        READY:      'complete'
    });

    /**
     * Bookshare page for adding/modifying members.
     *
     * @constant
     * @type {string}
     */
    const BS_ACCOUNT_URL = 'https://www.bookshare.org/orgAccountMembers';

    /**
     * Properties for the elements of the member selection popup panel.
     *
     * @constant
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
     *      label:      string|null|undefined,
     *      text:       string|null|undefined,
     *      html:       string|null|undefined,
     *      row_input:  ElementProperties,
     *      row_label:  ElementProperties,
     *      notice:     ElementProperties
     *  },
     *  buttons:    ElementProperties,
     *  submit:     ActionProperties,
     *  cancel:     ActionProperties
     * }}
     */
    const MEMBER_POPUP = deepFreeze({
        url:     '/member.json',
        name:    'member-select',
        panel: {
            tag:     'form',
            class:   cssClass('member-select', Emma.Popup.panel.class),
            tooltip: ''
        },
        title: {
            tag:     'label',
            class:   '',
            label:   'Select a member', // TODO: I18n
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
            tag:         'div',
            class:       'fields',
            row_input: {
                tag:     'input',
                type:    'radio',
                class:   '',
                tooltip: ''
            },
            row_label: {
                tag:     'label',
                class:   '',
                tooltip: ''
            },
            notice: {
                tag:     'div',
                class:   'notice',
                html:    'You must define one or more qualifying members at ' +
                         `<a href="${BS_ACCOUNT_URL}" target="_blank">` +
                             'Bookshare' +
                         '</a>' +
                         ' then ' +
                         '<a href="javascript:location.reload()">refresh</a>' +
                         ' this page.'
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
            label:   'Submit', // TODO: I18n
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
            label:   'Cancel', // TODO: I18n
            tooltip: ''
        }
    });

    /**
     * Member popup panel selector.
     *
     * @constant
     * @type {string}
     */
    const MEMBER_POPUP_SELECTOR = selector(MEMBER_POPUP.panel.class);

    /**
     * Progress indicator element selector.
     *
     * @constant
     * @type {string}
     */
    const PROGRESS_SELECTOR = selector(Emma.Download.progress.class);

    /**
     * Failure message element selector.
     *
     * @constant
     * @type {string}
     */
    const FAILURE_SELECTOR = selector(Emma.Download.failure.class);

    /**
     * Download button element selector.
     *
     * @constant
     * @type {string}
     */
    const BUTTON_SELECTOR = selector(Emma.Download.button.class);

    /**
     * Name of the data attribute holding the link's retry period.
     *
     * @constant
     * @type {string}
     */
    const RETRY_ATTRIBUTE = 'retry';

    // ========================================================================
    // Event handlers
    // ========================================================================

    // Override download links in order to get the artifact asynchronously.
    handleClickAndKeypress($artifact_links, getDownload);

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Prompt for Bookshare member and download.
     *
     * @param {jQuery.Event} event
     *
     * @returns {boolean}             Always *false* to end event propagation.
     */
    function getDownload(event) {
        let $link  = $(this || event.target);
        let $panel = $link.siblings(MEMBER_POPUP_SELECTOR);
        const url  = $link.attr('href');
        if (setLinkMember($link, getUrlMember(url))) {
            manageDownloadState($link);
        } else if (isPresent($panel)) {
            hideFailureMessage($link);
            $panel.removeClass('hidden');
            scrollIntoView($panel);
        } else {
            hideFailureMessage($link);
            getMembers(function(member_table, error) {
                if (isPresent(member_table)) {
                    $panel = createMemberPopup(member_table);
                    handleEvent($panel, 'submit', onSubmit);
                    $panel.insertAfter($link);
                    scrollIntoView($panel);
                } else if (error) {
                    endRequesting($link, error);
                } else {
                    endRequesting($link, Emma.Download.failure.unknown);
                }
            });
        }
        return false;

        /**
         * Handle form submission by associating the selection(s) with the
         * link.  If none were selected, make sure all associations are removed
         * from the link.
         *
         * NOTE: Currently on single-select due to the Bookshare API method.
         *
         * @param {jQuery.Event} event
         */
        function onSubmit(event) {
            event.preventDefault();
            let members = [];
            // noinspection JSCheckFunctionSignatures
            $panel.find(':checked').each(function() {
                members.push(this.value);
                this.checked = false; // Reset for later iteration.
            });
            $panel.addClass('hidden');
            if (setLinkMember($link, members)) {
                manageDownloadState($link);
            } else {
                endRequesting($link, Emma.Download.failure.canceled);
            }
            return false;
        }
    }

    /**
     * Fetch the Bookshare members associated with the current user and pass
     * them to the callback function.
     *
     * @param {function(object, string?)} callback
     */
    function getMembers(callback) {
        const func  = 'getMembers: ';
        const url   = MEMBER_POPUP.url;
        const start = Date.now();

        debug(func, 'VIA', url);

        /** @type {MemberMessage|object|undefined} info */
        let message;
        let error = '';

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
            // debug(func, 'received data: |', data, '|');
            if (isMissing(data)) {
                error = 'no data';
            } else if (typeof(data) !== 'object') {
                error = `unexpected data type ${typeof data}`;
            } else {
                // The actual data may be inside '{ "response" : { ... } }'.
                message = data.response || data;
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
            if (xhr.status === 401) {
                error = Emma.Download.failure.sign_in;
            } else {
                error = `${status}: ${xhr.status} ${message}`;
            }
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
            if (error) {
                consoleWarn(func, `${url}:`, error);
                callback(null, error);
            } else {
                callback(extractMemberData(message));
            }
        }

        /**
         * Produce a mapping of member ID to member name from the message.
         *
         * @param {MemberMessage|object} [data]    Default: message.
         *
         * @returns {object}
         */
        function extractMemberData(data) {
            let result    = {};
            const info    = data || message;
            const members = info.members && info.members.list || [];
            members.forEach(function(entry) {
                const member      = entry.member;
                const name        = member.name || {};
                const family_name = [name.prefix, name.lastName, name.suffix];
                const given_name  = [name.firstName, name.middle];
                const family      = compact(family_name).join(' ');
                const given       = compact(given_name).join(' ');
                const full_name   = compact([family, given]).join(', ');
                result[member.userAccountId] =
                    full_name || `id: ${member.userAccountId}`;
            });
            return result;
        }
    }

    /**
     * Create a popup for displaying a selection of Bookshare members which
     * invokes the callback with the selected member(s) when the enclosed form
     * is submitted.
     *
     * @param {object} member_table
     *
     * @returns {jQuery}
     */
    function createMemberPopup(member_table) {

        let $panel = create(MEMBER_POPUP.panel).attr('href', '#0');

        // Start with a title.
        const id   = randomizeClass(MEMBER_POPUP.name);
        let $title = create(MEMBER_POPUP.title).attr('for', id);
        $panel.attr('id', id);

        // Follow with an explanatory note.
        let $note = create(MEMBER_POPUP.note);

        // Construct the member selection group.
        let $fields = create(MEMBER_POPUP.fields);
        let $radio  = create(MEMBER_POPUP.fields.row_input).attr('name', id);
        let row     = 0;
        $.each(member_table, function(account_id, full_name) {
            // noinspection IncrementDecrementResultUsedJS
            let row_id = `${id}-row${row++}`;
            let $input = $radio.clone().attr('value', account_id);
            let $label = create(MEMBER_POPUP.fields.row_label).text(full_name);
            $input.attr('id',  row_id).appendTo($fields);
            $label.attr('for', row_id).appendTo($fields);
        });

        // Handle the edge case where the user has no members defined.
        if (row === 0) {
            create(MEMBER_POPUP.fields.notice).appendTo($fields);
        }

        // Construct the button tray for the bottom of the panel.
        let $tray   = create(MEMBER_POPUP.buttons);
        let $submit = create(MEMBER_POPUP.submit);
        let $cancel = create(MEMBER_POPUP.cancel);
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
     * @returns {jQuery}
     */
    function resetMemberPopup(panel) {
        const disabled = MEMBER_POPUP.submit.disabled.class;
        let $panel     = $(panel);
        let $submit    = $panel.find('[type="submit"]').addClass(disabled);
        let $fields    = $panel.find('.fields input');
        $fields.change(function() {
            if ($fields.is(':checked')) {
                $submit.removeClass(disabled);
                $submit.attr('title', MEMBER_POPUP.submit.enabled.tooltip);
                $submit.attr('tabindex', 0);
            } else {
                $submit.addClass(disabled);
                $submit.attr('title', MEMBER_POPUP.submit.disabled.tooltip);
                $submit.attr('tabindex', -1);
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
        let $link = $(link);
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
        const func  = 'requestArtifact: ';
        const start = Date.now();
        let $link   = $(link);
        let url     = $link.attr('href') || $link.data('path') || '';

        // Update URL with Bookshare member if not already present.
        if (!getUrlMember(url)) {
            const member = getLinkMember($link);
            const append = url.includes('?') ? '&' : '?';
            url += `${append}member=${member}`;
        }

        debug(func, 'VIA', url);

        /** @type {string} target */
        let target = undefined;
        let delay  = undefined;
        let error  = '';

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
            // debug(func, 'received data: |', data, '|');
            if (isMissing(data)) {
                error = 'no data';
            } else if (typeof(data) !== 'object') {
                error = `unexpected data type ${typeof data}`;
            } else if ((delay = getRetryPeriod($link)) === NO_RETRY) {
                error = Emma.Download.failure.canceled;
            } else {
                // The actual data may be inside '{ "response" : { ... } }'.
                const info = data.response || data;
                target = info.url;
                if (!target) {
                    if (info.error) {
                        error = `reported error: "${info.error}"`;
                    } else if (info.state !== 'SUBMITTED') {
                        error = `unexpected state: "${info.state}"`;
                    }
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
         * Actions after the request is completed.  If the target URL was made
         * available then the download button is displayed.  If there was an
         * error condition a failure message is displayed.  Otherwise, another
         * request is scheduled to be performed after a delay.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         */
        function onComplete(xhr, status) {
            debug(func, 'complete', secondsSince(start), 'sec.');
            if (target) {
                $link.data('path', target);
                endRequesting($link);
            } else if (error) {
                consoleWarn(func, `${url}:`, error);
                endRequesting($link, error);
            } else {
                setTimeout(reRequestArtifact, delay);
            }
        }

        /**
         * Poll for completion of the artifact being generated unless the
         * current browser tab is not visible.  In that case, do nothing but
         * reschedule another polling attempt.
         */
        function reRequestArtifact() {
            if (document.hidden) {
                setTimeout(reRequestArtifact, delay);
            } else {
                requestArtifact($link);
            }
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
     * @param {jQuery.Event} event
     */
    function cancelRequest(event) {
        const state = STATE.REQUESTING;
        let $link   = $(this || event.target);
        if (!$link.hasClass(state)) {
            let selector = '.' + state;
            let $element = $link.siblings(selector);
            if (!$element.hasClass(state)) {
                $element = $link.parents(selector);
            }
            // noinspection JSUnresolvedFunction
            $link = $element.first();
        }
        endRequesting($link, Emma.Download.failure.canceled);
        setRetryPeriod($link, NO_RETRY);
    }

    // ========================================================================
    // Functions - members
    // ========================================================================

    /**
     * Extract a member from URL parameters.
     *
     * @param {string} url
     *
     * @returns {string|undefined}
     */
    function getUrlMember(url) {
        const params = urlParameters(url);
        return params['member'] || params['forUser'];
    }

    /**
     * Get the member associated with the download link.
     *
     * @param {jQuery} $link
     *
     * @returns {string}
     */
    function getLinkMember($link) {
        const for_user = $link.attr('data-forUser');
        $link.removeAttr('data-forUser');
        return for_user || $link.attr('data-member') || '';
    }

    /**
     * Set the member associated with the download link.
     *
     * @param {jQuery}          $link
     * @param {string|string[]} [member]
     *
     * @returns {string}
     */
    function setLinkMember($link, member) {
        const value = Array.isArray(member) ? member.join(',') : member;
        if (value) {
            $link.attr('data-member', value);
        } else {
            $link.removeAttr('data-member');
        }
        $link.removeAttr('data-forUser');
        return value || '';
    }

    // ========================================================================
    // Functions - progress indicator
    // ========================================================================

    /**
     * Display a "downloading" progress indicator.
     *
     * @param {jQuery} $link
     */
    function showProgressIndicator($link) {
        let $indicator = $link.siblings(PROGRESS_SELECTOR);
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
        let $indicator = $link.siblings(PROGRESS_SELECTOR);
        $indicator.addClass('hidden').off('click', cancelRequest);
    }

    // ========================================================================
    // Functions - failure message
    // ========================================================================

    /**
     * Display a download failure message after the download link.
     *
     * @param {jQuery} $link
     * @param {string} [error]
     */
    function showFailureMessage($link, error) {
        let content = error || '';
        if (!content.match(/cancell?ed/i)) {
            const error_message = error || Emma.Download.failure.unknown;
            content = '' + Emma.Download.failure.prefix + error_message;
        }
        let $failure = $link.siblings(FAILURE_SELECTOR);
        $failure.attr('title', content).text(content).removeClass('hidden');
    }

    /**
     * Stop displaying a download failure message.
     *
     * @param {jQuery} $link
     */
    function hideFailureMessage($link) {
        let $failure = $link.siblings(FAILURE_SELECTOR);
        $failure.addClass('hidden');
    }

    // ========================================================================
    // Functions - download button
    // ========================================================================

    /**
     * Show the button to download the artifact.
     *
     * @param {Selector}      link
     * @param {string|jQuery} [target]
     */
    function showDownloadButton(link, target) {
        const func = 'showDownloadButton:';
        let $link  = $(link);
        const url  = target || $link.data('path');
        if (target) {
            $link.data('path', url);
        }
        debug(func, 'FROM', url);
        const new_tip = $link.data('complete_tooltip');
        if (new_tip) {
            const original_tip = $link.attr('title');
            $link.data('tooltip', original_tip);
            $link.attr('title', new_tip);
        }
        $link.addClass('disabled').attr('tabindex', -1);
        let $button = $link.siblings(BUTTON_SELECTOR);
        $button.attr('href', url).removeClass('hidden');
    }

    /**
     * Hide the button to download the artifact.
     *
     * @param {Selector} link
     */
    function hideDownloadButton(link) {
        let $link          = $(link);
        const original_tip = $link.data('tooltip');
        if (original_tip) {
            $link.attr('title', original_tip);
        }
        $link.removeData('path');
        $link.removeClass('disabled').removeAttr('tabindex');
        let $button = $link.siblings(BUTTON_SELECTOR);
        $button.addClass('hidden');
    }

    // ========================================================================
    // Functions - download link state
    // ========================================================================

    /**
     * Set the state of a download link.
     *
     * @param {string} new_state
     * @param {jQuery} $link
     */
    function set(new_state, $link) {
        $.each(STATE, function(key, state) {
            if (state === new_state) {
                $link.addClass(state);
            } else {
                clear(state, $link);
            }
        });
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
    // Functions - retry period
    // ========================================================================

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
        const period = value || defaultRetryPeriod($link);
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
        const href = $link.attr('href') || '';
        return href.match(/DAISY_AUDIO/) ? RETRY_DAISY_AUDIO : RETRY_PERIOD;
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
