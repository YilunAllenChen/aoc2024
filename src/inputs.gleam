import simplifile
import gleam/string
import gleam/list

pub fn readfile(path) -> List(String) {
  case simplifile.read(path) {
    Ok(data) -> {
      data
      |> string.split("\n")
      |> list.filter(fn(s) { s != "" })
    }
    Error(err) -> panic as string.inspect(err)
  }
}