const $ = require('jquery');

const {
  polymer_ext
} = require('libs_frontend/polymer_utils');

const {
  get_seconds_spent_on_current_domain_today
} = require('libs_common/time_spent_utils');

const {
  url_to_domain,
} = require('libs_common/domain_utils');

const {
  close_selected_tab
} = require('libs_common/tab_utils')

polymer_ext({
  is: 'time-until-tab-autoclose-view',
  properties: {
    minutes: {
      type: Number,
      computed: 'compute_minutes(secondsRemaining)'
    },
    seconds: {
      type: Number,
      computed: 'compute_seconds(secondsRemaining)'
    },
    site: {
      type: String,
      value: url_to_domain(window.location.href)
    },
    displayText: {
      type: String,
      computed: 'compute_displayText(minutes, seconds)'
    },
    numClicked: {
        type: Number,
        value: 0
    },
    secondsRemaining: {
      type: Number,
      value: 60
    },
  },
  more_time_button_clicked: function() {
    var self = this;
    if (!self.numClicked) self.numClicked = 0;
    self.numClicked++;
    self.secondsRemaining += 60;
  },
  compute_displayText: function(minutes, seconds) {
    return minutes + " minutes and " + seconds;
  },
  compute_minutes: function(secondsRemaining) {
    return Math.floor(secondsRemaining/60);
  },
  compute_seconds: function(secondsRemaining) {
    return secondsRemaining % 60;
  },


  attached: function() {
    var update_page = function(self) {
      console.log('attached')
      
      /*
      get_seconds_spent_on_current_domain_today(function(seconds_spent) {
        self.minutes = Math.floor(seconds_spent/60);
        self.seconds = seconds_spent % 60;
        self.displayText = self.minutes + " minutes and " + self.seconds
      });
      */

    };
    update_page(this);
    var self = this;
    setInterval(function() {
      update_page(self);
      if (self.secondsRemaining <= 0) {
        self.fire('time_has_run_out', {});
      } else {
        self.secondsRemaining -= 1;
      }
    }, 1000); 
  }
    
});
