const $ = require('jquery');

const {
  close_selected_tab
} = require('libs_common/tab_utils')

const {
  load_css_file,
} = require('libs_common/content_script_utils')

const {
  get_seconds_spent_on_current_domain_today,
  get_minutes_spent_on_domain_today,
} = require('libs_common/time_spent_utils');

const {
  url_to_domain,
} = require('libs_common/domain_utils');

const {
  polymer_ext
} = require('libs_frontend/polymer_utils');

polymer_ext({
  is: 'fb-scroll-block-display',
  properties: {
    intervention: {
      type: String,
      value: '',
    },
    minutes: {
      type: Number,
    },
    site: {
      type: String,
      value: url_to_domain(window.location.hostname),
    },
    visits: {
      type: Number,
    }
  },
  listeners: {
    
  },
  /*
  clicked: function(event) {
    if (this.$.habitlab_logo !== Polymer.dom(event).localTarget) {
      this.fire('continue_scrolling', {});
    }
    
  },
  */
  continue_scrolling: function(event) {
    this.fire('continue_scrolling', {})
  },
  ready: function() {
    console.log('fb-scroll-block-display ready');
    const self = this;
    setInterval(() => {
      get_seconds_spent_on_current_domain_today(function(seconds_spent) {
        self.minutes = Math.floor(seconds_spent/60);
        self.seconds = seconds_spent % 60;
      });
    }, 1000);
  },
});

