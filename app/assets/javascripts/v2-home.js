$(document).ready(function(){
  $('.slideshow-container').flexslider({
    animation: "slide",
    animationSpeed: 500,
    slideshow:true,
    // controlsContainer: $(".custom-pagination"),
    customDirectionNav: $(".arrows")
  });

  var posObj = {
    "pos_1": ["0px", "-128px", "-251.5px", "-377.6px", "-503.8px", "-629.6px"],
    "pos_2": ["0px", "-126px", "-252px", "-375px", "-504px", "-630px"],
    "pos_3": ["0px", "-125.6px", "-251.5px", "-378px", "-503.5px", "-630px"],
    "pos_4": ["0px", "-125.5px", "-250.5px", "-375.5px", "-501.5px", "-627.5px"],
    "pos_5": ["0px", "-125.5px", "-250px", "-375px", "-499.5px", "-624px"],
    "pos_6": ["0px", "-126.3px", "-252.2px", "-378.4px", "-504.4px", "-630.5px"],
  };

  $(".skills-item").mouseenter(function(){
    // console.log()
    var pos = posObj["pos_"+$(this).data("index")];
    let count = 0;
    var sk = $(this);

    var mvImage = setInterval(function(){
      sk.find('.skill-image').css('background-position-x', pos[count + 1]);

      if(count == 4) clearInterval(mvImage);

      count++;
    }, 50);


  }).mouseleave(function(){
    var pos = posObj["pos_"+$(this).data("index")];
    let count = 5;
    var sk = $(this);

    var mvImage = setInterval(function(){
      sk.find('.skill-image').css('background-position-x', pos[count - 1]);

      count-=1;
      if(count == 0) clearInterval(mvImage);
    }, 50);

    // sk.find('.skill-image').css('background-position-x', '0px');
  });

  var TxtRotate = function(el, toRotate, period) {
    this.toRotate = toRotate;
    this.el = el;
    this.loopNum = 0;
    this.period = parseInt(period, 10) || 2000;
    this.txt = '';
    this.tick();
    this.isDeleting = false;
  };

  TxtRotate.prototype.tick = function() {
    var i = this.loopNum % this.toRotate.length;
    var fullTxt = this.toRotate[i];

    if (this.isDeleting) {
      this.txt = fullTxt.substring(0, this.txt.length - 1);
    } else {
      this.txt = fullTxt.substring(0, this.txt.length + 1);
    }

    this.el.innerHTML = '<span class="wrap">'+this.txt+'</span>';

    var that = this;
    var delta = 300 - Math.random() * 100;

    if (this.isDeleting) { delta /= 2; }

    if (!this.isDeleting && this.txt === fullTxt) {
      delta = this.period;
      this.isDeleting = true;
    } else if (this.isDeleting && this.txt === '') {
      this.isDeleting = false;
      this.loopNum++;
      delta = 500;
    }

    setTimeout(function() {
      that.tick();
    }, delta);
  };

  var elements = document.getElementsByClassName('txt-rotate');
  for (var i=0; i<elements.length; i++) {
    var toRotate = elements[i].getAttribute('data-rotate');
    var period = elements[i].getAttribute('data-period');
    if (toRotate) {
      new TxtRotate(elements[i], JSON.parse(toRotate), period);
    }
  }
  // INJECT CSS
  var css = document.createElement("style");
  css.type = "text/css";
  css.innerHTML = ".txt-rotate > .wrap { border-right: 0.08em solid #EE7623E5 }";
  document.body.appendChild(css);
});



// window.onload = function() {
//   var elements = document.getElementsByClassName('txt-rotate');
//   for (var i=0; i<elements.length; i++) {
//     var toRotate = elements[i].getAttribute('data-rotate');
//     var period = elements[i].getAttribute('data-period');
//     if (toRotate) {
//       new TxtRotate(elements[i], JSON.parse(toRotate), period);
//     }
//   }
//   // INJECT CSS
//   var css = document.createElement("style");
//   css.type = "text/css";
//   css.innerHTML = ".txt-rotate > .wrap { border-right: 0.08em solid #666 }";
//   document.body.appendChild(css);
// };
