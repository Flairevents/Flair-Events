$(document).ready(function(){
  // Get the show event id
  show_event_id = $('#show_event_id').attr('show_event_id');
  mobile = $('#show_event_id').attr('mobile');

  if(show_event_id != "" && show_event_id != undefined){
    console.log(show_event_id)
    $([document.documentElement, document.body]).animate({
        scrollTop: $(`#${show_event_id}-header`).offset().top - 100
    }, 500);
  }
  ///////////////////////////////////////////////////////////////////////////////////////

  filter_events = $('.filter_events')

  filter_events.each(function(){
    if(!$(this).find('a').children('img').last().hasClass('hide')){
      switch ($(this).attr('category_name')) {
        case `Commercial`:
          li = $('#job-board-Commercial a')
          var selectedJobType = $(li).find('span').text().toLowerCase();

          $(".btn-all-jobs").removeClass('hide');
          $(".latest-jobs-text").text(selectedJobType.charAt(0).toUpperCase() + selectedJobType.slice(1) + ' Jobs');
          $("#selectedCategory").val(selectedJobType).trigger('change');
          break;

        case `Sports`:
          li = $('#job-board-Sports a')
          var selectedJobType = $(li).find('span').text().toLowerCase();

          $(".btn-all-jobs").removeClass('hide');
          $(".latest-jobs-text").text(selectedJobType.charAt(0).toUpperCase() + selectedJobType.slice(1) + ' Jobs');
          $("#selectedCategory").val(selectedJobType).trigger('change');
          break;

        case `Promotional`:
          li = $('#job-board-Promotional a')
          var selectedJobType = $(li).find('span').text().toLowerCase();

          $(".btn-all-jobs").removeClass('hide');
          $(".latest-jobs-text").text(selectedJobType.charAt(0).toUpperCase() + selectedJobType.slice(1) + ' Jobs');
          $("#selectedCategory").val(selectedJobType).trigger('change');
          break;

        case `Logistics`:
          li = $('#job-board-Logistics a')
          var selectedJobType = $(li).find('span').text().toLowerCase();

          $(".btn-all-jobs").removeClass('hide');
          $(".latest-jobs-text").text(selectedJobType.charAt(0).toUpperCase() + selectedJobType.slice(1) + ' Jobs');
          $("#selectedCategory").val(selectedJobType).trigger('change');
          break;

        case `Events`:
          li = $('#job-board-Events a')
          var selectedJobType = $(li).find('span').text().toLowerCase();

          $(".btn-all-jobs").removeClass('hide');
          $(".latest-jobs-text").text(selectedJobType.charAt(0).toUpperCase() + selectedJobType.slice(1) + ' Jobs');
          $("#selectedCategory").val(selectedJobType).trigger('change');
          break;

        case `Hospitality`:
          li = $('#job-board-Hospitality a')
          var selectedJobType = $(li).find('span').text().toLowerCase();

          $(".btn-all-jobs").removeClass('hide');
          $(".latest-jobs-text").text(selectedJobType.charAt(0).toUpperCase() + selectedJobType.slice(1) + ' Jobs');
          $("#selectedCategory").val(selectedJobType).trigger('change');
          break;

        default:
          break;
      }
    }
  })

  $('body').on('click', ".view-details", function(e){
    e.preventDefault();
    var accordionParent = $(this).closest(".job-accordion");
    console.log(accordionParent)
    var panel = accordionParent.next();
    console.log(panel)

    if (panel.is(':visible')) {
      accordionParent.removeClass('active')
      $(this).removeClass("less-details").text("VIEW DETAILS");
      panel.hide();
      event_adjust_bg('#v2-events-bg-indicator', 500)
    } else {
      $('.view-details').each(function(){
        var accordionParent = $(this).closest(".job-accordion");
        var panel = accordionParent.next();

        if (panel.is(':visible')) {
          accordionParent.removeClass('active')
          $(this).removeClass("less-details").text("VIEW DETAILS");
          panel.hide();
        }
      })
      accordionParent.addClass('active')
      $(this).addClass("less-details").text("LESS DETAILS");
      panel.show();
      event_adjust_bg('#v2-events-bg-indicator', 600)
    }
  });

  $('body').on('click', ".view-details-mobile", function(e){
    e.preventDefault();
    var panel = $(this).closest(".job-accordion-panel");
    console.log(panel)

    if (panel.is(':visible')) {
      panel.hide();
      event_adjust_bg('#v2-events-bg-indicator', 500)
    } else {
      $('.view-details').each(function(){

        if (panel.is(':visible')) {
          panel.hide();
        }
      })
      panel.show();
      event_adjust_bg('#v2-events-bg-indicator', 600)
    }
  });

  $('body').on('click', '.job-board-mobile', function(){
    var accordionParent = $(this);
    var panel = accordionParent.next();

    if (panel.is(':visible')) {
      accordionParent.removeClass('active')
      panel.hide();
      event_adjust_bg('#v2-events-bg-indicator', 500)
    } else {
      $('.job-board-mobile').each(function(){
        var accordionParent = $(this);
        var panel = accordionParent.next();

        if (panel.is(':visible')) {
          accordionParent.removeClass('active')
          panel.hide();
        }
      })
      accordionParent.addClass('active')
      panel.show();
      event_adjust_bg('#v2-events-bg-indicator', 600)
    }
  })

  // $(".v2-job-nav li").on("click", function(){
  //   var dots = $(this).children().last();
  //   var unSelectedImg = $(this).children('img').first();
  //   var selectedImg = $(this).children('img').last();
  //   var selectedJobType = $(this).find('span').text().toLowerCase();

  //   $(this).addClass('active');
  //   $(this).parent().find('.unselected').removeClass('hide');
  //   $(this).parent().find('.selected').addClass('hide');
  //   $(this).parent().find(".three-dots").addClass("hide");

  //   dots.removeClass("hide");
  //   unSelectedImg.addClass('hide');
  //   selectedImg.removeClass('hide');

  //   $(".btn-all-jobs").removeClass('hide');
  //   $(".latest-jobs-text").text(selectedJobType.charAt(0).toUpperCase() + selectedJobType.slice(1) + ' Jobs');
  //   $("#selectedCategory").val(selectedJobType).trigger('change');
  // });

  $(".btn-all-jobs").on('click', function(){
    prospect = $('#prospect_check').attr('prospect')
    window.location.href = `${prospect == "true" ? '/staff' : ''}/events`;
  });

  $(".job-accordion-panel .job-desc").on('click', function(e){
    // var parentPanel = $(this).closest('.job-accordion-panel');
    // var chosenJobs =  parentPanel.data('chosen-jobs') === undefined ? [] : parentPanel.data('chosen-jobs');

    // if ($(this).hasClass('job-selected')) {
    //   var jobIndex = chosenJobs.indexOf($(this).text());

    //   if (jobIndex > -1) {
    //     chosenJobs.splice(jobIndex,1);
    //   }

    //   if (chosenJobs.length <= 2) {
    //     $(this).removeClass('job-selected');
    //   }
    // } else {
    //   if (chosenJobs.length < 2) {
    //     if (!chosenJobs.includes($(this).text())) {
    //       chosenJobs.push($(this).text());
    //     }
    //     $(this).addClass('job-selected');
    //   }
    // }

    // parentPanel.data('chosen-jobs', chosenJobs);

    // check if  selected
    e.preventDefault();
    id = $(this).attr('id')
    event_id = $(this).attr('event_id')
    // description = $(this).attr('description') || " "
    job_description = $(this).attr('job_description') || " "
    uniform_info = $(this).attr('uniform_info') || " "
    shift_info = $(this).attr('shift_info') || " "
    number_of_jobs = $(this).attr('number_of_jobs') || " "
    pay_18 = $(this).attr('pay_18') || 0
    hp_18 = $(this).attr('hp_18') || 0
    pay_21 = $(this).attr('pay_21') || 0
    hp_21 = $(this).attr('hp_21') || 0
    pay_25 = $(this).attr('pay_25') || 0
    hp_25 = $(this).attr('hp_25') || 0

    pay_18 = parseFloat(pay_18).toFixed(2)
    hp_18 = parseFloat(hp_18).toFixed(2)
    pay_21 = parseFloat(pay_21).toFixed(2)
    hp_21 = parseFloat(hp_21).toFixed(2)
    pay_25 = parseFloat(pay_25).toFixed(2)
    hp_25 = parseFloat(hp_25).toFixed(2)
    $(`.job-button-${event_id}`).each(function () {
      $(this).removeClass('job-selected')
    })

    $(this).addClass('job-selected')

    if($(`#radio-${id}`).prop('checked') == false){
      $(`#radio-${id}`).prop('checked', true);

      // Show data
      // $(`#description-${event_id}`).text(description)
      $(`#job-description-${event_id}`).text(job_description)
      $(`#uniform-${event_id}`).text(uniform_info)
      $(`#shift-${event_id}`).text(shift_info)
      $(`#number-of-jobs-${event_id}`).text(number_of_jobs)

      // check if pay rates are the same
      rate_array = [pay_18, pay_21, pay_25].filter(onlyUnique)

      // check if prospect is present
      prospect = $('#prospect_check').attr('prospect')
      // get age of prospect
      age = $('#prospect_age').attr('age')
      if(prospect == "true"){
        switch (age) {
          case "23":
            main_rate = pay_25
            break;

          case "21":
            main_rate = pay_21
            break;

          case "18":
            main_rate = pay_18
            break;

          default:
            main_rate = 0
            break;
        }
      }

      if(rate_array.length < 2){
        if(prospect == "true"){
          $(`#rate-${age}-${event_id}`).css('display','block')
          $(`#main-rate-${event_id}`).text(`£${pay_25}`)

          $(`#rate-${age}-${event_id}`).text(`£${pay_25}(£${(pay_25 - hp_25).toFixed(2)} + £${hp_25})`)
        }else{
          $(`#main-rate-${event_id}`).text(`£${pay_25}`)
          $(`#rate-23-${event_id}`).css('display','block')
          $(`#rate-21-${event_id}`).css('display','none')
          $(`#rate-18-${event_id}`).css('display','none')

          $(`#rate-23-${event_id}`).text(`£${pay_25}(£${(pay_25 - hp_25).toFixed(2)} + £${hp_25})`)
        }
      }else if(pay_25 == pay_21){
        $(`#main-rate-${event_id}`).text(`£${prospect == "true" ? main_rate : pay_21}`)
        $(`#rate-23-${event_id}`).css('display','block')
        $(`#rate-21-${event_id}`).css('display','block')
        $(`#rate-18-${event_id}`).css('display','block')

        $(`#rate-23-${event_id}`).text(`${prospect == "true" ? '' : '23+ years:'} £${pay_25}(£${(pay_25 - hp_25).toFixed(2)} + £${hp_25})`)
        $(`#rate-21-${event_id}`).text(`${prospect == "true" ? '' : '21-22 years:'} £${pay_25}(£${(pay_25 - hp_25).toFixed(2)} + £${hp_25})`)
        $(`#rate-18-${event_id}`).text(`${prospect == "true" ? '' : '18-20 years:'} £${pay_18}(£${(pay_18 - hp_18).toFixed(2)} + £${hp_18})`)
      }else if(pay_21 == pay_18){
        $(`#main-rate-${event_id}`).text(`£${prospect == "true" ? main_rate : pay_25}`)
        $(`#rate-23-${event_id}`).css('display','block')
        $(`#rate-21-${event_id}`).css('display','block')
        $(`#rate-18-${event_id}`).css('display','block')

        $(`#rate-23-${event_id}`).text(`${prospect == "true" ? '' : '23+ years:'} £${pay_25}(£${(pay_25 - hp_25).toFixed(2)} + £${hp_25})`)
        $(`#rate-21-${event_id}`).text(`${prospect == "true" ? '' : '21-22 years:'} £${pay_21}(£${(pay_21 - hp_21).toFixed(2)} + £${hp_21})`)
        $(`#rate-18-${event_id}`).text(`${prospect == "true" ? '' : '18-20 years:'} £${pay_21}(£${(pay_21 - hp_21).toFixed(2)} + £${hp_21})`)
      }else{
        $(`#main-rate-${event_id}`).text(`£${prospect == "true" ? main_rate : pay_25}`)
        $(`#rate-23-${event_id}`).css('display','block')
        $(`#rate-21-${event_id}`).css('display','block')
        $(`#rate-18-${event_id}`).css('display','block')

        $(`#rate-23-${event_id}`).text(`${prospect == "true" ? '' : '23+ years:'} £${pay_25}(£${(pay_25 - hp_25).toFixed(2)} + £${hp_25})`)
        $(`#rate-21-${event_id}`).text(`${prospect == "true" ? '' : '21-22 years:'} £${pay_21}(£${(pay_21 - hp_21).toFixed(2)} + £${hp_21})`)
        $(`#rate-18-${event_id}`).text(`${prospect == "true" ? '' : '18-20 years:'} £${pay_18}(£${(pay_18 - hp_18).toFixed(2)} + £${hp_18})`)
      }
    }
  });
  function openAndHideAccording (refrence) {
    var accordionParent = $(refrence).closest(".job-accordion");
    var panel = accordionParent.next();
    console.log(panel)
    if (panel.is(':visible')) {
      accordionParent.removeClass('active')
      $(refrence).parent().find('.view-details').removeClass("less-details").text("VIEW DETAILS");
      panel.hide();
      event_adjust_bg('#v2-events-bg-indicator', 500)
    } else {
      $('.view-details').each(function(){
        var accordionParent = $(refrence).closest(".job-accordion");
        var panel = accordionParent.next();

        if (panel.is(':visible')) {
          accordionParent.removeClass('active')
          $(refrence).parent().find('.view-details').removeClass("less-details").text("VIEW DETAILS");
          panel.hide();
        }
      })
      accordionParent.addClass('active')
      $(refrence).parent().find('.view-details').addClass("less-details").text("LESS DETAILS");
      panel.show();
      event_adjust_bg('#v2-events-bg-indicator', 600)
    }
  }

  $('.apply-job').on('click', function(){
    event_id = $(this).attr('event_id');
    // check if prospect is present
    prospect = $('#prospect_check').attr('prospect')
    if(prospect == "true"){
      form = $(`#event-${event_id}`)
      check_details = $(this).parent().find('.view-details')
      var accordionParent = $(this).closest(".job-accordion");
      var panel = accordionParent.next();
      if(panel.is(':visible')) {
        if($(check_details).text() == "VIEW DETAILS"){
          job_id = $(this).attr('default_job_id')
        }else{
          job_id = $(form).find('input[name="job"]:checked').val()
        }
      } else if (window.outerWidth < 600) {
        job_id = $(form).find('input[name="job"]:checked').val()
      } else if($(form).find('input[name="job"]').length == 1) {
        var job_id = $(this).attr('default_job_id')
      } else {
        var job_id;
      }
      if(job_id == undefined){
        openAndHideAccording(this);
        // $('body').append(`
        //   <div class="v2-flash-bg">
        //     <div class="v2-flash-body">
        //       <i class="icon--notice-flag"></i>
        //       <div class="v2-flash-message">Please Choose A Job To Apply</div>
        //       <a class="fl-flash__close-btn" onclick="$(&quot;.v2-flash-bg&quot;).fadeOut()">
        //           <span>Close</span>
        //       </a>
        //     </div>
        //   </div>
        // `)
      }else{
        $.ajax({
          url: '/staff/select_event',
          type: 'POST',
          data: {
            job: job_id,
            event_id: event_id
          },
          success: function(data) {
            $('body').append(`
              <div class="v2-flash-bg">
                <div class="v2-flash-body-job-board">
                  <h2 class="v2-flash-title">Request sent.</h2>

                  <div class="v2-flash-message">Keep an eye out for further communication from us as the start date draws closer. We look forward to potentially working with you.</div>

                  <center>
                    <div class="v2-flash-button-no" onclick="$(&quot;.v2-flash-bg&quot;).fadeOut()">Got it</div>
                  </center>
                </div>
              </div>
            `)

            // remove tags and add pending tag
            $(`#event-${event_id}-tags`).html(`
              <div class="badge badge--event-status badge--orange contract-btn">Pending</div>
            `)
            // add class to create elipsis
            $(`#${event_id}-header`).find('.event-title').addClass('event-title-elip')
            // Change button
            $(`#event-${event_id}-btns`).html(`
              <button class="view-details mobile-hide mb-5"> VIEW DETAILS </button>
              <button class="web-hide view-details-mobile mb-5"> LESS DETAILS </button>
              <br>
              <a href="/staff/deselect_event/${event_id}">
                <button class="cancel-job"> CANCEL REQUEST </button>
              </a>
            `)
            // change view details
            job_name = $(`.job-button-${event_id}.job-selected`).text()
            $(`#event-${event_id}-jobs-container`).html(`
              <label class="applied-position normal-bold-text" style="text-align:right;width:100%;margin-left: 5px;">Applied Position</label>
              <div class="v2-explore-jobs-list-event-job-title" style="width: 305px;margin-bottom: 0;margin-left: 5px;">${job_name}</div>
            `)
          }
        })
      }
    }else{
      window.location.href = '/login';
    }
  })

  $('#v2-staff-cancel-application').on('click', function(){
    job_name = $(this).attr("job_name")
    event_id = $(this).attr("event_id")
    event_name = $(this).attr("event_name")

    $('body').append(`
      <div class="v2-flash-bg">
        <div class="v2-flash-body-job-board">
          <h2 class="v2-flash-title">Cancel Job Application</h2>

          <div class="v2-flash-message">Are you sure you want to cancel your Job Application? <br> "<b>${job_name}</b>" position at ${event_name}</div>

          <center>
            <div style="display: inline-flex;">
              <a href="/staff/deselect_event/${event_id}" rel="nofollow">
                <div class="v2-flash-button" style="width: 150px;">Confirm</div>
              </a>
              <div class="v2-flash-button-no" onclick="$(&quot;.v2-flash-bg&quot;).fadeOut()" style="width: 120px;">NO</div>
            </div>
          </center>
        </div>
      </div>
    `)
    return false
  })
  // adjust height of bg
  event_adjust_bg('#v2-events-bg-indicator', 500)

  function event_adjust_bg(div, add_height) {
    height = $(`${div}`).height() + add_height
    $('.v2-profile-applications-content-layer-1').css('height', height)
    $('.v2-profile-applications-content-layer-2').css('height', height)
    $('.v2-profile-applications-content-layer-3').css('height', height)
    $('.v2-profile-applications-content-layer-4').css('height', height)
  }

  function onlyUnique(value, index, self) {
    return self.indexOf(value) === index;
  }
});
