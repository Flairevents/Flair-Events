
document.addEventListener('turbolinks:load',function(){
  console.log("was worker here");
  // $(".v2-jobs-slider").slick({
  //   dots: true,
  //   slidesToShow: 3,
  //   centerMode: true,
  //   centerPadding: '50px',
  //   // adaptiveHeight: true,
  //   // slidesPerRow: 3,
  //   variableWidth: true,
  //   nextArrow: $(".arrows.fa-chevron-right"),
  //   prevArrow: $(".arrows.fa-chevron-left"),
  // })
  // $num = $('.job-container').length;
  // $even = $num / 2;
  // $odd = ($num + 1) / 2;

  // if ($num % 2 == 0) {
  //   $('.v2-jobs-slider').css('left', '187px');
  //   $('.job-container:nth-child(' + $even +')').addClass('carousel-active');
  //   $('.featured-jobs-dots li:nth-child(' + $even + ')').addClass('dots-active');
  //   $('.job-container:nth-child(' + $even +')').prev().addClass('carousel-prev');
  //   $('.job-container:nth-child(' + $even +')').next().addClass('carousel-next');
  // }else {
  //   $('.job-container:nth-child(' + $odd +')').addClass('carousel-active');
  //   $('.featured-jobs-dots li:nth-child(' + $odd + ')').addClass('dots-active');
  //   $('.job-container:nth-child(' + $odd +')').prev().addClass('carousel-prev');
  //   $('.job-container:nth-child(' + $odd +')').next().addClass('carousel-next');
  // }

  // $('.job-container').click(function() {
  //   $slide = $('.carousel-active').width();
  //   $dot = $('.featured-jobs-dots li.dots-active');
  //   // console.log($('.carousel-active').position().left);
  //   $('.featured-jobs-dots li').siblings().removeClass('dots-active');

  //   if ($(this).hasClass('carousel-next')) {
  //     $dot.next().addClass('dots-active');
  //     $('.v2-jobs-slider').stop(false,true).animate({left:'-=' + $slide});
  //   }else if ($(this).hasClass('carousel-prev')) {
  //     $dot.prev().addClass('dots-active');
  //     $('.v2-jobs-slider').stop(false,true).animate({left:'+=' + $slide});
  //   }

  //   $(this).removeClass('carousel-prev carousel-next');
  //   $(this).siblings().removeClass('carousel-prev carousel-active carousel-next');

  //   $(this).addClass('carousel-active');
  //   $(this).prev().addClass('carousel-prev');
  //   $(this).next().addClass('carousel-next');
  // });


  // // Keyboard nav
  // $('html body').keydown(function(e) {
  //   if (e.keyCode == 37) {// left
  //     $('.carousel-active').prev().trigger('click');
  //   }
  //   else if (e.keyCode == 39) {// right
  //     $('.carousel-active').next().trigger('click');
  //   }
  // });

  // $(".box-4-content .arrows").click(function(){
  //   if ($(this).hasClass('flex-prev')) {
  //     $('.carousel-active').prev().trigger('click');
  //   } else if ($(this).hasClass('flex-next')){
  //     $('.carousel-active').next().trigger('click');
  //   }
  // });

  // $('.featured-jobs-dots li').click(function(){
  //   $index = $(this).index();
  //   $slide = $('.job-container').eq($index);

  //   if ($slide.hasClass('carousel-next') || $slide.hasClass('carousel-prev')) {
  //     $slide.trigger('click');
  //   }
  // });

  $('.featured-jobs-dots li').click(function(){
    $index = $(this).index();
    $slide = $('.job-container[data-index='+$index+']');

    // if ($slide.hasClass('carousel-next') || $slide.hasClass('carousel-prev')) {
    //   $slide.trigger('click');
    // }
    if ($slide.hasClass('left-slide') || $slide.hasClass('right-slide')) {
      $slide.trigger('click');
    }
  });

  $('.box-4-content .flex-next, .box-4-content .flex-prev').click(function(){
    if ($(this).hasClass('flex-next')) {
      $('.right-slide').trigger('click');
    } else if ($(this).hasClass('flex-prev')){
      $('.left-slide').trigger('click');
    }
  });

  $(".v2-jobs-slider").cardSlider({
    slideTag: 'div',
    slideClass: 'slide',
    swipe: true,
    onMove: function(){
      changeDotActive($('.center-slide').data('index'));
    }
  });

  // $("div").on("swipeleft",function(){
  //   alert("#v2-worker-box-4-mobile");
  // });

  $('.box-category').flexslider({
    animation: "slide",
    animationSpeed: 500,
    slideshow:false,
    // controlsContainer: $(".custom-pagination"),
  });

  $('.feature-jobs-con').flexslider({
    animation: "slide",
    animationSpeed: 500,
    slideshow:false,
    // controlsContainer: $(".custom-pagination"),
  });

  function changeDotActive(index){
    $('.featured-jobs-dots li').siblings().removeClass('dots-active');
    $('.featured-jobs-dots li').eq(index).addClass('dots-active');
  }

});
