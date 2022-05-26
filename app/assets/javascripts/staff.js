//= require diffDOM
//= require staff-refresh
//= require sortablejs/Sortable
//= require training
//= require croppie/croppie
//= require exif-js/exif.js
//= require jquery.watermark
//= require jquery-ui

document.addEventListener("turbolinks:load", function() {
  var training = {};
  setupTabHrefs();
  setupTrainingTriggers();
  resizeFlairLevelText();
  setupInterviewCalendarRefreshResize();
  setupStaffSpinner();
  markContactPreferencesValidity();
  setupLoggedInCheck();
  setupQuestionnaire();
  setupPhotoUpload();
  onFocusOutAjaxCall();
  installDatePicker();
  Inputmask().mask(document.querySelectorAll("input"));

  // cookie
  cookie = document.cookie.split(';')[1];
  console.log(cookie);
  if(cookie && !cookie.includes("flair_people_cookie=true")){
    $('body').append(`
      <div class="d-flex justify-content-center cookie" id="cookie-bar">
        <div class="d-flex justify-content-between" style="width:900px;margin-top: 30px;">
          <div class="cookie-content">
            Flair's website uses cookies to ensure you get the best possible experience. <a href="/privacy">Learn More!</a>
          </div>
          <button class="cookie-btn" id="cookie-btn">GOT IT!</button>
        </div>
      </div>
    `);
  }

  $('body').on('click', '#cookie-btn', function(){
    // document.cookie = "flair_people_cookie=true";
    setcookie(
      "flair_people_cookie",
      "true",
      (10*365)
    );
    $('#cookie-bar').remove();
  })
});

/**
 * Helper functions for custom form validation
 */
function markInvalid(e, message) {
    e.addClass('invalid');
    e.removeClass('valid');
    e.setCustomValidity(message);
}

function markValid(e) {
    e.addClass('valid');
    e.removeClass('invalid');
    e.setCustomValidity('');
}

function setupLoggedInCheck() {
  window.onfocus = function() {
    $.ajax({
      url: '/staff/check_if_logged_in',
      type: 'POST',
      success: function(data, status, xhr) {
        if (data.logged_in == false) {
          $('#login-popup').show();
        }
      }
    })
  }
}

/**
 * Open "tab-name" when linking to an anchor with "anchor-name"
 */

function setupTabHrefs() {
  $('.tab_href').click(function (e) {
    var href = $(this).attr('href');
    href = "#tab" + href.slice("anchor".length+1, href.length);
    $('a[href="' + href + '"]').tab('show');
  })
}

function setTabCheckMark(tabNavID,tabID,tabState) {
  var mark = $(".nav-tabs#" + tabNavID + " li[role=tablist] a#" + tabID + " div").get();
  if($(mark).length<1) return false;
  if(tabState) {
    $(mark).removeClass("fl-icon--checkmark-unchecked").addClass("fl-icon--checkmark");
  } else {
    $(mark).removeClass("fl-icon--checkmark").addClass("fl-icon--checkmark-unchecked");
  }
  return true;
}

/**
 * Training-specific functions
 */
function setupTrainingTriggers() {
  $("#tabs-training li a").not("#tab_training_intro").on('shown.bs.tab', function(){
    var target = $(this).attr("href");
    var module = $(this).data("module");
    var status = $(this).data("status") || null;
    fetchTrainingModule(module,target,status);
    fetchTrainingAudio();
  });
}

function setupTrainingSortables() {
  /**
   * FIX FOR IOS 10 DRAG-N-DROP
   * iOS 10 has a bug where event.preventDefault() will not cancel window scrolling.
   * We fix this by adding the following innocuous event handler:
   * (https://github.com/metafizzy/flickity/issues/457#issuecomment-254501356)
   */
  window.addEventListener( 'touchmove', function() {});
  $('.list--sortable').each(function(){
    var container = this;
    var sortable = Sortable.create(container, {
      animation: 150
    });
  });
}

function fetchTrainingModule(module, target, status) {
  $.ajax({
    url: '/staff/get_training_module',
    data: { module : module },
    type: 'POST',
    success: function(data) {
      $(target).html(data.module);
      training = new Training.TestModule($(target),module,status,data.index);
      setupTrainingSortables();
    },
    error: function(request, errorType, errorMessage) {
      console.log("error: " + errorMessage);
    }
  });
}

