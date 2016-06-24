"use strict";

(() => {

const $ = require('jquery')

const {
  // libs_frontend/common_libs.ls
  once_available,
  run_only_one_at_a_time,
  on_url_change,
} = require('libs_frontend/common_libs')

console.log('youtube prompt before watch loaded frontend')

//Initially pauses the video when the page is loaded
function pauseVideo() {
	const overlayBox = document.querySelector('video');
	if (!overlayBox.paused) {
		overlayBox.pause();
	}
}

//Places a white box over the video with a warning message
function divOverVideo(status) {
	//Constructs white overlay box
  if ($('video').length == 0) {
    return
  }
  if (window.location.href.indexOf('watch') == -1) {
    return
  }
  const $a = $('<div class="whiteOverlay">').css({'position': 'absolute'});
	$a.width($('video').width());
	$a.height($('video').height());
	$a.css({'background-color': 'white'});
	$a.css('z-index', 30);
	$a.text();
	$(document.body).append($a);
	const b = $a[0];
	b.style.left = $('video').offset().left + 'px';
	b.style.top = $('video').offset().top + 'px';
	b.style.opacity = 0.9;

	//Centered container for text in the white box
	const $contentContainer = $('<div class="contentContainer">').css({
							'position': 'absolute',
							'top': '50%',
							'left': '50%',
							'transform': 'translateX(-50%) translateY(-50%)'});

	//Message to user
	const $text1 = $('<h1>');
	if (status === 'begin') {
		$text1.text("Are you sure you want to play the video?");
	} else {
		$text1.text("Are you sure you want to continue watching videos?");
	}
	$contentContainer.append($text1);
	$contentContainer.append($('<p>'));

	//Close tab button
	const $button1 = $('<button>');
	$button1.text("Close Tab");
	$button1.css({'cursor': 'pointer'});
	$button1.click(() => {
		closeTab();
		$button1.hide();
	})
	$contentContainer.append($button1);

	//Continue watching video button
	const $button2 = $('<button>');
	$button2.text("Watch Video");
	$button2.css({'cursor': 'pointer', 'padding': '10px'});
	$button2.click(() => {
		removeDivAndPlay();
		$button2.hide();
	})
	$contentContainer.append($button2);

	//Adds text into the white box
	$('.whiteOverlay').append($contentContainer);
}

//Remove the white div
function removeDivAndPlay() {
	$('.whiteOverlay').remove();
	const play = document.querySelector('video');
	play.play();
}

//Remove the white div
function removeDiv() {
	$('.whiteOverlay').remove();
}

//Close the current tab
function closeTab() {
	chrome.runtime.sendMessage({greeting: "closeTab"}, (response) => {});
}

//TODO: Make event listener for end of video instead of checking every second if the video is finished
function endWarning() {
	/*
	$('video').on('ended', function() {
		console.log("executing");
		divOverVideoEnd();
	});
	*/
	const overlayBox = document.querySelector('video');
	if ((overlayBox.currentTime > (overlayBox.duration - 0.25)) && !overlayBox.paused) {
		divOverVideo("end");
		//overlayBox.pause();
	}
}

let video_pauser = null

//All method calls
function main() {
  console.log('main called');
  removeDiv();
	divOverVideo("begin");
  if (video_pauser == null) {
    video_pauser = setInterval(() => {
      pauseVideo();
      console.log('video pauser running')
      const video_elem = document.querySelector('video')
      if (video_elem && video_elem.paused) {
        clearInterval(video_pauser)
      }
    }, 250);
  }
	//pauseVideo();
	//endWarning();
	setInterval(endWarning, 250); //Loop every second to test the status of the video until near the end
}

//Link to Fix: http://stackoverflow.com/questions/18397962/chrome-extension-is-not-loading-on-browser-navigation-at-youtube
function afterNavigate() {
  console.log('afterNavigate')
  if ('/watch' === location.pathname) {
    console.log('youtube watch page')
    if (video_pauser) {
      clearInterval(video_pauser);
      video_pauser = null;
    }
    console.log('right before main gets called')
    //$(document).ready(main);
    main();
  } else {
    removeDiv();
  }
}

//Youtube specific call for displaying the white div/message when the red top slider transitions
//(Solution from link above)
(document.body || document.documentElement).addEventListener('transitionend',
  (event) => {
    if (event.propertyName === 'width' && event.target.id === 'progress') {
        afterNavigate();
    }
}, true);

$(document).ready(main);
//main()

//Executed after page load
//afterNavigate();

})();