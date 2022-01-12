// app/assets/javascripts/vendor/rails.js
//
// Load Rails UJS.


import Rails from '@rails/ujs'
export { Rails }


if (!window._rails_loaded) {
    Rails.start();
}