function v2_profile_bg_size(target) {
  height = $(target).height() + 400

  $('.v2-profile-applications-content-layer-1').css('height', height)
  $('.v2-profile-applications-content-layer-2').css('height', height)
  $('.v2-profile-applications-content-layer-3').css('height', height)
  $('.v2-profile-applications-content-layer-4').css('height', height)
}

function fetchTrainingAudio() {
  if($("#audioslot #fl-training__audio--correct").length > 0) return false;
  $.ajax({
    url: '/staff/get_training_module',
    data: { module : "audio" },
    type: 'POST',
    success: function(data) {
      $("#audioslot").html(data);
    },
    error: function(request, errorType, errorMessage) {
      console.log("error: " + errorMessage);
    }
  });
}
/**
 *
 */
  // Resize 'Flair Level' text to fit in container
function resizeFlairLevelText() {
  var flairLevel = $('#flair-level');
  var container = flairLevel.parent();
  var fontSize = container.width() / flairLevel.width() * parseInt(flairLevel.css('font-size'), 10);
  flairLevel.css('font-size', fontSize);
}

/**
 * Refresh/Resize the Interview Calendar when the tab is clicked on
 */
function setupInterviewCalendarRefreshResize() {
  $('a[href="#tab-interview-signup"]').on('shown.bs.tab', function (e) {
    $('#interview-flexslider').data('flexslider').resize();
    refreshOnlineInterviews();
  })
}

/**
 * HighlightBlankQuestionnaireFields
 */
function setupQuestionnaire() {
  $questions = $('.questions');
  $questions.find('.radio-row#heard-about-flair').find('input[type="radio"]').on('change', heardAboutFlairChanged);
  $questions.find('.radio-row#criminal-convictions').find('input[type="radio"]').on('change', criminalConvictionsChanged);
  $('a[href="#tab-questions"]').on('shown.bs.tab', function (e) {
    highlightQuestions();
  })
}

function highlightQuestions() {
  if ($('.questions').find('#questionnaire-is-new').length < 1) {
    highlightBlankFields($('.questions'));
  }
}

/**
 * Staff Spinner
 */

function setupStaffSpinner() {
  $('form').submit(function(e) {
    $('#upload-spinner').fadeIn();
  });
  $('.badge--button, .event-list.btn').click(function(e) {
    e.stopPropagation();
    $('#upload-spinner').fadeIn();
  });
  $('.spin').click(function(e) {
    $('#upload-spinner').fadeIn();
  })
}

/**
 * ID
 */

function nationality_changed() {
  $.ajax({
    url: '/staff/update_nationality',
    data: { prospect: { nationality_id: $('#nationality_id').val()}},
    type: 'POST',
    success: function(data, status, xhr) {
      $('.id_type').html(xhr.responseText);
      $('.id_type').find('form').submit(function(e) {
        $('#upload-spinner').fadeIn();
      });
      if ($('.non-eu').length > 0) {
        $('#non_eu_id_type_Work_Visa').change();
      }
    },
    error: function(request, errorType, errorMessage) {
      console.log("error: " + errorMessage)
    }
  })
}

function nationalityValue() {
  if($('#nationality_ireland').prop("checked")) {
    return $('#nationality_ireland').val()
  }
  if($('#nationality_united_kingdom').prop("checked")) {
    return $('#nationality_united_kingdom').val()
  }
  if($('#nationality_others').prop("checked")) {
    if ($('#nationality_id').val()) {
      return $('#nationality_id').val()
    } else {
      return $('#nationality_others').val()
    }
  }

  return $('#nationality_id').val()
}

function v2_nationality_changed() {
  if($('#nationality_others').prop('checked')) {
    $('#collapse').collapse('show')
  } else {
    $('#collapse').collapse('hide')
  }

  let nationality = nationalityValue()

  $('#prospect_nationality_id').val(nationality)
  $.ajax({
    url: '../staff/update_nationality',
    data: { prospect: { nationality_id: nationality}},
    type: 'POST',
    success: function(data, status, xhr) {
      $('#nationality_id').val(nationality)
      $('.id_type').html(xhr.responseText);
      $('.id_type').find('form').submit(function(e) {
        $('#upload-spinner').fadeIn();
      });
      if ($('.non-eu').length > 0) {
        $('#non_eu_id_type_Work_Visa').change();
      }

      if($('#v2-profile-identification-passport-checkbox-1').prop("checked")){
        check = true;
      }else if($('#v2-profile-identification-passport-checkbox-2').prop("checked")){
        check = false;
      }else {
        check = null;
      }

      if(check!=null){
        $.ajax({
          url: '../staff/check_non_uk',
          data: { check: check},
          type: 'GET',
          success: function(data, status, xhr) {
            $('.non_eu_id_upload_form').html(xhr.responseText);
          },
          error: function(request, errorType, errorMessage) {
            console.log("error: " + errorMessage)
          }
        })
      }

      v2_profile_bg_size('#v2-profile-applications-application-container')
    },
    error: function(request, errorType, errorMessage) {
      console.log("error: " + errorMessage)
    }
  })
}

