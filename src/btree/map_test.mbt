///|
test "btree" {
  let data = [
    (50, "fifty"),
    (30, "thirty"),
    (70, "seventy"),
    (20, "twenty"),
    (40, "forty"),
    (60, "sixty"),
    (80, "eighty"),
    (10, "ten"),
    (25, "twenty-five"),
    (35, "thirty-five"),
    (45, "forty-five"),
    (55, "fifty-five"),
    (65, "sixty-five"),
    (75, "seventy-five"),
    (90, "ninety"),
    (5, "five"),
    (15, "fifteen"),
    (28, "twenty-eight"),
    (38, "thirty-eight"),
    (48, "forty-eight"),
    (58, "fifty-eight"),
    (68, "sixty-eight"),
    (78, "seventy-eight"),
    (85, "eighty-five"),
    (95, "ninety-five"),
    (100, "one hundred"),
  ]
  let tree = from_array(data)
  println(tree.to_string_pretty())
  inspect(tree.size(), content="\{data.length()}")
}

///|
test "btree add" (b : @bench.T) {
  let data : Array[(Int, String)] = Array::default()
  let r = @random.Rand::new()
  for _j in 0..<10000 {
    let i = r.int()
    data.push((i, i.to_string()))
  }
  b.bench(
    fn() {
      let tree = @sorted_map.from_array(data)
      for p in data {
        ignore(tree.get(p.0))
      }
      for p in data {
        tree.remove(p.0)
      }
    },
    count=10,
  )
  b.bench(
    fn() {
      let tree = from_array(data)
      for p in data {
        ignore(tree.get(p.0))
      }
      for p in data {
        tree.remove(p.0)
      }
    },
    count=10,
  )
}

///|
test "btree get" (b : @bench.T) {
  let data : Array[(Int, String)] = Array::default()
  let r = @random.Rand::new()
  for _j in 0..<10000 {
    let i = r.int()
    data.push((i, i.to_string()))
  }
  let avltree = @sorted_map.from_array(data)
  let btree = from_array(data)
  b.bench(
    fn() {
      for p in data {
        ignore(avltree.get(p.0))
      }
    },
    count=10,
  )
  b.bench(
    fn() {
      for p in data {
        ignore(btree.get(p.0))
      }
    },
    count=10,
  )
}

///|
test "btree remove" (b : @bench.T) {
  let data : Array[(Int, String)] = Array::default()
  let r = @random.Rand::new()
  for _j in 0..<10000 {
    let i = r.int()
    data.push((i, i.to_string()))
  }
  let avltree = @sorted_map.from_array(data)
  let btree = from_array(data)
  b.bench(
    fn() {
      for p in data {
        avltree.remove(p.0)
      }
    },
    count=1,
  )
  b.bench(
    fn() {
      for p in data {
        btree.remove(p.0)
      }
    },
    count=1,
  )
}

///|
test {
  let bt = T::new()
  for i = 1; i <= 100; i = i + 1 {
    bt.add(i, i)
  }
  bt.remove(50)
  assert_eq(bt.contains(50), false)
  assert_eq(bt.size(), 99)
  for i = 0; i < 30; i = i + 1 {
    let k = i * 7 % 100 + 1
    bt.remove(k)
    assert_eq(bt.contains(k), false)
  }
}

///|
test "remove2" {
  let map = from_array([(1, "a"), (2, "b")])
  inspect(map.size(), content="2")
  map.remove(1)
  inspect(map.size(), content="1")
}

///|
test "remove3" {
  let map = from_array([(1, "a"), (2, "b"), (3, "c")])
  map.remove(0)
  inspect(map.size(), content="3")
  map.remove(4)
  inspect(map.size(), content="3")
}

///|
test "remove on empty map" {
  let map : T[Int, String] = new()
  map.remove(1)
  inspect(map.size(), content="0")
}

///|
test "get" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(
    map.get(1),
    content=(
      #|Some("a")
    ),
  )
  inspect(
    map.get(2),
    content=(
      #|Some("b")
    ),
  )
  inspect(
    map.get(3),
    content=(
      #|Some("c")
    ),
  )
  inspect(map.get(4), content="None")
}

