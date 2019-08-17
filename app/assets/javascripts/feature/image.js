// app/assets/javascripts/feature/image.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    /** @type {jQuery} */
    var $placeholders = $('*:not(.complete) > .placeholder:not(.hidden)');

    // Only perform these actions on the appropriate pages.
    if (isMissing($placeholders)) { return; }

    /**
     * Flag controlling console debug output.
     *
     * @constant {boolean}
     */
    var DEBUGGING = true;

    // ========================================================================
    // Actions
    // ========================================================================

    // noinspection JSUnresolvedFunction
    $placeholders.each(function() {
        var $image = $(this);
        var src;
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

        var func   = 'loadImage: ';
        var $image = $(image);
        var src    = source || $image.data('path') || $image.attr('src');
        var url    = urlProxyPath(src);
        var start  = Date.now();

        var err, content;
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
            debug(func, 'received', (data ? data.length : 0), 'bytes.');
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
                // Prepare the image container.
                var $container = $image.parent();
                if ($image.hasClass('placeholder')) {
                    // Add this for accessibility analyzers that don't
                    // ignore hidden images:
                    $image.attr('alt', 'Downloading...');
                    $image.addClass('hidden');
                } else {
                    $container.empty();
                }

                // Insert the new image element.
                var id  = $image.data('id')  || $container.data('id');
                var alt = $image.data('alt') || $container.data('alt');
                $('<img>')
                    .attr('src', content)
                    .attr('alt', (alt || ''))
                    .attr('id',  (id  || imageId(src)))
                    .data('turbolinks-permanent', true)
                    .appendTo($container);
                $container.addClass('complete');
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
     * Generate an element ID from a source URL.
     *
     * @param {string} url
     *
     * @returns {string}
     */
    function imageId(url) {
        var file_name = url.replace(/^.*\//, '');
        return 'img-' + escape(file_name);
    }

    /**
     * Create a placeholder image element.
     *
     * @returns {jQuery}
     */
    function imagePlaceholder() {
        return $('<img>')
            .attr('src', PLACEHOLDER_IMAGE_ASSET)
            .attr('alt', PLACEHOLDER_IMAGE_ALT)
            .data('turbolinks-track', false)
            .addClass('placeholder');
    }

    /**
     * Emit a console message if debugging.
     */
    function debug() {
        if (DEBUGGING) {
            consoleLog.apply(null, arguments);
        }
    }

});
