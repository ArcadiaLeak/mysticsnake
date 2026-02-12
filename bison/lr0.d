module bison.lr0;
import bison;

class state_list {
  state_list next;
  state state_;
}

state_list first_state;
state_list last_state;

bool[] shift_symbol;

rule[][] redset;
state[] shiftset;

item_index[][] kernel_base;
int[] kernel_size;

item_index[] kernel_items;

void allocate_storage() {
  allocate_itemsets();

  redset = new rule[][nrules];
  shift_symbol = new bool[nsyms];
}

void allocate_itemsets() {
  size_t count = 0;
  size_t[] symbol_count = new size_t[nsyms];

  for (int r = 0; r < nrules; ++r)
    for (size_t i = 0; rules[r].rhs[i] >= 0; i++) {
      symbol_number sym = symbol_number(rules[r].rhs[i]);
      count += 1;
      symbol_count[sym] += 1;
    }

  kernel_base = new item_index[][nsyms];
  kernel_items = new item_index[count];

  count = 0;
  for (int i = 0; i < nsyms; i++) {
    kernel_base[i] = kernel_items[count..$];
    count += symbol_count[i];
  }

  kernel_size = new int[nsyms];
}

void generate_states() {
  allocate_storage();
  closure_new(nritems);

  {
    kernel_size[0] = 0;
    for (int r = 0; r < nrules && rules[r].lhs.symbol_ == acceptsymbol; ++r)
      kernel_base[0][kernel_size[0]++] = item_index(ritem.length - rules[r].rhs.length);
    state_list_append(symbol_number(0), kernel_base[0][0..kernel_size[0]]);
  }

  for (state_list list = first_state; list; list = list.next) {
    state s = list.state_;

    s.closure;
    s.save_reductions;
    s.new_itemsets;
    s.append_states;
  }
}

state state_list_append(symbol_number sym, item_index[] core) {
  state_list node = new state_list;
  state res = new state(sym, core.idup);

  node.next = null;
  node.state_ = res;

  if (!first_state)
    first_state = node;
  if (last_state)
    last_state.next = node;
  last_state = node;

  return res;
}

void save_reductions(state s) {
  int count = 0;

  foreach (i; itemset[0..nitemset]) {
    item_number item = ritem[i];
    if (item < 0) {
      rule_number r = rule_number(-1 - item);
      redset[count++] = rules[r..$];
      if (r == 0)
        final_state = s;
    }
  }

  s.reductions = redset[0..count].dup;
}

void new_itemsets(state s) {
  kernel_size[] = 0;
  shift_symbol[] = 0;

  foreach (i; itemset[0..nitemset]) {
    if (ritem[i] >= 0) {
      symbol_number sym = symbol_number(ritem[i]);
      shift_symbol[sym] = true;
      kernel_base[sym][kernel_size[sym]] = i + 1;
      kernel_size[sym]++;
    }
  }

  if (TRACE_AUTOMATON) {
    import std.stdio;
    write("final kernel:\n");
    kernel_print();
    writef("new_itemsets: end: state = %d\n\n", s.number);
  }
}

void core_print(item_index[] core) {
  foreach (c; core) {
    import std.stdio;
    item_print(ritem[c..$]);
    write("\n");
  }
}

void kernel_print() {
  for (int i = 0; i < nsyms; ++i)
    if (kernel_size[i]) {
      import std.stdio;
      writef("kernel[%s] =\n", symbols[i].tag);
      core_print(kernel_base[i][0..kernel_size[i]]);
    }
}

state get_state(symbol_number sym, item_index[] core) {
  if (core !in state_table)
    state_list_append(sym, core);

  return state_table[core];
}

void append_states(state s) {
  import std.stdio;

  if (TRACE_AUTOMATON) 
    writef("append_states: begin: state = %d\n", s.number);

  int i = 0;
  foreach(sym, flag; shift_symbol)
    if (flag) {
      shiftset[i] = get_state(
        symbol_number(cast(int) sym),
        kernel_base[sym][0..kernel_size[sym]]
      );
      ++i;
    }

  if (TRACE_AUTOMATON) 
    writef("append_states: end: state = %d\n", s.number);
}
