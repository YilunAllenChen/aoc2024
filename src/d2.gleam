import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type Report {
  Report(levels: List(Int))
}

pub type Order {
  Ascending
  Descending
}

fn report_is_safe(report: Report) {
  report.levels
  |> list.window_by_2
  |> list.map(fn(pair) { pair.1 - pair.0 })
  |> list.window_by_2
  |> list.fold(True, fn(acc, pair) {
    let #(a, b) = pair
    let a_b_same_sign = a * b > 0
    acc
    && a_b_same_sign
    && int.absolute_value(a) <= 3
    && int.absolute_value(b) <= 3
  })
}

fn report_is_safe_without_mid_rec(left: List(Int), mid: Int, right: List(Int)) {
  let this_case = list.append(left, right)
  case report_is_safe(Report(this_case)) {
    True -> True
    False ->
      case right {
        [] -> report_is_safe(Report(left))
        [hd, ..tl] -> {
          report_is_safe_without_mid_rec(list.append(left, [mid]), hd, tl)
        }
      }
  }
}

fn report_is_safe_with_dampener(report: Report) {
  case report_is_safe(report) {
    True -> True
    False -> {
      case report.levels {
        [] -> True
        [hd, ..tl] -> report_is_safe_without_mid_rec([], hd, tl)
      }
    }
  }
}

fn line_to_report(line: String) {
  let #(nums, _errs) =
    line
    |> string.split(" ")
    |> list.map(int.parse)
    |> result.partition
  Report(nums)
}

pub fn read_reports(filepath: String) {
  simplifile.read(filepath)
  |> result.unwrap("")
  |> string.split("\n")
  |> list.filter(fn(line) { line != "" })
  |> list.map(line_to_report)
}

pub fn part1() {
  read_reports("./data/d2.data")
  |> list.count(report_is_safe)
}

pub fn part2() {
  read_reports("./data/d2.data")
  |> list.filter(report_is_safe_with_dampener)
  |> list.length
  |> io.debug
}
