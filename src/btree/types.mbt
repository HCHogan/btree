///|
priv struct Node[K, V] {
  mut keys : Array[(K, V)]
  mut children : Array[Node[K, V]]
}

///|
struct T[K, V] {
  mut root : Node[K, V]?
  mut size : Int
}
