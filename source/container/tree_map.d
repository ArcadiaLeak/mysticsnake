module container.tree_map;

import std.typecons;

@safe struct TreeMap(Key, Value) {
private:
  enum Color { RED, BLACK };

  class Node {
    Entry data;
    Node left;
    Node right;
    Node parent;
    Color color;

    this(
      in Key k,
      in Value v,
      Color c = Color.RED,
      Node p = null,
      Node l = null,
      Node r = null
    ) {
      data = Entry(k, v);
      left = l;
      right = r;
      parent = p;
      color = c;
    }

    Node successor() {
      Node node = this;

      if (node.right !is null) {
        node = node.right;
        while (node.left !is null) {
          node = node.left;
        }
        return node;
      }
      
      Node parent = node.parent;
      while (parent !is null && node is parent.right) {
        node = parent;
        parent = parent.parent;
      }
      return parent;
    }
    
    Node predecessor() {
      Node node = this;

      if (node.left !is null) {
        node = node.left;
        while (node.right !is null) {
          node = node.right;
        }
        return node;
      }
        
      Node parent = node.parent;
      while (parent !is null && node is parent.left) {
        node = parent;
        parent = parent.parent;
      }
      return parent;
    }

    Node minimum() {
      Node node = this;
      while (node.left !is null) {
        node = node.left;
      }
      return node;
    }

    Node maximum() {
      Node node = this;
      while (node.right !is null) {
        node = node.right;
      }
      return node;
    }
  }

  Node root = null;
  size_t size_ = 0;

  void rotateLeft(Node x) {
    Node y = x.right;
    x.right = y.left;
    if (y.left !is null) {
      y.left.parent = x;
    }
    y.parent = x.parent;
    if (x.parent is null) {
      root = y;
    } else if (x is x.parent.left) {
      x.parent.left = y;
    } else {
      x.parent.right = y;
    }
    y.left = x;
    x.parent = y;
  }

  void rotateRight(Node y) {
    Node x = y.left;
    y.left = x.right;
    if (x.right !is null) {
      x.right.parent = y;
    }
    x.parent = y.parent;
    if (y.parent is null) {
      root = x;
    } else if (y is y.parent.right) {
      y.parent.right = x;
    } else {
      y.parent.left = x;
    }
    x.right = y;
    y.parent = x;
  }

  void fixInsert(Node node) {
    while (node !is root && node.parent.color == Color.RED) {
      if (node.parent is node.parent.parent.left) {
        Node uncle = node.parent.parent.right;
        
        if (uncle !is null && uncle.color == Color.RED) {
          node.parent.color = Color.BLACK;
          uncle.color = Color.BLACK;
          node.parent.parent.color = Color.RED;
          node = node.parent.parent;
        } else {
          if (node is node.parent.right) {
            node = node.parent;
            rotateLeft(node);
          }
          node.parent.color = Color.BLACK;
          node.parent.parent.color = Color.RED;
          rotateRight(node.parent.parent);
        }
      } else {
        Node uncle = node.parent.parent.left;
        
        if (uncle !is null && uncle.color == Color.RED) {
          node.parent.color = Color.BLACK;
          uncle.color = Color.BLACK;
          node.parent.parent.color = Color.RED;
          node = node.parent.parent;
        } else {
          if (node is node.parent.left) {
            node = node.parent;
            rotateRight(node);
          }
          node.parent.color = Color.BLACK;
          node.parent.parent.color = Color.RED;
          rotateLeft(node.parent.parent);
        }
      }
    }
    root.color = Color.BLACK;
  }

  void fixDelete(Node node, Node parent) {
    while (node !is root && (node is null || node.color == Color.BLACK)) {
      if (node is parent.left) {
          Node sibling = parent.right;
          
          if (sibling.color == Color.RED) {
            sibling.color = Color.BLACK;
            parent.color = Color.RED;
            rotateLeft(parent);
            sibling = parent.right;
          }
          
          if ((sibling.left is null || sibling.left.color == Color.BLACK) &&
              (sibling.right is null || sibling.right.color == Color.BLACK)) {
            sibling.color = Color.RED;
            node = parent;
            parent = node.parent;
          } else {
            if (sibling.right is null || sibling.right.color == Color.BLACK) {
              if (sibling.left !is null) {
                sibling.left.color = Color.BLACK;
              }
              sibling.color = Color.RED;
              rotateRight(sibling);
              sibling = parent.right;
            }
            sibling.color = parent.color;
            parent.color = Color.BLACK;
            if (sibling.right !is null) {
              sibling.right.color = Color.BLACK;
            }
            rotateLeft(parent);
            node = root;
          }
      } else {
        Node sibling = parent.left;
        
        if (sibling.color == Color.RED) {
          sibling.color = Color.BLACK;
          parent.color = Color.RED;
          rotateRight(parent);
          sibling = parent.left;
        }
        
        if ((sibling.right is null || sibling.right.color == Color.BLACK) &&
            (sibling.left is null || sibling.left.color == Color.BLACK)) {
          sibling.color = Color.RED;
          node = parent;
          parent = node.parent;
        } else {
          if (sibling.left is null || sibling.left.color == Color.BLACK) {
            if (sibling.right !is null) {
              sibling.right.color = Color.BLACK;
            }
            sibling.color = Color.RED;
            rotateLeft(sibling);
            sibling = parent.left;
          }
          sibling.color = parent.color;
          parent.color = Color.BLACK;
          if (sibling.left !is null) {
            sibling.left.color = Color.BLACK;
          }
          rotateRight(parent);
          node = root;
        }
      }
    }
    
    if (node !is null) {
      node.color = Color.BLACK;
    }
  }

