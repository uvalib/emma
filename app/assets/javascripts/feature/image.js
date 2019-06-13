// app/assets/javascripts/feature/image.js

//= require shared/assets
//= require shared/definitions

$(document).on('turbolinks:load', function() {

    /** @type {jQuery} */
    var $placeholders = $('.placeholder').not('.hidden');

    // Only perform these actions on the appropriate pages.
    if (isMissing($placeholders)) { return; }

    // ========================================================================
    // Actions
    // ========================================================================

    $placeholders.each(function() {
        var $image = $(this);
        var src;
        if (src = $image.data('path')) {
            console.log('FETCHING IMAGE data-path == ' + src);
            loadImage($image, src);
        } else if ((src = $image.attr('src')) && src.match(/^http/)) {
            console.log('REPLACING IMAGE src == ' + src);
            $image.parent().append(imagePlaceholder());
            loadImage($image, src);
        } else {
            console.log('USING IMAGE src == ' + src);
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
        $.ajax({

            url:  url,
            type: 'GET',

            /**
             * Create an <img> from the supplied data and insert in $element.
             *
             * @param {object}         data
             * @param {string}         status
             * @param {XMLHttpRequest} xhr
             */
            success: function(data, status, xhr) {
                if (isMissing(data)) {
                    console.warn(func + 'no data from ' + url);
                } else {
                    console.log(func + 'received ' + data.length);
                    var content    = 'data:image/jpg;base64,' + data;
                    var $new_image = $('<img>').attr('src', content);
                    var $container = $image.parent();
                    if ($image.hasClass('placeholder')) {
                        $image.addClass('hidden');
                        $container.append($new_image);
                    } else {
                        $container.empty().append($new_image);
                    }
                }
            },

            /**
             * Note failures on the console.
             *
             * @param {XMLHttpRequest} xhr
             * @param {string}         status
             * @param {string}         error
             */
            error: function(xhr, status, error) {
                console.warn(func + status + ': ' + error);
            },

            /**
             * Actions after the request is completed.
             *
             * @param {XMLHttpRequest} xhr
             * @param {string}         status
             */
            complete: function(xhr, status) {
                console.log(func + 'complete ' + secondsSince(start) + 'sec.');
            }
        });
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

});
