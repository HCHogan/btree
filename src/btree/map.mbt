///|
const B : Int = 16

///|
pub fnalias T::new

///|
/// Creates a new, empty **BTreeMap**.
///
/// Returns a map with `size() == 0` and `root == None`.
///
/// Example:
///
/// ```moonbit
///   let m : @btree.T[Int,String] = @btree.new()
///   inspect(m.is_empty(), content="true")
/// ```
pub fn[K, V] T::new() -> T[K, V] {
  { root: None, size: 0 }
}

///|
/// Returns the number of key‑value pairs contained in the map.
///
/// Complexity: **O(1)**.
///
/// Parameters:
/// * `self` – The map whose size is requested.
///
/// Example:
///
/// ```moonbit
///   let m = @btree.from_array([(1,"a"),(2,"b")])
///   inspect(m.size(), content="2")
/// ```
pub fn[K, V] T::size(self : Self[K, V]) -> Int {
  self.size
}

///|
/// Builds a `BTreeMap` from an **array** of key‑value tuples.
///
/// Duplicate keys are *overwritten* by later entries in the array.
///
/// Complexity: `O(n log₍B₎ n)` – inserts each element individually.
///
/// Parameters:
/// * `arr` – Array containing `(K,V)` pairs.  
///
/// Example:
///
/// ```moonbit
///   let m = @btree.from_array([(3,"c"),(1,"a"),(2,"b")])
///   inspect(m.keys(), content="[1, 2, 3]")
/// ```
pub fn[K : Compare, V] from_array(arr : Array[(K, V)]) -> T[K, V] {
  let tree = T::new()
  for i in arr {
    tree.add(i.0, i.1)
  }
  tree
}

///|
/// Returns `true` when the map contains **no** key‑value entries.
///
/// Complexity: **O(1)**.
///
/// Example:
///
/// ```moonbit
///   let m : @btree.T[Int, String] = @btree.new()
///   inspect(m.is_empty(), content="true")
/// ```
pub fn[K, V] is_empty(self : T[K, V]) -> Bool {
  self.size == 0
}

///|
fn[K, V] Node::new() -> Node[K, V] {
  Node::{ keys: [], children: [] }
}

///|
fn[K, V] Node::is_leaf(self : Node[K, V]) -> Bool {
  self.children.is_empty()
}

///|
fn[K : Compare, V] search(node : Node[K, V], k : K) -> V? {
  match node.keys.binary_search_by(fn(pair) { pair.0.compare(k) }) {
    Ok(i) => Some(node.keys[i].1)
    Err(i) => if node.is_leaf() { None } else { search(node.children[i], k) }
  }
}

///|
/// Retrieves a **value** associated with `key`, or `None` if absent.
///
/// Complexity: `O(log₍B₎ n)` – binary‑search inside a node + child hop.
///
/// Parameters:
/// * `key` – The key to look for.
///
/// Example:
///
/// ```moonbit
///   let m = @btree.from_array([(1,"one"),(2,"two")])
///   inspect(m.get(2), content="Some(\"two\")")
///   inspect(m.get(3), content="None")
/// ```
pub fn[K : Compare, V] T::get(self : Self[K, V], k : K) -> V? {
  match self.root {
    None => None
    Some(node) => search(node, k)
  }
}

///|
/// Checks whether `key` exists in the map.
///
/// Returns `true` exactly when `get(key)` returns `Some(_)`.
///
/// Complexity: `O(log₍B₎ n)`.
///
/// Example:
///
/// ```moonbit
///   let m = @btree.from_array([(1,"a")])
///   inspect(m.contains(1), content="true")
///   inspect(m.contains(2), content="false")
/// ```
pub fn[K : Compare, V] T::contains(self : Self[K, V], k : K) -> Bool {
  self.get(k) is Some(_)
}

///|
/// **Clears** the map, removing all entries in `O(1)` time
/// by dropping the root reference.
///
/// Example:
///
/// ```moonbit
///   let m = @btree.from_array([(1,"a")])
///   m.clear()
///   inspect(m.is_empty(), content="true")
/// ```
pub fn[K, V] T::clear(self : Self[K, V]) -> Unit {
  self.root = None
  self.size = 0
}

