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

fn report_is_safe_with_dampener(report: Report) {
  let diffs =
    report.levels
    |> list.window_by_2
    |> list.map(fn(pair) { pair.1 - pair.0 })

  let num_too_far = list.count(diffs, fn(diff) { int.absolute_value(diff) > 3 })

  case num_too_far < 1 {
    False -> False
    True -> {
      let #(gt, lez) = list.partition(diffs, fn(diff) { diff > 0 })
      let #(lt, ez) = list.partition(lez, fn(diff) { diff < 0 })
      let num_gt = list.length(gt)
      let num_lt = list.length(lt)
      let num_ez = list.length(ez)
      case num_gt, num_lt, num_ez {
        _, 1, 0 | _, 0, 1 | _, 0, 0 -> True
        0, _, 1 | 1, _, 0 | 0, _, 0 -> True
        _, _, _ -> False
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
