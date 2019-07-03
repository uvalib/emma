// app/assets/javascripts/shared/fonts.js
//
//= require shared/definitions

/**
 * Load Typekit fonts, adding the script if it is not already present.
 */
(function() {
    var $head   = $('head');
    var $script = $head.find('script[src*="/use.typekit.net/"]');
    var adding  = isMissing($script);
    if (adding) {
        $script =
            $('<script>')
                .attr('src',  '//use.typekit.net/tgy5tlj.js')
                .attr('type', 'text/javascript');
    }
    $script
        .off('readystatechange', loadFonts)
        .on( 'readystatechange', loadFonts)
        .off('load', loadFonts)
        .on( 'load', loadFonts);
    if (adding) {
        $head.append($script);
    }

    function loadFonts() {
        try {
            Typekit.load();
        }
        catch(error) {
            console.warn('Could not load Typekit: ' + error.message);
        }
    }

})();
