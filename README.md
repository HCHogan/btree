# B‑tree Map

A mutable map backed by a **B‑tree** that keeps keys in sorted order and stores *multiple* key‑value pairs per node, dramatically reducing tree height and cache misses for large data sets. Implements all the public api that @core/sorted_map has.

## Overview

`BTreeMap` is an ordered map whose internal node (branch) factor is **`2 × B – 1` keys / `2 × B` children**.
By default we use **`B = 16`**, so every inner node can hold up to **31 keys + 32 children**, giving excellent locality.
All mutating operations (insert/delete) split / merge nodes **only when necessary**, keeping the tree balanced and the height `O(log₍B₎ n)`.

## Performance

| Operation            | Time Complexity   | Notes                                           |
| -------------------- | ----------------- | ----------------------------------------------- |
| **add / set**        | `O(log n)`     | (`≈ log₂ n / 4.0` when `B = 16`)                |
| **remove**           | `O(log n)`     | node merge / borrow costs one extra memory move |
| **get / contains**   | `O(log n)`     | binary‑search inside node + child hop           |
| **iterate (full)**   | `O(n)`            | in‑order traversal                              |
| **range \[lo, hi\]**  | `O(log n + k)` | `k` = pairs yielded                             |
| **space complexity** | `O(n)`            | plus ≤ `n / (B‑1)` internal pointers            |

For small maps an AVL tree may be faster; for anything larger B‑tree usually wins thanks to fewer pointer hops and better cache utilization.

## Usage

### Create

```moonbit
test {
  let _m1 : @btree_map.T[Int, String] = @btree_map.new()
  let _m2 = @btree_map.from_array([(1, "one"), (2, "two"), (3, "three")])
}
```

### Container Operations

```moonbit
test "add" {
  let m = @btree_map.from_array([(1, "one"), (2, "two")])
  m.add(3, "three")
  assert_eq(m.size(), 3)
}

test "subscript‑set" {
  let m = @btree_map.new()
  m[1] = "one"
  m[2] = "two"
  assert_eq(m.size(), 2)
}

test "remove" {
  let m = @btree_map.from_array([(1,"one"),(2,"two"),(3,"three")])
  m.remove(2)
  assert_eq(m.contains(2), false)
}
```

### Query Operations

```moonbit
test {
  let m = @btree_map.from_array([(1,"one"),(2,"two"),(3,"three")])
  assert_eq(m.get(2), Some("two"))
  assert_eq(m.contains(4), false)
}
```

### Traversal

```moonbit
test "each" {
  let m = @btree_map.from_array([(3,"three"),(1,"one"),(2,"two")])
  let ks = []; let vs = []
  m.each((k,v)=>{ ks.push(k); vs.push(v) })
  assert_eq(ks, [1,2,3])
  assert_eq(vs, ["one","two","three"])
}

test "index‑each" {
  let m = @btree_map.from_array([(3,"three"),(1,"one"),(2,"two")])
  let acc = []
  m.eachi((i,k,v)=>{ acc.push((i,k,v)) })
  assert_eq(acc, [(0,1,"one"),(1,2,"two"),(2,3,"three")])
}
```

### Size / Empty / Clear

```moonbit
test {
  let m = @btree_map.from_array([(1,"one"),(2,"two"),(3,"three")])
  assert_eq(m.size(), 3)
  assert_eq(m.is_empty(), false)
  m.clear()
  assert_eq(m.is_empty(), true)
}
```

### Data Extraction

```moonbit
test {
  let m = @btree_map.from_array([(3,"three"),(1,"one"),(2,"two")])
  assert_eq(m.keys(),   [1,2,3])
  assert_eq(m.values(), ["one","two","three"])
  assert_eq(m.to_array(), [(1,"one"),(2,"two"),(3,"three")])
}
```

### Range Queries

```moonbit
test {
  let m = @btree_map.from_array([(1,"one"),(2,"two"),(3,"three"),
                                 (4,"four"),(5,"five")])
  let sub = []
  m.range(2,4).each((k,v)=>sub.push((k,v)))
  assert_eq(sub, [(2,"two"),(3,"three"),(4,"four")])
}
```

### Iterators

```moonbit
test {
  let it = [(1,"one"),(2,"two"),(3,"three")].iter()
  let m = @btree_map.from_iter(it)
  assert_eq(m.iter().to_array(),
            [(1,"one"),(2,"two"),(3,"three")])
}
```

### Equality

```moonbit
test {
  let a = @btree_map.from_array([(1,"one"),(2,"two")])
  let b = @btree_map.from_array([(2,"two"),(1,"one")])
  assert_eq(a == b, true)
}
```

### Error‑handling Best Practices

## Implementation Notes

Our B‑tree adheres to the textbook definition (Knuth Vol. 3):

* **Node invariants**

  * Root may contain `1 … 2B-1` keys.
  * Non‑root internal nodes contain `B … 2B-1` keys.
  * Leaves have no children; internal nodes store child pointers count = key‑count + 1.
* **Insertion**

  * If root is full, allocate new root and split once, guaranteeing room on descent.
  * Descend until a non‑full leaf is reached, splitting any full child on the way down.
* **Deletion**

  * Symmetric mirror of insertion: during descent ensure target child has ≥ `B` keys by **borrow** or **merge**, so that under‑flow never propagates upward.
* **Traversal**

  * In‑order DFS yields sorted key‑value pairs and is tail‑recursive‑friendly.
* **Degree ( B ) configurability**

  * Currently `const B : Int = 16`.

### Why B‑tree over AVL?

* **I/O & Cache friendly** — multiple keys per node mean *far fewer pointer hops*.
* **Excellent sequential throughput** — once a node is in cache, binary‑search over up to 31 keys is extremely cheap.
* **Range queries** naturally fast: scan within node, then descend only relevant subtrees.

## Comparison with Other Collections

| Collection         | Ordering  | Lookup Avg  | Memory Locality | Best Use Case                                        |
| ------------------ | --------- | ----------- | --------------- | ---------------------------------------------------- |
| **@hashmap.T**     | ✗         | O(1)        | ★★☆☆☆           | Unordered, constant‑time key lookup                  |
| **@indexmap.T**    | Insertion | O(1)        | ★★☆☆☆           | Preserve *insertion* order                           |
| **@sorted\_map.T** | Sorted    | O(log n)    | ★★★☆☆           | Small‑to‑medium maps, low constant factors           |
| **@btree\_map.T**  | Sorted    | O(log n) | ★★★★☆           | Large maps, frequent range queries, cache efficiency |

Choose **BTreeMap** when you need:

* Keys in sorted order **and** dataset can grow big (10³ + items).
* Efficient *inclusive* range queries.
* Better real‑world performance on modern CPUs due to cache sensitivity.