///|
fn[K, V] split_child(parent : Node[K, V], idx : Int) -> Unit {
  let child = parent.children[idx]
  let median = child.keys[B - 1]
  let sibling = Node::new()
  let (_left, right) = child.keys.split_at(B)
  sibling.keys.append(right)
  child.keys.truncate(B - 1)
  if !child.is_leaf() {
    let (_l, right_child) = child.children.split_at(B)
    sibling.children.append(right_child)
    child.children.truncate(B)
  }
  parent.keys.insert(idx, median)
  parent.children.insert(idx + 1, sibling)
}

///|
fn[K : Compare, V] insert_non_full(
  node : Node[K, V],
  key : K,
  value : V,
) -> Bool {
  match node.keys.binary_search_by(fn(pair) { pair.0.compare(key) }) {
    Ok(i) => {
      node.keys[i] = (key, value)
      false
    }
    Err(i) => {
      let mut i = i
      if node.is_leaf() {
        node.keys.insert(i, (key, value))
        true
      } else {
        if node.children[i].keys.length() == 2 * B - 1 {
          split_child(node, i)
          if key > node.keys[i].0 {
            i = i + 1
          }
        }
        insert_non_full(node.children[i], key, value)
      }
    }
  }
}

///|
/// Inserts / updates the pair `(key, value)`.
///
/// * If `key` is new, the pair is inserted and `size()` increases by 1.  
/// * If `key` already exists, its value is **replaced**.
///
/// Complexity: `O(log₍B₎ n)` average – may split one node on the descent.
///
/// Example:
///
/// ```moonbit
///   let m = @btree.new()
///   m.add(1, "one")  // insert
///   m.add(1, "uno")  // update
///   inspect(m.get(1), content="Some(\"uno\")")
/// ```
pub fn[K : Compare, V] T::add(self : Self[K, V], key : K, value : V) -> Unit {
  match self.root {
    Some(old_root) =>
      if old_root.keys.length() == 2 * B - 1 {
        let new_root = Node::new()
        new_root.children.push(old_root)
        self.root = Some(new_root)
        split_child(new_root, 0)
        if insert_non_full(new_root, key, value) {
          self.size += 1
        }
      } else if insert_non_full(old_root, key, value) {
        self.size += 1
      }
    None => {
      let root = Node::new()
      root.keys.push((key, value))
      self.root = Some(root)
      self.size = 1
    }
  }
}

///|
fn[K : Compare + Show, V] to_string_pretty_recursive(
  node : Node[K, V],
  prefix : String,
  is_tail : Bool,
) -> String {
  let mut result = prefix
  if is_tail {
    result = result + "└── "
  } else {
    result = result + "├── "
  }
  let keys_str = node.keys.map(x => x.0.to_string()).join(", ")
  result = result + "[\{keys_str}]\n"
  if node.is_leaf() == false {
    let num_children = node.children.length()
    let new_prefix = prefix + (if is_tail { "    " } else { "│   " })
    for i in 0..<num_children {
      let child = node.children[i]
      let child_is_tail = i == num_children - 1
      result = result +
        to_string_pretty_recursive(child, new_prefix, child_is_tail)
    }
  }
  result
}

///|
/// Pretty‑prints the map as a tree structure.
///
/// Prints the keys like this:
///
/// ```text
///   BTree(size=26)
///   [50]
///   ├── [30]
///   │   ├── [20]
///   │   │   ├── [5, 10, 15]
///   │   │   └── [25, 28]
///   │   └── [40]
///   │       ├── [35, 38]
///   │       └── [45, 48]
///   └── [70]
///       ├── [60]
///       │   ├── [55, 58]
///       │   └── [65, 68]
///       └── [80, 90]
///           ├── [75, 78]
///           ├── [85]
///           └── [95, 100]
/// ```
pub fn[K : Compare + Show, V] T::to_string_pretty(self : Self[K, V]) -> String {
  match self.root {
    None => "BTree(size=0) <empty>".to_string()
    Some(root_node) => {
      let mut result = "BTree(size=\{self.size()})\n"
      let root_keys_str = root_node.keys.map(x => x.0.to_string()).join(", ")
      result = result + "[\{root_keys_str}]\n"
      if root_node.is_leaf() == false {
        let num_children = root_node.children.length()
        for i in 0..<num_children {
          let child = root_node.children[i]
          let is_tail = i == num_children - 1
          result = result + to_string_pretty_recursive(child, "", is_tail)
        }
      }
      result
    }
  }
}

