module bison.lalr;
import bison;

struct goto_number {
  size_t _;
  alias _ this;
}

goto_number[] goto_map;
goto_number ngotos;
state_number[] from_state;
state_number[] to_state;

bool[][] LA;
size_t nLA;

void lalr() {
  initialize_LA;
  set_goto_map;
}

void initialize_LA() {
  nLA = 0;
  foreach (cur_state; states)
    nLA += state_lookaheads_count(cur_state);

  if (!nLA)
    nLA = 1;

  import std.array;
  import std.range;

  bool[][] pLA = LA = new bool[nLA * ntokens]
    .chunks(ntokens)
    .array;

  foreach (cur_state; states) {
    int count = state_lookaheads_count(cur_state);

    if (count) {
      cur_state.lookaheads = pLA;
      pLA = pLA[count..$];
    }
  }
}

int state_lookaheads_count(state s) {
  auto reds = s.reductions;
  auto trans = s.transitions;

  s.consistent = !(
    reds.length > 1 ||
    (reds.length == 1 && trans.length && trans[0].accessing_symbol < ntokens)
  );

  return s.consistent ? 0 : cast(int) reds.length;
}

void set_goto_map() {
  goto_map = new goto_number[nnterms + 1];
  ngotos = goto_number(0);

  foreach (s; states) {
    import std.range;
    foreach (trans; s.transitions.retro) {
      if (trans.accessing_symbol < ntokens) break;
      ngotos++;
      goto_map[trans.accessing_symbol - ntokens]++;
    }
  }

  goto_number[] temp_map = new goto_number[nnterms + 1];
  {
    goto_number k = goto_number(0);
    for (size_t i = ntokens; i < nsyms; ++i) {
      temp_map[i - ntokens] = k;
      k += goto_map[i - ntokens];
    }

    for (size_t i = ntokens; i < nsyms; ++i)
      goto_map[i - ntokens] = temp_map[i - ntokens];

    goto_map[nsyms - ntokens] = ngotos;
    temp_map[nsyms - ntokens] = ngotos;
  }

  from_state = new state_number[ngotos];
  to_state = new state_number[ngotos];

  foreach (s_idx, s; states) {
    import std.range;
    foreach (trans; s.transitions.retro) {
      if (trans.accessing_symbol < ntokens) break;
      goto_number k = temp_map[trans.accessing_symbol - ntokens]++;
      from_state[k] = state_number(s_idx);
      to_state[k] = trans.number;
    }
  }

  if (TRACE_AUTOMATON) {
    import std.stdio;
    for (size_t i = 0; i < nnterms; ++i)
      writef(
        "goto_map[%d (%s)] = %d .. %d\n",
        i, symbols[ntokens + i].tag,
        goto_map[i], cast(int) goto_map[i + 1] - 1
      );
    for (size_t i = 0; i < ngotos; ++i) {
      goto_print(i.goto_number);
      write("\n");
    }
  }
}

void goto_print(goto_number i) {
  import std.stdio;
  state_number src = from_state[i];
  state_number dst = to_state[i];
  symbol_number var = states[dst].accessing_symbol;
  writef("goto[%d] = (%d, %s, %d)", i, src, symbols[var].tag, dst);
}
