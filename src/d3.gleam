import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type Token {
  M
  U
  L
  LParen
  Digit(dig: String)
  Comma
  RParen
  Garbage
  D
  O
  N
  Tick
  T
}

fn to_token(s: String) {
  case s {
    "(" -> LParen
    ")" -> RParen
    "," -> Comma
    "m" -> M
    "u" -> U
    "l" -> L
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> Digit(s)
    "d" -> D
    "o" -> O
    "n" -> N
    "t" -> T
    "'" -> Tick
    _ -> Garbage
  }
}

fn is_valid_succ(left: Token, right: Token) {
  case left {
    M -> right == U
    U -> right == L
    L -> right == LParen
    LParen ->
      case right {
        Digit(_) | RParen -> True
        _ -> False
      }
    Digit(_) ->
      case right {
        Digit(_) | Comma | RParen -> True
        _ -> False
      }
    Comma ->
      case right {
        Digit(_) -> True
        _ -> False
      }
    RParen ->
      case right {
        Garbage -> False
        _ -> True
      }
    Garbage ->
      case right {
        _ -> False
      }

    D -> right == O
    O -> right == N || right == LParen
    N -> right == Tick
    T -> right == LParen
    Tick -> right == T
  }
}

fn eval_digits(digits: List(Token)) {
  digits
  |> list.fold(0, fn(acc, token) {
    case token {
      Digit(dig) -> acc * 10 + result.unwrap(int.parse(dig), 0)
      _ -> acc
    }
  })
}

pub type Valuation {
  STOP
  RESUME
  Value(val: Int)
}

fn eval_valid_expr(tokens: List(Token)) {
  let first = list.first(tokens) |> result.unwrap(Garbage)
  case first {
    D ->
      case list.contains(tokens, Tick) {
        True -> STOP
        False -> RESUME
      }
    M -> {
      let #(left, right) = list.split_while(tokens, fn(tok) { tok != Comma })
      let left_val = eval_digits(left)
      let right_val = eval_digits(right)
      Value(left_val * right_val)
    }
    _ -> panic as "invalid expr"
  }
}

fn expr_is_ready(tokens: List(Token)) {
  let first = list.first(tokens) |> result.unwrap(Garbage)
  let last = list.last(tokens) |> result.unwrap(Garbage)
  case first, last {
    M, RParen | D, RParen -> True
    _, _ -> False
  }
}

fn collect(acc: List(List(Token)), wip: List(Token), rest: List(Token)) {
  case rest {
    [] -> acc
    [hd, ..tl] -> {
      case list.last(wip) {
        Error(Nil) -> {
          case hd {
            M | D -> collect(acc, [hd], tl)
            _ -> collect(acc, [], tl)
          }
        }
        Ok(last) -> {
          case is_valid_succ(last, hd) {
            False -> collect(acc, [], rest)
            True -> {
              let new_wip = list.append(wip, [hd])
              case expr_is_ready(new_wip) {
                True -> collect(list.append(acc, [new_wip]), [], tl)
                False -> collect(acc, new_wip, tl)
              }
            }
          }
        }
      }
    }
  }
}

pub fn read_as_exprs() {
  let content =
    simplifile.read("./data/d3.data")
    |> result.unwrap("")
    |> string.to_graphemes
    |> list.map(to_token)

  collect([], [], content)
  |> list.map(eval_valid_expr)
}

pub fn part1() {
  read_as_exprs()
  |> list.fold(0, fn(acc, expr) {
    case expr {
      STOP | RESUME -> acc
      Value(val) -> {
        acc + val
      }
    }
  })
  |> io.debug
}

pub type PausableAccumulator {
  Accumulator(collecting: Bool, value: Int)
}

pub fn part2() {
  read_as_exprs()
  |> list.map(io.debug)
  |> list.fold(Accumulator(True, 0), fn(acc, expr) {
    case expr {
      STOP -> Accumulator(False, acc.value)
      RESUME -> Accumulator(True, acc.value)
      Value(val) -> {
        let new_val = case acc.collecting {
          True -> acc.value + val
          False -> acc.value
        }
        Accumulator(acc.collecting, new_val)
      }
    }
  })
}
