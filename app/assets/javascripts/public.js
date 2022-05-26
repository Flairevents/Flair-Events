// This will compile into a file which contains all the JS needed for the Flair "Public Zone" pages
//= require jquery
//= require jquery_ujs
//= require proper.min
//= require boostrap.min
//= require turbolinks
//= require turbolinks-anchors
// = require webshims/polyfiller
//= require greensock/dist/TweenMax
//= require jquery.carouFredSel
//= require flexslider/jquery.flexslider
//= require bootstrap3/dist/js/bootstrap
//= require bowser/bowser
//= require slick.min
//= require inputmask/dist/inputmask
//= require inputmask/dist/bindings/inputmask.binding
// Lets not require social
//

var $ = jQuery;

$.webshims.setOptions('basePath', '/webshims/1.16.0/shims/');
$.webshims.polyfill('forms');

document.addEventListener("turbolinks:load", function() {
    // $('.v2-jobs-slider').slick({
    //     slidesToShow: 10,
    //     dots: true,
    //     autoplay: true,
    //     autoplaySpeed: 1000,
    //     centerMode: true,
    // })
    $('body').on('click', '.v2-flash-bg', function(){
        $(".v2-flash-bg").fadeOut();
    })
    var isIpad = window.outerWidth < 1025;
    $('.v2-flash-bg').click(function (){
        $(".v2-flash-bg").fadeOut();
    })
    if(isIpad) {
        $('.company-logos').slick({
            dots: true,
            slidesToShow: 5,
            autoplay: true,
            autoplaySpeed: 1000,
            centerMode: true,
        })
    }
    $('.testimonial-slider-containers').flexslider({
        animation: "slide",
        animationSpeed: 500,
        slideshow:true,
        // controlsContainer: $(".custom-pagination"),
        customDirectionNav: $(".box-9-content .arrows")
    });
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
    return $(this).updatePolyfill();
});