function uk_id_type_changed() {
  $.ajax({
    url: '/staff/update_uk_id_type',
    data: { prospect: { uk_id_type: $('input[name=uk_id_type]:checked').val()}},
    type: 'POST',
    success: function(data, status, xhr) {
      $('.uk_id_upload_form').html(xhr.responseText);
      $('.uk_id_upload_form').find('form').submit(function(e) {
        $('#upload-spinner').fadeIn();
      });
    },
    error: function(request, errorType, errorMessage) {
      console.log("error: " + errorMessage)
    }
  })
}

function v2_uk_id_type_changed() {
  $.ajax({
    url: 'staff/update_uk_id_type',
    data: { prospect: { uk_id_type: $('input[name=uk_id_type]:checked').val()}},
    type: 'POST',
    success: function(data, status, xhr) {
      $('.uk_id_upload_form').html(xhr.responseText);
      $('.uk_id_upload_form').find('form').submit(function(e) {
        $('#upload-spinner').fadeIn();
      });
    },
    error: function(request, errorType, errorMessage) {
      console.log("error: " + errorMessage)
    }
  })
}

function non_eu_id_type_changed() {
    var id_type = $('input[name=non_eu_id_type]:checked').val();
    console.log("id_type:", id_type);
    $.ajax({
        url: '/staff/get_non_eu_id_view',
        data: { id_type: id_type},
        type: 'POST',
        success: function(data, status, xhr) {
            $('.non_eu_id_upload_form').html(xhr.responseText);
            $('.non_eu_id_upload_form').find('form').submit(function(e) {
                $('#upload-spinner').fadeIn();
            });
            if (id_type === 'Work Visa') {
              $('#visa-no-label').text('Visa Number')
            } else {
              $('#visa-no-label').text('Permit Number')
            }
        },
        error: function(request, errorType, errorMessage) {
            console.log("error: " + errorMessage)
        }
    });
}

function v2_non_eu_id_type_changed() {
    var id_type = $('input[name=non_eu_id_type]:checked').val();
    console.log("id_type:", id_type);
    $.ajax({
        url: '../staff/get_non_eu_id_view',
        data: { id_type: id_type},
        type: 'POST',
        success: function(data, status, xhr) {
            $('.non_eu_id_upload_form').html(xhr.responseText);
            $('.non_eu_id_upload_form').find('form').submit(function(e) {
                $('#upload-spinner').fadeIn();
            });
            if (id_type === 'Work Visa') {
              $('#visa-no-label').text('Visa Number')
            } else {
              $('#visa-no-label').text('Permit Number')
            }
        },
        error: function(request, errorType, errorMessage) {
            console.log("error: " + errorMessage)
        }
    });
}

/**
 * Bar type changed
 */

function bar_type_changed() {
  var value = $('.bar-license__type__select option:checked').val();
  if (value == 'english-pl' || value == 'scottish-pl') {
    $('.bar-license__sclps').addClass('hidden');
    $('.bar-license__personal-license').removeClass('hidden');
  }
  if (value == 'sclps-2-hr' || value == 'sclps-screen-shot') {
    $('.bar-license__personal-license').addClass('hidden');
    $('.bar-license__sclps').removeClass('hidden');
  }
}

/**
 * Contact Preferences Validation
 */

function markContactPreferencesValidity() {
  markPreferredTimeValidity();
  markPreferredOnlineContactMethod();
  markSkypeValidity();
  markFacetimeValidity();
  markPhoneValidity()
}

