prelude = require 'prelude-ls'

{
  get_interventions
  get_enabled_interventions
  get_manually_managed_interventions
  set_intervention_enabled
  set_intervention_disabled
  set_intervention_automatically_managed
  set_intervention_manually_managed
  set_override_enabled_interventions_once
} = require 'libs_backend/intervention_utils'

{
  get_and_set_new_enabled_interventions_for_today
  enable_interventions_because_goal_was_enabled
} = require 'libs_backend/intervention_manager'

{
  get_enabled_goals
  get_goals
  set_goal_enabled_manual
  set_goal_disabled_manual
  set_goal_target
  get_goal_target
  remove_custom_goal_and_generated_interventions
  add_enable_custom_goal_reduce_time_on_domain
} = require 'libs_backend/goal_utils'

{
  as_array
} = require 'libs_common/collection_utils'

{
  add_log_interventions
} = require 'libs_backend/log_utils'

{
  url_to_domain
} = require 'libs_common/domain_utils'

{
  get_canonical_domain
} = require 'libs_backend/canonical_url_utils'

{load_css_file} = require 'libs_common/content_script_utils'
{cfy} = require 'cfy'

{polymer_ext} = require 'libs_frontend/polymer_utils'

swal = require 'sweetalert2'

$ = require 'jquery'

