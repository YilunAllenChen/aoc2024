import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub fn main() {
  let content = case simplifile.read("./data/d1p1.data") {
    Ok(content) ->
      content
      |> string.split("\n")
      |> list.flat_map(fn(line) { string.split(line, " ") })
      |> list.filter(fn(part) { part != "" })
    Error(_err) -> []
  }

  content |> io.debug

  let #(left, right) =
    list.index_fold(content, #([], []), fn(acc, item, idx) {
      case idx % 2 {
        0 -> #(list.prepend(acc.0, item), acc.1)
        1 -> #(acc.0, list.prepend(acc.1, item))
        _ -> #(acc.0, acc.1)
      }
    })

  left |> list.sort(string.compare) |> io.debug
  right |> list.sort(string.compare) |> io.debug
}
