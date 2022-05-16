// app/assets/javascripts/tool/bibliographic-lookup.js
//
// Bibliographic Lookup


import { Api }        from '../shared/api'
import { notEmpty }   from '../shared/definitions'
import { maxSize }    from '../shared/objects'
import { asDateTime } from '../shared/time'
import {
    handleClickAndKeypress,
    handleEvent,
    onPageExit
} from '../shared/events'


// ============================================================================
// Functions
// ============================================================================

/**
 * Setup a page with interactive bibliographic lookup.
 *
 * @param {Selector} [root]
 */
export async function setup(root) {

    let channel    = await import('../channels/lookup_channel');

    let $root      = root ? $(root) : $('body');
    let $prompt    = $root.find('.lookup-prompt');
    let $input     = $prompt.find('[type="text"]');
    let $submit    = $prompt.find('[type="submit"]');
    let $separator = $prompt.find('[type="radio"]');

    let $result    = $root.find('.item-results');
    let $error     = $root.find('.item-errors');
    let $diag      = $root.find('.item-diagnostics');

    /**
     * SEPARATORS
     *
     * * space: Space, tab, and <strong>|</strong> (pipe)
     * * pipe:  Only <strong>|</strong> (pipe)
     *
     * @type {{[k: string]: string[]}}
     */
    const SEPARATORS = {
        space: ['\\s', '|'],
        pipe:  ['|']
    };

    const DEFAULT_SEPARATOR = 'pipe';

    // ========================================================================
    // Actions
    // ========================================================================

    channel.setCallback(updateResults);
    channel.setErrorCallback(updateErrors);
    channel.setDiagnosticCallback(updateDiagnostics);

    onPageExit((() => channel.disconnect()), true);

    [$result, $error, $diag].forEach(function(item) {
        let $item = $(item);
        if (!$item.attr('spellcheck')) {
            $item.attr('spellcheck', 'false');
        }
    });

    handleEvent($input, 'keyup', ev => (ev.key === 'Enter') && submit(ev));
    handleClickAndKeypress($submit, ev => submit(ev));

    // ========================================================================
    // Functions
    // ========================================================================

    /**
     * Submit the query terms as a lookup request.
     *
     * @param {Event|jQuery.Event} [_event]     Ignored.
     *
     * @returns {boolean}
     */
    function submit(_event) {
        $result.text('');
        $error.text('');
        const sep = $separator.filter(':checked').val() || DEFAULT_SEPARATOR;
        return channel.request($input.val(), SEPARATORS[sep]);
    }

    /**
     * Update the main display element.
     *
     * @param {object} data
     */
    function updateResults(data) {
        const url = data['data_url'];
        if (url) {
            fetchData(url, function(result) {
                // NOTE: Keeping this allows the fetch event to be documented.
                // delete data['data_url'];
                const new_data = $.extend({}, data, { data: result });
                update($result, new_data);
            });
        } else {
            update($result, data);
        }
    }

    /**
     * Get data that was replaced by a URL reference because it was too large.
     *
     * @param {string}       url
     * @param {XmitCallback} callback
     */
    function fetchData(url, callback) {
        new Api(url, { callback: callback }).get();
    }

    /**
     * Update the error log element.
     *
     * @param {object} data
     */
    function updateErrors(data) {
        update($error, data);
    }

    /**
     * Update the diagnostics display element.
     *
     * @param {object} data
     */
    function updateDiagnostics(data) {
        update($diag, data, '');
    }

    /**
     * Update the contents of a display element.
     *
     * @param {jQuery} $element
     * @param {object} data
     * @param {string} gap
     */
    function update($element, data, gap = "\n") {
        let added = formatData(data);
        let text  = $element.text()?.trimEnd();
        if (text) {
            text = text.concat("\n", gap, added);
        } else {
            text = added;
        }
        $element.text(text);
    }

    const DEF_INDENT     = 2;
    const DEF_INLINE_MAX = 80;

    /**
     * Render a data object as a sequence of lines.
     *
     * @param {object} data
     * @param {number} indent         Indentation of nested object.
     *
     * @returns {string}
     */
    function formatData(data, indent = DEF_INDENT) {
        // noinspection RegExpRedundantEscape
        return JSON.stringify(alignKeys(data), stringifyReplacer, indent)
            .replace(/\\"/g, '"')
            .replace(/"(\(\w+\))"/g, '$1')
            .replace(/"(\{.+\})"/gm, '$1')
            .replace(/"(\[.+\])"/gm, '$1')
            .replace(/^( *)"(\w+)(\s*)":/gm,  '$1$2:$3')
            .replace(/^( *)"(\S+?)(\s+)":/gm, '$1"$2":');
    }

    /**
     * Recursively regenerate an item so that its object keys are replaced with
     * names appended with zero or more spaces in order to make each key the
     * same length.
     *
     * @param {object|array|*} item
     *
     * @returns {object|array|*}
     */
    function alignKeys(item) {
        if (typeof item !== 'object') {
            return item;
        } else if (Array.isArray(item)) {
            return item.map(element => alignKeys(element));
        } else {
            const max_width = maxSize(Object.keys(item));
            let result = {};
            $.each(item, function(k, v) {
                const space = Math.max(0, (max_width - k.length));
                const key   = '' + k + ' '.repeat(space);
                result[key] = alignKeys(v);
            });
            return result;
        }
    }

    /**
     * Replacer function for `JSON.stringify`.
     *
     * @param {*} _this
     * @param {*} item
     *
     * @returns {string|*}
     */
    function stringifyReplacer(_this, item) {
        const type = typeof(item);
        if (type === 'undefined')      { return '(undefined)'; }
        else if (item === null)        { return '(null)'; }
        else if (item instanceof Date) { return asDateTime(item); }
        else if (type === 'object')    { return possiblyInlined(item); }
        return item;
    }

    /**
     * Render a data object as a sequence of lines.
     *
     * @param {object|*} value
     * @param {number}   threshold    Threshold for rendering a nested object
     *                                  on a single line.
     *
     * @returns {string|*}
     */
    function possiblyInlined(value, threshold = DEF_INLINE_MAX) {
        if (notEmpty(value)) {
            const json = JSON.stringify(value);
            const size = json.replace(/\\/g, '').length;
            if (size <= threshold) {
                return json;
            }
        }
        return value;
    }

}