function markPreferredTimeValidity() {
  //If there are no preferred time checkboxes checked, display an error message on the morning checkbox on form submit
  var morning = $('#prospect_prefers_morning');
  if (morning.is(':checked') || $('#prospect_prefers_afternoon').is(':checked') || $('#prospect_prefers_early_evening').is(':checked') || $('#prospect_prefers_midweek').is(':checked') || $('#prospect_prefers_weekend').is(':checked')) {
    markValid(morning);
  } else {
    markInvalid(morning, 'Please select one or more times');
  }
}

function markPreferredOnlineContactMethod() {
  //If there are no preferred time checkboxes checked, display an error message on the morning checkbox on form submit
  var phone = $('#prospect_prefers_phone');
  if (phone.is(':checked') || $('#prospect_prefers_skype').is(':checked') || $('#prospect_prefers_facetime').is(':checked')) {
    markValid(phone);
  } else {
    markInvalid(phone, 'Please select one or more telephone/online contact preferences');
  }
}

function markSkypeValidity() {
  markPreferredValidity($('#prospect_prefers_skype'), $('#prospect_preferred_skype'), 'Skype ID');
}

function markFacetimeValidity() {
  markPreferredValidity($('#prospect_prefers_facetime'), $('#prospect_preferred_facetime'), 'Facetime Email or Phone Number');
}

function markPhoneValidity() {
  markPreferredValidity($('#prospect_prefers_phone'), $('#prospect_preferred_phone'), 'Phone Number');
}

function markPreferredValidity(typeField, valueField, type) {
  if (typeField.is(':checked') && valueField.val() == '') {
    markInvalid(valueField, 'Please enter your ' + type);
  } else {
    markValid(valueField);
  }
}

function highlightBlankFields($element) {
  var fieldsToHighlight = [];
  var fieldsToUnhighlight = [];
  var highlightClass = 'fl-form__row--highlight';

  var $text_inputs = $element.find(':text, textarea').not('.fl-form__optional').filter(':visible');
  $text_inputs.each(function(index) {
    if ($(this).val().length < 1) {
      fieldsToHighlight.push(this)
    } else {
      fieldsToUnhighlight.push(this)
    }
  });

  var $radio_rows = $element.find('.radio-row').not('.fl-form__optional').filter(':visible');
  $radio_rows.each(function(index) {
    if ($(this).find("input:checked").length < 1) {
      fieldsToHighlight.push(this)
    } else {
      fieldsToUnhighlight.push(this)
    }
  });

  var $date_input_group = $element.find('.date-input-group').not('.fl-form__optional').filter(':visible');
  $date_input_group.each(function(index) {
    if ($(this).find('select').filter(function() {return !this.value;}).length === 3) {
      fieldsToHighlight.push($(this).parent()[0]);
    } else {
      fieldsToUnhighlight.push($(this).parent()[0]);
    }
  });

  $.each(fieldsToHighlight, function(index, field) {
    var isHighlighted = ($(this).parent().attr('class') == highlightClass);
    if (isHighlighted !== true) {
      // $(this).wrap("<div class='" + highlightClass + "'></div>");
    }
  });

  $.each(fieldsToUnhighlight, function(index, field) {
    var isHighlighted = ($(this).parent().attr('class') == highlightClass);
    if (isHighlighted === true) {
      $(this).unwrap();
    }
  });
}

function unhighlightIfHighlighted($element) {
  $element.parent().each(function(index) {
    if ($(this).attr('class') == 'fl-form__row--highlight') {
      $element.unwrap();
    }
  })
}

/**
 * Questionnaire
 */

function heardAboutFlairChanged() {
  var $textbox = $('#heard_about_flair_other_text');
  if ($('#questionnaire_heard_about_flair_other').is(':checked') == true) {
    $textbox.disabled = false;
    $textbox.show();
  } else {
    $textbox.disabled = true;
    $textbox.hide();
    unhighlightIfHighlighted($textbox);
  }
}

function criminalConvictionsChanged() {
  var $fields = $('.has_criminal_convictions');
  if ($('#questionnaire_has_criminal_convictions_true').is(':checked') == true) {
    $fields.disabled = false;
    $fields.show();
  } else {
    $fields.disabled = true;
    $fields.hide();
    unhighlightIfHighlighted($fields);
  }
}

///// Photo Upload

///// Use Croppie with viewport the same size as the boundary
///// We add our own overlay to help align the head

