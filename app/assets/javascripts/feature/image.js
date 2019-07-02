// app/assets/javascripts/feature/image.js

//= require shared/assets
//= require shared/definitions

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    /** @type {jQuery} */
    const $placeholders = $('.placeholder').not('.hidden');

    // Only perform these actions on the appropriate pages.
    if (isMissing($placeholders)) { return; }

    /**
     * Flag controlling console debug output.
     *
     * @type {boolean}
     */
    const DEBUGGING = true;

    // ========================================================================
    // Actions
    // ========================================================================

    //noinspection JSUnresolvedFunction
    $placeholders.each(function() {
        const $image = $(this);
        let   src;
        // noinspection JSAssignmentUsedAsCondition, AssignmentResultUsedJS
        if (src = $image.data('path')) {
            debug('FETCHING IMAGE data-path ==', src);
            loadImage($image, src);
        } else if ((src = $image.attr('src')) && src.match(/^http/)) {
            debug('REPLACING IMAGE src ==', src);
            $image.parent().append(imagePlaceholder());
            loadImage($image, src);
        } else {
            debug('USING IMAGE src ==', src);
        }
    });

    // ========================================================================
    // Internal functions
    // ========================================================================

    /**
     * Load an image asynchronously via the server.
     *
     * @param {Selector} image
     * @param {string}   [source]
     */
    function loadImage(image, source) {

        const func   = 'loadImage: ';
        const $image = $(image);
        const src    = source || $image.data('path') || $image.attr('src');
        const url    = urlProxyPath(src);
        const start  = Date.now();

        let err, content;
        $.ajax({
            url:  url,
            type: 'GET',
            success:  onSuccess,
            error:    onError,
            complete: onComplete
        });

        /**
         * Create an <img> from the supplied data and insert in $element.
         *
         * @param {object}         data
         * @param {string}         status
         * @param {XMLHttpRequest} xhr
         */
        function onSuccess(data, status, xhr) {
            debug(func, 'received', data.length, 'bytes.');
            if (isMissing(data)) {
                err = 'no data';
            } else {
                content = 'data:image/jpg;base64,' + data;
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
         * Actions after the request is completed.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         */
        function onComplete(xhr, status) {
            if (err) {
                consoleWarn(func, (url + ':'), err);
            } else {
                const $new_image = $('<img>').attr('src', content);
                const $container = $image.parent();
                if ($image.hasClass('placeholder')) {
                    // Add this for accessibility analyzers that don't
                    // ignore hidden images:
                    $image.attr('alt', 'Downloading...');
                    $image.addClass('hidden');
                    $container.append($new_image);
                } else {
                    $container.empty().append($new_image);
                }
            }
            debug(func, 'complete', secondsSince(start), 'sec.');
        }
    }

    /**
     * Request an image via the server.
     *
     * @param {string} url
     *
     * @returns {string}
     */
    function urlProxyPath(url) {
        return '/api/image?url=' + encodeURIComponent(url);
    }

    /**
     * Create a placeholder image element.
     *
     * @return {jQuery}
     */
    function imagePlaceholder() {
        return $('<img>')
            .addClass('placeholder')
            .data('turbolinks-track', false)
            .attr('src', LOADING_IMAGE);
    }

    /**
     * Emit a console message if debugging.
     */
    function debug() {
        if (DEBUGGING) {
            consoleLog(arguments);
        }
    }

});
