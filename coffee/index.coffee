window.moneys = {}
window.money_histories = {}
window.status = {}
window.games = {}
window.step = 0
window.titles = [
  '所持金3n',
  '所持金3n+1',
  '所持金3n+2',
]
window.main_game = {
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

window.timer = null;

$().ready ->
  init()
  $('#start').on 'click', ->
    if window.timer is null then stop() else start()

start = ->
  stop()
  init()
  startInterval

stop = ->
  clearInterval window.timer if window.timer is null
  window.timer = null

calc = ->

calc_main = ->
  seed = lot()
  p_total = 0
  Object.keys(window.main_game.p).map (game_name)->
    p = window.main_game.p[game_name]
    p_total += p
    if seed < p_total

play_game = (id, status_before)->
  game = window.games[id]
  seed = lot()
  p_total = 0
  selected_index = undefined
  game.p[status_before].map (p, index)->
    p_total += p
    selected_index = index if seed < p_total and selected_index is undefined

  status = game.to[status_before][selected_index]
  gain = game.to[status_before][selected_index]

  {status: status, gain: gain}

init = ->
  window.games = window.DEFAULT_GAMES;
  init_st()
  reflect_games()
  reflect_main_game()

init_st = ->
  window.moneys = {game_main: 0}
  window.status = {game_main: 0}
  window.money_histories = {game_main: 0}
  window.step = 0
  Object.keys(window.main_game.p).map (game_name)->
    window.moneys[game_name] = 0
    window.status[game_name] = 0
    window.money_histories[game_name] = [0]

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
        text = (p * 100)+"%<br>"+
              (if gain < 0 then '<span class="red">-$' else '<span class="blue">$')+Math.abs(gain)+'</span>'
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