///|
fn[K, V] borrow_from_prev(parent : Node[K, V], idx : Int) -> Unit {
  let child = parent.children[idx]
  let sibling = parent.children[idx - 1]
  child.keys.insert(0, parent.keys[idx - 1])
  if sibling.is_leaf() == false {
    let last_child = sibling.children.remove(sibling.children.length() - 1)
    child.children.insert(0, last_child)
  }
  parent.keys[idx - 1] = sibling.keys.remove(sibling.keys.length() - 1)
}

///|
fn[K, V] borrow_from_next(parent : Node[K, V], idx : Int) -> Unit {
  let child = parent.children[idx]
  let sibling = parent.children[idx + 1]
  child.keys.push(parent.keys[idx])
  if sibling.is_leaf() == false {
    let first_child = sibling.children.remove(0)
    child.children.push(first_child)
  }
  parent.keys[idx] = sibling.keys.remove(0)
}

///|
fn[K, V] merge_children(parent : Node[K, V], idx : Int) -> Unit {
  let child = parent.children[idx]
  let sibling = parent.children.remove(idx + 1)
  child.keys.push(parent.keys.remove(idx))
  child.keys.append(sibling.keys)
  if sibling.is_leaf() == false {
    child.children.append(sibling.children)
  }
}

///|
fn[K, V] fill_child(parent : Node[K, V], idx : Int) -> Unit {
  if idx > 0 && parent.children[idx - 1].keys.length() >= B {
    borrow_from_prev(parent, idx)
  } else if idx < parent.children.length() - 1 &&
    parent.children[idx + 1].keys.length() >= B {
    borrow_from_next(parent, idx)
  } else {
    let merge_idx = if idx < parent.children.length() - 1 {
      idx
    } else {
      idx - 1
    }
    merge_children(parent, merge_idx)
  }
}

///|
fn[K, V] predecessor(node : Node[K, V]) -> (K, V) {
  let mut cur = node
  while cur.is_leaf() == false {
    cur = cur.children[cur.children.length() - 1]
  }
  cur.keys[cur.keys.length() - 1]
}

///|
fn[K, V] successor(node : Node[K, V]) -> (K, V) {
  let mut cur = node
  while cur.is_leaf() == false {
    cur = cur.children[0]
  }
  cur.keys[0]
}

///|
fn[K : Compare, V] remove_key(node : Node[K, V], key : K) -> Bool {
  match node.keys.binary_search_by(fn(p) { p.0.compare(key) }) {
    Ok(idx) => {
      if node.is_leaf() {
        ignore(node.keys.remove(idx))
        return true
      }
      if node.children[idx].keys.length() >= B {
        let (pk, pv) = predecessor(node.children[idx])
        node.keys[idx] = (pk, pv)
        ignore(remove_key(node.children[idx], pk))
      } else if node.children[idx + 1].keys.length() >= B {
        let (sk, sv) = successor(node.children[idx + 1])
        node.keys[idx] = (sk, sv)
        ignore(remove_key(node.children[idx + 1], sk))
      } else {
        merge_children(node, idx)
        ignore(remove_key(node.children[idx], key))
      }
      true
    }
    Err(idx) => {
      if node.is_leaf() {
        return false
      }
      fill_child(node, idx)
      let new_idx = if idx >= node.children.length() { idx - 1 } else { idx }
      remove_key(node.children[new_idx], key)
    }
  }
}

///|
/// Removes `key` and its value.  
///
/// Does nothing if `key` is absent.
///
/// Complexity: `O(log₍B₎ n)` – may cause one merge or borrow on the descent.
///
/// Example:
///
/// ```moonbit
///   let m = @btree.from_array([(1,"a"),(2,"b")])
///   m.remove(1)
///   inspect(m.contains(1), content="false")
/// ```
pub fn[K : Compare, V] T::remove(self : Self[K, V], key : K) -> Unit {
  match self.root {
    None => return ()
    Some(root) =>
      if remove_key(root, key) {
        self.size -= 1
        if root.keys.is_empty() {
          self.root = if root.is_leaf() { None } else { Some(root.children[0]) }
        }
      }
  }
}

