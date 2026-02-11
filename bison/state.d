module bison.state;
import bison;

class state {
  symbol_number accessing_symbol;
  item_index[] items;

  this(symbol_number sym, item_index[] core) {
    accessing_symbol = sym;
    items = core;
  }
}
