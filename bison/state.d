module bison.state;
import bison;

state final_state;
state_number nstates;
state[item_index[]] state_table;

struct state_number {
  int _;
  alias _ this;
}

class state {
  symbol_number accessing_symbol;
  immutable item_index[] items;
  rule[][] reductions;
  state_number number;

  this(symbol_number sym, immutable item_index[] core) {
    accessing_symbol = sym;
    items = core;
    number = nstates++;
    state_table[core] = this;
  }
}
