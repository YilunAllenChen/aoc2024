import gleam/function.{identity}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import rememo/memo
import simplifile

pub type Equation {
  Equation(test_val: Int, operands: List(Int))
}

pub type Operator {
  Add
  Mult
  Concat
}

fn perform(op: Operator, left: Int, right: Int) {
  case op {
    Add -> left + right
    Mult -> left * right
    Concat ->
      case
        string.concat([left, right] |> list.map(string.inspect)) |> int.parse
      {
        Ok(parsed) -> parsed
        Error(_) -> panic as "not possible"
      }
  }
}

pub type Attempt {
  Attempt(equation: Equation, operators: List(Operator))
}

fn eval_attempt(attempt: Attempt, cache) {
  use <- memo.memoize(cache, attempt)
  let equation = attempt.equation
  case equation.operands {
    [] -> 0
    [only_one] -> only_one
    [hd_operand, ..rest_operands] -> {
      let ops = list.zip(rest_operands, attempt.operators)
      list.fold(over: ops, from: hd_operand, with: fn(acc, op) {
        let #(operand, operator) = op
        perform(operator, acc, operand)
      })
    }
  }
}

fn solve_rec(
  equation: Equation,
  candidates: List(Attempt),
  allowed_operators: List(Operator),
  cache,
) {
  case candidates {
    [] -> False
    [hd_soln, ..rest_solns] -> {
      let len_diff =
        { list.length(hd_soln.operators) + 1 }
        - { list.length(equation.operands) }

      case len_diff {
        0 -> {
          case eval_attempt(hd_soln, cache) == equation.test_val {
            True -> True
            False -> solve_rec(equation, rest_solns, allowed_operators, cache)
          }
        }
        other if other > 0 -> {
          // if too many operators, no solution
          solve_rec(equation, rest_solns, allowed_operators, cache)
        }
        other if other < 0 -> {
          let equation_val_already_too_big =
            eval_attempt(hd_soln, cache) > equation.test_val
          case equation_val_already_too_big {
            True -> solve_rec(equation, rest_solns, allowed_operators, cache)
            False -> {
              let new_attempts =
                allowed_operators
                |> list.map(fn(op) { list.append(hd_soln.operators, [op]) })
                |> list.map(fn(new_ops) {
                  Attempt(..hd_soln, operators: new_ops)
                })
              solve_rec(
                equation,
                list.append(new_attempts, rest_solns),
                allowed_operators,
                cache,
              )
            }
          }
        }
        _ -> panic as "not possible"
      }
    }
  }
}

fn line_to_equation(line: String) {
  use #(val_str, operands_str) <- result.try(string.split_once(line, ":"))
  use test_val <- result.try(int.parse(val_str))
  let operands =
    string.split(operands_str, " ")
    |> list.map(int.parse)
    |> list.filter_map(identity)
  Ok(Equation(test_val, operands))
}

fn parse_equations() {
  simplifile.read("./data/d7.data")
  |> result.unwrap("")
  |> string.split("\n")
  |> list.filter(fn(line) { line != "" })
  |> list.map(line_to_equation)
  |> list.filter_map(identity)
}

pub fn part1() {
  use cache <- memo.create()
  parse_equations()
  |> list.filter(fn(equation) {
    solve_rec(
      equation,
      [Attempt(equation, [Add]), Attempt(equation, [Mult])],
      [Add, Mult],
      cache,
    )
  })
  |> list.map(fn(attempt) { attempt.test_val })
  |> list.fold(0, int.add)
  |> io.debug
}

pub fn part2() {
  use cache <- memo.create()
  parse_equations()
  |> list.filter(fn(equation) {
    solve_rec(
      equation,
      [
        Attempt(equation, [Add]),
        Attempt(equation, [Mult]),
        Attempt(equation, [Concat]),
      ],
      [Add, Mult, Concat],
      cache,
    )
  })
  |> list.map(fn(attempt) { attempt.test_val })
  |> list.fold(0, int.add)
  |> io.debug
}
