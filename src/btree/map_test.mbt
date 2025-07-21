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
  for i in 1..=100 {
    bt.add(i, i)
  }
  bt.remove(50)
  assert_eq(bt.contains(50), false)
  assert_eq(bt.size(), 99)
  for i in 1..<30 {
    let k = i * 7 % 100 + 1
    bt.remove(k)
    assert_eq(bt.contains(k), false)
  }
}
