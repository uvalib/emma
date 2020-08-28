// app/assets/javascripts/feature/images.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    /**
     * Placeholder elements for images that are to be loaded asynchronously.
     *
     * @type {jQuery}
     */
    let $placeholders = $('*:not(.complete) > .placeholder:not(.hidden)');

    // Only perform these actions on the appropriate pages.
    if (isMissing($placeholders)) { return; }

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

    /**
     * Placeholder CSS class.
     *
     * @constant
     * @type {string}
     */
    const PLACEHOLDER_CLASS = Emma.Image.placeholder.class;

    /**
     * Placeholder alt text.
     *
     * @constant
     * @type {string}
     */
    const PLACEHOLDER_ALT = Emma.Image.placeholder.alt;

    /**
     * Placeholder image source.
     *
     * @constant
     * @type {string}
     */
    const PLACEHOLDER_SRC = Emma.Image.placeholder.asset;

    // ========================================================================
    // Actions
    // ========================================================================

    // Download all deferred images.
    $placeholders.each(function() {
        let $image = $(this);
        let src;
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
    // Functions
    // ========================================================================

    /**
     * Load an image asynchronously via the server.
     *
     * @param {Selector} image
     * @param {string}   [source]
     */
    function loadImage(image, source) {
        const func  = 'loadImage:';
        let $image  = $(image || this);
        const src   = source || $image.data('path') || $image.attr('src');
        const url   = urlProxyPath(src);
        const start = Date.now();

        /** @type {string} content */
        let content = undefined;
        let error   = '';

        $.ajax({
            url:      url,
            type:     'GET',
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
                error   = 'no data';
            } else {
                content = 'data:image/jpg;base64,' + data;
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
         * Actions after the request is completed.
         *
         * @param {XMLHttpRequest} xhr
         * @param {string}         status
         */
        function onComplete(xhr, status) {
            debug(func, 'complete', secondsSince(start), 'sec.');
            if (error) {
                consoleWarn(func, `${url}:`, error);
            } else {
                insertImage(content);
            }
        }

        /**
         * Load the deferred image into its container.
         *
         * @param {string} [data]       Default: content.
         */
        function insertImage(data) {
            let image_content = data || content;

            // Prepare the image container by hiding the placeholder (with an
            // appropriate alt tag for accessibility analyzers that don't
            // ignore hidden images).
            let $container = $image.parent();
            if ($image.hasClass(PLACEHOLDER_CLASS)) {
                $image.attr('alt', 'Downloading...'); // TODO: I18n
                $image.addClass('hidden');
            } else {
                $container.empty();
            }

            // Insert the new image element.
            const id  = $image.data('id')  || $container.data('id');
            const alt = $image.data('alt') || $container.data('alt');
            makeImage(image_content, alt)
                .attr('id', (id  || imageId(src)))
                .attr('data-turbolinks-permanent', true)
                .appendTo($container);
            $container.addClass('complete');
        }
    }

    /**
     * Request an image via the server.
     *
     * @param {string} url
     *
     * @return {string}
     */
    function urlProxyPath(url) {
        return '/api/image?url=' + encodeURIComponent(url);
    }

    /**
     * Generate an element ID from a source URL.
     *
     * @param {string} url
     *
     * @return {string}
     */
    function imageId(url) {
        const file_name = url.replace(/^.*\//, '');
        return 'img-' + escape(file_name);
    }

    /**
     * Create a placeholder image element.
     *
     * @return {jQuery}
     */
    function imagePlaceholder() {
        return makeImage(PLACEHOLDER_SRC, PLACEHOLDER_ALT)
            .addClass(PLACEHOLDER_CLASS)
            .attr('data-turbolinks-track', false);
    }

    /**
     * Create an image element.
     *
     * @param {string} src
     * @param {string} [alt]
     *
     * @return {jQuery}
     */
    function makeImage(src, alt) {
        return $(`<img alt="${alt || ''}" src="${src}">`);
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
