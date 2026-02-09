module bison.glslgram.primary_expression;

import bison;

private auto batch(string tags ...) {
  foreach (tag; tags) {
    grammar_current_rule_begin(symbol_get("primary_expression"));
    grammar_current_rule_symbol_append(symbol_get(tag));
    grammar_current_rule_end();
  }
}

auto primary_expression() {
  declare_sym(symbol_get("primary_expression"), symbol_class_t.nterm_sym);

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("variable_identifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("expression"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  batch("FLOATCONSTANT", "INTCONSTANT", "UINTCONSTANT", "BOOLCONSTANT");
  batch("STRING_LITERAL", "INT32CONSTANT", "UINT32CONSTANT", "INT64CONSTANT");
  batch("UINT64CONSTANT", "INT16CONSTANT", "UINT16CONSTANT", "DOUBLECONSTANT");
  batch("FLOAT16CONSTANT");
}
