///|
const B : Int = 4

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
fn[K, V] split_child(parent : Node[K, V], i : Int) -> Unit {
  let full_child = parent.children[i]
  let new_sibling = Node::new()
  let median_key_val = full_child.keys[B - 1]
  parent.keys.insert(i, median_key_val)
  let (left_keys, right_keys) = full_child.keys.split_at(B)
  new_sibling.keys.append(right_keys)
  let final_left_keys = Array::new()
  for i = 0; i < B - 1; i = i + 1 {
    final_left_keys.push(left_keys[i])
  }
  full_child.keys = final_left_keys
  if full_child.is_leaf() == false {
    let (left_children, right_children) = full_child.children.split_at(B)
    new_sibling.children.append(right_children)
    full_child.children = left_children
  }
  parent.children.insert(i + 1, new_sibling)
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
