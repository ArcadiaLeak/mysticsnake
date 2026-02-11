module bison.lr0;
import bison;

class state_list {
  state_list next;
  state state_;
}

state_list first_state;
state_list last_state;

rule[][] redset;

item_index[][] kernel_base;
item_index[] kernel_items;

void allocate_storage() {
  allocate_itemsets();

  redset = new rule[][nrules];
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
}

void generate_states() {
  allocate_storage();
  closure_new(nritems);

  {
    size_t kernel_size = 0;
    for (int r = 0; r < nrules && rules[r].lhs.symbol_ == acceptsymbol; ++r)
      kernel_base[0][kernel_size++] = item_index(ritem.length - rules[r].rhs.length);
    kernel_base[0] = kernel_base[0][0..kernel_size];
    state_list_append(symbol_number(0), kernel_base[0]);
  }

  for (state_list list = first_state; list; list = list.next) {
    state s = list.state_;

    s.closure;
    s.save_reductions;
  }
}

state state_list_append(symbol_number sym, item_index[] core) {
  state_list node = new state_list;
  state res = new state(sym, core);

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
