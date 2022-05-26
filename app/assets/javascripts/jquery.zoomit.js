/**
 * Author: Constantin Boiangiu (services[at]constantinb.com)
 * Homepage: http://www.constantinb.com/project/jquery-image-zoom-zoomit/
 * Forum : http://www.constantinb.com/forums/forum/jquery-zoomit-plugin/
 * jQuery version: 1.6
 * Copyright (c) author
 * License: MIT (http://www.opensource.org/licenses/mit-license.php)
 */
// Hacked by Alex Dowad to make it work right

;(function($){

	var is_touch = function(){
		return /Android|webOS|iPhone|iPad|iPod|BlackBerry/i.test(navigator.userAgent);
	}

  // this should be called AFTER the small image is visible
	$.fn.jqZoomIt = function(options) {
		if (this.length > 1) {
			this.each(function() {
				$(this).jqZoomIt(options);
			});
			return this;
		}

		if (this.data("zoomready"))
			return;
		this.data("zoomready", true);

		var defaults = {
			mouseEvent			: 'mouseenter', // click, mouseenter, mouseover
			zoomAreaMove		: 'drag', // drag or mousemove
			zoomPosition		: 'right', // left, right, top, bottom
			// CSS
			zoomAreaColor		: '#fff', // zoomed area bg color

			zoomAreaOpacity	: 0.5, // dragger opacity
			zoomDistance		: 10, // distance of the zoomer from the trigger

			multiplierX			: 0.5, // how much of the big image width will be displayed
			multiplierY			: 0.5, // how much of the big image height will be displayed
		};

		var options = $.extend({}, defaults, options),
		  self = this,
		  bigImg = $(this).attr('href'),
		  smallImg = $('img', this),
		  zoomer  = null,
		  dragger = null,
		  fullImg = null;

		self.data("options", options);

    // don't download image if clicked on
    self.removeAttr('href', null)

		// if element doesn't have href attribute
		// or small image isn't within main element,
		// bail out
		if('' == bigImg || 0 == smallImg.length) {
			return false;
		}

		// start the plugin
		var initialize = function() {
			zoomer = $('<div />', {
				'class' : 'zoomed',
				'css'	: {
					'display'	: 'none',
					'position'	: 'absolute',
					'top'		: -1000,
					'overflow'	: 'hidden',
					'z-index'	: 1050
				}
			}).appendTo($(document.body));

			dragger = $('<div />', {
				'class' : 'dragger',
				'css': {
					'background-color' : options.zoomAreaColor || '#999',
					'opacity'			: options.zoomAreaOpacity || .7,
					'display'			: 'none',
					'position'		: 'absolute',
					'top'				  : 0,
					'left'				: 0,
					'cursor'			: 'move',
					'z-index'			: 1000
				}
			}).appendTo(self);

      self.data("zoomer", zoomer);
      self.data("dragger", dragger);

			// add the events
			var enterEvent = is_touch() ? 'touchstart' : ( 'click' == options.mouseEvent ? 'click' : 'mouseenter' ),
				leaveEvent = is_touch() ? 'touchend' : 'mouseleave';

			self.bind(enterEvent, function(event) {
				event.preventDefault();
				startZoom();
			});
			self.bind(leaveEvent, closeZoom);

			return self;
		}

		var startZoom = function() {
			var sizes = get_small_size();

			zoomer.show().css({
				'top' : sizes.zTop,
				'left' : sizes.zLeft
			});

			// show and position preview area
			dragger.show();

			// code after this will run only once
			if(fullImg) {
				// added by Alex to make zoomed image rotate along with small one
        fullImg.removeClass('rotate90', 'rotate180', 'rotate270');
        fullImg.addClass(rotation_class());
				return;
			}

			// load the big image
			fullImg = $('<img />', {'src' : bigImg}).load(function() {
				// inject full image
				fullImg.css({
					'position' : 'absolute',
					'top'    : 0,
					'left'   : 0,
					'width'  : 800, // hard-coded by Alex Dowad
					'height' : 800
				}).appendTo(zoomer);

				// added by Alex to make zoomed image rotate along with small one
				fullImg.removeClass('rotate90', 'rotate180', 'rotate270');
				fullImg.addClass(rotation_class());

				var fullWidth = fullImg.width(),
					fullHeight 	= fullImg.height(),
					ratioX 		  = fullWidth / sizes.width,
					ratioY 		  = fullHeight / sizes.height,
					draggerW 		= sizes.width * options.multiplierX,
					draggerH 	  = sizes.height * options.multiplierY;

				// resize drag area that shows the position on small image
				dragger.css({'width': draggerW, 'height': draggerH});
			  // resize zoomed-in area
			  zoomer.css({
			    'width'  : fullWidth * options.multiplierX,
			    'height' : fullHeight * options.multiplierY
			  });

				if('drag' == options.zoomAreaMove && $.fn.draggable && !is_touch()) {
					// start drag
					dragger.draggable({
						containment : 'parent',
						drag: function(event, ui){
							var pos = dragger.position(),
								left 	= -(pos.left * ratioX),
								top 	= -(pos.top * ratioY);
							fullImg.css({
								'left':left,
								'top':top
							});
						}
					})

				} else {

					var moveEvent = is_touch() ? 'touchmove' : 'mousemove';

					$(self).bind(moveEvent, function(e) {
						// used to store current mouse position
						var mouseX = 0, mouseY = 0;
						// get position on touch
						if (is_touch()) {
							e.preventDefault();
							event = e.originalEvent.touches[0] || e.originalEvent.changedTouches[0];
							mouseX = event.pageX;
							mouseY = event.pageY;
						} else {
							// get position on non-touch
							mouseX = e.pageX;
							mouseY = e.pageY;
						}

						var sizes = get_small_size(),
							draggerX = mouseX - sizes.left - draggerW/2,
							draggerY = mouseY - sizes.top - draggerH/2;

						// horizontal left limit
						if(draggerX < 0) { draggerX = 0; }
						// vertical top limit
						if(draggerY < 0) { draggerY = 0; }
						// horizontal right limit
						if(draggerX > sizes.width - draggerW) {
							draggerX = sizes.width - draggerW;
						}
						// vertical bottom limit
						if(draggerY > sizes.height - draggerH) {
							draggerY = sizes.height - draggerH;
						}

						dragger.css({'left':draggerX, 'top':draggerY});

						// move full image
						fullImg.css({
							'left'	: -(draggerX * ratioX),
							'top'	: -(draggerY * ratioY)
						});
					})
				}
			});
		}

		var closeZoom = function(){
			zoomer.css({
				'top' : -5000,
				'left': -5000
			});
			dragger.hide();
		}

		var get_small_size = function() {
			var position = $(smallImg[0]).offset(),
			    width    = $(smallImg[0]).outerWidth(),
			    zLeft    = position.left + width + options.zoomDistance;

			if (zLeft + width > $(window).width()) {
				if (position.left - options.zoomDistance - width > 0) {
					zLeft = position.left - options.zoomDistance - width;
				}
			}

			return {
				'width'  : width,
				'height' : $(smallImg[0]).outerHeight(),
				'top' 	 : position.top,
			  'left' 	 : position.left,
			  'zTop' 	 : position.top,
			  'zLeft'  : zLeft
			};
		}

    var rotation_class = function() {
			if (smallImg.hasClass('rotate90'))
				return 'rotate90';
			else if (smallImg.hasClass('rotate180'))
				return 'rotate180';
			else if (smallImg.hasClass('rotate270'))
				return 'rotate270';
			else return null;
    }

		return initialize();
	}

	$.fn.jqZoomItDispose = function() {
		if(this.length == 0) return this;

		var self = this,
			enterEvent = is_touch() ? 'touchstart' : ('click' == self.data("options").mouseEvent ? 'click' : 'mouseenter'),
			leaveEvent = is_touch() ? 'touchend' : 'mouseleave';

		self.unbind(enterEvent);
		self.unbind(leaveEvent);
		self.data("dragger").remove();
		self.data("zoomer").remove();

		return self;
	}
})(jQuery);