function setupPhotoUpload() {
  $('.photo-edit').hide();
  if ($('.upload-photo__image').length > 0) {
    $('#photo-upload').hide()
  }
  $('#submit-photo').prop('disabled', true);

  var $croppie = $('.croppie-photo-preview');
  var width             = 240;
  var height            = 320;
  var $overlayHeight    = 240;
  var $overlayWidth     = 200;
  var $overlayTopOffset = -30;

  ///// Setup Overlay
  var $overlay = $("<div>", {class: 'croppie-photo-overlay'});
  var $overlay_inner = $("<div>", {class: 'croppie-photo-overlay-inner'});
  $overlay.append($overlay_inner);
  $overlay.css({
    width: width + 'px',
    height: height + 'px',
    top: height,
    'margin-top': -1*height
  });
  $overlay_inner.css({
    width:  $overlayWidth+'px',
    height: $overlayHeight+'px',
    top: $overlayTopOffset+'px'
  });

  ///// Setup Croppie
  $croppie.before($overlay);
  $croppie.croppie({
    boundary: {
      width:  width,
      height: height
    },
    viewport: {
      width: width,
      height: height,
    },
    enableExif: true
  });
  $('.croppie-photo-overlay').hide();
  $('.croppie-photo-preview').hide();
  $('#photo-input').on('change', function(e) {
    $('#upload-photo').css('display', 'none')
    $('.v2-upload-photo-caption-desk').css('display', 'none')
    $('.v2-upload-photo-caption-mobile').css('display', 'none')
    $('#submit-photo').css('display', '')
    $('.v2-upload-photo-caption-drag').css('display', '')
    // $('.existing-photo').hide();
    $('.v2-profile-photo-show-container').hide();
    $('.croppie-photo-preview').show();
    $('.croppie-photo-overlay').show();
    $('.photo-edit').show();
    parent_container = $('.cr-slider').parent();
    if($(parent_container).find('.v2-cs-slider-icon').length == 0){
      $(parent_container).prepend(`<div class="v2-cs-slider-icon"><div></div></div>`)
      $(parent_container).append(`<div class="v2-cs-slider-icon">&#x271A;</div>`)
    }
    $(parent_container).addClass('d-flex justify-content-center')
    var fr = new FileReader();
    fr.onload = function (e) {
      $croppie.croppie('bind', {
        url: e.target.result
      });
    };
    fr.readAsDataURL(this.files[0]);
    $('#submit-photo').prop('disabled', false);
  });
  $('#photo-form').on('submit', function() {
    var cropData = $('.croppie-photo-preview').croppie('get');
    $('#cropLeftX'  ).val(cropData['points'][0]);
    $('#cropTopY'   ).val(cropData['points'][1]);
    $('#cropRightX' ).val(cropData['points'][2]);
    $('#cropBottomY').val(cropData['points'][3]);
    $('#orientation').val(cropData['orientation'] == undefined ? 1 : cropData['orientation']);
    return true;
  });
}

function onFocusOutAjaxCall() {
  var formIds = [];
  $('form.edit_questionnaire input, select, textarea').not('.sports-outdoor, .bar-hospitality, .festivals-concerts, .merchandise-retail, .promotional-street, .reception-office').each(function () {
    if ($(this).attr('id') != null) {
      formIds.push("#" + $(this).attr('id'));
    }
  });
  $(formIds.join(", ")).on('focusout', function () {
    if ($("form.edit_questionnaire").length > 0) {
      $.ajax({
        url: $("form.edit_questionnaire").attr("action"),
        type: 'post',
        data: $("form.edit_questionnaire").serialize()
      });
    };
  });
}

