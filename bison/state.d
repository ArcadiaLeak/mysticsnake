module bison.state;
import bison;

state final_state;

struct state_number {
  int _;
  alias _ this;
}

state_number nstates;

class state {
  symbol_number accessing_symbol;
  item_index[] items;
  rule[][] reductions;
  state_number number;

  this(symbol_number sym, item_index[] core) {
    accessing_symbol = sym;
    items = core;
    number = nstates++;
  }
}
