module bison.state;
import bison;

class state {
  item_index[] items;

  this(item_index[] core) {
    items = core;
  }
}
