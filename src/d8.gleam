import gleam/dict
import gleam/io
import gleam/list
import gleam/set
import gleam/string
import inputs

pub type Loc {
  Loc(y: Int, x: Int)
}

pub type Antenna {
  Antenna(kind: String, loc: Loc)
}

pub type Map {
  Map(
    length: Int,
    height: Int,
    antennas: dict.Dict(String, List(Antenna)),
    antinodes: set.Set(Loc),
  )
}

fn debug_map(map: Map) {
  let antennas_expr =
    dict.fold(map.antennas, "", fn(acc, kind, antennas) {
      acc
      <> "\n"
      <> kind
      <> " -> "
      <> list.fold(antennas, "", fn(acc, antenna) {
        acc <> string.inspect(antenna.loc) <> " "
      })
    })

  let antinodes_expr =
    set.fold(map.antinodes, "", fn(acc, loc) {
      acc <> string.inspect(loc) <> " "
    })

  {
    "Dims"
    <> string.inspect(map.length)
    <> " x "
    <> string.inspect(map.height)
    <> "\n\nAntennas"
    <> antennas_expr
    <> "\n\nAntinodes\n"
    <> antinodes_expr
  }
  |> io.println

  map
}

fn init_map() {
  let chars_and_locs =
    inputs.readfile("./data/d8.data")
    |> list.index_map(fn(line, y) {
      string.to_graphemes(line)
      |> list.index_map(fn(char, x) { #(char, Loc(y, x)) })
    })
    |> list.flatten

  let max_x =
    list.fold(chars_and_locs, 0, fn(acc, pair) {
      case { pair.1 }.x > acc {
        True -> { pair.1 }.x
        False -> acc
      }
    })

  let max_y =
    list.fold(chars_and_locs, 0, fn(acc, pair) {
      case { pair.1 }.y > acc {
        True -> { pair.1 }.y
        False -> acc
      }
    })

  let antennas =
    chars_and_locs
    |> list.filter(fn(pair) { pair.0 != "." })
    |> list.map(fn(pair) { Antenna(kind: pair.0, loc: pair.1) })
    |> list.group(fn(antenna) { antenna.kind })

  Map(length: max_x, height: max_y, antennas: antennas, antinodes: set.new())
}

fn potential_antinodes_locs_of(left: Antenna, right: Antenna) {
  let dx = right.loc.x - left.loc.x
  let dy = right.loc.y - left.loc.y
  set.from_list([
    Loc(left.loc.y - dy, left.loc.x - dx),
    Loc(right.loc.y + dy, right.loc.x + dx),
  ])
}

pub fn find_all_potential_antinodes(antennas: List(Antenna)) {
  let all_pairs = list.combination_pairs(antennas)
  list.fold(all_pairs, set.new(), fn(acc, pair) {
    let #(left, right) = pair
    set.union(acc, potential_antinodes_locs_of(left, right))
  })
}

fn loc_is_within_bounds(map: Map, loc: Loc) {
  loc.x >= 0 && loc.x <= map.length && loc.y >= 0 && loc.y <= map.height
}

fn keep_resonating_rec(acc: set.Set(Loc), current: Loc, dxdy: Loc, map: Map) {
  let dx = dxdy.x
  let dy = dxdy.y
  let newloc = Loc(current.y + dy, current.x + dx)
  case loc_is_within_bounds(map, newloc) {
    True -> keep_resonating_rec(set.insert(acc, newloc), newloc, dxdy, map)
    False -> acc
  }
}

pub fn find_all_resonating_antinodes_for_pair(
  map: Map,
  left: Antenna,
  right: Antenna,
) {
  let dx = right.loc.x - left.loc.x
  let dy = right.loc.y - left.loc.y

  let leftside = keep_resonating_rec(set.new(), left.loc, Loc(-dy, -dx), map)
  let rightside = keep_resonating_rec(set.new(), right.loc, Loc(dy, dx), map)
  set.union(leftside, rightside)
}

pub fn find_all_resonating_antinodes(map: Map, antennas: List(Antenna)) {
  let all_pairs = list.combination_pairs(antennas)
  list.fold(all_pairs, set.new(), fn(acc, pair) {
    let #(left, right) = pair
    set.union(acc, find_all_resonating_antinodes_for_pair(map, left, right))
  })
}

pub fn part1() {
  let init_map = init_map()
  let potential_antinodes =
    dict.values(init_map.antennas)
    |> list.map(find_all_potential_antinodes)
    |> list.map(fn(potential_antinodes) {
      set.to_list(potential_antinodes)
      |> list.filter(loc_is_within_bounds(init_map, _))
    })
    |> list.flatten
    |> list.fold(set.new(), set.insert)

  let final = Map(..init_map, antinodes: potential_antinodes) |> debug_map
  final.antinodes |> set.size |> io.debug
}

pub fn part2() {
  let init_map = init_map()
  let potential_antinodes =
    dict.values(init_map.antennas)
    |> list.map(find_all_resonating_antinodes(init_map, _))
    |> list.map(fn(potential_antinodes) {
      set.to_list(potential_antinodes)
      |> list.filter(loc_is_within_bounds(init_map, _))
    })
    |> list.flatten
    |> list.fold(set.new(), set.insert)

  let antennas_as_antinodes =
    dict.values(init_map.antennas)
    |> list.flatten
    |> list.map(fn(antenna) { antenna.loc })
    |> set.from_list

  let all_antennas = set.union(potential_antinodes, antennas_as_antinodes)

  let final = Map(..init_map, antinodes: all_antennas) |> debug_map
  final.antinodes |> set.size |> io.debug
}