///|
/// Array‑style **subscript assignment** sugar `map[key] = value`.
///
/// Equivalent to calling `add(key, value)`.
///
/// Example:
///
/// ```moonbit
///   let m = @btree.new()
///   m[42] = "Meaning of life"
///   inspect(m.get(42), content="Some(\"Meaning of life\")")
/// ```
pub fn[K : Compare, V] op_set(self : T[K, V], key : K, value : V) -> Unit {
  self.add(key, value)
}

///|
/// Equality comparison: two maps are equal iff their ordered
/// `to_array()` representations are equal.
pub impl[K : Eq, V : Eq] Eq for T[K, V] with op_equal(self, other) {
  self.to_array() == other.to_array()
}

///|
/// Applies function `f` to **each** `(key, value)` in ascending key order.
///
/// The traversal stops early if `f` raises an error.
///
/// Example:
///
/// ```moonbit
///   let m = @btree.from_array([(3,"c"),(1,"a"),(2,"b")])
///   let logger = StringBuilder::new()
///   m.each((k, v) => logger.write_string("\{k} -> \{v}\n"))
///   inspect(logger, content=(
///     #|1 -> a
///     #|2 -> b
///     #|3 -> c
///     #|
///   ))
/// ```
pub fn[K, V] each(self : T[K, V], f : (K, V) -> Unit raise?) -> Unit raise? {
  fn dfs(n : Node[K, V]?, f : (K, V) -> Unit raise?) -> Unit raise? {
    match n {
      None => ()
      Some(n) => {
        let len = n.keys.length()
        for i = 0; i < len; i = i + 1 {
          if !n.is_leaf() {
            dfs(Some(n.children[i]), f)
          }
          f(n.keys[i].0, n.keys[i].1)
        }
        if !n.is_leaf() {
          dfs(Some(n.children[len]), f)
        }
      }
    }
  }

  dfs(self.root, f)
}

///|
/// Same as `each` but also passes a **zero‑based index** `i`.
///
/// Example:
///
/// ```moonbit
///   let idxs = []
///   @btree.from_array([(2,"b"),(1,"a")])
///     .eachi((i, k, _v) => idxs.push((i,k)))
///   inspect(idxs, content="[(0, 1), (1, 2)]")
/// ```
pub fn[K, V] eachi(
  self : T[K, V],
  f : (Int, K, V) -> Unit raise?,
) -> Unit raise? {
  let mut idx = 0
  self.each((k, v) => {
    f(idx, k, v)
    idx = idx + 1
  })
}

///|
/// Collects all **keys** into a new array, in sorted order.
///
/// Complexity: `O(n)`.
///
/// Example:
///
/// ```moonbit
///   let ks = @btree.from_array([(3,"c"),(1,"a")]).keys()
///   inspect(ks, content="[1, 3]")
/// ```
pub fn[K, V] keys(self : T[K, V]) -> Array[K] {
  let ks = Array::new(capacity=self.size)
  self.each((k, _v) => ks.push(k))
  ks
}

///|
/// Collects all **values** into a new array, preserving key order.
///
/// Complexity: `O(n)`.
pub fn[K, V] values(self : T[K, V]) -> Array[V] {
  let vs = Array::new(capacity=self.size)
  self.each((_k, v) => vs.push(v))
  vs
}

///|
/// Converts the map into an **array of pairs** `[(K, V)]` in
/// ascending key order.
///
/// Complexity: `O(n)`.
pub fn[K, V] to_array(self : T[K, V]) -> Array[(K, V)] {
  let arr = Array::new(capacity=self.size)
  self.each((k, v) => arr.push((k, v)))
  arr
}

///|
/// Produces a **iterator** over `(key, value)` pairs.
///
/// The iterator yields pairs in sorted order and stops once all elements
/// have been visited.
///
/// Example:
///
/// ```moonbit
///   let m = @btree.from_array([(2,"b"), (1,"a")])
///   let arr = m.iter().to_array()
///   inspect(arr, content="[(1, \"a\"), (2, \"b\")]")
/// ```
pub fn[K, V] iter(self : T[K, V]) -> Iter[(K, V)] {
  Iter::new(yield_ => {
    fn go(n : Node[K, V]?, y : ((K, V)) -> IterResult) -> IterResult {
      match n {
        None => IterContinue
        Some(n) => {
          let len = n.keys.length()
          for i = 0; i < len; i = i + 1 {
            if !n.is_leaf() && go(Some(n.children[i]), y) is IterEnd {
              return IterEnd
            }
            if y((n.keys[i].0, n.keys[i].1)) is IterEnd {
              return IterEnd
            }
          }
          if !n.is_leaf() {
            go(Some(n.children[len]), y)
          } else {
            IterContinue
          }
        }
      }
    }

    go(self.root, yield_)
  })
}

