// app/assets/javascripts/feature/search-in-progress.js


import { Emma }             from '../shared/assets'
import { SearchInProgress } from '../shared/search-in-progress'


$(document).on('turbolinks:load', function() {
    const no_on_page_exit = (Emma.RAILS_ENV === 'test');
    SearchInProgress.initialize(no_on_page_exit);
});
