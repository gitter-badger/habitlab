require('enable-webcomponents-in-content-scripts')

const $ = require('jquery')
require('components/interstitial-screen-num-visits.deps')
const {
  get_minutes_spent_on_domain_today,
  get_visits_to_domain_today
} = require('libs_common/time_spent_utils')

const co = require('co')

const {
  log_impression,
  log_action,
} = require('libs_common/log_utils')

const {
  url_to_domain
} = require('libs_common/domain_utils')

co(function*() {
  if (document.querySelector("._1k67") === null) { //checks if user is logged in 
    return
  }
  var domain = url_to_domain(window.location.href)
  var numMins = yield get_minutes_spent_on_domain_today(domain)
  var numVisits = yield get_visits_to_domain_today(domain)
  var titleString = 'You have visited ' + url_to_domain(window.location.href) +' ' + numVisits + ' times and spent '+ numMins + ' minutes there today.'
  var buttonText = 'Click to continue to Facebook'
  var buttonText2 = 'Close Facebook'

  var interst_screen = $('<interstitial-screen-num-visits class="interst_screen">')
  interst_screen.attr('intervention', intervention.name)
  interst_screen.attr('btn-txt', buttonText)
  interst_screen.attr('btn-txt2', buttonText2)
  interst_screen.attr('title-text', titleString)
  interst_screen.attr('minutes', numMins);
  interst_screen.attr('visits', numVisits);
  interst_screen.attr('seconds', 0);
  log_impression(intervention.name)
  $(document.body).append(interst_screen)
})

document.body.addEventListener('disable_intervention', () => {
  $('.interst_screen').remove();
});

window.debugeval = x => eval(x);