///|
/// Like `iter`, but the yield signature is `yield_(k, v)`
/// instead of a tuple.
///
/// Useful when working with APIs that expect two separate arguments.
pub fn[K, V] iter2(self : T[K, V]) -> Iter2[K, V] {
  Iter2::new(yield_ => {
    fn go(n : Node[K, V]?, y : (K, V) -> IterResult) -> IterResult {
      match n {
        None => IterContinue
        Some(n) => {
          let len = n.keys.length()
          for i = 0; i < len; i = i + 1 {
            if !n.is_leaf() && go(Some(n.children[i]), y) is IterEnd {
              return IterEnd
            }
            if y(n.keys[i].0, n.keys[i].1) is IterEnd {
              return IterEnd
            }
          }
          if !n.is_leaf() {
            go(Some(n.children[len]), y)
          } else {
            IterContinue
          }
        }
      }
    }

    go(self.root, yield_)
  })
}

///|
/// Builds a map from any iterator of `(K,V)` pairs.
///
/// Parameters:
/// * `iter` – A value implementing `Iter[(K, V)]`.
///
/// Example:
///
/// ```moonbit
///   let m = @btree.from_iter([(1,"x"),(2,"y")].iter())
///   inspect(m.size(), content="2")
/// ```
pub fn[K : Compare, V] from_iter(iter : Iter[(K, V)]) -> T[K, V] {
  let m = new()
  iter.each(p => m.add(p.0, p.1))
  m
}

///|
/// Returns an iterator over all pairs with keys in **inclusive range**
/// `[low, high]`.
///
/// Complexity: `O(log₍B��� n + k)` where `k` is the number of pairs yielded.
///
/// Edge‑cases:
/// * If `low > high`, the iterator is empty.
/// * Keys outside the map bounds are ignored.
///
/// Example:
///
/// ```moonbit
///   let m = @btree.from_array([(1,"a"),(2,"b"),(3,"c")])
///   let sub = []
///   m.range(2,3).each((k,v)=>sub.push((k,v)))
///   inspect(sub, content="[(2, \"b\"), (3, \"c\")]")
/// ```
pub fn[K : Compare, V] range(self : T[K, V], low : K, high : K) -> Iter2[K, V] {
  Iter2::new(yield_ => {
    fn go(
      n : Node[K, V]?,
      low : K,
      high : K,
      y : (K, V) -> IterResult,
    ) -> IterResult {
      match n {
        None => IterContinue
        Some(n) => {
          let len = n.keys.length()
          for i = 0; i < len; i = i + 1 {
            if !n.is_leaf() &&
              n.keys[i].0 >= low &&
              go(Some(n.children[i]), low, high, y) is IterEnd {
              return IterEnd
            }
            let k = n.keys[i].0
            if k >= low && k <= high {
              if y(k, n.keys[i].1) is IterEnd {
                return IterEnd
              }
            }
            if k > high {
              return IterContinue
            }
          }
          if !n.is_leaf() && n.keys[len - 1].0 <= high {
            go(Some(n.children[len]), low, high, y)
          } else {
            IterContinue
          }
        }
      }
    }

    go(self.root, low, high, yield_)
  })
}

///|
pub impl[K : @quickcheck.Arbitrary + Compare, V : @quickcheck.Arbitrary] @quickcheck.Arbitrary for T[
  K,
  V,
] with arbitrary(size, rs) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_iter
}

///|
/// Pretty `Show` implementation – prints as
/// `of([(k1, v1), (k2, v2), …])`.
///
/// Example:
///
/// ```moonbit
///   inspect(@btree.from_array([(1,1)]),
///           content="of([(1, 1)])")
/// ```
pub impl[K : Show, V : Show] Show for T[K, V] with output(self, logger) {
  logger.write_string("of(\{self.to_array().to_string()})")
}

///|
/// Returns the **default** empty map.
pub impl[K, V] Default for T[K, V] with default() {
  new()
}
