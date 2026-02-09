module bison.glslgram.primary_expression;

import bison;

void primary_expression() {
  declare_sym(symbol_get("primary_expression"), symbol_class_t.nterm_sym);

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("variable_identifier"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("LEFT_PAREN"));
  grammar_current_rule_symbol_append(symbol_get("expression"));
  grammar_current_rule_symbol_append(symbol_get("RIGHT_PAREN"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("FLOATCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("INTCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("UINTCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("BOOLCONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("STRING_LITERAL"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("INT32CONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("UINT32CONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("INT64CONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("UINT64CONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("INT16CONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("UINT16CONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("DOUBLECONSTANT"));
  grammar_current_rule_end();

  grammar_current_rule_begin(symbol_get("primary_expression"));
  grammar_current_rule_symbol_append(symbol_get("FLOAT16CONSTANT"));
  grammar_current_rule_end();
}
