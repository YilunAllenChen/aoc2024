import gleam/dict
import gleam/function
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import glearray
import simplifile

pub type Token {
  X
  M
  A
  S
  Garbage
}

pub type Loc {
  Loc(y: Int, x: Int)
}

pub type LocToken {
  LocToken(token: Token, loc: Loc)
}

fn to_token(s: String) {
  case s {
    "X" -> X
    "M" -> M
    "A" -> A
    "S" -> S
    _ -> Garbage
  }
}

fn legal_next_token(tok: Token) {
  case tok {
    X -> M
    M -> A
    A -> S
    _ -> Garbage
  }
}

pub type Direction {
  Left
  Top
  TopLeft
  TopRight
  Right
  Bottom
  BottomLeft
  BottomRight
}

pub fn next_loc(dir: Direction, loc: Loc) {
  case dir {
    Left -> Loc(x: loc.x - 1, y: loc.y)
    Top -> Loc(x: loc.x, y: loc.y - 1)
    TopLeft -> Loc(x: loc.x - 1, y: loc.y - 1)
    TopRight -> Loc(x: loc.x + 1, y: loc.y - 1)
    Right -> Loc(x: loc.x + 1, y: loc.y)
    Bottom -> Loc(x: loc.x, y: loc.y + 1)
    BottomLeft -> Loc(x: loc.x - 1, y: loc.y + 1)
    BottomRight -> Loc(x: loc.x + 1, y: loc.y + 1)
  }
}

fn tokenize() {
  case simplifile.read("./data/d4.data") {
    Ok(content) ->
      content
      |> string.split("\n")
      |> list.filter(fn(line) { line != "" })
      |> list.index_map(fn(line, y) {
        line
        |> string.to_graphemes
        |> list.index_map(fn(char, x) {
          LocToken(token: to_token(char), loc: Loc(x: x, y: y))
        })
      })
      |> list.flatten
    Error(_err) -> panic as "could not read file"
  }
}

fn traverse(acc: List(LocToken), avail: set.Set(LocToken), dir: Direction) {
  case list.last(acc) {
    Error(_) -> panic as "acc is empty! should start with something at least..."
    Ok(LocToken(S, _)) -> option.Some(acc)
    Ok(LocToken(tailtok, tailloc)) -> {
      let expected_tok =
        LocToken(token: legal_next_token(tailtok), loc: next_loc(dir, tailloc))

      case set.contains(avail, expected_tok) {
        False -> option.None
        True -> {
          traverse(list.append(acc, [expected_tok]), avail, dir)
        }
      }
    }
  }
}

fn traverse_for_all_dirs(start: LocToken, avail: set.Set(LocToken)) {
  [Left, Top, TopLeft, TopRight, Right, Bottom, BottomLeft, BottomRight]
  |> list.map(fn(dir) { traverse([start], avail, dir) })
  |> list.filter(fn(res) { res != option.None })
}

fn xmas_form_around_loc(loc: Loc, all_loctoks: set.Set(LocToken)) {
  let valid_placements = [
    [
      LocToken(S, next_loc(TopRight, loc)),
      LocToken(S, next_loc(TopLeft, loc)),
      LocToken(M, next_loc(BottomLeft, loc)),
      LocToken(M, next_loc(BottomRight, loc)),
    ],
    [
      LocToken(S, next_loc(BottomLeft, loc)),
      LocToken(S, next_loc(TopLeft, loc)),
      LocToken(M, next_loc(TopRight, loc)),
      LocToken(M, next_loc(BottomRight, loc)),
    ],
    [
      LocToken(S, next_loc(TopRight, loc)),
      LocToken(S, next_loc(BottomRight, loc)),
      LocToken(M, next_loc(TopLeft, loc)),
      LocToken(M, next_loc(BottomLeft, loc)),
    ],
    [
      LocToken(S, next_loc(BottomRight, loc)),
      LocToken(S, next_loc(BottomLeft, loc)),
      LocToken(M, next_loc(TopLeft, loc)),
      LocToken(M, next_loc(TopRight, loc)),
    ],
  ]
  valid_placements
  |> list.map(fn(placements) {
    list.all(placements, fn(loctok) { set.contains(all_loctoks, loctok) })
  })
  |> list.any(function.identity)
}

pub fn part1() {
  let useful_loctoks =
    tokenize()
    |> list.filter(fn(loktok) { loktok.token != Garbage })

  let loctoks_set = useful_loctoks |> set.from_list

  let x_loctoks =
    useful_loctoks
    |> list.filter(fn(loktok) { loktok.token == X })

  x_loctoks
  |> list.map(fn(loktok) { traverse_for_all_dirs(loktok, loctoks_set) })
  |> list.flatten
  |> list.length
  |> io.debug
}

pub fn part2() {
  let useful_loctoks =
    tokenize()
    |> list.filter(fn(loktok) { loktok.token != Garbage })

  let loctok_set = useful_loctoks |> set.from_list

  useful_loctoks
  |> list.filter(fn(loktok) { loktok.token == A })
  |> list.map(fn(loktok) { xmas_form_around_loc(loktok.loc, loctok_set) })
  |> list.count(function.identity)
  |> io.debug
}
