import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

fn extract_numbers(filepath: String) {
  case simplifile.read(filepath) {
    Ok(content) ->
      content
      |> string.split("\n")
      |> list.flat_map(fn(line) { string.split(line, " ") })
      |> list.filter(fn(part) { part != "" })
      |> list.map(int.parse)
      |> result.partition
    Error(_err) -> #([], [])
  }
}

fn unzip(numbers) {
  list.index_fold(numbers, #([], []), fn(acc, item, idx) {
    case idx % 2 {
      0 -> #(list.prepend(acc.0, item), acc.1)
      1 -> #(acc.0, list.prepend(acc.1, item))
      _ -> #(acc.0, acc.1)
    }
  })
}

fn part1() {
  let #(numbers, _) = extract_numbers("./data/d1p1.data")
  let #(left, right) = unzip(numbers)

  let left = left |> list.sort(int.compare)
  let right = right |> list.sort(int.compare)

  list.zip(left, right)
  |> list.fold(0, fn(acc, pair) {
    let #(left, right) = pair
    acc + int.absolute_value(left - right)
  })
  |> io.debug
}

fn part2() {
  let #(left, right) = extract_numbers("./data/d1p1.data").0 |> unzip

  let right_counter =
    right
    |> list.fold(dict.new(), fn(acc, item) {
      case dict.get(acc, item) {
        Ok(value) -> dict.insert(acc, item, value + 1)
        Error(Nil) -> dict.insert(acc, item, 1)
      }
    })

  list.fold(left, 0, fn(acc, item) {
    case dict.get(right_counter, item) {
      Ok(value) -> acc + value * item
      Error(Nil) -> acc
    }
  })
  |> io.debug
}

pub fn main() {
  part1()
  part2()
}
