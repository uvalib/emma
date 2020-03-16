// app/assets/javascripts/feature/file-upload.js

//= require shared/assets
//= require shared/definitions
//= require shared/logging
//= require feature/flash
//x require ../../../../node_modules/uppy/bundle

// noinspection FunctionWithMultipleReturnPointsJS
$(document).on('turbolinks:load', function() {

    /**
     * CSS class for eligible form elements.
     *
     * @constant {string}
     */
    var FORM_CLASS = 'file-upload-form';

    /**
     * File upload forms on the page.
     *
     * NOTE: There is no current scenario where there should be more than one
     * of these on a given page, despite the fact that the logic (mostly)
     * supports the concept that there could be an arbitrary number of them.
     * (That scenario has not been tested.)
     *
     * @constant {jQuery}
     */
    var $file_upload_form = $('.' + FORM_CLASS);

    // Only perform these actions on the appropriate pages.
    if (isMissing($file_upload_form)) { return; }

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Flag controlling console debug output.
     *
     * @constant {boolean}
     */
    var DEBUGGING = true;

    /**
     * Uppy plugin selection plus other optional settings.
     *
     * replace_input:   Hide the <input type="file"> present in the container.
     * upload_to_aws:   Cloud upload enabled.
     * progress_bar:    Minimal upload progress bar.
     * status_bar:      Heftier progress and control bar.
     * popup_messages:  Popup event/status messages.
     * dashboard:       Uppy dashboard.
     * drag_and_drop:   Drag-and-drop file selection enabled.
     * image_preview:   Image preview thumbnail.
     * flash_messages   Display flash messages.
     * flash_errors     Display flash errors.
     * debugging:       Turn on Uppy debugging.
     *
     * @constant {{
     *      replace_input:  boolean,
     *      upload_to_aws:  boolean,
     *      progress_bar:   boolean,
     *      status_bar:     boolean,
     *      popup_messages: boolean,
     *      dashboard:      boolean,
     *      drag_and_drop:  boolean,
     *      image_preview:  boolean,
     *      flash_messages: boolean,
     *      flash_errors:   boolean,
     *      debugging:      boolean
     * }}
     */
    var FEATURES = {
        replace_input:  true,
        upload_to_aws:  false,
        popup_messages: true,
        progress_bar:   true,
        status_bar:     false,
        dashboard:      false,
        drag_and_drop:  false,
        image_preview:  false,
        flash_messages: true,
        flash_errors:   true,
        debugging:      DEBUGGING
    };

    /**
     * How long to display transient messages.
     *
     * @constant {number}
     */
    var MESSAGE_DURATION = 3 * SECONDS;

    /**
     * Selector for Uppy drag-and-drop target.
     *
     * @constant {string}
     */
    var DRAG_AND_DROP_SELECTOR = '.' + Emma.Upload.css.drag_target;

    /**
     * Selector for thumbnail display of the selected file.
     *
     * @constant {string}
     */
    var PREVIEW_SELECTOR = '.' + Emma.Upload.css.preview;

    /**
     * Selectors for input fields.
     *
     * @type {string[]}
     */
    var FORM_FIELD_TYPES = [
        'select',
        'textarea',
        'input[type="text"]',
        'input[type="checkbox"]'
    ];

    /**
     * Selector for input fields.
     *
     * @type {string}
     */
    var FORM_FIELD_SELECTOR = FORM_FIELD_TYPES.join(', ');

    // ========================================================================
    // Actions
    // ========================================================================

    // Setup Uppy any <input type="file"> elements (unless this page is being
    // reached via browser history).
    $file_upload_form.each(function() {
        var $form = $(this);
        if (!isUppyInitialized($form)) {
            initializeUppy($form[0]);
            initializeForm($form);
        }
    });

    // ========================================================================
    // Functions - Initialization
    // ========================================================================

    /**
     * Initialize Uppy file uploader.
     *
     * @param {Selector} [file_upload_form]     Default: *this*.
     */
    function initializeUppy(file_upload_form) {

        var form       = file_upload_form || this;
        var $form      = $(form);
        var $container = $form.parent();
        var feature    = $.extend({}, FEATURES);

        // Get targets for these features; disable the feature if its target is
        // not present.
        if (feature.drag_and_drop) {
            feature.drag_and_drop = $container.find(DRAG_AND_DROP_SELECTOR)[0];
        }
        if (feature.image_preview) {
            feature.image_preview = $container.find(PREVIEW_SELECTOR)[0];
        }

        // === Initialization ===

        var uppy = buildUppy(form, feature);

        // Events for these features are also applicable to Uppy.Dashboard.
        if (feature.dashboard) {
            feature.replace_input = true;
            feature.drag_and_drop = true;
            feature.progress_bar  = true;
            feature.status_bar    = true;
        }

        // === Event handlers ===

        setupHandlers(uppy, form, feature);

        if (feature.popup_messages) { setupMessages(uppy,  feature); }
        if (feature.debugging)      { setupDebugging(uppy, feature); }

        // === Display cleanup ===

        if (feature.replace_input) { initializeFileSelectContainer($form); }
    }

    /**
     * Initialize form display and event handlers.
     *
     * @param {Selector} [form]       Default: *this*.
     */
    function initializeForm(form) {

        var $form = $(form || this);

        // Setup buttons.
        setupSubmitButton($form);
        setupCancelButton($form);
        setupFileSelectButton($form);

        // Prevent password managers from incorrectly interpreting any of the
        // fields as something that might pertain to user information.
        turnOffAutocomplete($form);
        inputFields($form).each(function() { turnOffAutocomplete(this); });

        // Broaden click targets for radio buttons and checkboxes that are
        // paired with labels.
        fieldDisplayFilterContainer($form).children().each(function() {
            delegateClick(this);
        });
        $form.find('.menu.multi .checkbox').each(function() {
            delegateClick(this);
        });

        // Ensure that required fields are indicated.
        initializeFormFields($form);
        monitorInputFields($form);

        // Set initial field filtering and setup field display filter controls.
        monitorFieldDisplayFilterButtons($form);
        var field_filter = isUpdateForm($form) ? 'available' : 'filled';
        fieldDisplayFilterSelect(field_filter, $form);

        // Intercept form submission so that it can be handled via AJAX in
        // order to retrieve information sent back from the server via headers.
        monitorRequestResponse($form);
    }

    /**
     * Initialize the Uppy-provided file select button container.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function initializeFileSelectContainer(form) {
        var $form    = formElement(form);
        var $element = fileSelectContainer($form);

        // Uppy will replace <input type="file"> with its own mechanisms so
        // the original should not be displayed.
        $form.find('input#upload_file').css('display', 'none');

        // Reposition it so that it comes before the display of the uploaded
        // filename.
        $element.insertBefore(uploadedFilenameDisplay($form));

        // This hidden element is inappropriately part of the tab order.
        $element.find('.uppy-FileInput-input').attr('tabindex', -1);

        // Set the tooltip for the file select button.
        $element.find('button').attr('title', fileSelectTooltip($form));
    }

    /**
     * Initialize the state of the submit button.
     *
     * @param {Selector} [form]       Passed to {@link formElement}.
     */
    function setupSubmitButton(form) {
        var $form = formElement(form);
        submitButton($form)
            .attr('title', submitTooltip($form))
            .text(submitLabel($form));
    }

    /**
     * Initialize the state of the cancel button, and set it up to clear the
     * form when it is activated.
     *
     * @param {Selector} [form]       Passed to {@link formElement}.
     *
     * == Implementation Notes
     * Although the button is created with 'type="reset"' HTML reset behavior
     * is not relied upon because it only clears form fields but not file data.
     */
    function setupCancelButton(form) {
        var $form = formElement(form);
        cancelButton($form)
            .attr('title', cancelTooltip($form))
            .text(cancelLabel($form))
            .off('click', cancelForm)
            .on('click', cancelForm)
            .each(handleKeypressAsClick);
    }

    /**
     * Initialize the state of the file select button.
     *
     * @param {Selector} [form]       Passed to {@link formElement}.
     */
    function setupFileSelectButton(form) {
        var $form   = formElement(form);
        var $button = fileSelectButton($form);
        if (isCreateForm($form)) {
            $button.addClass('best-choice');
        }
        $button.attr('title', fileSelectTooltip($form));
        $button.text(fileSelectLabel($form));
    }

    /**
     * Adjust an input element to prevent password managers from interpreting
     * certain fields like "Title" as ones that they should offer to
     * autocomplete.
     *
     * @param {Selector} element      Default: *this*.
     */
    function turnOffAutocomplete(element) {
        $(element || this).attr({
            'autocomplete':  'off',
            'data-lpignore': 'true' // LastPass requires this.
        });
    }

    /**
     * Allow a click anywhere within the element holding a label/button pair
     * to be delegated to the enclosed input.  This broadens the "click target"
     * and allows clicks in the "void" between the input and the label to be
     * accredited to the input that the user was trying to click.
     *
     * @param {Selector} element      Default: *this*.
     */
    function delegateClick(element) {

        var $element = $(element || this);
        $element
            .off('click', clickChildInput)
            .on('click', clickChildInput);

        /**
         * If the container receives a click event in an area not covering
         * either the input or label element then it will be handled here and
         * "converted" into a click on the input element.
         *
         * Events that would have gone to the input or label will not be
         * impeded here (nor will the event bubbling up from the input).
         *
         * @param {Event} event
         */
        function clickChildInput(event) {
            if (event.target === event.currentTarget) {
                event.stopPropagation();
                $element.find('[type="radio"],[type="checkbox"]').click();
            }
        }
    }

    /**
     * Initialize each form field then update any fields associated with
     * server-provided metadata.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function initializeFormFields(form) {
        var $form = formElement(form);
        var data  = emmaDataElement($form).val();
        if (data) {
            try {
                data = JSON.parse(data);
            }
            catch (err) {
                console.warn('initializeFormFields:', err, '- data:', data);
                data = undefined;
            }
        }
        data = data || {};
        formFields($form).each(function() {
            var $field = $(this);
            var key    = $field.attr('data-field');
            var value  = data[key];
            updateInputField(this, value, true);
        });
        disableSubmit($form);
    }

    /**
     * The container element for all input fields and their labels.
     *
     * @param {Selector} [form]       Passed to {@link fieldContainer}.
     */
    function normalizeLabelColumnWidth(form) {

        var $container = fieldContainer(form);

        // Find the widest label.
        var max_width = 0;
        $container.children('label').each(function() {
            max_width = Math.max(max_width, $(this).width());
        });
        var column_width = '' + max_width + 'px';

        // Replace the first column definition.
        var old_columns = $container.css('grid-template-columns') || '';
        var parts = old_columns.trim().split(/\s+/);
        var first = parts.shift();
        if (first.indexOf('repeat') === 0) {
            var count = first.replace(/(repeat\()(\d+)(,.*)/, '$2') || 1;
            if (count > 1) {
                column_width += ' ' + RegExp.$1 + (count - 1) + RegExp.$3;
            }
        }
        var new_columns = column_width;
        if (isPresent(parts)) {
            new_columns += ' ' + parts.join(' ');
        }
        $container.css('grid-template-columns', new_columns);
    }

    // ========================================================================
    // Functions - Uppy
    // ========================================================================

    /**
     * Indicate whether Uppy already appears to be set up.
     *
     * @param {Selector} [container]  Default: {@link formElement}.
     *
     * @return {boolean}
     */
    function isUppyInitialized(container) {
        var $container = formContainer(container);
        return isPresent($container.find('.uppy-Root'));
    }

    /**
     * Build an Uppy instance with specified plugins.
     *
     * @param {HTMLElement} form
     * @param {object}      [features]
     *
     * @return {Uppy}
     */
    function buildUppy(form, features) {
        var container = form.parentElement;
        var ftrs      = features || FEATURES;
        var uppy = Uppy.Core({
            id:          form.id,
            autoProceed: true,
            debug:       ftrs.debugging
        });
        if (ftrs.dashboard) {
            uppy.use(Uppy.Dashboard, { target: container, inline: true });
        } else {
            if (ftrs.replace_input) {
                uppy.use(Uppy.FileInput, {
                    target: buttonTray(form)[0], // NOTE: not container
                    locale: { strings: { chooseFiles: fileSelectLabel(form) } }
                });
            }
            if (ftrs.drag_and_drop) {
                uppy.use(Uppy.DragDrop, { target: ftrs.drag_and_drop });
            }
            if (ftrs.progress_bar) {
                uppy.use(Uppy.ProgressBar, { target: container });
            }
            if (ftrs.status_bar) {
                uppy.use(Uppy.StatusBar, {
                    target: container,
                    showProgressDetails: true
                });
            }
        }
        if (ftrs.popup_messages) {
            uppy.use(Uppy.Informer, { target: container });
        }
        if (ftrs.image_preview) {
            uppy.use(Uppy.ThumbnailGenerator, { thumbnailWidth: 400 });
        }
        if (ftrs.upload_to_aws) {
            uppy.use(Uppy.AwsS3, {
                limit:        2,
                timeout:      Uppy.ms('1 minute'),
                companionUrl: 'https://companion.myapp.com/' // TODO: ???
            });
        }
        uppy.use(Uppy.XHRUpload, {
            endpoint:   Emma.Upload.path.endpoint,
            fieldName: 'file',
            headers:   { 'X-CSRF-Token': Rails.csrfToken() }
        });
        return uppy;
    }

    /**
     * Setup handlers for Uppy events that drive the workflow of uploading
     * a file and creating a database entry from it.
     *
     * @param {Uppy}        uppy
     * @param {HTMLElement} form
     * @param {object}      [features]
     */
    function setupHandlers(uppy, form, features) {

        var ftrs = features || FEATURES;

        uppy.on('upload',         onFileUploadStarting);
        uppy.on('upload-success', onFileUploadSuccess);
        uppy.on('upload-error',   onFileUploadError);

        if (ftrs.image_preview) {
            uppy.on('thumbnail:generated', onThumbnailGenerated);
        }

        // ====================================================================
        // Handlers
        // ====================================================================

        /**
         * This event occurs between the 'file-added' and 'upload-started'
         * events.
         *
         * @param {*} status
         */
        function onFileUploadStarting(status) {
            console.log('Uppy: upload', status);
            clearFlash();
        }

        /**
         * This event occurs when the response from POST /upload/endpoint is
         * received with success status (200).  At this point, the file has
         * been uploaded by Shrine, but has not yet been validated.
         *
         * @param {Uppy.UppyFile} file
         * @param {Body}          response
         * @param {string}        upload_url
         */
        function onFileUploadSuccess(file, response, upload_url) {

            console.log('Uppy: upload-success', file, response);

            if (ftrs.popup_messages) {
                uppyInfoClear(uppy);
            }

            var $form = $(form);
            var body  = response.body || {};

            // Save uploaded EMMA metadata.
            var emma_data = body.emma_data || {};
            if (isPresent(emma_data)) {
                emma_data = compact(emma_data);
                var $emma_data = emmaDataElement($form);
                if (isPresent($emma_data)) {
                    $emma_data.val(JSON.stringify(emma_data));
                }
                delete body.emma_data;
            }

            // Set hidden field value to the uploaded file data so that it is
            // submitted with the form as the attachment.
            var file_data = body;
            if (file_data) {
                var $file_data = fileDataElement($form);
                if (isPresent($file_data)) {
                    $file_data.val(JSON.stringify(file_data));
                }
                if (!emma_data.dc_format) {
                    var meta = file_data.metadata;
                    var mime = meta && meta.mime_type;
                    var fmt  = Emma.Upload.mime.to_fmt[mime] || [];
                    if (fmt[0]) { emma_data.dc_format = fmt[0]; }
                }
            }

            if (emma_data.error) {

                // If there was a problem with the uploaded file (e.g. not an
                // expected file type) it will be reported here.
                showFlashError(emma_data.error);

            } else {

                // Display the name of the provisionally uploaded file.
                displayUploadedFilename(file_data, $form);

                // Disable the file select button.
                //
                // The 'cancel' button is used to select a different file
                // because previous metadata (manually or automatically
                // acquired) may no longer be appropriate.
                //
                disableFileSelectButton($form);

                // Update form fields with the transmitted EMMA data.
                //
                // When the form is submitted these values should take
                // precedence over the original values which will be
                // retransmitted the hidden '#upload_emma_data' field.
                //
                populateFormFields(emma_data, $form);
            }
        }

        /**
         * This event occurs when the response from POST /upload/endpoint is
         * received with a failure status (4xx).
         *
         * @param {Uppy.UppyFile} file
         * @param {Error}         error
         * @param {Body}          response
         */
        function onFileUploadError(file, error, response) {
            console.warn('Uppy: upload-error', file, error, response);
            var msg = extractFlashMessage(error.request) || error.message;
            showFlashError('ERROR: ' + (msg || error)); // TODO: I18n
        }

        /**
         * This event occurs a thumbnail of an uploaded image is available.
         *
         * @param {Uppy.UppyFile} file
         * @param {string}        image
         */
        function onThumbnailGenerated(file, image) {
            console.log('Uppy: thumbnail:generated', file, image);
            ftrs.image_preview.src = image;
        }
    }

    /**
     * Setup handlers for Uppy events that should trigger popup messages.
     *
     * @param {Uppy}   uppy
     * @param {object} [features]
     */
    function setupMessages(uppy, features) {

        var ftrs = features || FEATURES;
        var info;
        if (ftrs.popup_messages) {
            info = function(txt, time, lvl) { uppyInfo(uppy, txt, time, lvl); }
        } else {
            info = function() {}; // A placeholder "null function".
        }

        uppy.on('upload-started', function(file) {
            console.warn('Uppy: upload-started', file);
            info('Uploading "' + (file.name || file) + '"'); // TODO: I18n
        });

        uppy.on('upload-pause', function(file_id, is_paused) {
            console.log('Uppy: upload-pause', file_id, is_paused);
            info(is_paused ? 'PAUSED' : 'RESUMED'); // TODO: I18n
        });

        uppy.on('upload-retry', function(file_id) {
            console.log('Uppy: upload-retry', file_id);
            info('Retrying...'); // TODO: I18n
        });

        uppy.on('retry-all', function(count) {
            console.log('Uppy: retry-all', count);
            var msg = 'Retrying '; // TODO: I18n
            msg += (count === 1) ? 'upload' : ('' + count + ' uploads');
            msg += '...';
            info(msg);
        });

        uppy.on('pause-all', function() {
            console.log('Uppy: pause-all');
            info('Uploading PAUSED'); // TODO: I18n
        });

        uppy.on('cancel-all', function() {
            console.log('Uppy: cancel-all');
            info('Uploading CANCELLED'); // TODO: I18n
        });

        uppy.on('resume-all', function() {
            console.log('Uppy: resume-all');
            info('Uploading RESUMED'); // TODO: I18n
        });

    }

    /**
     * Set up console debugging messages for other Uppy events.
     *
     * @param {Uppy}   uppy
     * @param {object} [features]
     */
    function setupDebugging(uppy, features) {

        var ftrs = features || FEATURES;

        // This event occurs after 'upload-success' or 'upload-error'.
        uppy.on('complete', function(status) {
            console.log('Uppy: complete', status);
        });

        // This event is observed concurrent with the 'progress' event.
        uppy.on('upload-progress', function(file, progress) {
            var bytes = progress.bytesUploaded;
            var total = progress.bytesTotal;
            var msg = 'Uppy: Uploading';
            msg += ' ' + bytes + ' of ' + total;
            msg += ' (' + percent(bytes, total) + '%)';
            console.log(msg);
        });

        // This event is observed concurrent with the 'upload-progress' event.
        uppy.on('progress', function(percent) {
            console.log('Uppy: progress', percent);
        });

        uppy.on('reset-progress', function() {
            console.log('Uppy: reset-progress');
        });

        uppy.on('file-added', function(file) {
            console.log('Uppy: file-added', file);
        });

        uppy.on('file-removed', function(file) {
            console.log('Uppy: file-removed', file);
        });

        uppy.on('restriction-failed', function(file, error) {
            console.warn('Uppy: restriction-failed', file, error);
        });

        uppy.on('error', function(file, error) {
            console.warn('Uppy: error', file, error);
        });

        uppy.on('preprocess-progress', function(file, status) {
            console.log('Uppy: preprocess-progress', file, status);
        });

        uppy.on('preprocess-complete', function(file) {
            console.log('Uppy: preprocess-complete', file);
        });

        uppy.on('is-offline', function() {
            console.log('Uppy: OFFLINE');
        });

        uppy.on('is-online', function() {
            console.log('Uppy: ONLINE');
        });

        uppy.on('back-online', function() {
            console.log('Uppy: BACK ONLINE');
        });

        uppy.on('info-visible', function() {
            console.log('Uppy: info-visible');
        });

        uppy.on('info-hidden', function() {
            console.log('Uppy: info-hidden');
        });

        uppy.on('plugin-remove', function(instance) {
            console.log('Uppy: plugin-remove', (instance.id || instance));
        });

        if (ftrs.dashboard) {
            uppy.on('dashboard:modal-open', function() {
                console.log('Uppy: dashboard:modal-open');
            });
            uppy.on('dashboard:modal-closed', function() {
                console.log('Uppy: dashboard:modal-closed');
            });
            uppy.on('dashboard:file-edit-start', function() {
                console.log('Uppy: dashboard:file-edit-start');
            });
            uppy.on('dashboard:file-edit-complete', function() {
                console.log('Uppy: dashboard:file-edit-complete');
            });
        }

        if (ftrs.image_preview) {
            uppy.on('thumbnail:error', function(file, error) {
                console.log('Uppy: thumbnail:error', file, error);
            });
            uppy.on('thumbnail:all-generated', function() {
                console.log('Uppy: thumbnail:all-generated');
            });
        }

        if (ftrs.upload_to_aws) {
            uppy.on('s3-multipart:part-uploaded', function(file, pt) {
                console.log('Uppy: s3-multipart:part-uploaded', file, pt);
            });
        }

/*
        uppy.on('state-update', function(prev, next, path) {
            console.log('Uppy: state-update', prev, next, path);
        });
*/
    }

    /**
     * Invoke `uppy.info`.
     *
     * @param {Uppy}   uppy
     * @param {string} text
     * @param {number} [time]
     * @param {string} [message_level]
     */
    function uppyInfo(uppy, text, time, message_level) {
        var level    = message_level || 'info';
        var duration = time || MESSAGE_DURATION;
        uppy.info(text, level, duration);
    }

    /**
     * Invoke `uppy.info` with an empty string and very short duration.
     *
     * @param {Uppy}   uppy
     */
    function uppyInfoClear(uppy) {
        uppyInfo(uppy, '', 1);
    }

    // ========================================================================
    // Functions - form fields
    // ========================================================================

    /**
     * Interpret the object keys as field names to locate the input elements
     * to update.
     *
     * @param {object}   data
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function populateFormFields(data, form) {
        if (isPresent(data)) {
            var $form = formElement(form);
            $.each(data, function(field, value) {
                var $input = formField(field, $form);
                updateInputField($input, value);
            });
            validateForm($form);
        }
    }

    /**
     * Update a single input field and its label.
     *
     * @param {Selector} [target]     Default: *this*.
     * @param {*}        [new_value]
     * @param {boolean}  [init]       If *true*, in initialization phase.
     */
    function updateInputField(target, new_value, init) {
        var $input = $(target || this);

        if ($input.is('fieldset.input.multi')) {
            updateFieldsetInputs($input, new_value, init);

        } else if ($input.is('fieldset.menu.multi')) {
            updateFieldsetCheckboxes($input, new_value, init);

        } else if ($input.is('[type="checkbox"]')) {
            updateCheckboxInputField($input, new_value, init);

        } else if ($input.is('textarea')) {
            updateTextAreaField($input, new_value, init);

        } else {
            updateTextInputField($input, new_value, init);
        }
    }

    /**
     * Update the input field collection and label for a <fieldset> and its
     * enclosed set of text inputs.
     *
     * @param {Selector} [target]     Default: *this*.
     * @param {Array}    [new_value]
     * @param {boolean}  [init]       If *true*, in initialization phase.
     *
     * @see "ModelHelper#render_form_input_multi"
     */
    function updateFieldsetInputs(target, new_value, init) {

        var $fieldset = $(target || this);
        var $inputs   = $fieldset.find('input');

        // If multiple values are provided, they are treated as a complete
        // replacement for the existing set of values.
        var value, values;
        if (new_value instanceof Array) {
            values = compact(new_value);
            $inputs.each(function(i) {
                value = values[i];
                if (init && !value) {
                    value = '';
                }
                if (isDefined(value)) {
                    setValue(this, value, init);
                }
            });
        } else {
            // Initialize original values for all elements.
            $inputs.each(function() {
                setOriginalValue(this);
            });
            if (new_value) {
                value = new_value.trim();
                var index = -1;
                // noinspection FunctionWithInconsistentReturnsJS, FunctionWithMultipleReturnPointsJS
                $inputs.each(function(i) {
                    var old_value = this.value || '';
                    if (old_value === value) {
                        // The value is present in this slot.
                        index = -1;
                        return false;
                    } else if (index >= 0) {
                        // An empty slot has already been reserved; continue
                        // looking for the value in later slots.
                    } else if (!old_value) {
                        // The value will be placed in this empty slot unless
                        // it is found in a later slot.
                        index = i;
                    }
                });
                if (index >= 0) {
                    setValue($inputs[index], value, init);
                }
            }
        }

        // Enumerate the valid inputs and update the fieldset.
        values = [];
        $inputs.each(function() {
            if (this.value) { values.push(this.value); }
        });
        updateFieldAndLabel($fieldset, values);
    }

    /**
     * Update the input field collection and label for a <fieldset> and its
     * enclosed set of checkboxes.
     *
     * @param {Selector} [target]     Default: *this*.
     * @param {Array}    [setting]
     * @param {boolean}  [init]       If *true*, in initialization phase.
     *
     * @see "ModelHelper#render_form_menu_multi"
     */
    function updateFieldsetCheckboxes(target, setting, init) {

        var $fieldset   = $(target || this);
        var $checkboxes = $fieldset.find('input[type="checkbox"]');

        // If a value is provided, use it to define the state of the contained
        // checkboxes if it is an array, or to set a specific checkbox if it
        // is a string.
        if (setting instanceof Array) {
            var values = compact(setting);
            $checkboxes.each(function() {
                var checked = (values.indexOf(this.value) >= 0);
                setChecked(this, checked, init);
            });
        } else if (typeof setting === 'string') {
            $checkboxes.each(function() {
                if (this.value === setting) {
                    setChecked(this, true, init);
                } else if (init) {
                    setOriginalValue(this);
                }
            });
        } else if (init) {
            $checkboxes.each(function() {
                setOriginalValue(this);
            });
        }

        // Enumerate the checked items and update the fieldset.
        var checked = [];
        $checkboxes.each(function() {
            if (this.checked) { checked.push(this.value); }
        });
        updateFieldAndLabel($fieldset, checked);
    }

    /**
     * Update the input field and label for a <input type="checkbox">.
     *
     * For this type, the checkbox is within a hierarchy under a <fieldset>
     * element which is a sibling of the label element associated with any of
     * the contained checkboxes.
     *
     * @param {Selector}       [target]     Default: *this*.
     * @param {string|boolean} [setting]
     * @param {boolean}  [init]       If *true*, in initialization phase.
     */
    function updateCheckboxInputField(target, setting, init) {

        var $input    = $(target || this);
        var $fieldset = $input.parents('fieldset').first();
        var checkbox  = $input[0];

        var checked;
        if (notDefined(setting)) {
            checked = checkbox.checked;
        } else if (typeof setting === 'boolean') {
            checked = setting;
        } else if (setting === checkbox.value) {
            checked = true;
        } else if (setting === 'true') {
            checked = true;
        } else if (setting === 'false') {
            checked = false;
        }

        if (isDefined(checked)) {
            setChecked($input, checked, init);
        } else {
            console.warn('updateCheckboxInputField unexpected:', setting);
        }

        // Update the enclosing fieldset.
        updateFieldsetCheckboxes($fieldset, undefined, init);
    }

    /**
     * Update the input field and label for a <textarea>.
     *
     * For this type, the label is a sibling of the input element.
     *
     * @param {Selector} [target]     Default: *this*.
     * @param {*}        [new_value]
     * @param {boolean}  [init]       If *true*, in initialization phase.
     *
     * @see "ModelHelper#render_form_input"
     */
    function updateTextAreaField(target, new_value, init) {
        var $input = $(target || this);
        var value  = textAreaValue(new_value || $input.val());
        setTextAreaValue($input, value, init);
        updateFieldAndLabel($input, value);
    }

    /**
     * Update the input field and label for <select> or <input type="text">.
     *
     * For these types, the label is a sibling of the input element.
     *
     * @param {Selector} [target]     Default: *this*.
     * @param {*}        [new_value]
     * @param {boolean}  [init]       If *true*, in initialization phase.
     *
     * @see "ModelHelper#render_form_input"
     */
    function updateTextInputField(target, new_value, init) {

        var $input = $(target || this);
        var value  = new_value || $input.val();

        // Clean up stray leading and trailing white space and blank values in
        // order to determine whether the field actually has a value.
        if (value instanceof Array) {
            value = compact(value).join('; ');
        } else if (typeof value === 'string') {
            value = value.trim();
        }
        setValue($input, value, init);

        // If this is one of a collection of text inputs under <fieldset> then
        // it has to be handled differently.
        if ($input.parent().hasClass('multi')) {
            var $fieldset = $input.parents('fieldset').first();
            updateFieldsetInputs($fieldset, undefined, init);
        } else {
            updateFieldAndLabel($input, $input.val());
        }
    }

    /**
     * Update the input field and label for a <select>, <textarea>, or
     * <input type="text">.
     *
     * For these types, the label is a sibling of the input element.
     *
     * @param {Selector} target       Default: *this*.
     * @param {*}        values
     */
    function updateFieldAndLabel(target, values) {
        var $input = $(target || this);
        if ($input.attr('readonly')) {

            // Database fields should not be marked for validation.
            $input.removeClass('valid invalid');

        } else {

            var name     = $input.attr('name');
            var $label   = $input.siblings('label[for="' + name + '"]');
            var $status  = $label.find('.status-marker');
            var required = $input.attr('data-required');
            var missing  = isEmpty(values);
            var invalid  = missing; // TODO: per-field validation
            var valid    = !invalid && !missing;


            // Manage positive indication of *validity* for a field that has
            // been supplied with a value (or had a value removed).
            if (valid) {
                $input.addClass('valid');
                $label.addClass('valid');
                $status.addClass('valid');
            } else {
                $input.removeClass('valid');
                $label.removeClass('valid');
                $status.removeClass('valid');
            }

            // Manage positive indication of *invalidity* for an optional field
            // with an incorrect value or a required field without a correct
            // value.
            if (invalid && (!required || !missing)) {
                setInvalid($status);
            } else {
                unsetInvalid($status);
            }
            if (!required) {
                invalid = invalid && !missing;
                if (invalid) {
                    setTooltip($status);
                } else {
                    restoreTooltip($status);
                }
            }
            if (invalid) {
                $input.addClass('invalid');
                $label.addClass('invalid');
                $status.addClass('invalid');
            } else {
                $input.removeClass('invalid');
                $label.removeClass('invalid');
                $status.removeClass('invalid');
            }
        }
    }

    /**
     * If the checkbox state is changing, save the old state.
     *
     * If *new_state* is undefined then it is assumed that this invocation is
     * in response to a change event, in which case the state change has
     * already happened so the old state is the opposite of the current state.
     *
     * @param {Selector} target       Default: *this*.
     * @param {boolean}  [new_state]
     * @param {boolean}  [init]       If *true*, in initialization phase.
     */
    function setChecked(target, new_state, init) {
        var $item = $(target || this);
        if (init) {
            setOriginalValue($item, new_state);
        }
        $item[0].checked = new_state;
    }

    /**
     * If the input value is changing, save the old value.
     *
     * @param {Selector} target       Default: *this*.
     * @param {string}   new_value
     * @param {boolean}  [init]       If *true*, in initialization phase.
     */
    function setTextAreaValue(target, new_value, init) {
        var $item = $(target || this);
        if (init) {
            setOriginalValue($item, new_value);
        }
        $item.val(new_value);
    }

    /**
     * If the input value is changing, save the old value.
     *
     * @param {Selector} target       Default: *this*.
     * @param {string}   new_value
     * @param {boolean}  [init]       If *true*, in initialization phase.
     */
    function setValue(target, new_value, init) {
        var $item = $(target || this);
        if (init) {
            setOriginalValue($item, new_value);
        }
        $item.val(new_value);
    }

    /**
     * Change a status marker to indicate a field with an invalid value.
     *
     * @param {Selector} element
     * @param {string}   [text]       Default: Emma.Upload.InputInvalid.label
     */
    function setInvalid(element, text) {
        var $element = $(element || this);
        var new_icon = text || Emma.Upload.Status.invalid.label;
        var old_icon = $element.attr('data-icon');
        if (isMissing(old_icon)) {
            old_icon = $element.text();
            if (isPresent(old_icon)) {
                $element.attr('data-icon', old_icon);
            }
        }
        $element.text(new_icon);
    }

    /**
     * Restore a status marker after the associated input value is no longer
     * invalid.
     *
     * @param {Selector} element
     */
    function unsetInvalid(element) {
        var $element = $(element || this);
        var old_icon = $element.attr('data-icon');
        if (isPresent(old_icon)) {
            $element.text(old_icon);
        } else {
            $element.empty();
        }
    }

    /**
     * Translate a value for a <textarea> into a string.
     *
     * @param {string|string[]} value
     *
     * @return {string}
     */
    function textAreaValue(value) {
        var result = value;
        if (typeof result === 'string') {
            result = result.trim();
            if (!result || (result === '[]')) {
                result = '';
            } else if (result[0] === '[') {
                try {
                    result = JSON.parse(result);
                }
                catch (err) {
                    var len = result.length;
                    if (result[len-1] === ']') {
                        result = result.substr(1, (len-2));
                    } else {
                        result = result.substr(1);
                    }
                    result = [result];
                }
            } else {
                result = [result];
            }
        }
        if (result instanceof Array) {
            result = compact(result);
            for (var i = 0; i < result.length; i++) {
                result[i] = htmlDecode(result[i]);
            }
            result = result.join("\n");
        }
        return result;
    }

    /**
     * Save the original value of an element.
     *
     * If *value* is present, that is assigned directly as the original value.
     * If *value* was not provided, and no saved value is present then the
     * current value will be saved as the original value.
     *
     * @param {Selector}                 target
     * @param {string|boolean|undefined} [value]
     */
    function setOriginalValue(target, value) {
        var $item = $(target || this);
        var new_value;
        if (isDefined(value)) {
            new_value = valueOf(value);
        } else if (notDefined(rawOriginalValue($item))) {
            new_value = valueOf($item);
        }
        if (isDefined(new_value)) {
            $item.attr('data-original-value', new_value);
        }
    }

    /**
     * Get the effective original value of the element.
     *
     * @param {Selector} target
     *
     * @return {string}
     */
    function getOriginalValue(target) {
        var value = rawOriginalValue(target);
        return notDefined(value) ? '' : value;
    }

    /**
     * Get the saved original value of the element.
     *
     * @param {Selector} target
     *
     * @return {string|undefined}
     */
    function rawOriginalValue(target) {
        var $item = $(target || this);
        return $item.attr('data-original-value');
    }

    /**
     * Get the value string associated with *item*.
     *
     * If *item* is a checkbox element, the state of it's 'checked' attribute
     * is found; if *item* is another type of element, its 'value' attribute
     * is found.
     *
     * Booleans are converted to either 'true' or 'false'.
     *
     * @param {jQuery|HTMLElement|string|boolean|undefined} item
     *
     * @returns {string}
     */
    function valueOf(item) {
        var value;
        if (typeof item === 'object') {
            var $i = $(item);
            value  = $i.is('[type="checkbox"]') ? $i[0].checked : $i.val();
        } else {
            value  = item;
        }
        switch (typeof value) {
            case 'boolean': value = value ? 'true' : 'false'; break;
            case 'string':  value = value.trim();             break;
            default:        value = '';                       break;
        }
        return value;
    }

    // ========================================================================
    // Functions - form validation
    // ========================================================================

    /**
     * Listen for changes on input fields.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function monitorInputFields(form) {

        var $form = formElement(form);

        inputFields($form)
            .off('change', validateInputField)
            .on('change',  validateInputField);

        /**
         * Update a single input field and its label.
         *
         * @param {Event} event
         */
        function validateInputField(event) {
            var target = event.target || event || this;
            updateInputField(target);
            validateForm($form);
        }
    }

    /**
     * Check whether all required field values are present and valid, and that
     * any other supplied values.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function validateForm(form) {
        var $form   = formElement(form);
        var $fields = inputFields($form);
        var ready   = !$fields.hasClass('invalid');
        if (ready && !fileSelected($form)) {
            var changes = 0;
            if (isUpdateForm($form)) {
                $fields.each(function() {
                    var $item = $(this);
                    if (valueOf($item) !== getOriginalValue($item)) {
                        changes += 1;
                    }
                });
            }
            ready = (changes > 0);
        }
        if (ready) {
            enableSubmit($form);
        } else {
            disableSubmit($form);
        }
    }

    /**
     * Enable form submission.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function enableSubmit(form) {
        var $form = formElement(form);
        var tip   = submitReadyTooltip($form);
        submitButton($form)
            .addClass('best-choice')
            .removeClass('disabled forbidden')
            .removeAttr('disabled')
            .attr('title', tip)
            .attr('data-state', 'ready');
    }

    /**
     * Disable form submission.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function disableSubmit(form) {
        var $form = formElement(form);
        var tip   = submitNotReadyTooltip($form);
        submitButton($form)
            .removeClass('best-choice')
            .addClass('forbidden')
            .attr('disabled', true)
            .attr('title', tip)
            .attr('data-state', 'not-ready');
    }

    // ========================================================================
    // Functions - form submission
    // ========================================================================

    /**
     * Cancel the current action.
     *
     * @param {Event} [event]
     */
    function cancelForm(event) {
        var $button;
        if (typeof event === 'object') {
            event.stopPropagation();
            $button = $(event.target);
        } else {
            $button = $(event || this);
        }
        var $form = formElement($button);
        var url;
        if (fileSelected($form) && !canSubmit($form)) {
            url = window.location.href;
        } else if ((url = $button.attr('data-path'))) {
            var def_path  = Emma.Upload.path.index;
            var base_path = window.location.pathname;
            var base_url  = window.location.origin + base_path;
            if ((url === base_path) || (url === base_url)) {
                url = base_path;
            } else if (url.indexOf(def_path) === 0) {
                url = def_path;
            } else if (url.indexOf(window.location.origin + def_path) === 0) {
                url = def_path;
            }
        }
        cancelAction(url);
    }

    /**
     * React to the server's response after the form is submitted.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     */
    function monitorRequestResponse(form) {
        var $form = formElement(form);
        var event_handlers = {
            'ajax:before':     beforeAjax,
            'ajax:beforeSend': beforeAjaxFormSubmission,
            'ajax:success':    onAjaxFormSubmissionSuccess,
            'ajax:error':      onAjaxFormSubmissionError,
            'ajax:complete':   onAjaxFormSubmissionComplete
        };
        $.each(event_handlers, function(type, handler) {
            $form.off(type, handler).on(type, handler);
        });
    }

    /**
     * Before the XHR request is generated.
     *
     * @param {object} arg
     */
    function beforeAjax(arg) {
        // console.log('ajax:before - arguments', arguments);
    }

    /**
     * Pre-process form fields before the form is actually submitted.
     *
     * @param {object} arg
     */
    function beforeAjaxFormSubmission(arg) {
        // console.log('ajax:beforeSend - arguments', arguments);
        var $form = formElement();

        // Disable empty database fields.
        databaseInputFields($form).each(function() {
            if (this.placeholder || (this.value === "\u2013")) { // EN_DASH
                this.disabled = true;
            }
        });
    }

    /**
     * Process rails-ujs 'ajax:success' event data.
     *
     * @param {object} arg
     */
    function onAjaxFormSubmissionSuccess(arg) {
        // console.log('ajax:success - arguments', arguments);
        var data   = arg.data;
        var event  = arg.originalEvent || {};
        var _resp, status_text, xhr;
        [_resp, status_text, xhr] = event.detail || [];
        var status = xhr.status;
        onCreateSuccess(data, status, xhr);
    }

    /**
     * Process rails-ujs 'ajax:error' event data.
     *
     * @param {object} arg
     */
    function onAjaxFormSubmissionError(arg) {
        // console.log('ajax:error - arguments', arguments);
        var error = arg.data;
        var event = arg.originalEvent || {};
        var _resp, status_text, xhr;
        [_resp, status_text, xhr] = event.detail || [];
        var status = xhr.status;
        console.error('ajax:error', status, 'error', error, 'xhr', xhr);
        onCreateError(xhr, status, error);
    }

    /**
     * Process rails-ujs 'ajax:complete' event data.
     *
     * @param {object} arg
     */
    function onAjaxFormSubmissionComplete(arg) {
        // console.log('ajax:complete - arguments', arguments);
        onCreateComplete();
    }

    /**
     * When called this indicates that Shrine has validated the uploaded file
     * and has created an Upload record which references it.
     *
     * @param {object}         data
     * @param {string}         status
     * @param {XMLHttpRequest} xhr
     */
    function onCreateSuccess(data, status, xhr) {
        var flash   = compact(extractFlashMessage(xhr));
        var entry   = (flash.length > 1) ? 'entries' : 'entry';
        var message = 'EMMA ' + entry + ' ' + termActionOccurred(); // TODO: I18n
        if (isPresent(flash)) {
            message += ' for: ' + flash.join(', ');
        }
        console.log('onCreateSuccess:', message);
        showFlashMessage(message);
    }

    /**
     * When called this indicates that there was problem (e.g. a validation
     * error) which has prevented the creation of an Upload record.  This also
     * indicates that the previously-uploaded file has been removed from
     * storage.
     *
     * @param {XMLHttpRequest} xhr
     * @param {string}         status
     * @param {string}         error
     */
    function onCreateError(xhr, status, error) {
        var flash   = compact(extractFlashMessage(xhr));
        var message = 'EMMA entry not ' + termActionOccurred() + ':'; // TODO: I18n
        if (flash.length > 1) {
            message += "\n" + flash.join("\n");
        } else if (flash.length === 1) {
            message += ' ' + flash[0];
        } else {
            message += ' ' + status + ': ' + error;
        }
        console.warn('onCreateError:', message);
        showFlashError(message);
    }

    /**
     * Called at the end of the submission response.
     *
     * @param {XMLHttpRequest} [xhr]
     * @param {string}         [status]
     */
    function onCreateComplete(xhr, status) {
        // Restore empty database fields.
        databaseInputFields().each(function() {
            this.disabled = false;
        });
    }

    // ========================================================================
    // Functions - form field filtering
    // ========================================================================

    /**
     * The current field filtering selection.
     *
     * @param {Selector} [form]  Passed to {@link fieldDisplayFilterContainer}.
     *
     * @return {string}
     */
    function fieldDisplayFilterCurrent(form) {
        return fieldDisplayFilterContainer(form).find(':checked').val();
    }

    /**
     * Update the current field filtering selection.
     *
     * @param {string}   new_mode
     * @param {Selector} [form]    Passed to {@link fieldDisplayFilterButtons}.
     */
    function fieldDisplayFilterSelect(new_mode, form) {
        var selector = '[value="' + new_mode + '"]';
        var $radio   = fieldDisplayFilterButtons(form).filter(selector);
        $radio.prop('checked', true).change();
    }

    /**
     * Listen for changes on field display filter selection.
     *
     * @param {Selector} [form]  Passed to {@link fieldDisplayFilterButtons}.
     *
     * @see "UploadHelper#upload_field_control"
     */
    function monitorFieldDisplayFilterButtons(form) {

        var $form = formElement(form);
        fieldDisplayFilterButtons($form)
            .off('change', fieldDisplayFilterHandler)
            .on('change', fieldDisplayFilterHandler);

        /**
         * Update field display filtering if the target is checked.
         *
         * @param {Event} event
         */
        function fieldDisplayFilterHandler(event) {
            var $target = $(event.target || event || this);
            if ($target.is(':checked')) {
                filterFieldDisplay($target.val(), $form);
            }
        }
    }

    /**
     * Update field display filtering.
     *
     * @overload filterFieldDisplay(form_sel)
     *  @param {Selector} [form_sel]
     *
     * @overload filterFieldDisplay(new_mode, form_sel)
     *  @param {string|null} [new_mode]
     *  @param {Selector}    [form_sel]
     *
     * @see "UploadHelper#upload_field_control"
     */
    function filterFieldDisplay(new_mode, form_sel) {
        var obj   = (typeof new_mode === 'object');
        var mode  = obj ? undefined : new_mode;
        var form  = obj ? new_mode  : form_sel;
        var $form = $(form);
        if (!mode) {
            mode = fieldDisplayFilterCurrent($form);
        }
        switch (mode) {
            case 'filled':    fieldDisplayFilled($form);    break;
            case 'invalid':   fieldDisplayInvalid($form);   break;
            case 'available': fieldDisplayAvailable($form); break;
            case 'all':       fieldDisplayAll($form);       break;
            default:
                console.error('filterFieldDisplay', 'invalid mode:', mode);
        }
        // Scroll so the the first visible field is at the top of the display
        // beneath the field display controls.
        $form[0].scrollIntoView();
    }

    /**
     * Show fields that have data (plus required fields whether or not they
     * have data).
     *
     * @param {Selector} [form]       Passed to {@link fieldDisplayOnly}.
     */
    function fieldDisplayFilled(form) {
        fieldDisplayOnly('.valid, .invalid', form);
    }

    /**
     * Show only required fields that are missing values and fields with values
     * which are invalid.
     *
     * @param {Selector} [form]       Passed to {@link fieldDisplayOnly}.
     */
    function fieldDisplayInvalid(form) {
        fieldDisplayOnly('.invalid', form);
    }

    /**
     * Show fields that are modifiable by the user.
     *
     * @param {Selector} [form]       Passed to {@link fieldDisplayExcept}.
     */
    function fieldDisplayAvailable(form) {
        fieldDisplayExcept('.disabled', form);
    }

    /**
     * Show all fields including internal fields that are not modifiable.
     *
     * @param {Selector} [form]       Passed to {@link fieldContainer}.
     */
    function fieldDisplayAll(form) {
        var $container = fieldContainer(form);
        $container.children().show();
        $container.children('.no-fields').hide();
    }

    /**
     * Show only the matching fields.
     *
     * @param {Selector} match        Selector for visible fields.
     * @param {Selector} [form]       Passed to {@link fieldContainer}.
     */
    function fieldDisplayOnly(match, form) {
        var $container = fieldContainer(form);
        var $visible   = $container.children(match);
        var $no_fields = $container.children('.no-fields');
        $container.children().hide();
        if (isPresent($visible)) {
            $visible.show();
            $no_fields.hide();
        } else {
            $no_fields.show();
        }
    }

    /**
     * Hide the matching fields.
     *
     * @param {Selector} match        Selector for hidden fields.
     * @param {Selector} [form]       Passed to {@link fieldContainer}.
     */
    function fieldDisplayExcept(match, form) {
        var $container = fieldContainer(form);
        $container.children().show();
        $container.children(match).hide();
        $container.children('.no-fields').hide();
    }

    // ========================================================================
    // Functions - display manipulation
    // ========================================================================

    /**
     * Disable the file select button.
     *
     * @param {Selector} [form]       Passed to {@link formElement}.
     */
    function disableFileSelectButton(form) {
        var $form = formElement(form);
        var label = fileSelectDisabledLabel($form);
        var tip   = fileSelectDisabledTooltip($form);
        fileSelectButton($form)
            .removeClass('best-choice')
            .addClass('forbidden')
            .attr('title', tip)
            .text(label);
    }

    /**
     * Display the name of the uploaded file.
     *
     * @param {{
     *      id:      string,
     *      storage: string,
     *      metadata: {
     *          filename:  string,
     *          size:      number,
     *          mime_type: string,
     *      }
     * }} file_data
     * @param {Selector} [element]    Default: {@link uploadedFilenameDisplay}.
     */
    function displayUploadedFilename(file_data, element) {
        var $element = uploadedFilenameDisplay(element);
        if (isPresent($element)) {
            var metadata = file_data && file_data.metadata;
            var filename = metadata && metadata.filename;
            if (filename) {
                var $filename = $element.find('.filename');
                if (isPresent($filename)) {
                    $filename.text(filename);
                } else {
                    $element.text(filename);
                }
                $element.addClass('complete');
            }
        }
    }

    /**
     * Set a temporary tooltip.
     *
     * @param {Selector} element      Default: *this*.
     * @param {string}   [text]       Default: Emma.Upload.InputInvalid.tooltip
     */
    function setTooltip(element, text) {
        var $element = $(element || this);
        var new_tip  = text || Emma.Upload.Status.invalid.tooltip;
        var old_tip  = $element.attr('data-title');
        if (isMissing(old_tip)) {
            // noinspection ReuseOfLocalVariableJS
            old_tip = $element.attr('title');
            if (isPresent(old_tip)) {
                $element.attr('data-title', old_tip);
            }
        }
        $element.attr('title', new_tip);
    }

    /**
     * Remove a temporary tooltip.
     *
     * @param {Selector} element      Default: *this*.
     */
    function restoreTooltip(element) {
        var $element = $(element || this);
        var old_tip  = $element.attr('data-title');
        if (isPresent(old_tip)) {
            $element.attr('title', old_tip);
        } else {
            $element.removeAttr('title');
        }
    }

    // ========================================================================
    // Functions - elements
    // ========================================================================

    /**
     * The parent element of the form.
     *
     * @param {Selector} [container]    Passed to {@link formElement}.
     *
     * @return {jQuery}
     */
    function formContainer(container) {
        return formElement(container).parent();
    }

    /**
     * The given form element or the first file upload form on the page.
     *
     * @param {Selector} [form]       Default: '.' + FORM_CLASS.
     *
     * @return {jQuery}
     */
    function formElement(form) {
        var $form = $(form);
        if (!$form.hasClass(FORM_CLASS)) {
            $form = $form.parents('.' + FORM_CLASS).first();
        }
        if (isMissing($form)) {
            $form = $file_upload_form.first();
        }
        return $form;
    }

    /**
     * The hidden element with metadata information supplied by the server.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @return {jQuery}
     */
    function emmaDataElement(form) {
        return formElement(form).find('#upload_emma_data');
    }

    /**
     * The hidden element with file metadata information maintained by Uppy.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @return {jQuery}
     */
    function fileDataElement(form) {
        return formElement(form).find('#upload_file_data');
    }

    /**
     * All elements that are or that contain form field inputs.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @return {jQuery}
     */
    function formFields(form) {
        return formElement(form).find('[data-field]');
    }

    /**
     * The element that maintains the given form field.
     *
     * @param {string}   field
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @return {jQuery}
     */
    function formField(field, form) {
        return formElement(form).find('[data-field="' + field + '"]');
    }

    /**
     * The control button container
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @return {jQuery}
     *
     * @see "UploadHelper#upload_submit_button"
     */
    function buttonTray(form) {
        return formElement(form).find('.button-tray');
    }

    /**
     * The submit button.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @return {jQuery}
     *
     * @see "UploadHelper#upload_submit_button"
     */
    function submitButton(form) {
        return buttonTray(form).children('[type="submit"]').first();
    }

    /**
     * The cancel button.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @return {jQuery}
     *
     * @see setupCancelButton
     * @see "UploadHelper#upload_cancel_button"
     */
    function cancelButton(form) {
        return buttonTray(form).children('.cancel-button').first();
    }

    /**
     * The element displaying the uploaded file.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @return {jQuery}
     */
    function uploadedFilenameDisplay(form) {
        return formElement(form).find('.uploaded-filename');
    }

    /**
     * The container for the field filtering controls.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @return {jQuery}
     */
    function fieldDisplayFilterContainer(form) {
        return formElement(form).find('.upload-field-control');
    }

    /**
     * Field display filter radio buttons.
     *
     * @param {Selector} [form]  Passed to {@link fieldDisplayFilterContainer}.
     *
     * @return {jQuery}
     */
    function fieldDisplayFilterButtons(form) {
        return fieldDisplayFilterContainer(form).find('input[type="radio"]');
    }

    /**
     * The Uppy-generated element containing the file select button.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @return {jQuery}
     */
    function fileSelectContainer(form) {
        return formElement(form).find('.uppy-FileInput-container');
    }

    /**
     * The Uppy-generated file select button.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @return {jQuery}
     */
    function fileSelectButton(form) {
        return fileSelectContainer(form).children('button');
    }

    /**
     * The container element for all input fields and their labels.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @return {jQuery}
     */
    function fieldContainer(form) {
        return formElement(form).find('.upload-fields');
    }

    /**
     * All input fields.
     *
     * @param {Selector} [form]       Passed to {@link fieldContainer}.
     *
     * @return {jQuery}
     */
    function inputFields(form) {
        return fieldContainer(form).find(FORM_FIELD_SELECTOR);
    }

    /**
     * Input fields directly associated with database columns.
     *
     * @param {Selector} [form]       Passed to {@link inputFields}.
     *
     * @return {jQuery}
     */
    function databaseInputFields(form) {
        return inputFields(form).filter('[readonly]');
    }

    /**
     * Only input fields which are checkboxes.
     *
     * @param {Selector} [form]       Passed to {@link inputFields}.
     *
     * @return {jQuery}
     */
    function checkboxInputFields(form) {
        return inputFields(form).filter('[type="checkbox"]');
    }

    // ========================================================================
    // Functions - state
    // ========================================================================

    /**
     * Indicate whether the form is ready to submit.
     *
     * @param {Selector} [form]       Passed to {@link submitButton}.
     *
     * @return {boolean}
     */
    function canSubmit(form) {
        return submitButton(form).attr('data-state') === 'ready';
    }

    /**
     * Indicate whether the form can be cancelled.
     *
     * @param {Selector} [form]       Passed to {@link submitButton}.
     *
     * @return {boolean}
     */
    function canCancel(form) {
        return true; // TODO: canCancel?
    }

    /**
     * Indicate whether file select is enabled.
     *
     * @param {Selector} [form]       Passed to {@link fileSelected}.
     *
     * @return {boolean}
     */
    function canSelect(form) {
        return !fileSelected(form);
    }

    /**
     * Indicate whether the user has selected a file (which implies that the
     * file has been uploaded for validation).
     *
     * @param {Selector} [form]       Passed to {@link uploadedFilenameDisplay}
     *
     * @return {boolean}
     */
    function fileSelected(form) {
        return uploadedFilenameDisplay(form).css('display') !== 'none';
    }

    // ========================================================================
    // Functions - data properties
    // ========================================================================

    /**
     * Indicate whether the purpose of the form is for creation of a new entry.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @return {boolean}
     */
    function isCreateForm(form) {
        return formElement(form).hasClass('new');
    }

    /**
     * Indicate whether the purpose of the form is for update of an existing
     * entry.
     *
     * @param {Selector} [form]       Default: {@link formElement}.
     *
     * @return {boolean}
     */
    function isUpdateForm(form) {
        return formElement(form).hasClass('edit');
    }

    /**
     * Displayable term for the action associated with the form.
     *
     * @param {Selector} [form]       Passed to {@link isUpdateForm}.
     *
     * @return {string}
     */
    function termAction(form) {
        return isUpdateForm(form) ? 'update' : 'create'; // TODO: I18n
    }

    /**
     * Displayable term for the past-tense action associated with the form.
     *
     * @param {Selector} [form]       Passed to {@link isUpdateForm}.
     *
     * @return {string}
     */
    function termActionOccurred(form) {
        return isUpdateForm(form) ? 'updated' : 'created'; // TODO: I18n
    }

    /**
     * The label for the Submit button.
     *
     * @param {Selector} [form]       Passed to {@link formElement}.
     *
     * @return {string}
     */
    function submitLabel(form) {
        var $form  = formElement(form);
        var button = assetObject($form).submit;
        var data   = canSubmit($form) ? button.enabled : button.disabled;
        return data.label;
    }

    /**
     * The tooltip for the Submit button.
     *
     * @param {Selector} [form]       Passed to {@link formElement}.
     *
     * @return {string}
     */
    function submitTooltip(form) {
        var $form  = formElement(form);
        var button = assetObject($form).submit;
        var data   = canSubmit($form) ? button.enabled : button.disabled;
        return data.tooltip;
    }

    /**
     * The tooltip for the Submit button after the form is validated.
     *
     * @param {Selector} [form]       Passed to {@link assetObject}.
     *
     * @return {string}
     */
    function submitReadyTooltip(form) {
        return assetObject(form).submit.enabled.tooltip;
    }

    /**
     * The tooltip for the Submit button before the form is validated.
     *
     * @param {Selector} [form]       Passed to {@link assetObject}.
     *
     * @return {string}
     */
    function submitNotReadyTooltip(form) {
        return assetObject(form).submit.disabled.tooltip;
    }

    /**
     * The current label for the Cancel button.
     *
     * @param {Selector} [form]       Passed to {@link formElement}.
     *
     * @return {string}
     */
    function cancelLabel(form) {
        var $form  = formElement(form);
        var button = assetObject($form).cancel;
        var data   = canCancel($form) ? button.enabled : button.disabled;
        return data.label;
    }

    /**
     * The current tooltip for the Cancel button.
     *
     * @param {Selector} [form]       Passed to {@link formElement}.
     *
     * @return {string}
     */
    function cancelTooltip(form) {
        var $form  = formElement(form);
        var button = assetObject($form).cancel;
        var data   = canCancel($form) ? button.enabled : button.disabled;
        return data.tooltip;
    }

    /**
     * The current label for the file select button.
     *
     * @param {Selector} [form]       Passed to {@link formElement}.
     *
     * @return {string}
     */
    function fileSelectLabel(form) {
        var $form  = formElement(form);
        var branch = assetObject($form).select;
        var data   = canSelect($form) ? branch.enabled : branch.disabled;
        return data.label;
    }

    /**
     * The current tooltip for the file select button.
     *
     * @param {Selector} [form]       Passed to {@link formElement}.
     *
     * @return {string}
     */
    function fileSelectTooltip(form) {
        var $form  = formElement(form);
        var button = assetObject($form).select;
        var data   = canSelect($form) ? button.enabled : button.disabled;
        return data.tooltip;
    }

    /**
     * The label for the file select button when disabled.
     *
     * @param {Selector} [form]       Passed to {@link assetObject}.
     *
     * @return {string}
     */
    function fileSelectDisabledLabel(form) {
        return assetObject(form).select.disabled.label;
    }

    /**
     * The tooltip for the file select button when disabled.
     *
     * @param {Selector} [form]       Passed to {@link assetObject}.
     *
     * @return {string}
     */
    function fileSelectDisabledTooltip(form) {
        return assetObject(form).select.disabled.tooltip;
    }

    /**
     * Get the Emma data branch associated with the current type of form.
     *
     * @param {Selector} [form]       Passed to {@link isUpdateForm}.
     *
     * @return {{
     *      submit: {
     *          label:    string,
     *          tooltip:  string,
     *          enabled:  { label: string, tooltip: string },
     *          disabled: { label: string, tooltip: string }
     *      }
     *      cancel: {
     *          label:    string,
     *          tooltip:  string,
     *          enabled:  { label: string, tooltip: string },
     *          disabled: { label: string, tooltip: string }
     *      },
     *      select: {
     *          label:    string,
     *          tooltip:  string,
     *          enabled:  { label: string, tooltip: string },
     *          disabled: { label: string, tooltip: string }
     *      }
     * }}
     */
    function assetObject(form) {
        return isUpdateForm(form) ? Emma.Upload.Update : Emma.Upload.Create;
    }

    // ========================================================================
    // Functions - flash messages
    // ========================================================================

    /**
     * Show flash messages (unless disabled).
     *
     * @param {string} text
     */
    function showFlashMessage(text) {
        if (FEATURES.flash_messages) {
            flashMessage(text);
        }
    }

    /**
     * Show flash errors (unless disabled).
     *
     * @param {string} text
     */
    function showFlashError(text) {
        if (FEATURES.flash_errors) {
            flashError(text);
        }
    }

});
