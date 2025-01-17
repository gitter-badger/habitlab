{polymer_ext} = require 'libs_frontend/polymer_utils'

{cfy} = require 'cfy'

require! {
  moment
}

prelude = require 'prelude-ls'

{
  get_multi_armed_bandit_algorithm
} = require 'libs_backend/multi_armed_bandit'

intervention_utils = require 'libs_common/intervention_utils'

polymer_ext {
  is: 'multi-armed-bandit-debug'
  properties: {
    goal: {
      type: String
      value: 'facebook/spend_less_time'
      observer: 'goal_changed'
    }
    mab_algorithm: {
      type: Object
      computed: 'compute_mab_algorithm(algorithm, algorithm_options)'
    }
    rewards_info: {
      type: Array
      value: []
    }
    chosen_intervention: {
      type: String
      value: ''
    }
    multi_armed_bandit: {
      type: Object
    }
    intervention_score_ranges: {
      type: Object
    }
    chosen_intervention_reward_value: {
      type: Number
    }
    regret_this_round: {
      type: Number
    }
    total_regret: {
      type: Number
      value: 0
    }
    total_rounds_played: {
      type: Number
      value: 0
    }
    average_regret: {
      type: Number
      computed: "compute_average_regret(total_regret, total_rounds_played)"
    }
    simulations_disabled: {
      type: Object
      value: {}
    }
    algorithm: {
      type: String
      value: 'thompson'
    }
    algorithm_options: {
      type: Object
      value: {}
    }
  }
  compute_mab_algorithm: (algorithm, algorithm_options) ->
    return get_multi_armed_bandit_algorithm(algorithm, algorithm_options)
  algorithm_changed: (evt) ->
    prev_algorithm = this.algorithm
    new_algorithm = evt.target.name
    if prev_algorithm == new_algorithm
      return
    # algorithm was changed!
    console.log 'algorithm changed to ' + new_algorithm
    this.algorithm = new_algorithm
  get_lower_range_time: (intervention_name, intervention_score_ranges) ->
    lower_range = intervention_score_ranges[intervention_name].min
    seconds = 3600 * Math.atanh(1 - lower_range)
    return moment.utc(1000*seconds).format('HH:mm:ss')
  get_upper_range_time: (intervention_name, intervention_score_ranges) ->
    upper_range = intervention_score_ranges[intervention_name].max
    seconds = 3600 * Math.atanh(1 - upper_range)
    return moment.utc(1000*seconds).format('HH:mm:ss')
  compute_average_regret: (total_regret, total_rounds_played) ->
    return total_regret / total_rounds_played
  retrain_multi_armed_bandit: cfy ->*
    goal_name = this.goal
    intervention_names = yield intervention_utils.list_available_interventions_for_goal(goal_name)
    intervention_names = [x for x in intervention_names when this.simulations_disabled[x] != true]
    this.multi_armed_bandit = yield this.mab_algorithm.train_multi_armed_bandit_for_goal(goal_name, intervention_names)
    this.update_rewards_info()
  goal_changed: cfy ->*
    goal_name = this.goal
    console.log "new goal is #{goal_name}"
    #this.multi_armed_bandit = null
    yield this.retrain_multi_armed_bandit()
  disable_intervention_in_simulation: cfy (evt) ->*
    intervention = evt.target.intervention
    this.simulations_disabled[evt.target.intervention] = !evt.target.checked
    this.multi_armed_bandit = null
    this.total_rounds_played = 0
    this.total_regret = 0
    yield this.retrain_multi_armed_bandit()
  is_simulation_enabled: (intervention, simulations_disabled) ->
     return simulations_disabled[intervention] != true
  update_rewards_info: ->
    new_rewards_info = []
    for arm in this.multi_armed_bandit.arms_list
      intervention = arm.reward
      if arm.trials == 0
        average_score = 0
      else
        average_score = arm.wins / arm.trials
      num_trials = arm.trials
      new_rewards_info.push {
        intervention
        average_score
        num_trials
      }
    console.log new_rewards_info
    this.rewards_info = new_rewards_info
  slider_changed: (evt) ->
    score_ranges = {}
    for slider in this.$$$('.intervention_score_range')
      value_min = parseFloat slider.getAttribute('value-min')
      value_max = parseFloat slider.getAttribute('value-max')
      intervention = slider.intervention
      score_ranges[intervention] = {
        min: value_min
        max: value_max
      }
    console.log 'score ranges are now'
    console.log score_ranges
    this.intervention_score_ranges = score_ranges
  get_reward_values_for_all_interventions: ->
    output = {}
    for intervention,score_range of this.intervention_score_ranges
      reward_value = score_range.min + Math.random()*(score_range.max - score_range.min)
      output[intervention] = reward_value
    return output
  to_id: (intervention_name) ->
    alphabet = ['a' to 'z'].concat ['A' to 'Z'].concat ['0' to '9']
    output = intervention_name.split('').filter(-> alphabet.indexOf(it) != -1).join('')
    console.log output
    return output
  choose_intervention: cfy ->*
    console.log 'choose intervention button clicked'
    goal_name = this.goal
    if not this.multi_armed_bandit?
      this.total_rounds_played = 0
      this.total_regret = 0
      yield this.retrain_multi_armed_bandit()
    arm = this.multi_armed_bandit.predict()
    intervention = arm.reward
    score_range = this.intervention_score_ranges[intervention]
    all_reward_values = this.get_reward_values_for_all_interventions()
    best_reward_value = prelude.maximum [v for k,v of all_reward_values]
    reward_value = all_reward_values[intervention]
    this.chosen_intervention = intervention
    this.chosen_intervention_reward_value = reward_value
    this.total_rounds_played += 1
    this.regret_this_round = best_reward_value - reward_value
    this.total_regret += this.regret_this_round
    this.multi_armed_bandit.learn(arm, reward_value)
    this.update_rewards_info()
    this.SM('.intervention_name').css 'background-color', 'white'
    #console.log this.S("#{this.to_id(intervention)}")
    this.S('#' + this.to_id(intervention)).css 'background-color', 'yellow'
    #this.$$("#{this.to_id(intervention)}").style.backgroundColor = 'red'
  ready: ->
    self = this
    self.once_available '.intervention_score_range', ->
      self.slider_changed()
}, {
  source: require 'libs_frontend/polymer_methods'
  methods: [
    '$$$'
    'SM'
    'S'
    'once_available'
  ]
}
