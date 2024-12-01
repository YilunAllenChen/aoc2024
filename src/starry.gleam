import gleam/io

pub type Node(inner, outer) {
  Const(val: inner)
  Var(val: inner)
  Map(f: fn(inner) -> outer, val: outer)
}

pub fn stablize(node: Node(inner, outer)) -> Node(inner, outer) {
	case node {
		Const(val) -> Const(val)
		Var(val) -> Var(val)
		Map(f, val) -> Map(f, f(val))
	}
}

pub fn main() {
  let node1 = Var(1)
  let add1 = Map(fn(x) { x + 1 }, 1)
  io.println("Hello from starry!")
  io.debug(node1)
  io.debug(add1)

  io.debug(add1.f(node1.val))
}