///|
test "contains" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(map.contains(1), content="true")
  inspect(map.contains(2), content="true")
  inspect(map.contains(3), content="true")
  inspect(map.contains(4), content="false")
}

///|
test "op_get" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(
    map.get(1),
    content=(
      #|Some("a")
    ),
  )
  inspect(
    map.get(2),
    content=(
      #|Some("b")
    ),
  )
  inspect(
    map.get(3),
    content=(
      #|Some("c")
    ),
  )
  inspect(map.get(4), content="None")
}

///|
test "op_equal" {
  let a = from_array([(3, "c"), (2, "b"), (1, "a")])
  let b = from_array([(4, "d"), (5, "e"), (6, "f")])
  inspect(a == a, content="true")
  inspect(b == b, content="true")
  inspect(a == b, content="false")
  inspect(b == a, content="false")
}

///|
test "is_empty" {
  let map : T[Int, String] = new()
  inspect(map.is_empty(), content="true")
  map[1] = "a"
  inspect(map.is_empty(), content="false")
}

///|
test "size" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(map.size() == map.size(), content="true")
}

///|
test "each" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  let buf = StringBuilder::new()
  map.each((k, v) => buf.write_string("\{k}\{v}"))
  inspect(buf.to_string(), content="1a2b3c")
}

///|
test "eachi" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  let buf = StringBuilder::new()
  map.eachi((i, k, v) => buf.write_string("[\{i}]\{k}\{v}"))
  inspect(buf.to_string(), content="[0]1a[1]2b[2]3c")
}

///|
test "keys" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(map.keys(), content="[1, 2, 3]")
}

///|
test "values" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(
    map.values(),
    content=(
      #|["a", "b", "c"]
    ),
  )
}

///|
test "to_array" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(
    map.to_array(),
    content=(
      #|[(1, "a"), (2, "b"), (3, "c")]
    ),
  )
}

///|
test "iter" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  inspect(
    map.iter().collect(),
    content=(
      #|[(1, "a"), (2, "b"), (3, "c")]
    ),
  )
  inspect(
    map.iter().take(2).collect(),
    content=(
      #|[(1, "a"), (2, "b")]
    ),
  )
}

///|
test "from_iter multiple elements iter" {
  inspect(
    from_iter([(1, 1), (2, 2), (3, 3)].iter()),
    content="of([(1, 1), (2, 2), (3, 3)])",
  )
}

///|
test "from_iter single element iter" {
  inspect(from_iter([(1, 1)].iter()), content="of([(1, 1)])")
}

///|
test "from_iter empty iter" {
  let pq : T[Int, Int] = from_iter(Iter::empty())
  inspect(pq, content="of([])")
}

///|
test "arbitrary" {
  let map : Array[T[Int, UInt]] = @quickcheck.samples(20)
  inspect(
    map[5:10],
    content="[of([]), of([]), of([(0, 0)]), of([(0, 0)]), of([(0, 0)])]",
  )
  inspect(
    map[11:15],
    content="[of([(-3, 2), (-1, 1), (0, 0), (2, 1)]), of([(0, 0)]), of([(-8, 1), (-2, 5), (0, 3), (3, 6), (7, 6)]), of([(0, 0)])]",
  )
}

///|
test "iter2" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  let buf = StringBuilder::new()
  for k, v in map {
    buf.write_string("[\{k}\{v}]")
  }
  inspect(buf, content="[1a][2b][3c]")
}

///|
test "iter" {
  let map = from_array([(3, "c"), (2, "b"), (1, "a")])
  let buf = StringBuilder::new()
  for kv in map {
    buf.write_string("[\{kv.0}\{kv.1}]")
  }
  inspect(buf, content="[1a][2b][3c]")
}

///|
test "range" {
  let map = from_array([(1, "a"), (2, "b"), (3, "c"), (4, "d"), (5, "e")])
  let result = map.range(2, 4)
  let buf = StringBuilder::new()
  for k, v in result {
    buf.write_string("[\{k}\{v}]")
  }
  inspect(buf, content="[2b][3c][4d]")
}
