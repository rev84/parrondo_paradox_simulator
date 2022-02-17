window.INTERVAL_SEC = 1

window.draw_count = 1
window.statuses = {}
window.logs = {}
window.games = {}
window.charts = {}
window.titles = [
  '所持金3n',
  '所持金3n+1',
  '所持金3n+2',
]
window.main_game = {
  title: '本命ゲーム'
  p: {
    game_a: 0.5,
    game_b: 0.5
  },
}
window.DEFAULT_GAMES = {
  'game_a': {
    title: 'ゲームA',
    p: [
      [0, 0.48, 0.52],
      [0.52, 0, 0.48],
      [0.48, 0.52, 0],
    ],
    to: [
      [0, 1, 2],
      [0, 1, 2],
      [0, 1, 2],
    ],
    gain: [
      [0, 1, -1],
      [-1, 0, 1],
      [1, -1, 0],
    ]
  },
  'game_b': {
    title: 'ゲームB',
    p: [
      [0, 0.01, 0.99],
      [0.15, 0, 0.85],
      [0.85, 0.15, 0],
    ],
    to: [
      [0, 1, 2],
      [0, 1, 2],
      [0, 1, 2],
    ],
    gain: [
      [0, 1, -1],
      [-1, 0, 1],
      [1, -1, 0],
    ]
  }
}

window.timer = null

$().ready ->
  init_charts()
  init()
  $('#start').on 'click', ->
    if window.timer is null then start() else stop()
  $('#draw_count').on 'change', ->
    window.draw_count = Number $(@).val()

start = ->
  stop()
  init()
  window.timer = setTimeout(calc, window.INTERVAL_SEC)

stop = ->
  clearInterval window.timer unless window.timer is null
  window.timer = null

calc = (id)->
  calc_main()
  calc_game('game_a')
  calc_game('game_b')
  setTimeout(calc, window.INTERVAL_SEC) unless window.timer is null

calc_main = ->
  seed = lot()
  p_total = 0
  selected_game_name = undefined
  Object.keys(window.main_game.p).map (game_name)->
    p = window.main_game.p[game_name]
    p_total += p
    selected_game_name = game_name if seed < p_total and selected_game_name is undefined

  result = play_game(selected_game_name, window.statuses['game_main'].state)
  push('game_main', result)
  draw_graph('game_main', 'recent_game_main', window.logs.game_main.status_recent_logs)
  draw_graph('game_main', 'all_game_main', window.logs.game_main.status_all_logs)
  draw_summary('game_main')

calc_game = (id)->
  result = play_game(id, window.statuses[id].state)
  push(id, result)
  draw_graph(id, 'recent_'+id, window.logs[id].status_recent_logs)
  draw_graph(id, 'all_'+id, window.logs[id].status_all_logs)
  draw_summary(id)

push = (id, result)->
  window.statuses[id].step += 1
  window.statuses[id].money += result.gain
  window.statuses[id].state = result.state
  
  window.logs[id].status_all_logs.push(window.statuses[id].clone()) unless window.statuses[id].step % 100
  window.logs[id].status_recent_logs.push(window.statuses[id].clone())
  window.logs[id].status_recent_logs.shift() if window.logs[id].status_recent_logs.length > 1000

draw_summary = (id)->
  return if window.statuses[id].step % window.draw_count

  $('#step_'+id).html(window.statuses[id].step)
  $('#money_'+id).html(format_money(window.statuses[id].money))
  $('#dps_'+id).html(format_money(window.statuses[id].money / window.statuses[id].step, 5))

draw_graph = (id, graph_id, statuses)->
  return if statuses.length <= 0
  return if window.statuses[id].step % window.draw_count

  window.charts[graph_id].data.datasets[0].data = statuses.map (v)-> v.money
  window.charts[graph_id].data.labels = statuses.map (v)-> v.step
  window.charts[graph_id].update()

