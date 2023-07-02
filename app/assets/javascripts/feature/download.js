// app/assets/javascripts/feature/download.js
//
// A small portion of this module involves displaying the inline message that
// indicates sign-in is required on download links in an anonymous session.
// The rest involves the UI for downloading Bookshare artifacts via the
// Bookshare API (which is no longer supported).


import { AppDebug }               from '../application/debug';
import { appSetup }               from '../application/setup';
import { handleClickAndKeypress } from '../shared/accessibility';
import { Emma }                   from '../shared/assets';
import { isMissing, isPresent }   from '../shared/definitions';
import { handleEvent }            from '../shared/events';
import { create, scrollIntoView } from '../shared/html';
import { compact, deepFreeze }    from '../shared/objects';
import { randomizeName }          from '../shared/random';
import { SearchInProgress }       from '../shared/search-in-progress';
import { SECOND, secondsSince }   from '../shared/time';
import { urlParameters }          from '../shared/url';
import {
    cssClassList,
    isHidden,
    selector,
    toggleHidden,
} from '../shared/css';


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

    /**
     * Console output functions for this module.
     */
    const OUT = AppDebug.consoleLogging(MODULE, DEBUG);

    // ========================================================================
    // Type definitions
    // ========================================================================

    /**
     * @typedef {object} Linkage
     *
     * @property {string}       href
     * @property {string}       rel
     */

    /**
     * @typedef {object} MemberName
     *
     * Bookshare organization member name parts.
     *
     * @property {string}       firstName
     * @property {string}       lastName
     * @property {string}       [middle]
     * @property {string}       [prefix]
     * @property {string}       [suffix]
     */

    /**
     * @typedef {object} Member
     *
     * Bookshare organization member information.
     *
     * @property {boolean}      allowAdultContent
     * @property {boolean}      canDownload
     * @property {string}       dateOfBirth
     * @property {boolean}      boolean
     * @property {string}       [emailAddress]
     * @property {boolean}      hasAgreement
     * @property {string}       language
     * @property {Linkage[]}    links
     * @property {boolean}      locked
     * @property {MemberName}   name
     * @property {string}       phoneNumber
     * @property {string}       proofOfDisabilityStatus
     * @property {string[]}     roles
     * @property {string}       site
     * @property {string}       subscriptionStatus
     * @property {string}       userAccountId
     */

    /**
     * @typedef {object} MessageProperties
     *
     * @property {number}       total
     * @property {number}       [limit]
     * @property {Linkage[]}    [links]
     * @property {string}       [list_type]     Only present with session_debug
     * @property {string}       [item_type]     Only present with session_debug
     */

    /**
     * @typedef {object} MemberMessageTable
     *
     * @property {MessageProperties} properties
     * @property {Member[]}          list
     */

    /**
     * @typedef {object} MemberMessage
     *
     * @property {MemberMessageTable} members
     */

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Frequency for re-requesting a download link from the Bookshare API.
     *
     * @readonly
     * @type {number}
     */
    const BS_RETRY_PERIOD = 1 * SECOND;

    /**
     * Frequency for re-requesting a download link for DAISY_AUDIO.
     *
     * @readonly
     * @type {number}
     */
    const BS_RETRY_DAISY_AUDIO = 5 * BS_RETRY_PERIOD;

    /**
     * Retry period value which indicates the end of retrying.
     *
     * @readonly
     * @type {number}
     */
    const BS_NO_RETRY = -1;

    /**
     * Bookshare API download link state.  Each key represents a state and each
     * value is the CSS class indicating that state on the link element.
     *
     * - FAILED:     The request to generate an artifact failed.
     * - REQUESTING: The request to generate an artifact is in progress.
     * - READY:      A direct link to the generated artifact is available.
     *
     * @readonly
     * @type {StringTable}
     */
    const BS_DOWNLOAD_STATE = deepFreeze({
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
     * Properties for the elements of the Bookshare member selection popup
     * panel.
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
    const BS_MEMBER_POPUP = deepFreeze({
        url:     '/member.json', // NOTE: This endpoint no longer exists
        name:    'member-select',
        panel: {
            tag:     'form',
            class:   cssClassList('member-select', Emma.Popup.panel.class),
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
    const BS_POPUP_PANEL = selector(BS_MEMBER_POPUP.panel.class);

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
     * The data() item holding the Bookshare API download link retry period.
     *
     * @readonly
     * @type {string}
     */
    const BS_RETRY_DATA = 'retry';

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Prompt for Bookshare member and download.
     *
     * @param {jQuery.Event|Event} event
     *
     * @returns {boolean}            Always **false** to end event propagation.
     */
    function getBsDownload(event) {
        //OUT.debug('getBsDownload: event =', event);
        const $link = $(event.currentTarget || event.target);
        const url   = $link.attr('href');
        let $panel  = $link.siblings(BS_POPUP_PANEL);
        if (setLinkBsMember($link, getUrlBsMember(url))) {
            manageBsDownloadState($link);
        } else if (isPresent($panel)) {
            hideFailureMessage($link);
            toggleHidden($panel, false);
            scrollIntoView($panel);
        } else {
            hideFailureMessage($link);
            getBsMembers((member_table, error) => {
                if (isPresent(member_table)) {
                    $panel = createBsMemberPopup(member_table);
                    handleEvent($panel, 'submit', onSubmit);
                    $panel.insertAfter($link);
                    scrollIntoView($panel);
                } else if (error) {
                    endBsRequesting($link, error);
                } else {
                    endBsRequesting($link, Emma.Download.failure.unknown);
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
         * @param {jQuery.Event|Event} event
         *
         * @returns {boolean}
         */
        function onSubmit(event) {
            //OUT.debug('onSubmit: event =', event);
            event.preventDefault();
            // noinspection JSCheckFunctionSignatures
            const $checked = $panel.find(':checked');
            const members  = $checked.map((_, cb) => cb.value);
            toggleHidden($panel, true);
            if (setLinkBsMember($link, members)) {
                manageBsDownloadState($link);
            } else {
                endBsRequesting($link, Emma.Download.failure.canceled);
            }
            // Reset for later iteration.
            $checked.each((_, cb) => { cb.checked = false });
            return false;
        }
    }

    /**
     * Fetch the Bookshare members associated with the current user and pass
     * them to the callback function.
     *
     * @param {function(object, string=)} callback
     */
    function getBsMembers(callback) {
        const func  = 'getBsMembers';
        const url   = BS_MEMBER_POPUP.url;
        const start = Date.now();

        OUT.debug(`${func}: VIA`, url);

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
         * @param {string}         _status
         * @param {XMLHttpRequest} _xhr
         */
        function onSuccess(data, _status, _xhr) {
            //OUT.debug(`${func}: received data:`, data);
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
         * @param {XMLHttpRequest} _xhr
         * @param {string}         _status
         */
        function onComplete(_xhr, _status) {
            OUT.debug(`${func}: completed in`, secondsSince(start), 'sec.');
            if (error) {
                OUT.warn(`${func}: ${url}:`, error);
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
            //OUT.debug('`${func}: extractMemberData: data =', data);
            const result  = {};
            const info    = data || message;
            /** @type {Member[]} */
            const members = info?.members?.list || [];
            members.forEach(member => {
                const acct_id     = member.userAccountId;
                const name        = member.name || {};
                const family_name = [name.prefix, name.lastName, name.suffix];
                const given_name  = [name.firstName, name.middle];
                const family      = compact(family_name).join(' ');
                const given       = compact(given_name).join(' ');
                const full_name   = compact([family, given]).join(', ');
                result[acct_id]   = full_name || `id: ${acct_id}`;
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
    function createBsMemberPopup(member_table) {
        //OUT.debug('createBsMemberPopup: member_table =', member_table);

        const $panel = create(BS_MEMBER_POPUP.panel).attr('href', '#0');

        // Start with a title.
        const id     = randomizeName(BS_MEMBER_POPUP.name);
        const $title = create(BS_MEMBER_POPUP.title).attr('for', id);
        $panel.attr('id', id);

        // Follow with an explanatory note.
        const $note = create(BS_MEMBER_POPUP.note);

        // Construct the member selection group.
        const $fields = create(BS_MEMBER_POPUP.fields);
        const $radio  = create(BS_MEMBER_POPUP.fields.row_input).attr('name', id);
        let row       = 0;
        for (const [account_id, name] of Object.entries(member_table)) {
            const row_id = `${id}-row${row++}`;
            const $input = $radio.clone().attr('value', account_id);
            const $label = create(BS_MEMBER_POPUP.fields.row_label).text(name);
            $input.attr('id',  row_id).appendTo($fields);
            $label.attr('for', row_id).appendTo($fields);
        }

        // Handle the edge case where the user has no members defined.
        if (row === 0) {
            create(BS_MEMBER_POPUP.fields.notice).appendTo($fields);
        }

        // Construct the button tray for the bottom of the panel.
        const $tray   = create(BS_MEMBER_POPUP.buttons);
        const $submit = create(BS_MEMBER_POPUP.submit);
        const $cancel = create(BS_MEMBER_POPUP.cancel);
        $tray.append($submit).append($cancel);

        // Implement the cancel button.
        $cancel.click(function() {
            resetBsMemberPopup($panel);
            $panel.submit();
        });

        // The caller is responsible for making use of the panel.
        $title.appendTo($panel);
        $note.appendTo($panel);
        $fields.appendTo($panel);
        $tray.appendTo($panel);
        return resetBsMemberPopup($panel);
    }

    /**
     * Reset the state of the popup member panel form.
     *
     * @param {Selector} panel
     *
     * @returns {jQuery}
     */
    function resetBsMemberPopup(panel) {
        //OUT.debug('resetBsMemberPopup: panel =', panel);
        const disabled = BS_MEMBER_POPUP.submit.disabled.class;
        const $panel   = $(panel);
        const $submit  = $panel.find('[type="submit"]').addClass(disabled);
        const $fields  = $panel.find('.fields input');
        $fields.change(function() {
            if ($fields.is(':checked')) {
                $submit.removeClass(disabled);
                $submit.attr('title', BS_MEMBER_POPUP.submit.enabled.tooltip);
                $submit.attr('tabindex', 0);
            } else {
                $submit.addClass(disabled);
                $submit.attr('title', BS_MEMBER_POPUP.submit.disabled.tooltip);
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
    function manageBsDownloadState(link) {
        //OUT.debug('manageBsDownloadState: link =', link);
        const $link = $(link);
        if ($link.hasClass(BS_DOWNLOAD_STATE.READY)) {
            endBsRequesting($link);
        } else if (!$link.hasClass(BS_DOWNLOAD_STATE.REQUESTING)) {
            beginBsRequesting($link);
            requestBsArtifact($link);
        }
    }

    /**
     * Asynchronously request a Bookshare "artifact" download URL.
     *
     * @param {Selector} link
     */
    function requestBsArtifact(link) {
        const func  = 'requestBsArtifact';
        const start = Date.now();
        const $link = $(link);

        // Update URL with Bookshare member if not already present.
        let url = $link.attr('href') || $link.data('path') || '';
        if (!getUrlBsMember(url)) {
            const member = getLinkBsMember($link);
            const append = url.includes('?') ? '&' : '?';
            url += `${append}member=${member}`;
        }

        OUT.debug(`${func}: VIA`, url);

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
         * specify a state of "SUBMITTED".
         *
         * @param {object}         data
         * @param {string}         _status
         * @param {XMLHttpRequest} _xhr
         */
        function onSuccess(data, _status, _xhr) {
            //OUT.debug(`${func}: received data:`, data);
            if (isMissing(data)) {
                error = 'no data';
            } else if (typeof(data) !== 'object') {
                error = `unexpected data type ${typeof data}`;
            } else if ((delay = getBsRetryPeriod($link)) === BS_NO_RETRY) {
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
         * @param {XMLHttpRequest} _xhr
         * @param {string}         _status
         */
        function onComplete(_xhr, _status) {
            OUT.debug(`${func}: completed in`, secondsSince(start), 'sec.');
            if (target) {
                $link.data('path', target);
                endBsRequesting($link);
            } else if (error) {
                OUT.warn(`${func}: ${url}:`, error);
                endBsRequesting($link, error);
            } else {
                setTimeout(reRequestBsArtifact, delay);
            }
        }

        /**
         * Poll for completion of the artifact being generated unless the
         * current browser tab is not visible.  In that case, do nothing but
         * reschedule another polling attempt.
         */
        function reRequestBsArtifact() {
            //OUT.debug('reRequestBsArtifact');
            if (document.hidden) {
                setTimeout(reRequestBsArtifact, delay);
            } else {
                requestBsArtifact($link);
            }
        }
    }

    /**
     * Update state and display to indicate that an artifact download URL
     * request is in progress.
     *
     * @param {jQuery} $link
     */
    function beginBsRequesting($link) {
        //OUT.debug('beginBsRequesting: $link =', $link);
        showBsProgressIndicator($link);
        hideFailureMessage($link);
        hideBsDownloadButton($link);
        set(BS_DOWNLOAD_STATE.REQUESTING, $link);
        setBsRetryPeriod($link);
    }

    /**
     * Update state and display to indicate that an artifact download URL
     * request is no longer in progress.
     *
     * @param {jQuery} $link
     * @param {string} [error]
     */
    function endBsRequesting($link, error) {
        //OUT.debug(`endBsRequesting: error = "${error}"; $link =`, $link);
        hideBsProgressIndicator($link);
        if (error) {
            const canceled = error.match(/cancell?ed/i);
            const prefix   = canceled ? '' : Emma.Download.failure.prefix;
            showFailureMessage($link, `${prefix}${error}`);
            hideBsDownloadButton($link);
            set(BS_DOWNLOAD_STATE.FAILED, $link);
        } else {
            hideFailureMessage($link);
            showBsDownloadButton($link);
            set(BS_DOWNLOAD_STATE.READY, $link);
        }
        clearBsRetryPeriod($link);
    }

    /**
     * Stop polling with "download" requests.
     *
     * @param {jQuery.Event|Event} event
     */
    function cancelBsRequest(event) {
        //OUT.debug('cancelBsRequest: event =', event);
        const state = BS_DOWNLOAD_STATE.REQUESTING;
        const req   = selector(state);
        let $link   = $(event.currentTarget || event.target);
        if (!$link.is(req)) {
            $link = $link.siblings(req).first();
        }
        if (!$link.is(req)) {
            $link = $link.parents(req).first();
        }
        endBsRequesting($link, Emma.Download.failure.canceled);
        setBsRetryPeriod($link, BS_NO_RETRY);
    }

    // ========================================================================
    // Functions - members
    // ========================================================================

    /**
     * Extract a Bookshare member from URL parameters.
     *
     * @param {string} url
     *
     * @returns {string|undefined}
     */
    function getUrlBsMember(url) {
        //OUT.debug('getUrlBsMember: url =', url);
        const params = urlParameters(url);
        return params['member'] || params['forUser'];
    }

    /**
     * Get the member associated with the Bookshare API download link.
     *
     * @param {jQuery} $link
     *
     * @returns {string}
     */
    function getLinkBsMember($link) {
        //OUT.debug('getLinkBsMember: $link =', $link);
        const for_user = $link.attr('data-forUser');
        $link.removeAttr('data-forUser');
        return for_user || $link.attr('data-member') || '';
    }

    /**
     * Set the member associated with the Bookshare API download link.
     *
     * @param {jQuery}          $link
     * @param {string|string[]} [member]
     *
     * @returns {string}
     */
    function setLinkBsMember($link, member) {
        //OUT.debug(`setLinkBsMember: member = "${member}"; $link =`, $link);
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
    function showBsProgressIndicator($link) {
        //OUT.debug('showBsProgressIndicator: $link =', $link);
        const $indicator = $link.siblings(PROGRESS);
        if (isHidden($indicator)) {
            toggleHidden($indicator, false).on('click', cancelBsRequest);
        }
    }

    /**
     * Stop displaying a "downloading" progress indicator.
     *
     * @param {jQuery} $link
     */
    function hideBsProgressIndicator($link) {
        //OUT.debug('hideBsProgressIndicator: $link =', $link);
        const $indicator = $link.siblings(PROGRESS);
        toggleHidden($indicator, true).off('click', cancelBsRequest);
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
        //OUT.debug('showNotAuthorized: event =', event);
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
        $failure.attr('title', message);
        toggleHidden($failure, false);
    }

    /**
     * Stop displaying a download failure message.
     *
     * @param {jQuery} $link
     */
    function hideFailureMessage($link) {
        //OUT.debug('hideFailureMessage: $link =', $link);
        const $failure = $link.siblings(FAILURE);
        toggleHidden($failure, true);
    }

    // ========================================================================
    // Functions - download button
    // ========================================================================

    /**
     * Show the button to download the Bookshare artifact.
     *
     * @param {Selector}      link
     * @param {string|jQuery} [target]
     */
    function showBsDownloadButton(link, target) {
        const func  = 'showBsDownloadButton';
        const $link = $(link);
        const url   = target || $link.data('path');
        if (target) {
            $link.data('path', url);
        }
        OUT.debug(`${func}: FROM`, url);
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
     * Hide the button to download the Bookshare artifact.
     *
     * @param {Selector} link
     */
    function hideBsDownloadButton(link) {
        //OUT.debug('hideBsDownloadButton: link =', link);
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
        //OUT.debug(`set: new_state = "${new_state}"; $link =`, $link);
        for (const [_key, state] of Object.entries(BS_DOWNLOAD_STATE)) {
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
        //OUT.debug(`clear: old_state = "${old_state}"; $link =`, $link);
        $link.removeClass(old_state);
    }

    // ========================================================================
    // Functions - retry period
    // ========================================================================

    /**
     * Get the retry period for a Bookshare API download link.
     *
     * @param {jQuery} $link
     *
     * @returns {number|undefined}
     */
    function getBsRetryPeriod($link) {
        return $link.data(BS_RETRY_DATA);
    }

    /**
     * Set the retry period for a Bookshare API download link.
     *
     * @param {jQuery} $link
     * @param {number} [value]        Default: BS_RETRY_PERIOD.
     */
    function setBsRetryPeriod($link, value) {
        //OUT.debug(`setBsRetryPeriod: value = "${value}"; $link =`, $link);
        const period = value || defaultBsRetryPeriod($link);
        $link.data(BS_RETRY_DATA, period);
    }

    /**
     * Clear the retry period for a Bookshare API download link.
     *
     * @param {jQuery} $link
     */
    function clearBsRetryPeriod($link) {
        //OUT.debug('clearBsRetryPeriod: $link =', $link);
        $link.removeData(BS_RETRY_DATA);
    }

    /**
     * Determine the retry period for this download link.
     *
     * @param {jQuery} $link
     *
     * @returns {number}
     */
    function defaultBsRetryPeriod($link) {
        const href  = $link.attr('href') || '';
        const audio = !!href.match(/DAISY_AUDIO/);
        return audio ? BS_RETRY_DAISY_AUDIO : BS_RETRY_PERIOD;
    }

    // ========================================================================
    // Event handlers
    // ========================================================================

    // Display failure message if not authorized.
    handleClickAndKeypress($no_auth_links, showNotAuthorized);

    // Override download links in order to get the artifact asynchronously.
    handleClickAndKeypress($artifact_links, getBsDownload);

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
