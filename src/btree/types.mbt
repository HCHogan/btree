///|
priv struct Node[K, V] {
  keys : Array[(K, V)]
  children : Array[Node[K, V]]
}

///|
struct T[K, V] {
  mut root : Node[K, V]?
  mut size : Int
}
