import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string
import inputs

pub type Loc {
  Loc(y: Int, x: Int)
}

pub type Trail {
  Trail(loc: Loc, z: Int)
}

pub type Map {
  Map(
    lookup: dict.Dict(Loc, Int),
    scores: dict.Dict(Loc, Int),
    length: Int,
    width: Int,
  )
}

fn max(lst: List(Int)) -> Int {
  list.fold(lst, -1, fn(acc, x) { int.max(acc, x) })
}

fn make_map() -> Map {
  let lookup =
    inputs.input("d10")
    |> list.index_map(fn(line, y) {
      line
      |> string.to_graphemes
      |> list.index_map(fn(c, x) {
        case int.parse(c) {
          Ok(n) -> Trail(Loc(y, x), n)
          Error(err) -> panic as string.inspect(err)
        }
      })
    })
    |> list.flatten
    |> list.map(fn(trail) { #(trail.loc, trail.z) })
    |> dict.from_list
    |> io.debug

  let length =
    lookup
    |> dict.keys
    |> list.map(fn(loc) { loc.x })
    |> max

  let width =
    lookup
    |> dict.keys
    |> list.map(fn(loc) { loc.y })
    |> max

  Map(
    lookup: lookup,
    scores: dict.map_values(lookup, fn(_, _) { 0 }),
    length: length,
    width: width,
  )
}

fn starting_pos_of(map: Map) -> List(Loc) {
  map.lookup
  |> dict.filter(fn(_, v) { v == 0 })
  |> dict.to_list
  |> list.map(fn(kv) { kv.0 })
}

fn within_bound(loc: Loc, map: Map) -> Bool {
  loc.x >= 0 && loc.x < map.length && loc.y >= 0 && loc.y < map.width
}

fn neighbors_of(loc: Loc, map: Map) -> List(Loc) {
  [
    Loc(loc.y + 1, loc.x),
    Loc(loc.y - 1, loc.x),
    Loc(loc.y, loc.x + 1),
    Loc(loc.y, loc.x - 1),
  ]
  |> list.filter(within_bound(_, map))
}

fn good_next_steps(trail: Trail, map: Map) -> List(Loc) {
  neighbors_of(trail.loc, map)
  |> list.filter(fn(loc) {
    case dict.get(map.lookup, loc) {
      Ok(z) -> z == trail.z + 1
      _ -> False
    }
  })
}

// fn travel_from(map: Map, 3)

pub fn part1() {
  let map = make_map()

  let starting_pos = starting_pos_of(map)
}

pub fn part2() {
  io.print("pt2")
}
