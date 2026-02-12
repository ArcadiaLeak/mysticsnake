module bison.state;
import bison;

state final_state;

state[] states;
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
  state[] transitions;
  state_number number;

  this(symbol_number sym, immutable item_index[] core) {
    accessing_symbol = sym;
    items = core;
    number = nstates++;
    state_table[core] = this;
  }
}

void state_transitions_print(state s) {
  import std.stdio;
  writef("transitions of %d (%d):\n", s.number, s.transitions.length);
  foreach (i, trans; s.transitions)
    writef(
      "  %d: (%d, %s, %d)\n",
      i,
      s.number,
      symbols[trans.accessing_symbol].tag,
      trans.number
    );
}
