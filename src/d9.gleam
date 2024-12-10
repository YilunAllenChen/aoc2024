import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import inputs

pub type FreeSpace {
  FreeSpace(start_pos: Int, len: Int)
}

pub type DataChunk {
  DataChunk(id: Int, start_pos: Int, len: Int)
}

pub type Disk {
  Disk(curr_len: Int, free_space: List(FreeSpace), data_chunks: List(DataChunk))
}

pub type DiskWithRecords {
  DiskWithRecords(
    curr_len: Int,
    free_space: List(FreeSpace),
    data_chunks: List(DataChunk),
    moved_chunks: List(DataChunk),
  )
}

fn map_disk(disk: Disk, pair: #(Int, String)) -> Disk {
  let #(index, digit) = pair
  case index % 2 == 1 {
    True -> {
      let assert Ok(space_size) = int.parse(digit)
      Disk(
        ..disk,
        curr_len: disk.curr_len + space_size,
        free_space: list.append(disk.free_space, [
          FreeSpace(start_pos: disk.curr_len, len: space_size),
        ]),
      )
    }
    False -> {
      let assert Ok(data_size) = int.parse(digit)
      Disk(
        ..disk,
        curr_len: disk.curr_len + data_size,
        data_chunks: list.append(
          [DataChunk(start_pos: disk.curr_len, id: index / 2, len: data_size)],
          disk.data_chunks,
        ),
      )
    }
  }
}

fn disk_to_with_records(disk: Disk) -> DiskWithRecords {
  DiskWithRecords(
    curr_len: disk.curr_len,
    free_space: disk.free_space,
    data_chunks: disk.data_chunks,
    moved_chunks: [],
  )
}

fn space_not_empty(segment: FreeSpace) -> Bool {
  segment.len != 0
}

fn data_not_empty(segment: DataChunk) -> Bool {
  segment.len != 0
}

fn eval_chunk(chunk: DataChunk) -> Int {
  list.range(chunk.start_pos, chunk.start_pos + chunk.len - 1)
  |> list.fold(0, fn(acc, pos) { acc + pos * chunk.id })
}

pub fn compact_disk(disk: Disk) -> Disk {
  case disk.free_space, disk.data_chunks {
    [], [] -> disk
    [], [_hd, ..] -> panic as "unreachable"
    [space_hd, ..space_tl], [data_hd, ..data_tl] -> {
      case space_hd.start_pos > data_hd.start_pos {
        True -> disk
        False -> {
          let match_size = int.min(space_hd.len, data_hd.len)
          let moved_data =
            DataChunk(
              id: data_hd.id,
              start_pos: space_hd.start_pos,
              len: match_size,
            )
          let remaining_data =
            DataChunk(
              id: data_hd.id,
              start_pos: data_hd.start_pos,
              len: data_hd.len - match_size,
            )
          let remaining_space =
            FreeSpace(
              start_pos: space_hd.start_pos + match_size,
              len: space_hd.len - match_size,
            )
          let data_to_add_to_hd =
            [remaining_data] |> list.filter(data_not_empty)
          let data_to_add_to_tl = [moved_data] |> list.filter(data_not_empty)
          let space_to_add = [remaining_space] |> list.filter(space_not_empty)
          Disk(
            ..disk,
            free_space: list.append(space_to_add, space_tl),
            data_chunks: list.flatten([
              data_to_add_to_hd,
              data_tl,
              data_to_add_to_tl,
            ]),
          )
          |> compact_disk
        }
      }
    }
    _redundant_spaces, [] -> disk
  }
}

pub fn compact_disk_wholefile(disk: DiskWithRecords) -> DiskWithRecords {
  case disk.free_space, disk.data_chunks {
    [], [] -> disk
    [], [_hd, ..] -> panic as "unreachable"
    [space_hd, ..space_tl], [data_hd, ..data_tl] -> {
      case space_hd.start_pos > data_hd.start_pos {
        True -> disk
        False -> {
          let can_match = fn(space: FreeSpace) { space.len >= data_hd.len }
          let first_space_to_fit = list.find(disk.free_space, can_match)
          case first_space_to_fit {
            Ok(space) -> {
              let match_size = data_hd.len
              let moved_data =
                DataChunk(
                  id: data_hd.id,
                  start_pos: space.start_pos,
                  len: match_size,
                )
              let remaining_space =
                FreeSpace(
                  start_pos: space.start_pos + match_size,
                  len: space.len - match_size,
                )
              let space_to_add =
                [remaining_space] |> list.filter(space_not_empty)
              let assert Ok(#(_, rest)) = list.pop(disk.free_space, can_match)
              disk |> io.debug
              moved_data |> io.debug
              space |> io.debug
              space_to_add |> io.debug
              io.println("")

              DiskWithRecords(
                ..disk,
                free_space: list.append(space_to_add, rest)
                  |> list.sort(fn(a, b) {
                    int.compare(a.start_pos, b.start_pos)
                  }),
                data_chunks: data_tl,
                moved_chunks: list.append(disk.moved_chunks, [moved_data]),
              )
              |> compact_disk_wholefile
            }
            Error(Nil) -> {
              DiskWithRecords(
                ..disk,
                data_chunks: data_tl,
                moved_chunks: list.append(disk.moved_chunks, [data_hd]),
              )
              |> compact_disk_wholefile
            }
          }
        }
      }
    }
    _redundant_spaces, [] -> disk
  }
}

pub fn part1() {
  let compacted_disk =
    inputs.readfile("./data/d9.data")
    |> list.first
    |> result.unwrap("")
    |> string.to_graphemes
    |> list.index_map(fn(char, i) { #(i, char) })
    |> list.fold(Disk(0, [], []), map_disk)
  // |> compact_disk

  compacted_disk.data_chunks
  |> list.map(eval_chunk)
  |> list.fold(0, int.add)
  |> io.debug
}

pub fn part2() {
  io.println("pt2")
  let compacted_disk =
    inputs.readfile("./data/d9.data")
    |> list.first
    |> result.unwrap("")
    |> string.to_graphemes
    |> list.index_map(fn(char, i) { #(i, char) })
    |> list.fold(Disk(0, [], []), map_disk)
    |> disk_to_with_records
    |> compact_disk_wholefile

  list.flatten([compacted_disk.moved_chunks, compacted_disk.data_chunks])
  |> list.sort(fn(a, b) { int.compare(a.start_pos, b.start_pos) })
  |> list.map(eval_chunk)
  |> list.fold(0, int.add)
  |> io.debug
}
