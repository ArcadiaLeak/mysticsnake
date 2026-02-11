module bison.lr0;
import bison;

class state_list {
  state_list next;
  state state_;
}

item_index[][] kernel_base;
item_index[] kernel_items;

void allocate_storage() {
  allocate_itemsets();
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
  }
}