function installDatePicker() {
  // var availableDates = ["1-6-2020","16-6-2020","17-6-2020"];
  if($("#interview-date-picker").length > 0) {
    availableDates = [];
    availableDatesForDsiplay = [];
    dates = $("#interview-date-picker").data('dates');
    dates = dates.map(function (date) {
      day = date.split('-')[2];
      if (!(date.split('-')[2] == '10' || date.split('-')[2] == '20' || date.split('-')[2] == '30'))
        day = day.replace('0', '');
      month = date.split('-')[1];
      if (!(date.split('-')[2] == '10'))
        month = month.replace('0', '');
      year = date.split('-')[0];
      // console.log(day+'-'+month+'-'+year)
      availableDates.push(day + '-' + month + '-' + year);
      availableDatesForDsiplay.push(date.split('-')[2] + '-' + date.split('-')[1] + '-' + year)
    });

    function available(date) {
      dmy = date.getDate() + "-" + (date.getMonth() + 1) + "-" + date.getFullYear();
      if ($.inArray(dmy, availableDates) != -1) {
        return true;
      } else {
        return false;
      }
    }

    // console.log('dates___', availableDates)

    $('#' + availableDatesForDsiplay[0]).show();
    $("#interview-date-picker").datepicker({
      dateFormat: 'dd-mm-yy',
      defaultDate: availableDatesForDsiplay[0],
      onSelect: function (date) {
        $('.available-slots').hide();
        $('#' + date).show();
        editUI()
      },
      beforeShowDay: function (dt) {
        return [available(dt), ""];
      }
    });

    function editUI() {
      $('.ui-state-default').css('font-size', '18px');
      $('.ui-state-default').css('text-align', 'left');
      $('.ui-state-default').css('height', '40px');
      $('.ui-state-default').css('width', 'auto');
      $('.ui-state-default').css('background-color', 'orange');
      $('.ui-widget.ui-widget-content').css('width', '84%');
      $('.ui-widget.ui-widget-content').css('background', 'none');
      $('.ui-widget.ui-widget-content').css('background', 'unset');
      $('.ui-widget.ui-widget-content').css('border', '0px');
      $('.ui-datepicker .ui-datepicker-next').css('right', '29%');
      $('.ui-datepicker .ui-datepicker-prev').css('left', '29%');
      $('.ui-datepicker .ui-datepicker-header').css('background', 'none');
      $('.ui-datepicker .ui-datepicker-header').css('background', 'unset');
      $('.ui-datepicker .ui-datepicker-header').css('border', '0px');
      $('.ui-datepicker td').css('padding', '-1px');
      $('.ui-datepicker td').css('border', '1px solid');
      $('.ui-datepicker-unselectable .ui-state-default, .ui-state-disabled  .ui-state-default').css('background-color', 'white');
      $('.ui-datepicker-unselectable, .ui-state-disabled').css('opacity', '1');
      $('.ui-datepicker-other-month.ui-datepicker-unselectable.ui-state-disabled').css('border', '0px solid');
      $('.ui-datepicker-week-end.ui-datepicker-other-month.ui-datepicker-unselectable.ui-state-disabled').css('border', '0px solid');
      // $('.ui-datepicker-other-month').css('border', '0px')

    }

    editUI();
  }
}

$(document).ready(function(){

  $('body').on('click', '.v2-flash-bg', function(){
    $(".v2-flash-bg").fadeOut();
  })

  // cookie
  cookie = document.cookie.split(';')[1];
  console.log(cookie);
  if(cookie && !cookie.includes("flair_people_cookie=true")){
    $('body').append(`
      <div class="d-flex justify-content-center cookie" id="cookie-bar">
        <div class="d-flex justify-content-between" style="width:900px;margin-top: 30px;">
          <div class="cookie-content">
            Flair's website uses cookies to ensure you get the best possible experience. <a href="/privacy">Learn More!</a>
          </div>
          <button class="cookie-btn" id="cookie-btn">GOT IT!</button>
        </div>
      </div>
    `);
  }

  $('body').on('click', '#cookie-btn', function(){
    // document.cookie = "flair_people_cookie=true";
    setcookie(
      "flair_people_cookie",
      "true",
      (10*365)
    );
    $('#cookie-bar').remove();
  })

})

// Profile Staff
function click_category(category) {
  $(`#v2-profile-application-header-${category} .v2-profile-application-header-container`).find('img').each(function(){
      $(this).css('display', 'none')
  })
  done = $(`#v2-profile-application-header-${category} .done`).attr('done')
  $(`#v2-profile-application-header-${category}  .v2-profile-application-header-container #${done == "true" ? 'done' : 'not_done'}`).css('display', '')
}

function setcookie(cname, cvalue, exdays) {
  var d = new Date();
  d.setTime(d.getTime() + (exdays*24*60*60*1000));
  var expires = "expires="+ d.toUTCString();
  document.cookie = cname + "=" + cvalue + ";" + expires + ";path=/";
}

function new_employee_true() {
  $.ajax({
    url: '/staff/change_new_employee_status',
    type: 'POST',
    success: function(data) {

    }
  })
}
