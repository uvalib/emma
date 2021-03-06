// app/assets/javascripts/shared/fonts.js
//
//= require shared/definitions

/**
 * Load Typekit fonts, adding the script if it is not already present.
 */
(function() {

    let $head   = $('head');
    let $script = $head.find('script[src*="/use.typekit.net/"]');

    if (isMissing($script)) {
        $script =
            $('<script>')
                .attr('src',  'https://use.typekit.net/tgy5tlj.js')
                .attr('type', 'text/javascript');
        $script.appendTo($head);
    }

    handleEvent($script, 'readystatechange', loadFonts);
    handleEvent($script, 'load',             loadFonts);

    function loadFonts() {
        try {
            Typekit.load();
        }
        catch(error) {
            console.warn('Could not load Typekit:', error.message);
        }
    }

})();