document.addEventListener("turbolinks:load", function() {
    // store the slider in a local variable
    var $window = $(window),
        flexslider;

    // tiny helper function to add breakpoints
    function getGridSize() {
        return (window.innerWidth < 768) ? 1 :
               (window.innerWidth < 992) ? 2 : 3;
    }

    // tiny helper function to add breakpoints
    function getGridSizeFour() {
        return (window.innerWidth < 768) ? 1 :
               (window.innerWidth < 992) ? 3 : 4;
    }

    // check grid size on resize event
    $window.resize(function() {
        if (typeof flexslider !== 'undefined') {
            var gridSize = getGridSize();
            flexslider.vars.minItems = gridSize;
            flexslider.vars.maxItems = gridSize;
        }
    });

    function activateClientCarousel() {
        $('.client-logos__vert-carousel').each(function(index, carousel){
            $(carousel).carouFredSel({
                items: 1,
                auto: {
                    duration: 1000
                },
                direction: "down"
            });
        });
        setTimeout(function () {
            $('.client-logos__vert-carousel').each(function(index, carousel){
                $(carousel).trigger('pause');
                setTimeout(function () {
                    $(carousel).trigger('resume');
                }, 300 * index);
            });
        }, 4000);
    }

    function activateGenericSlider() {
        $('.slider--generic').flexslider({
            animation: "slide",
            slideshow: false,
            nextText: "",
            prevText: ""
        });
    }

    function activateHomeCarousel() {
        $('.home-carousel').flexslider({
            animation: "slide",
            directionNav: false,
            slideshow: true,
            slideshowSpeed: 8000,
            nextText: "",
            prevText: "",
            start: function(){
              $('.home-carousel .slides li').height('auto').css('visibility', 'visible');
            }
        });
    }

    function activateTestimonialCarousel() {
        $('.testimonial-carousel').flexslider({
            animation: "slide",
            nextText: "",
            prevText: ""
        });
    }

    function activateInformationSliders() {
        $('.advantage-slider').flexslider({
            animation: "slide",
            nextText: "",
            prevText: "",
            itemWidth: 300,
            slideshow: false,
            minItems: getGridSizeFour(), // use function to pull in initial value
            maxItems: getGridSizeFour() // use function to pull in initial value
        });

        $('.staff-carousel').flexslider({
            animation: "slide",
            nextText: "",
            prevText: "",
            itemWidth: 300,
            slideshow: false,
            minItems: getGridSize(), // use function to pull in initial value
            maxItems: getGridSize() // use function to pull in initial value
        });
    }

    // An expandable table or list is one where the top part of the table or list is visible
    // and can be expanded when you click on a button

    function activateExpandables() {
        $('.table-expandable').parent().after('<a href="#" class="expand-button" onClick="toggleExpandableTable(this);  return false;">Show More</a>');

        $('.list-expandable').after('<a href="#" class="expand-button" onClick="toggleExpandableList(this);  return false;">Show More</a>');

        if ($('.expand-button').length) {
            // When the user scrolls
            $(window).scroll(function() {
                // For each button
                $('.accordion-item__expanded + .expand-button').each(function(index, button) {
                    var $button = $(button);
                    var $table = $(button).prev();

                    // If the bottom edge of the table is visible, then don't affix the button

                    var scrollBottom = $(window).scrollTop() + $(window).height();
                    var rect = cumulativeOffset($table.get(0));
                    var bottom = rect.top + $table.height();
                    if (scrollBottom > bottom) {
                        $button.removeClass('affix');
                    } else {
                        $button.addClass('affix');
                    }
                    // Otherwise affix the button
                });
            });
        }

        $('#tab-joining-flair a').remove();
        $('#tab-post-event a').remove();
    }

    // An accordion table or list is when you can expand and collapse individual items

    function activateAccordions() {
        $('.accordion-item').find('.header').click(function(e){
          accordionHeaderClick(e);
        });
    }

    function activateEventCategoryTabs() {
      $('.events-list').find('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
        changeEventCategory($(e.target).attr('category'));
      });
    }

    function activateEventMap() {
        $('#map > *').click(function(){
            changeEventRegion(this.id);
            return false;
        });
    }

    function activateRegionFilterDropdown() {
        $('.region-filter-dropdown').change(function(){
            if (this.value == "All_UK") {
              showAllRegions();
            } else {
              changeEventRegion(this.value);
            }
            return false;
        });
    }

    function activateFlexsliders() {
        $('.flexslider').flexslider();
    }

    function activateHowPeopleAreUsingUsHover() {
        $('.fl-how-people-are-using-us').hover(
            function() {
                $(this).addClass('hover');
            },
            function() {
                $(this).removeClass('hover');
            }
        );
    }

    function activateWageBreakdownButton() {
        $('.event-blurb-wage-breakdown-btn').click(function() {
            $(this).parent().next('.event-blurb-wage-breakdown').toggleClass('hidden');
        });
    }


    function showScrollTabHints() {
      $('.nav-tabs--scroll').each(function(){
        if ($(this).width() < this.scrollWidth) {
          $(this).addClass('nav-tabs--scroll--hints');
          $(this).scroll(function(){
            $(this).removeClass('nav-tabs--scroll--hints');
          });
          /*
          $('.nav-tabs--scroll--hints::after').click(function(){
            console.log($(this));
            $(this).animate({
              scrollLeft: 100
            });
          });
          */
        }
      });
    }

    activateGenericSlider();

    activateFlexsliders();

    activateInformationSliders();

    activateTestimonialCarousel();

    activateHomeCarousel();

    activateClientCarousel();

    activateExpandables();

    activateAccordions();

    activateEventMap();

    activateHowPeopleAreUsingUsHover();

    activateEventCategoryTabs();

    showScrollTabHints();

    activateRegionFilterDropdown();

    activateWageBreakdownButton();


    //Display message if browser does not support newer features
    // - flexbox
    // - css calc()
    // - Visibility API
    if( (bowser.msie && bowser.version < 10) ||
        (bowser.chrome && bowser.version < 21) ||
        (bowser.firefox && bowser.version < 28) ||
        (bowser.android && bowser.version < 4.4) ||
        (bowser.ios && bowser.version < 7.1) ||
        (bowser.opera && bowser.version < 15) ||
        (bowser.safari && bowser.version < 7.1) ||
        (bowser.blackberry && bowser.version < 7)
      ) {
      $('#legacy_browser').show();
    }
    $('#legacy_browser').click(function() {
      $('#legacy_browser').hide();
    });

    $('.event-list__item').on('mouseenter mouseleave click', highlightMapRegionListItemElementAttribute);

    //FacebookSDK.load();
    //TwitterSDK.load();

    function swipedetect(el, callback){

        var touchsurface = el,
            swipedir,
            startX,
            startY,
            distX,
            distY,
            threshold = 50, //required min distance traveled to be considered swipe
            restraint = 100, // maximum distance allowed at the same time in perpendicular direction
            allowedTime = 500, // maximum time allowed to travel that distance
            elapsedTime,
            startTime,
            handleswipe = callback || function(swipedir){}

        touchsurface.addEventListener('touchstart', function(e){
            var touchobj = e.changedTouches[0]
            swipedir = 'none'
            dist = 0
            startX = touchobj.pageX
            startY = touchobj.pageY
            startTime = new Date().getTime() // record time when finger first makes contact with surface
            e.preventDefault()
        }, false)

        touchsurface.addEventListener('touchmove', function(e){
            e.preventDefault() // prevent scrolling when inside DIV
        }, false)

        touchsurface.addEventListener('touchend', function(e){
            var touchobj = e.changedTouches[0]
            distX = touchobj.pageX - startX // get horizontal dist traveled by finger while in contact with surface
            distY = touchobj.pageY - startY // get vertical dist traveled by finger while in contact with surface
            elapsedTime = new Date().getTime() - startTime // get time elapsed
            if (elapsedTime <= allowedTime){ // first condition for awipe met
                if (Math.abs(distX) >= threshold && Math.abs(distY) <= restraint){ // 2nd condition for horizontal swipe met
                    swipedir = (distX < 0)? 'left' : 'right' // if dist traveled is negative, it indicates left swipe
                }
                else if (Math.abs(distY) >= threshold && Math.abs(distX) <= restraint){ // 2nd condition for vertical swipe met
                    swipedir = (distY < 0)? 'up' : 'down' // if dist traveled is negative, it indicates up swipe
                }
            }
            handleswipe(swipedir)
            e.preventDefault()
        }, false)
    }
   var jobCards = document.getElementsByClassName('job-inner-container');
    for(let index=0; index < jobCards.length; index++) {
        swipedetect(jobCards[index], function (direction) {
            console.log(direction, 'swap')
            if(direction === 'right') {
                // debugger;
                $('.left-slide').trigger('click')
            } else if(direction === 'left') {
                $('.right-slide').trigger('click')
            }
        })
    }
});

