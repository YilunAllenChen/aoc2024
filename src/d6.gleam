import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import simplifile

pub type Loc {
  Loc(y: Int, x: Int)
}

pub type Marker {
  Wall(loc: Loc)
  Space(loc: Loc)
  Visited(loc: Loc)
  Start(loc: Loc)
}

pub type Facing {
  Left
  Right
  Up
  Down
}

pub type Step {
  Step(start_loc: Loc, facing: Facing)
}

pub type Map {
  Map(
    markers: List(Marker),
    walls: set.Set(Loc),
    visited: set.Set(Loc),
    max_x: Int,
    max_y: Int,
    curr_loc: Loc,
    curr_facing: Facing,
    // for part 2
    steps: set.Set(Step),
    contains_loop: Bool,
  )
}

pub fn debugmap(map: Map) {
  map.markers
  |> list.fold("", fn(acc, marker) {
    let is_newline = marker.loc.x == 0
    let repr = case marker {
      Wall(_) -> "#"
      Space(loc) ->
        case set.contains(map.visited, loc) {
          True -> "x"
          False -> "."
        }
      Visited(_) -> "x"
      Start(_) -> "S"
    }

    case is_newline {
      True -> acc <> "\n" <> repr
      False -> acc <> repr
    }
  })
  |> io.println
  map
}

fn turn(facing: Facing) {
  case facing {
    Left -> Up
    Up -> Right
    Right -> Down
    Down -> Left
  }
}

fn ahead(loc: Loc, facing: Facing) {
  case facing {
    Left -> Loc(x: loc.x - 1, y: loc.y)
    Right -> Loc(x: loc.x + 1, y: loc.y)
    Up -> Loc(x: loc.x, y: loc.y - 1)
    Down -> Loc(x: loc.x, y: loc.y + 1)
  }
}

fn init_map() {
  let markers =
    simplifile.read("./data/d6.data")
    |> result.unwrap("")
    |> string.split("\n")
    |> list.filter(fn(line) { line != "" })
    |> list.index_map(fn(line, lineno) {
      list.index_map(string.to_graphemes(line), fn(char, colno) {
        case char {
          "#" -> Ok(Wall(Loc(lineno, colno)))
          "^" -> Ok(Start(Loc(lineno, colno)))
          "." -> Ok(Space(Loc(lineno, colno)))
          _ -> Error(Nil)
        }
      })
    })
    |> list.flatten
    |> list.filter_map(function.identity)

  let curr_loc =
    list.find_map(markers, fn(marker) {
      case marker {
        Start(loc) -> Ok(loc)
        _ -> Error(Nil)
      }
    })
    |> result.unwrap(Loc(-1, -1))
  let walls =
    list.filter_map(markers, fn(marker) {
      case marker {
        Wall(loc) -> Ok(loc)
        _ -> Error(Nil)
      }
    })
    |> set.from_list

  let max_x =
    list.fold(markers, 0, fn(acc, marker) {
      case marker.loc.x > acc {
        True -> marker.loc.x
        False -> acc
      }
    })

  let max_y =
    list.fold(markers, 0, fn(acc, marker) {
      case marker.loc.y > acc {
        True -> marker.loc.y
        False -> acc
      }
    })
  Map(
    markers: markers,
    walls: walls,
    max_x: max_x,
    max_y: max_y,
    steps: set.new(),
    curr_loc: curr_loc,
    curr_facing: Up,
    visited: set.new(),
    contains_loop: False,
  )
}

fn dispatch(map: Map) {
  let curr_loc = map.curr_loc
  let is_out =
    curr_loc.x < 0
    || curr_loc.x > map.max_x
    || curr_loc.y < 0
    || curr_loc.y > map.max_y

  case is_out {
    True -> map
    False -> {
      let next_loc = ahead(map.curr_loc, map.curr_facing)
      let wall_ahead = set.contains(map.walls, next_loc)
      let next_facing = case wall_ahead {
        True -> turn(map.curr_facing)
        False -> map.curr_facing
      }
      let this_step = Step(map.curr_loc, map.curr_facing)
      case set.contains(map.steps, this_step) {
        True -> Map(..map, contains_loop: True)
        False ->
          Map(
            ..map,
            curr_loc: case wall_ahead {
              True -> map.curr_loc
              False -> next_loc
            },
            curr_facing: next_facing,
            visited: set.insert(map.visited, map.curr_loc),
            steps: set.insert(map.steps, Step(map.curr_loc, map.curr_facing)),
          )
          |> dispatch
      }
    }
  }
}

pub fn part1() {
  let final_map =
    init_map()
    |> dispatch
    |> debugmap

  final_map.visited
  |> set.size
  |> int.add(1)
  |> io.debug
}

pub fn part2() {
  let orig_map = init_map()
  let candidate_placements = dispatch(orig_map).visited
  candidate_placements
  |> set.to_list
  |> list.map(fn(loc) {
    Map(..orig_map, walls: set.insert(orig_map.walls, loc))
  })
  |> list.map(dispatch)
  |> list.filter(fn(map) { map.contains_loop })
  |> list.length
  |> io.debug
}
