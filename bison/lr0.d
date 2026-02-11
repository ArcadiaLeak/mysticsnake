module bison.lr0;
import bison;

item_index[][] kernel_base;
item_index[] kernel_items;

void allocate_storage() {
  allocate_itemsets();
}

void allocate_itemsets() {
  size_t count = 0;
  size_t[] symbol_count = new size_t[nsyms];

  for (rule_number r = 0; r < nrules; ++r)
    for (size_t i = 0; rules[r].rhs[i] >= 0; i++) {
      symbol_number sym = rules[r].rhs[i];
      count += 1;
      symbol_count[sym] += 1;
    }

  kernel_base = new item_index[][nsyms];
  kernel_items = new item_index[count];

  count = 0;
  for (symbol_number i = 0; i < nsyms; i++) {
    kernel_base[i] = kernel_items[count..$];
    count += symbol_count[i];
  }
}

void generate_states() {
  allocate_storage();
  closure_new(nritems);
}
