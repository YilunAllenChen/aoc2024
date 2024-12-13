import gleam/list
import gleam/string
import simplifile

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

pub fn input(day) -> List(String) {
  readfile("./data/" <> day <> ".data")
}