  void transplant(Node u, Node v) {
    if (u.parent is null) {
      root = v;
    } else if (u is u.parent.left) {
      u.parent.left = v;
    } else {
      u.parent.right = v;
    }
    if (v !is null) {
      v.parent = u.parent;
    }
  }

  Node copy(Node node, Node parent) {
    if (node is null) return null;
    
    Node new_node = new Node(
      node.data.key,
      node.data.value, 
      node.color,
      parent
    );
    new_node.left = copy(node.left, new_node);
    new_node.right = copy(node.right, new_node);
    return new_node;
  }

  Node findNode(in Key key) {
    Node current = root;
    while (current !is null) {
      if (key < current.data.key) {
        current = current.left;
      } else if (key > current.data.key) {
        current = current.right;
      } else {
        return current;
      }
    }
    return null;
  }

public:
  struct Entry {
    const Key key;
    Value value;
  }

  struct Cursor {
    private Node current;
    
    Entry data() inout {
      return current.data;
    }
    
    Cursor inc() {
      return Cursor(current.successor);
    }
    
    Cursor dec() {
      return Cursor(current.predecessor);
    }
      
    bool opEquals(in Cursor other) {
      return current is other.current;
    }
  };

  size_t size() {
    return size_;
  }

  bool empty() {
    return size_ == 0;
  }

  Nullable!Cursor minimum() {
    if (root is null) return Nullable!Cursor.init;

    return Cursor(root.minimum).nullable;
  }
  
  Nullable!Cursor maximum() {
    if (root is null) return Nullable!Cursor.init;

    return Cursor(root.maximum).nullable;
  }

  struct InsertRet {
    Cursor cursor;
    bool didInsert;
  }

  InsertRet insert(in Key key, in Value value) {
    Node parent = null;
    Node current = root;
    
    while (current !is null) {
      parent = current;
      if (key < current.data.key) {
        current = current.left;
      } else if (key > current.data.key) {
        current = current.right;
      } else {
        return InsertRet(Cursor(current), false);
      }
    }
    
    Node new_node = new Node(key, value, Color.RED, parent);
    
    if (parent is null) {
      root = new_node;
    } else if (key < parent.data.key) {
      parent.left = new_node;
    } else {
      parent.right = new_node;
    }
    
    fixInsert(new_node);
    size_++;
    return InsertRet(Cursor(new_node), true);
  }

  Value opIndex(in Key key) {
    auto result = insert(key, Value.init);
    return result.cursor.current.data.value;
  }

  Value opIndexAssign(in Value value, in Key key) {
    auto result = insert(key, Value.init);
    result.cursor.current.data.value = value;

    return result.cursor.current.data.value;
  }

  Nullable!Cursor find(in Key key) {
    auto node = findNode(key);

    return node ? Cursor(node).nullable : Nullable!Cursor.init;
  }

  bool contains(in Key key) {
    return findNode(key) !is null;
  }

  size_t erase(in Key key) {
    Node node = findNode(key);
    if (node is null) return 0;
    
    erase(Cursor(node));
    return 1;
  }

  void erase(Cursor pos) {
    if (pos.current is null) return;
    
    Node z = pos.current;
    Node y = z;
    Node x = null;
    Node x_parent = null;
    Color original_color = y.color;
    
    if (z.left is null) {
      x = z.right;
      transplant(z, z.right);
      x_parent = z.parent;
    } else if (z.right is null) {
      x = z.left;
      transplant(z, z.left);
      x_parent = z.parent;
    } else {
      y = z.right.minimum;
      original_color = y.color;
      x = y.right;
      
      if (y.parent is z) {
        if (x !is null) x_parent = y;
        else x_parent = y;
      } else {
        transplant(y, y.right);
        y.right = z.right;
        if (y.right !is null) {
          y.right.parent = y;
        }
        x_parent = y.parent;
      }
      
      transplant(z, y);
      y.left = z.left;
      y.left.parent = y;
      y.color = z.color;
    }

    size_--;
    
    if (original_color == Color.BLACK && root !is null) {
      fixDelete(x, x_parent);
    }
  }
}

unittest {
  TreeMap!(int, string) map;
  assert(map.empty);
  assert(map.size == 0);
  assert(map.minimum == map.maximum);
}

unittest {
  TreeMap!(int, string) map;
  
  auto result1 = map.insert(10, "ten");
  assert(result1.didInsert);
  assert(result1.cursor.data.key == 10);
  assert(result1.cursor.data.value == "ten");
  assert(map.size == 1);
  assert(!map.empty);

  auto result2 = map.insert(20, "twenty");
  assert(result2.didInsert);
  assert(map.size == 2);

  auto result3 = map.insert(10, "ten_again");
  assert(!result3.didInsert);
  assert(result3.cursor.data.value == "ten");
  assert(map.size == 2);
}

unittest {
  TreeMap!(int, string) map;
  
  map[5] = "five";
  assert(map.size == 1);
  assert(map[5] == "five");

  map[5] = "FIVE";
  assert(map.size == 1);
  assert(map[5] == "FIVE");

  string value = map[100];
  assert(value == string.init);
  assert(map.size == 2);

  map[1] = map[5] = "shared";
  assert(map[1] == "shared");
  assert(map[5] == "shared");
}

unittest {
  TreeMap!(int, string) map;

  map.insert(10, "ten");
  map.insert(20, "twenty");
  map.insert(30, "thirty");

  auto it1 = map.find(20);
  assert(!it1.isNull());
  assert(it1.get.data.key == 20);
  assert(it1.get.data.value == "twenty");

  auto it2 = map.find(999);
  assert(it2.isNull());

  assert(map.contains(10));
  assert(map.contains(20));
  assert(map.contains(30));

  assert(!map.contains(0));
  assert(!map.contains(999));
}