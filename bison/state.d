module bison.state;
import bison;

state final_state;

class state {
  symbol_number accessing_symbol;
  item_index[] items;
  rule[][] reductions;

  this(symbol_number sym, item_index[] core) {
    accessing_symbol = sym;
    items = core;
  }
}