play_game = (id, state_before)->
  game = window.games[id]
  seed = lot()
  p_total = 0
  selected_index = undefined
  game.p[state_before].map (p, index)->
    p_total += p
    selected_index = index if seed < p_total and selected_index is undefined

  state = game.to[state_before][selected_index]
  gain = game.gain[state_before][selected_index]

  {state: state, gain: gain}

init = ->
  window.games = window.DEFAULT_GAMES;
  init_st()
  reflect_games()
  reflect_main_game()
  window.draw_count = Number $('#draw_count').val()
  ['game_main'].concat(Object.keys(window.main_game.p)).map (game_name)->
    window.logs[game_name].status_all_logs.push(window.statuses[game_name].clone())
    window.logs[game_name].status_recent_logs.push(window.statuses[game_name].clone())

init_charts = ->
  ['game_main'].concat(Object.keys(window.main_game.p)).map (game_name)->
    window.charts['recent_'+game_name] = chart_default('recent_'+game_name)
    window.charts['all_'+game_name] = chart_default('all_'+game_name)

init_st = ->
  window.step = 0
  window.statuses = {}
  window.logs = {}
  ['game_main'].concat(Object.keys(window.main_game.p)).map (game_name)->
    window.statuses[game_name] = new Status(0, 0, 0)
    window.logs[game_name] = logs_default()

reflect_main_game = ->
  thead = $('#game_main thead')
  thead.html('').append(
    $('<tr>').append(
      $('<th>').html('ゲーム')
    ).append(
      $('<th>').html('確率')
    )
  )

  tbody = $('#game_main tbody')
  tbody.html('')
  Object.keys(window.main_game.p).map (game_name)->
    p = window.main_game.p[game_name]
    tr = $('<tr>')
    tr.append(
      $('<td>').html(window.games[game_name].title)
    ).append(
      $('<td>').html ''+(p * 100)+'%'
    )
    tbody.append tr

reflect_games = ->
  Object.keys(window.games).map (k)->
    thead = $('#'+k+' thead')
    thead.html('')
    tr = $('<tr>').append(
      $('<th>').html('状態＼遷移先')
    )
    window.titles.map (title)->
      tr.append(
        $('<th>').html(title)
      )
    thead.append tr

    tbody = $('#'+k+' tbody')
    tbody.html('')
    window.games[k].p.map (v, index)->
      tr = $('<tr>').append(
        $('<th>').html(window.titles[index])
      )
      v.map (p, to_index)->
        gain = window.games[k].gain[index][to_index]
        text = (p * 100)+"%<br>"+format_money(gain)
        tr.append(
          $('<td>').html(
            if p is 0 then '-' else text
          )
        )
      tbody.append tr

# p[a][b]: aでの発生する確率
# to[a][b]: p発生時の遷移先
# gain[a][b] p発生時の報酬
set_game = (id, to_array, gain_array)->
  window.games[id] = {
    p: to_array,
    to: to_array,
    gain: gain_array
  }


lot = ->
  Math.random()

logs_default = ->
  {
    status_all_logs: []
    status_recent_logs: []
  }

chart_default = (id)->
  new Chart(document.getElementById(id).getContext('2d'), {
    type: 'line'
    data:
      labels: []
      datasets:[{
        data: [],
        steppedLine: false
        datalabels: 
          display: false
        showLine: true
        borderColor: 'rgb(0, 0, 255)'
        pointRadius: 0
        borderWidth: 1
      }]
    options:
      animation: false
      plugins:
        legend:
          display: false
  })

format_money = (money, fixed = 0)->
  amount = Math.abs(money)
  amount = amount.toFixed(fixed) if fixed > 0
  if money < 0
    '<span class="red">-'+amount+'$</span>'
  else
    '<span class="blue">+'+amount+'$</span>'

class Status
  constructor:(@step = 0, @money = 0, @state = 0)->
  clone:->
    new Status(
      @step,
      @money,
      @state
    )