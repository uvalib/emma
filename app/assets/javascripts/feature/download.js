// app/assets/javascripts/feature/download.js


import { AppDebug }               from '../application/debug';
import { appSetup }               from '../application/setup';
import { Emma }                   from '../shared/assets';
import { isMissing, isPresent }   from '../shared/definitions';
import { create, scrollIntoView } from '../shared/html';
import { compact, deepFreeze }    from '../shared/objects';
import { randomizeName }          from '../shared/random';
import { SearchInProgress }       from '../shared/search-in-progress';
import { SECOND, secondsSince }   from '../shared/time';
import { urlParameters }          from '../shared/url';
import {
    cssClass,
    HIDDEN,
    selector,
    toggleHidden,
} from '../shared/css';
import {
    handleClickAndKeypress,
    handleEvent
} from '../shared/events';


const MODULE = 'Download';
const DEBUG  = true;

AppDebug.file('feature/download', MODULE, DEBUG);

appSetup(MODULE, function() {

    /**
     * Selector for links which are not currently enabled.
     *
     * @type {string}
     */
    const UNAUTHORIZED = '.sign-in-required';

    /** @type {jQuery} */
    const $download_links = $('.artifact').children('.link, .download');
    const $no_auth_links  = $download_links.filter(UNAUTHORIZED);
    const $artifact_links = $download_links.not(`.download, ${UNAUTHORIZED}`);

    // Only perform these actions on the appropriate pages.
    if (isMissing($artifact_links) && isMissing($no_auth_links)) { return }

    // ========================================================================
    // Type definitions
    // ========================================================================

    /**
     * Linkage
     *
     * @typedef {{
     *      href:   string,
     *      rel:    string,
     * }} Linkage
     */

    /**
     * MemberName
     *
     * @typedef {{
     *      firstName:  string,
     *      lastName:   string,
     *      middle?:    string,
     *      prefix?:    string,
     *      suffix?:    string,
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
     *      emailAddress?:              string,
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
     *      userAccountId:              string,
     * }} Member
     */

    /**
     * MessageProperties
     *
     * - list_type: only present with session_debug
     * - item_type: only present with session_debug
     *
     * @typedef {{
     *      total:      number,
     *      limit:      number|undefined,
     *      links:      Linkage[]|undefined,
     *      list_type?: string|null|undefined,
     *      item_type?: string|null|undefined,
     * }} MessageProperties
     */

    /**
     * MemberMessage
     *
     * @typedef {{
     *      members: {
     *          properties: MessageProperties,
     *          list:       Member[],
     *      }
     * }} MemberMessage
     */

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Frequency for re-requesting a download link.
     *
     * @readonly
     * @type {number}
     */
    const RETRY_PERIOD = 1 * SECOND;

    /**
     * Frequency for re-requesting a download link for DAISY_AUDIO.
     *
     * @readonly
     * @type {number}
     */
    const RETRY_DAISY_AUDIO = 5 * RETRY_PERIOD;

    /**
     * Retry period value which indicates the end of retrying.
     *
     * @readonly
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
     * @readonly
     * @type {StringTable}
     */
    const STATE = deepFreeze({
        FAILED:     'failed',
        REQUESTING: 'requesting',
        READY:      'complete'
    });

    /**
     * Bookshare page for adding/modifying members.
     *
     * @readonly
     * @type {string}
     */
    const BS_ACCOUNT_URL = 'https://www.bookshare.org/orgAccountMembers';

    /**
     * Properties for the elements of the member selection popup panel.
     *
     * @readonly
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
     * @readonly
     * @type {string}
     */
    const PANEL = selector(MEMBER_POPUP.panel.class);

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
     * For the data() item holding the link's retry period.
     *
     * @readonly
     * @type {string}
     */
    const RETRY_DATA = 'retry';

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Prompt for Bookshare member and download.
     *
     * @param {jQuery.Event|Event} event
     *
     * @returns {boolean}             Always *false* to end event propagation.
     */
    function getDownload(event) {
        //_debug('getDownload: event =', event);
        const $link = $(event.currentTarget || event.target);
        const url   = $link.attr('href');
        let $panel  = $link.siblings(PANEL);
        if (setLinkMember($link, getUrlMember(url))) {
            manageDownloadState($link);
        } else if (isPresent($panel)) {
            hideFailureMessage($link);
            toggleHidden($panel, false);
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
         *
         * @returns {boolean}
         */
        function onSubmit(event) {
            //_debug('onSubmit: event =', event);
            event.preventDefault();
            const members = [];
            // noinspection JSCheckFunctionSignatures
            $panel.find(':checked').each(function() {
                members.push(this.value);
                this.checked = false; // Reset for later iteration.
            });
            toggleHidden($panel, true);
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
     * @param {function(object, string=)} callback
     */
    function getMembers(callback) {
        const func  = 'getMembers';
        const url   = MEMBER_POPUP.url;
        const start = Date.now();

        _debug(`${func}: VIA`, url);

        /** @type {MemberMessage|object|undefined} */
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
         * @param {*}              data
         * @param {string}         status
         * @param {XMLHttpRequest} xhr
         */
        function onSuccess(data, status, xhr) {
            // _debug(`${func}: received data:`, data);
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
            error = `${status}: ${xhr.status} ${message}`;
        }

        /**
         * Actions after the request is completed.  Invoke the callback with
         * the member selection table unless there was an error.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         */
        function onComplete(xhr, status) {
            _debug(`${func}: completed in`, secondsSince(start), 'sec.');
            if (error) {
                console.warn(`${func}: ${url}:`, error);
                callback(null, error);
            } else {
                callback(extractMemberData(message));
            }
        }

        /**
         * Produce a mapping of member ID to member name from the message.
         *
         * @param {MemberMessage|object} data   Default: message.
         *
         * @returns {object}
         */
        function extractMemberData(data) {
            //_debug('`${func}: extractMemberData: data =', data);
            const result  = {};
            const info    = data || message;
            /** @type {Member[]} */
            const members = info?.members?.list || [];
            members.forEach(function(member) {
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
        //_debug('createMemberPopup: member_table =', member_table);

        const $panel = create(MEMBER_POPUP.panel).attr('href', '#0');

        // Start with a title.
        const id     = randomizeName(MEMBER_POPUP.name);
        const $title = create(MEMBER_POPUP.title).attr('for', id);
        $panel.attr('id', id);

        // Follow with an explanatory note.
        const $note = create(MEMBER_POPUP.note);

        // Construct the member selection group.
        const $fields = create(MEMBER_POPUP.fields);
        const $radio  = create(MEMBER_POPUP.fields.row_input).attr('name', id);
        let row       = 0;
        $.each(member_table, function(account_id, name) {
            const row_id = `${id}-row${row++}`;
            const $input = $radio.clone().attr('value', account_id);
            const $label = create(MEMBER_POPUP.fields.row_label).text(name);
            $input.attr('id',  row_id).appendTo($fields);
            $label.attr('for', row_id).appendTo($fields);
        });

        // Handle the edge case where the user has no members defined.
        if (row === 0) {
            create(MEMBER_POPUP.fields.notice).appendTo($fields);
        }

        // Construct the button tray for the bottom of the panel.
        const $tray   = create(MEMBER_POPUP.buttons);
        const $submit = create(MEMBER_POPUP.submit);
        const $cancel = create(MEMBER_POPUP.cancel);
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
        //_debug('resetMemberPopup: panel =', panel);
        const disabled = MEMBER_POPUP.submit.disabled.class;
        const $panel   = $(panel);
        const $submit  = $panel.find('[type="submit"]').addClass(disabled);
        const $fields  = $panel.find('.fields input');
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
        //_debug('manageDownloadState: link =', link);
        const $link = $(link);
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
        const func  = 'requestArtifact';
        const start = Date.now();
        const $link = $(link);

        // Update URL with Bookshare member if not already present.
        let url = $link.attr('href') || $link.data('path') || '';
        if (!getUrlMember(url)) {
            const member = getLinkMember($link);
            const append = url.includes('?') ? '&' : '?';
            url += `${append}member=${member}`;
        }

        _debug(`${func}: VIA`, url);

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
            // _debug(`${func}: received data:`, data);
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
            _debug(`${func}: completed in`, secondsSince(start), 'sec.');
            if (target) {
                $link.data('path', target);
                endRequesting($link);
            } else if (error) {
                console.warn(`${func}: ${url}:`, error);
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
            //_debug('reRequestArtifact');
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
        //_debug('beginRequesting: $link =', $link);
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
        //_debug(`endRequesting: error = "${error}"; $link =`, $link);
        hideProgressIndicator($link);
        if (error) {
            const canceled = error.match(/cancell?ed/i);
            const prefix   = canceled ? '' : Emma.Download.failure.prefix;
            showFailureMessage($link, `${prefix}${error}`);
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
     * @param {jQuery.Event|Event} event
     */
    function cancelRequest(event) {
        //_debug('cancelRequest: event =', event);
        const state = STATE.REQUESTING;
        let $link   = $(event.currentTarget || event.target);
        if (!$link.hasClass(state)) {
            let selector = '.' + state;
            let $element = $link.siblings(selector);
            if (!$element.hasClass(state)) {
                $element = $link.parents(selector);
            }
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
        //_debug('getUrlMember: url =', url);
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
        //_debug('getLinkMember: $link =', $link);
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
        //_debug(`setLinkMember: member = "${member}"; $link =`, $link);
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
        //_debug('showProgressIndicator: $link =', $link);
        const $indicator = $link.siblings(PROGRESS);
        if ($indicator.is(HIDDEN)) {
            toggleHidden($indicator, false).on('click', cancelRequest);
        }
    }

    /**
     * Stop displaying a "downloading" progress indicator.
     *
     * @param {jQuery} $link
     */
    function hideProgressIndicator($link) {
        //_debug('hideProgressIndicator: $link =', $link);
        const $indicator = $link.siblings(PROGRESS);
        toggleHidden($indicator, true).off('click', cancelRequest);
    }

    // ========================================================================
    // Functions - failure message
    // ========================================================================

    /**
     * Display a failure message for an unauthorized link.
     *
     * @param {jQuery.Event|Event} event
     */
    function showNotAuthorized(event) {
        //_debug('showNotAuthorized: event =', event);
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
        //_debug(`showFailureMessage: error = "${error}"; $link =`, $link);
        const message  = error || Emma.Download.failure.unknown;
        const $failure = $link.siblings(FAILURE);
        $failure.text(message);
        $failure.attr('title', message);
        toggleHidden($failure, false);
    }

    /**
     * Stop displaying a download failure message.
     *
     * @param {jQuery} $link
     */
    function hideFailureMessage($link) {
        //_debug('hideFailureMessage: $link =', $link);
        const $failure = $link.siblings(FAILURE);
        toggleHidden($failure, true);
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
        const func  = 'showDownloadButton';
        const $link = $(link);
        const url   = target || $link.data('path');
        if (target) {
            $link.data('path', url);
        }
        _debug(`${func}: FROM`, url);
        const new_tip = $link.attr('data-complete-tooltip');
        if (new_tip) {
            $link.attr('data-tooltip', $link.attr('title'));
            $link.attr('title',        new_tip);
        }
        $link.addClass('disabled').attr('tabindex', -1);
        const $button = $link.siblings(BUTTON);
        $button.attr('href', url);
        toggleHidden($button, false);
    }

    /**
     * Hide the button to download the artifact.
     *
     * @param {Selector} link
     */
    function hideDownloadButton(link) {
        //_debug('hideDownloadButton: link =', link);
        const $link   = $(link);
        const old_tip = $link.attr('data-tooltip');
        if (old_tip) {
            $link.attr('title', old_tip);
        }
        $link.removeData('path');
        $link.removeClass('disabled').removeAttr('tabindex');
        const $button = $link.siblings(BUTTON);
        toggleHidden($button, true);
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
        //_debug(`set: new_state = "${new_state}"; $link =`, $link);
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
        //_debug(`clear: old_state = "${old_state}"; $link =`, $link);
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
        return $link.data(RETRY_DATA);
    }

    /**
     * Set the retry period for a download link.
     *
     * @param {jQuery} $link
     * @param {number} [value]        Default: RETRY_PERIOD.
     */
    function setRetryPeriod($link, value) {
        //_debug(`setRetryPeriod: value = "${value}"; $link =`, $link);
        const period = value || defaultRetryPeriod($link);
        $link.data(RETRY_DATA, period);
    }

    /**
     * Clear the retry period for a download link.
     *
     * @param {jQuery} $link
     */
    function clearRetryPeriod($link) {
        //_debug('clearRetryPeriod: $link =', $link);
        $link.removeData(RETRY_DATA);
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

    // Display failure message if not authorized.
    handleClickAndKeypress($no_auth_links, showNotAuthorized);

    // Override download links in order to get the artifact asynchronously.
    handleClickAndKeypress($artifact_links, getDownload);

    // Clicking on the download link causes a page navigation, which is set up
    // to cause a SearchInProgress overlay to display.  This is a problem
    // because it's not really a page transition so it just causes the page to
    // be unusable.
    //
    // TODO: Determine how to restore after the download is complete.
    //
    handleClickAndKeypress($artifact_links.siblings('.button'), () => {
        SearchInProgress.suppressed = true;
    });

});