function toggleExpandableTable(button) {
    var $table = $(button).prev();

    // Expand the table if not already expanded
    if (! $table.hasClass('active')) {
        $table.addClass('active');
        $(button).addClass('affix');
        $(button).text('Close');
    } else {
        $table.removeClass('active');
        $(button).text('Show More');
        $(button).removeClass('affix');
    }
}

function toggleExpandableList(button) {
    var $list = $(button).prev();

    // Expand the table if not already expanded
    if (! $list.hasClass('active')) {
        $list.addClass('active');
        $(button).addClass('affix');
        $(button).text('Close');
    } else {
        $list.removeClass('active');
        $(button).text('Show More');
        $(button).removeClass('affix');
    }
}

function changeEventCategory(category) {
  $('#event-category').attr('category', category);
  updateEvents();
}

function updateEvents() {
  $.ajax({
    url: window.location.pathname,
    type: 'POST',
    data: {category: $('#event-category').attr('category'), region: $('#event-region').attr('region')},
    success: (function (data, status, xhr) {
      $('#event-list-all').html(data['contents']);
      $('.event-list__item').on('mouseenter mouseleave click', highlightMapRegionListItemElementAttribute);
      $headers = $('#event-list-all').find('.header');
      $headers.on('click', accordionHeaderClick);
    })
  });
}

function showAllRegions() {
  $('#event-region').attr('region', 'All');
  $('.all-uk-btn').addClass('hidden');
  $('.region-map .hand-drawn-notice').removeClass('hidden');
  $('#map > *').removeAttr('class');
  updateEvents();
}

function changeEventRegion(region) {
    $('#event-region').attr('region', region);
    highlightMapRegion(region);
    $('.region-map .hand-drawn-notice').addClass('hidden');
    $('.all-uk-btn').removeClass('hidden');
    updateEvents();
}

function highlightMapRegion(region) {
    $('#map > *').removeAttr('class');
    $('#' + region).attr('class', 'active');
}

function unhighlightMapRegions() {
  $('#map > *').removeAttr('class');
}

function accordionHeaderClick(e) {
  var $item = $(e.target);
  $item = $item.parents('.accordion-item');
  if($item.hasClass('active')) {
    $item.removeClass('active');
    TweenMax.killChildTweensOf($item)
  } else {
    $item.addClass('active');
    $item.siblings().removeClass('active');
    bounceButton($item.find('.btn-bounce'));
  }
}

function highlightMapRegionListItemElementAttribute(e) {
  if (e.type == "mouseleave") {
    unhighlightMapRegions()
  } else {
    var $item = $(e.target).hasClass('event-list__item') ? $(e.target) : $(e.target).parents('.event-list__item');
    highlightMapRegion($item.attr('data-event-region'));
  }
}

function bounceButton(buttons) {
  var tl = new TimelineMax({delay: 1, repeat: -1, repeatDelay: 5});
  tl.to(buttons, 0.2, {y: -20, ease:Power3.easeOut})
    .to(buttons, 1.5, {y: 0, ease: Bounce.easeOut })
}

var cumulativeOffset = function(element) {
    var top = 0, left = 0;
    while (element) {
        top += element.offsetTop  || 0;
        left += element.offsetLeft || 0;
        element = element.offsetParent;
    }

    return {
        top: top,
        left: left
    };
};


// V2
$(document).ready(function(){

  $('body').on('click', '.v2-flash-bg', function(){
    $(".v2-flash-bg").fadeOut();
  })

  $('body').on('click', '#v2-forgot-password', function(){
    $('#v2-login-form').css('display','none')
    $('#v2-forgot-form').css('display','')
  })

  $('body').on('click', '#back-to-login', function(){
    $('#v2-login-form').css('display','')
    $('#v2-forgot-form').css('display','none')
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

function see_more_less() {
  if($('.see-content').css('display') == "none"){
    $('.see-content').css('display', 'block');
    $('.see-more').removeClass('see-more').addClass('see-less');
  }else{
    $('.see-content').css('display', 'none') ;
    $('.see-less').addClass('see-more').removeClass('see-less');
  }
}

function setcookie(cname, cvalue, exdays) {
  var d = new Date();
  d.setTime(d.getTime() + (exdays*24*60*60*1000));
  var expires = "expires="+ d.toUTCString();
  document.cookie = cname + "=" + cvalue + ";" + expires + ";path=/";
}