polymer_ext {
  is: 'options-interventions'
  properties: {
    enabled_goals: {
      type: Array
      value: {}
    },
    index_of_daily_goal_mins: {
      type: Object
      value: {}
    },
    goals_and_interventions: {
      type: Array
      value: []
    }
    sites_and_goals: {
      type: Array
      value: []
    }, 
    start_time_string: {
      type: String
      value: if localStorage.start_as_string then localStorage.start_as_string else '9:00 AM'
    },
    end_time_string: {
      type: String
      value: if localStorage.end_as_string then localStorage.end_as_string else '5:00 PM'
    },
    start_time_mins: {
      type: Number,
      value: if localStorage.start_mins_since_midnight then parseInt(localStorage.start_mins_since_midnight) else 540
    },
    end_time_mins: {
      type: Number,
      value: if localStorage.end_mins_since_midnight then parseInt(localStorage.end_mins_since_midnight) else 1020
    },
    always_active: {
      type: Boolean
      value: localStorage.work_hours_only != "true"
    },
    daily_goal_values: {
      type: Array
      value: ["5 minutes", "10 minutes", "15 minutes", "20 minutes", "25 minutes", "30 minutes", "35 minutes", "40 minutes", "45 minutes", "50 minutes", "55 minutes", "60 minutes"]
    }
    seen_tutorial: {
      type: Boolean
      value: localStorage.seen_tutorial != "true"
    }
    popup_view_has_been_opened: {
      type: Boolean
      value: localStorage.popup_view_has_been_opened == 'true'
    }
  }
  disable_interventions_which_do_not_satisfy_any_goals: cfy (goal_name) ->*
    enabled_goals = yield get_enabled_goals()
    enabled_interventions = yield get_enabled_interventions()
    all_interventions = yield get_interventions()
    interventions_to_disable = []
    for intervention_name,intervention_enabled of enabled_interventions
      if not intervention_enabled
        continue
      intervention_info = all_interventions[intervention_name]
      intervention_satisfies_an_enabled_goal = false
      for goal_info in intervention_info.goals
        if enabled_goals[goal_info.name]
          intervention_satisfies_an_enabled_goal = true
      if not intervention_satisfies_an_enabled_goal
        interventions_to_disable.push intervention_name
    prev_enabled_interventions = {} <<< enabled_interventions
    for intervention_name in interventions_to_disable
      yield set_intervention_disabled intervention_name
    if interventions_to_disable.length > 0
      add_log_interventions {
        type: 'interventions_disabled_due_to_user_disabling_goal'
        manual: false
        goal_name: goal_name
        interventions_list: interventions_to_disable
        prev_enabled_interventions: prev_enabled_interventions
      }

  goal_changed: cfy (evt) ->*
    
    checked = evt.target.checked
    
    goal_name = evt.target.goal.name


    self = this
    if checked
      yield set_goal_enabled_manual goal_name
      
      check_if_first_goal = cfy ->*       
        if !localStorage.first_goal?
          localStorage.first_goal = 'has enabled a goal before'
          #add_toolbar_notification!

          # yield load_css_file('bower_components/sweetalert2/dist/sweetalert2.css')
          # try
          #   yield swal {
          #     title: 'You set a goal!'
          #     text: 'HabitLab will use its algorithms to try different interventions on your webpages, and intelligently figure out what works best for you. You can manually tinker with settings if you\'d like.'
          #     type: 'success'
          #     confirmButtonText: 'See it in action'
          #   }
            
          #   set_override_enabled_interventions_once('facebook/show_user_info_interstitial')
          #   all_goals = yield get_goals()
          #   goal_info = all_goals[goal_name]
          #   chrome.tabs.create {url: goal_info.homepage }
          # catch
          #   console.log 'failure'
      check_if_first_goal!
    else
      
      yield set_goal_disabled_manual goal_name
    yield this.disable_interventions_which_do_not_satisfy_any_goals(goal_name)
    if checked
      yield enable_interventions_because_goal_was_enabled(goal_name)
    
    self.fire 'goal_changed', {goal_name: goal_name}
  select_new_interventions: (evt) ->
    self = this
    self.goals_and_interventions = []
    <- get_and_set_new_enabled_interventions_for_today()
    self.rerender()
  on_goal_changed: (evt) ->
    this.rerender()

    

  get_daily_targets: cfy ->*
    goals = yield get_goals!
    window.gols = goals
    for goal in Object.keys goals
      if goal == "debug/all_interventions" 
        continue
      mins = yield get_goal_target goal
      mins = mins/5 - 1
      this.index_of_daily_goal_mins[goal] = mins
    
  goals_set: (evt) ->
    if (Object.keys this.enabled_goals).length > 0 
      evt.target.style.display = "none"
      this.$$('#intro1').style.display = "block"
    
  intro1_read: (evt) ->
    evt.target.style.display = "none"
    this.$$('#intro2').style.display = "block"

  #intro2_read: (evt) ->
  #  evt.target.style.display = "none"
  #  this.$$('#intro3').style.display = "block"
  #  window.scrollTo 0, document.body.scrollHeight

  intro2_read: (evt) ->
    evt.target.style.display = "none"
    this.$$('#intro4').style.display = "block"
    this.$$('#intro4').scrollTop = this.$$('#intro4').scrollHeight
    window.scrollTo 0, document.body.scrollHeight
    console.log evt

  show_how_hl_works: (evt) ->
    evt.target.style.display = "none"
    this.$$('#how_hl_works').style.display = "block"

  get_icon: ->
    return chrome.extension.getURL('icons/icon_19.png')

  intro3_read: (evt) ->
    evt.target.style.display = "none"
    this.$$('#intro4').style.display = "block"
    this.$$('#intro4').scrollTop = this.$$('#intro4').scrollHeight
    window.scrollTo 0, document.body.scrollHeight
    console.log evt

  intro4_read: (evt) ->
    evt.target.style.display = "none"
    
    this.$$('#intro6').style.display = "block"
    window.scrollTo 0, document.body.scrollHeight

  intro5_read: (evt) ->
    evt.target.style.display = "none"
    this.$$('#intro6').style.display = "block"
    window.scrollTo 0, document.body.scrollHeight

  show_swal: ->
    #evt.target.style.display = "none"
    this.$$('#popup-button').style.display = 'none'
    swal {
      title: 'Tutorial Complete!'
      text: 'That\'s all you need to know to start using HabitLab. If you\'d like, you can configure more options and view the list of interventions for each goal at the bottom of this page.'
      type: 'success'
      allowOutsideClick: false
      allowEscapeKey: false
      #showCancelButton: true
      #confirmButtonText: 'Visit Facebook to see an intervention in action'
      #cancelButtonText: 'Close'
    }
    this.$$('#configurations').style.display = "block"
    this.$$('#intro3').style.display = "block"
    window.scrollTo 0, document.body.scrollHeight

  toggle_interventions: (evt) ->
    if ((evt.target.innerText.indexOf 'SHOW') > -1)
      this.$$('#ivn-toggle-btn').innerText = "Hide Intervention Details"
      this.$$('#interventions-list').style.display = "block"
    else 
      this.$$('#ivn-toggle-btn').innerText = "Show Intervention Details"
      this.$$('#interventions-list').style.display = "none"
    window.scrollTo 0, document.body.scrollHeight

  show_intro_button_clicked: ->
    this.$$('#show_intro_button').style.display = 'none'
    this.$$('#intro1_content').style.display = 'block'
    this.$$('#intro2').style.display = 'block'
    this.$$('#intro4').style.display = 'block'

  attached: ->
   if window.location.hash != '#introduction'
    for elem in Polymer.dom(this.root).querySelectorAll('.intro')
      elem.style.display = 'inline-flex';
    for elem in Polymer.dom(this.root).querySelectorAll('.next-button')
      elem.style.display = 'none';
    this.$$('#pointer-div').style.display = 'none';
    this.$$('#ivn-toggle-btn').style.display = 'none'
    this.$$('#interventions-list').style.display = 'block'
    this.$$('#show_intro_button').style.display = 'inline-flex'
    this.$$('#intro1_content').style.display = 'none'
    this.$$('#intro2').style.display = 'none'
    this.$$('#intro4').style.display = 'none'

  ready: ->
   
    this.rerender()
    this.get_daily_targets!
    self = this
    if window.location.hash == '#introduction'
      localStorage.removeItem 'popup_view_has_been_opened'
      popup_view_opened_checker = setInterval ->
        if localStorage.popup_view_has_been_opened == 'true'
          self.popup_view_has_been_opened = true
          self.$$('#pointer-div').style.display = 'none'
          self.$$('#popup-button').disabled = false
          self.$$('#popup-button').innerText = 'Next'
          clearInterval popup_view_opened_checker
          if self.$$('#intro4').style.display != 'none'
            self.show_swal()
      , 500
    load_css_file('bower_components/sweetalert2/dist/sweetalert2.css')
    
  set_sites_and_goals: cfy ->*
    self = this
    goal_name_to_info = yield get_goals()
    sitename_to_goals = {}
    for goal_name,goal_info of goal_name_to_info
      if goal_name == 'debug/all_interventions' and localStorage.getItem('intervention_view_show_debug_all_interventions_goal') != 'true'
        continue
      sitename = goal_info.sitename
      if not sitename_to_goals[sitename]?
        sitename_to_goals[sitename] = []
      sitename_to_goals[sitename].push goal_info
    list_of_sites_and_goals = []
    list_of_sites = prelude.sort Object.keys(sitename_to_goals)
    enabled_goals = yield get_enabled_goals()
    yield this.get_daily_targets!
    
    for sitename in list_of_sites
      current_item = {sitename: sitename}
      current_item.goals = prelude.sort-by (.name), sitename_to_goals[sitename]
      
      for goal in current_item.goals
        goal.enabled = (enabled_goals[goal.name] == true)
        goal.number = this.index_of_daily_goal_mins[goal.name]

      list_of_sites_and_goals.push current_item
    self.sites_and_goals = list_of_sites_and_goals
  show_internal_names_of_goals: ->
    return localStorage.getItem('intervention_view_show_internal_names') == 'true'
  show_randomize_button: ->
    return localStorage.getItem('intervention_view_show_randomize_button') == 'true'
  have_interventions_available: (goals_and_interventions) ->
    
    return goals_and_interventions and goals_and_interventions.length > 0
  show_dialog: (evt) ->
    if evt.target.id == 'start-time'
      this.$$('#start-dialog').toggle!
    else
      this.$$('#end-dialog').toggle!
  toggle_timepicker_idx: (evt) ->
   
    buttonidx = evt.detail.buttonidx
    if buttonidx == 1
      console.log ' just switched to Work Hours'
      localStorage.work_hours_only = true;
      @always_active = false
      localStorage.start_mins_since_midnight = @start_time_mins#this.$$('#start-picker').rawValue
      localStorage.end_mins_since_midnight = @end_time_mins#this.$$('#end-picker').rawValue
      localStorage.start_as_string = @start_time_string#this.$$('#start-picker').time
      localStorage.end_as_string = @end_time_string#this.$$('#end-picker').time
    else
      console.log ' just switched to Always On'
      localStorage.work_hours_only = false;
      @always_active = true
  toggle_timepicker: (evt) ->
    if evt.target.checked # if evt.target.checked is true, elem was just changed
      if this.$$('paper-radio-group').selected == 'always' #bizarre error, means currently selected is work_hours
        console.log ' just switched to Work Hours'
        
        localStorage.work_hours_only = true;
        @always_active = false
        localStorage.start_mins_since_midnight = @start_time_mins#this.$$('#start-picker').rawValue
        
        localStorage.end_mins_since_midnight = @end_time_mins#this.$$('#end-picker').rawValue
        localStorage.start_as_string = @start_time_string#this.$$('#start-picker').time
        localStorage.end_as_string = @end_time_string#this.$$('#end-picker').time
      else
        console.log ' just switched to Always On'
        
        localStorage.work_hours_only = false;
        @always_active = true

    # if not, it's a double click so you shouldn't do anything

  time_updated: cfy (evt, obj) ->*
    
    mins = Number (obj.item.innerText.trim ' ' .split ' ' .0)
    set_goal_target obj.item.class, mins
  

  dismiss_dialog: (evt) ->
    console.log evt
    if evt.detail.confirmed and (this.$$('#end-picker').rawValue - this.$$('#start-picker').rawValue > 0)
      if evt.target.id == 'start-dialog'
        @start_time_string = this.$$('#start-picker').time
        @start_time_mins = this.$$('#start-picker').rawValue
        localStorage.start_mins_since_midnight = @start_time_mins
        localStorage.start_as_string = @start_time_string
      else
        @end_time_string = this.$$('#end-picker').time
        @end_time_mins = this.$$('#end-picker').rawValue
        localStorage.end_mins_since_midnight = @end_time_mins
        localStorage.end_as_string = @end_time_string
    else #reset the time picker time to saved time
      this.$$('#start-picker').time = @start_time_string
      this.$$('#end-picker').time = @end_time_string

  # get_selected: cfy (name) ->*
  #   console.log "boo"
  #   console.log name
  #   ##time = yield get_goal_target name
  #   #console.log time
  #   return 4
  #   return (time/5 - 1)

  determine_selected: (always_active) ->
    if always_active
      return 'always'
    else 
      return 'workday'
  determine_selected_idx: (always_active) ->
    if always_active
      return 0
    else 
      return 1
  sort_custom_goals_and_interventions_after: (goals_and_interventions) ->
    [custom_goals_and_interventions,normal_goals_and_interventions] = prelude.partition (.goal.custom), goals_and_interventions
    return normal_goals_and_interventions.concat custom_goals_and_interventions
  sort_custom_sites_after: (sites_and_goals) ->
    [custom_sites_and_goals,normal_sites_and_goals] = prelude.partition (-> it.goals.filter((.custom)).length > 0), sites_and_goals
    return normal_sites_and_goals.concat custom_sites_and_goals
  add_custom_website_from_input: cfy ->*
    domain = url_to_domain(this.$$('#add_website_input').value.trim())
    if domain.length == 0
      return
    this.$$('#add_website_input').value = ''
    canonical_domain = yield get_canonical_domain(domain)
    if not canonical_domain?
      swal {
        title: 'Invalid Domain'
        html: $('<div>').append([
          $('<div>').text('You entered an invalid domain: ' + domain)
          $('<div>').text('Please enter a valid domain such as www.amazon.com')
        ])
        type: 'error'
      }
      return
    yield add_enable_custom_goal_reduce_time_on_domain(canonical_domain)
    this.rerender()
    return
  add_goal_clicked: (evt) ->
    this.add_custom_website_from_input()
    return
  add_website_input_keydown: (evt) ->
    if evt.keyCode == 13
      # enter pressed
      this.add_custom_website_from_input()
      return
  delete_goal_clicked: cfy (evt) ->*
    goal_name = evt.target.goal_name
    yield remove_custom_goal_and_generated_interventions goal_name
    this.rerender()
  help_icon_clicked: ->
    swal {
      title: 'How HabitLab Works'
      html: '''
      HabitLab will help you achieve your goal by showing you a different <i>intervention</i>, like a news feed blocker or a delayed page loader, each time you visit your goal site.
      <br><br>
      At first, HabitLab will show you a random intervention each visit, and over time it will learn what works most effectively for you.
      <br><br>
      Each visit, HabitLab will test a new intervention and measure how much time you spend on the site. Then it determines the efficacy of each intervention by comparing the time spent per visit when that intervention was deployed, compared to when other interventions are deployed. HabitLab uses an algorithmic technique called <a href="https://en.wikipedia.org/wiki/Multi-armed_bandit" target="_blank">multi-armed-bandit</a> to learn which interventions work best and choose which interventions to deploy, to minimize your time wasted online.
      '''
      allowOutsideClick: true
      allowEscapeKey: true
      #showCancelButton: true
      #confirmButtonText: 'Visit Facebook to see an intervention in action'
      #cancelButtonText: 'Close'
    }
  rerender: cfy ->*
    yield this.set_sites_and_goals()
    self = this
    intervention_name_to_info = yield get_interventions()
    
    enabled_interventions = yield get_enabled_interventions()
    enabled_goals = yield get_enabled_goals()
    
    this.enabled_goals = enabled_goals
    all_goals = yield get_goals()
    manually_managed_interventions = yield get_manually_managed_interventions()
    goal_to_interventions = {}
    for intervention_name,intervention_info of intervention_name_to_info
      for goal in intervention_info.goals
        goalname = goal.name
        if not goal_to_interventions[goalname]?
          goal_to_interventions[goalname] = []
        goal_to_interventions[goalname].push intervention_info
    list_of_goals_and_interventions = []
    list_of_goals = prelude.sort as_array(enabled_goals)
    for goalname in list_of_goals
      current_item = {goal: all_goals[goalname]}
      current_item.interventions = prelude.sort-by (.name), goal_to_interventions[goalname]
      for intervention in current_item.interventions
        intervention.enabled_goals = []
        #if intervention.goals?
        #  intervention.enabled_goals = [goal for goal in intervention.goals when enabled_goals[goal.name]]
        intervention.enabled = (enabled_interventions[intervention.name] == true)
        intervention.automatic = (manually_managed_interventions[intervention.name] != true)
      list_of_goals_and_interventions.push current_item
    self.goals_and_interventions = list_of_goals_and_interventions
    this.fire 'goals_interventions_updated'
    if (Object.keys this.enabled_goals).length > 0 and ((window.location.href.indexOf 'introduction') > -1)
      this.$$('#goals-button').style.display = "inline-flex"

}