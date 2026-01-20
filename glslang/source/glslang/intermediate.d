module glslang.intermediate;

import glslang;

class TIntermNode {
  protected TSourceLoc m_loc;

  this() { m_loc.init(); }

  ref const(TSourceLoc) loc() const => m_loc;
  ref const(TSourceLoc) loc(ref const(TSourceLoc) l) => m_loc = l;

  abstract void traverse(TInterimTraverser);

  inout(TIntermVariableDecl) getAsVariableDecl() inout => null;
  inout(TIntermTyped) getAsTyped() inout => null;
  inout(TIntermOperator) getAsOperator() inout => null;
  inout(TIntermConstantUnion) getAsConstantUnion() inout => null;
  inout(TIntermAggregate) getAsAggregate() inout => null;
  inout(TIntermUnary) getAsUnaryNode() inout => null;
  inout(TIntermBinary) getAsBinaryNode() inout => null;
  inout(TIntermSelection) getAsSelection() inout => null;
  inout(TIntermSwitch) getAsSwitch() inout => null;
  inout(TIntermMethod) getAsMethod() inout => null;
  inout(TIntermSymbol) getAsSymbol() inout => null;
  inout(TIntermBranch) getAsBranch() inout => null;
  inout(TIntermLoop) getAsLoop() inout => null;
}

class TInterimTraverser {
  protected {
    int depth = 0;
    int maxDepth = 0;
  }

  const bool preVisit;
  const bool inVisit;
  const bool postVisit;
  const bool rightToLeft;
  const bool includeDeclSymbol;

  this(
    bool in_preVisit = true,
    bool in_inVisit = false,
    bool in_postVisit = false,
    bool in_rightToLeft = false,
    bool in_includeDeclSymbol = false
  ) {
    preVisit = in_preVisit;
    inVisit = in_inVisit;
    postVisit = in_postVisit;
    rightToLeft = in_rightToLeft;
    includeDeclSymbol = in_includeDeclSymbol;
  }

  abstract void visitSymbol(TIntermSymbol);
  abstract void visitConstantUnion(TIntermConstantUnion);
  abstract void visitBinary(TVisit, TIntermBinary);
  abstract void visitUnary(TVisit, TIntermUnary);
  abstract void visitSelection(TVisit, TIntermSelection);
  abstract void visitAggregate(TVisit, TIntermAggregate);
  abstract void visitLoop(TVisit, TIntermLoop);
  abstract void visitBranch(TVisit, TIntermBranch);
  abstract void visitSwitch(TVisit, TIntermSwitch);
  abstract void visitVariableDecl(TVisit, TIntermVariableDecl);
}

enum TVisit {
  EvPreVisit,
  EvInVisit,
  EvPostVisit
}

class TIntermVariableDecl : TIntermNode {
  private { TIntermSymbol declSymbol; TIntermNode initNode; }

  this(TIntermSymbol in_declSymbol, TIntermNode in_initNode) {
    declSymbol = in_declSymbol; initNode = in_initNode; }

  override inout(TIntermVariableDecl) getAsVariableDecl() inout => this;
  inout(TIntermSymbol) getDeclSymbol() inout => declSymbol;
  inout(TIntermNode) getInitNode() inout => initNode;
}

class TIntermOperator;
class TIntermAggregate;
class TIntermUnary;
class TIntermBinary;
class TIntermConstantUnion;
class TIntermSelection;
class TIntermSwitch;
class TIntermBranch;
class TIntermTyped;
class TIntermMethod;
class TIntermSymbol;
class TIntermLoop;
