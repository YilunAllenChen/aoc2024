import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import simplifile

pub type Relation {
  Relation(left: String, right: String)
}

pub type Report {
  Report(pages: List(String))
}

pub type Constraint {
  Constraint(
    key: String,
    has_to_be_left_of: set.Set(String),
    has_to_be_right_of: set.Set(String),
  )
}

fn relations_to_constraints(
  relations: List(Relation),
) -> dict.Dict(String, Constraint) {
  list.fold(over: relations, from: dict.new(), with: fn(acc, relation) {
    let left = relation.left
    let right = relation.right
    let temp = case dict.get(acc, left) {
      Ok(cons) -> {
        dict.insert(
          acc,
          left,
          Constraint(
            ..cons,
            has_to_be_left_of: set.insert(cons.has_to_be_left_of, right),
          ),
        )
      }
      Error(Nil) ->
        dict.insert(
          acc,
          left,
          Constraint(left, set.insert(set.new(), right), set.new()),
        )
    }
    case dict.get(temp, right) {
      Ok(cons) -> {
        dict.insert(
          temp,
          right,
          Constraint(
            ..cons,
            has_to_be_right_of: set.insert(cons.has_to_be_right_of, left),
          ),
        )
      }
      Error(Nil) ->
        dict.insert(
          temp,
          right,
          Constraint(right, set.new(), set.insert(set.new(), left)),
        )
    }
  })
}

fn rule_str_to_relation(rule: String) -> Relation {
  let #(left, right) = case string.split_once(rule, "|") {
    Ok(pair) -> pair
    Error(_) -> panic as "bad rule"
  }
  Relation(left, right)
}

fn report_str_to_report(report: String) -> Report {
  Report(string.split(report, ","))
}

fn left_legal_placements(
  lefts: List(String),
  curr: String,
  constraints: dict.Dict(String, Constraint),
) {
  case dict.get(constraints, curr) {
    Ok(Constraint(_, has_to_be_left_of, _)) -> {
      case set.size(set.intersection(set.from_list(lefts), has_to_be_left_of)) {
        0 -> True
        _ -> False
      }
    }
    Error(Nil) -> {
      panic as "constraint not found"
    }
  }
}

fn seq_satisfy_constraints(
  left: List(String),
  curr: String,
  right: List(String),
  constraints: dict.Dict(String, Constraint),
) {
  case right {
    [] -> left_legal_placements(left, curr, constraints)
    [hd, ..tl] -> {
      case left_legal_placements(left, curr, constraints) {
        True ->
          seq_satisfy_constraints(
            list.append(left, [curr]),
            hd,
            tl,
            constraints,
          )
        False -> False
      }
    }
  }
}

fn report_is_valid(constraints: dict.Dict(String, Constraint), report: Report) {
  case report.pages {
    [] -> True
    [hd, ..tl] -> seq_satisfy_constraints([], hd, tl, constraints)
  }
}

fn mid_page_in_report(report: Report) {
  let len = list.length(report.pages)
  let mid = len / 2
  list.take(report.pages, mid + 1)
  |> list.last
  |> result.unwrap("0")
  |> int.parse
  |> result.unwrap(0)
}

pub fn part1() {
  let #(rules, reports) =
    simplifile.read("./data/d5.data")
    |> result.unwrap("")
    |> string.split("\n")
    |> list.filter(fn(line) { line != "" })
    |> list.partition(fn(line) { string.contains(line, "|") })

  let constraints =
    rules
    |> list.map(rule_str_to_relation)
    |> relations_to_constraints

  reports
  |> list.map(report_str_to_report)
  |> list.filter(fn(rep) { report_is_valid(constraints, rep) })
  |> list.map(mid_page_in_report)
  |> list.fold(0, int.add)
  |> io.debug
}

fn keep_ordering(
  sorted: List(String),
  constraints: dict.Dict(String, Constraint),
) {
  case dict.size(constraints) {
    0 -> sorted
    _ -> {
      let ready_to_push =
        dict.filter(constraints, fn(_, cons) {
          set.size(cons.has_to_be_right_of) == 0
        })
      case dict.size(ready_to_push) {
        0 -> sorted
        _ -> {
          let new_sorted = list.append(sorted, dict.keys(ready_to_push))
          let new_dict =
            dict.map_values(constraints, fn(_, cons) {
              Constraint(
                ..cons,
                has_to_be_right_of: set.drop(
                  cons.has_to_be_right_of,
                  dict.keys(ready_to_push),
                ),
              )
            })
            |> dict.drop(dict.keys(ready_to_push))
          keep_ordering(new_sorted, new_dict)
        }
      }
    }
  }
}

fn total_order(constraints: dict.Dict(String, Constraint)) {
  let need_orderings = dict.keys(constraints) |> set.from_list
  keep_ordering(
    [],
    constraints
      |> dict.map_values(fn(_, con) {
        Constraint(
          ..con,
          has_to_be_left_of: set.intersection(
            con.has_to_be_left_of,
            need_orderings,
          ),
          has_to_be_right_of: set.intersection(
            con.has_to_be_right_of,
            need_orderings,
          ),
        )
      }),
  )
}

fn debug_contraint(con: Constraint) {
  io.println(
    con.key
    <> " has to be right of "
    <> string.inspect(set.to_list(con.has_to_be_right_of)),
  )
}

pub fn part2() {
  let #(rules, reports) =
    simplifile.read("./data/d5.data")
    |> result.unwrap("")
    |> string.split("\n")
    |> list.filter(fn(line) { line != "" })
    |> list.partition(fn(line) { string.contains(line, "|") })

  let constraints =
    rules
    |> list.map(rule_str_to_relation)
    |> relations_to_constraints

  reports
  |> list.map(report_str_to_report)
  |> list.filter(fn(rep) { !report_is_valid(constraints, rep) })
  |> list.map(fn(bad_rep) {
    let seen_pages = bad_rep.pages |> set.from_list
    let partial_contraints =
      dict.filter(constraints, fn(_, cons) {
        set.contains(seen_pages, cons.key)
      })
    total_order(partial_contraints)
  })
  |> list.map(fn(sorted_pages) { Report(pages: sorted_pages) })
  |> list.map(mid_page_in_report)
  |> list.fold(0, int.add)
  |> io.debug
}
