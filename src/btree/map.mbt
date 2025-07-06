///|
const B : Int = 16

///|
pub fn[K, V] new() -> T[K, V] {
  { root: None, size: 0 }
}

///|
pub fn[K, V] T::new() -> T[K, V] {
  new()
}

///|
pub fn[K, V] T::size(self : Self[K, V]) -> Int {
  self.size
}

///|
pub fn[K : Compare, V] from_array(arr : Array[(K, V)]) -> T[K, V] {
  let tree = T::new()
  for i in arr {
    tree.add(i.0, i.1)
  }
  tree
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
  match
    node.keys.binary_search_by(fn(pair) {
      if pair.0 < k {
        return -1
      } else if pair.0 > k {
        return 1
      } else {
        return 0
      }
    }) {
    Ok(i) => Some(node.keys[i].1)
    Err(i) => if node.is_leaf() { None } else { search(node.children[i], k) }
  }
}

///|
pub fn[K : Compare, V] T::get(self : Self[K, V], k : K) -> V? {
  match self.root {
    None => None
    Some(node) => search(node, k)
  }
}

///|
pub fn[K : Compare, V] T::contains(self : Self[K, V], k : K) -> Bool {
  if self.get(k).is_empty() {
    return false
  } else {
    return true
  }
}

///|
pub fn[K, V] T::clear(self : Self[K, V]) -> Unit {
  self.root = None
  self.size = 0
}

///|
fn[K, V] split_child(parent : Node[K, V], idx : Int) -> Unit {
  let child = parent.children[idx]
  let median_idx = B - 1
  let (left_keys, right_with_median) = child.keys.split_at(median_idx)
  let median = right_with_median[0]
  let (_, right_keys) = right_with_median.split_at(1)
  let sibling = Node::new()
  sibling.keys = right_keys
  child.keys = left_keys
  if child.is_leaf() == false {
    let (left_children, right_children) = child.children.split_at(B)
    sibling.children.append(right_children)
    child.children = left_children
  }
  parent.keys.insert(idx, median)
  parent.children.insert(idx + 1, sibling)
}

///|
fn[K : Compare, V] insert_non_full(
  node : Node[K, V],
  key : K,
  value : V
) -> Bool {
  match
    node.keys.binary_search_by(fn(pair) {
      if pair.0 < key {
        return -1
      } else if pair.0 > key {
        return 1
      } else {
        return 0
      }
    }) {
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
pub fn[K : Compare, V] T::add(self : Self[K, V], key : K, value : V) -> Unit {
  match self.root {
    Some(root_node) =>
      if root_node.keys.length() == 2 * B - 1 {
        let old_root = self.root.unwrap()
        let new_root = Node::new()
        new_root.children.push(old_root)
        self.root = Some(new_root)
        split_child(new_root, 0)
        if insert_non_full(new_root, key, value) {
          self.size = self.size + 1
        }
      } else if insert_non_full(root_node, key, value) {
        self.size = self.size + 1
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
  is_tail : Bool
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
    for i = 0; i < num_children; i = i + 1 {
      let child = node.children[i]
      let child_is_tail = i == num_children - 1
      result = result +
        to_string_pretty_recursive(child, new_prefix, child_is_tail)
    }
  }
  result
}

///|
pub fn[K : Compare + Show, V] T::to_string_pretty(self : Self[K, V]) -> String {
  match self.root {
    None => "BTree(size=0) <empty>".to_string()
    Some(root_node) => {
      let mut result = "BTree(size=\{self.size()})\n"
      let root_keys_str = root_node.keys.map(x => x.0.to_string()).join(", ")
      result = result + "[\{root_keys_str}]\n"
      if root_node.is_leaf() == false {
        let num_children = root_node.children.length()
        for i = 0; i < num_children; i = i + 1 {
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
fn[K : Compare, V] borrow_from_prev(parent : Node[K, V], idx : Int) -> Unit {
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
fn[K : Compare, V] borrow_from_next(parent : Node[K, V], idx : Int) -> Unit {
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
fn[K : Compare, V] merge_children(parent : Node[K, V], idx : Int) -> Unit {
  let child = parent.children[idx]
  let sibling = parent.children[idx + 1]
  child.keys.push(parent.keys[idx])
  child.keys.append(sibling.keys)
  if sibling.is_leaf() == false {
    child.children.append(sibling.children)
  }
  ignore(parent.keys.remove(idx))
  ignore(parent.children.remove(idx + 1))
}

///|
fn[K : Compare, V] fill_child(parent : Node[K, V], idx : Int) -> Unit {
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
fn[K : Compare, V] predecessor(node : Node[K, V]) -> (K, V) {
  let mut cur = node
  while cur.is_leaf() == false {
    cur = cur.children[cur.children.length() - 1]
  }
  cur.keys[cur.keys.length() - 1]
}

///|
fn[K : Compare, V] successor(node : Node[K, V]) -> (K, V) {
  let mut cur = node
  while cur.is_leaf() == false {
    cur = cur.children[0]
  }
  cur.keys[0]
}

///|
fn[K : Compare, V] remove_key(node : Node[K, V], key : K) -> Bool {
  match
    node.keys.binary_search_by(fn(p) {
      if p.0 < key {
        -1
      } else if p.0 > key {
        1
      } else {
        0
      }
    }) {
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
pub fn[K : Compare, V] T::remove(self : Self[K, V], key : K) -> Unit {
  match self.root {
    None => return ()
    Some(root) =>
      if remove_key(root, key) {
        self.size = self.size - 1
        if root.keys.is_empty() {
          if root.is_leaf() {
            self.root = None
          } else {
            self.root = Some(root.children[0])
          }
        }
      }
  }
}
