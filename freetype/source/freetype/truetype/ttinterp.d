module freetype.truetype.ttinterp;

import freetype;

enum TT_MAX_CODE_RANGES = 3;

struct TT_ExecContextRec {
    TT_Face face;
    TT_Size size;
    FT_Memory memory;
    TT_Interpreter interpreter;

    FT_Error error;

    FT_Long top;

    FT_Long stackSize;
    FT_Long* stack;

    FT_Long args;
    FT_Long new_top;

    TT_GlyphZoneRec
      zp0, zp1, zp2, pts, twilight;

    FT_Long pointSize;
    FT_Size_Metrics metrics;
    TT_Size_Metrics tt_metrics;

    TT_GraphicsState GS;

    FT_Int iniRange;
    FT_Int curRange;
    FT_Byte* code;
    FT_Long IP;
    FT_Long codeSize;

    FT_Byte opcode;
    FT_Int length;

    FT_ULong cvtSize;
    FT_Long* cvt;
    FT_ULong glyfCvtSize;
    FT_Long* glyfCvt;

    FT_UInt glyphSize;
    FT_Byte* glyphIns;

    FT_UInt numFDefs;
    FT_UInt maxFDefs;
    TT_DefArray FDefs;

    FT_UInt numIDefs;
    FT_UInt maxIDefs;
    TT_DefArray IDefs;

    FT_UInt maxFunc;
    FT_UInt maxIns;

    FT_Int callTop, callSize;
    TT_CallStack callStack;

    FT_UShort maxPoints;
    FT_Short maxContours;

    TT_CodeRangeTable codeRangeTable;

    FT_UShort storeSize;
    FT_Long* storage;
    FT_UShort glyfStoreSize;
    FT_Long* glyfStorage;

    FT_F26Dot6 period;
    FT_F26Dot6 phase;
    FT_F26Dot6 threshold;

    FT_Bool instruction_trap;

    FT_Bool is_composite;
    FT_Bool pedantic_hinting;

    TT_Round_Func
      func_project, func_dualproj, func_freeProj;

    TT_Move_Func func_move;
    TT_Move_Func func_move_orig;

    TT_Cur_Ppem_Func func_cur_ppem;

    TT_Get_CVT_Func func_read_cvt;
    TT_Set_CVT_Func func_write_cvt;
    TT_Set_CVT_Func func_move_cvt;

    FT_Bool grayscale;

  static if (TT_SUPPORT_SUBPIXEL_HINTING_MINIMAL) {
    FT_Int backward_compatibility;

    FT_Render_Mode mode;
  }

    FT_ULong loopcall_counter;
    FT_ULong loopcall_counter_max;
    FT_ULong neg_jump_counter;
    FT_ULong neg_jump_counter_max;
}

struct TT_CodeRange {
  FT_Byte* base;
  FT_Long size;
}

struct TT_CallRec {
  FT_Int Caller_Range;
  FT_Long Caller_IP;
  FT_Long Cur_Count;

  TT_DefRecord* Def;
}

struct TT_DefRecord {
  FT_Int range;
  FT_Long start;
  FT_Long end;
  FT_UInt opc;
  FT_Bool active;
}

struct TT_GraphicsState {
  FT_UShort rp0;
  FT_UShort rp1;
  FT_UShort rp2;

  FT_UShort gep0;
  FT_UShort gep1;
  FT_UShort gep2;

  FT_UnitVector dualVector;
  FT_UnitVector projVector;
  FT_UnitVector freeVector;

  FT_Long loop;
  FT_Int round_state;
  FT_F26Dot6[4] compensation;

  FT_F26Dot6 minimum_distance;
  FT_F26Dot6 control_value_cutin;
  FT_F26Dot6 single_width_cutin;
  FT_F26Dot6 single_width_value;
  FT_UShort delta_base;
  FT_UShort delta_shift;

  FT_Bool auto_flip;
  FT_Byte instruct_control;

  FT_Bool scan_control;
  FT_Int scan_type;
}

alias TT_DefArray = TT_DefRecord*;

alias TT_CallStack = TT_CallRec*;

alias TT_CodeRangeTable = TT_CodeRange[TT_MAX_CODE_RANGES];

alias TT_Round_Func = FT_F26Dot6 function(
  TT_ExecContext exc,
  FT_F26Dot6 distance,
  FT_F26Dot6 compensation
);

alias TT_Move_Func = void function(
  TT_ExecContext exc,
  TT_GlyphZone zone,
  FT_UShort point,
  FT_F26Dot6 distance
);

alias TT_Get_CVT_Func = FT_F26Dot6 function(
  TT_ExecContext exc,
  FT_ULong idx
);

alias TT_Set_CVT_Func = void function(
  TT_ExecContext exc,
  FT_ULong idx,
  FT_F26Dot6 value
);

alias TT_Cur_Ppem_Func = FT_Long function(
  TT_ExecContext exc
);

auto NO_SUBPIXEL_HINTING(alias exc)() {
  return (cast(TT_Driver) FT_FACE_DRIVER(exc.face)).interpreter_version ==
    TT_INTERPRETER_VERSION_35;
}

auto SUBPIXEL_HINTING_MINIMAL(alias exc)() {
  return (cast(TT_Driver) FT_FACE_DRIVER(exc.face)).interpreter_version ==
    TT_INTERPRETER_VERSION_40;
}

const TT_GraphicsState tt_default_graphics_state = {
  0, 0, 0, 1, 1, 1,
  { 0x4000, 0 }, { 0x4000, 0 }, { 0x4000, 0 },
  1, 1, [0, 0, 0, 0],

  64, 68, 0, 0, 9, 3,
  true, 0, false, 0
};

private void TT_Set_CodeRange(
  TT_ExecContext exec,
  FT_Int range,
  FT_Byte* base,
  FT_Long length
) in (range >= 1 && range <= 3) {
  exec.codeRangeTable[range - 1].base = base;
  exec.codeRangeTable[range - 1].size = length;

  exec.code = base;
  exec.codeSize = length;
  exec.IP = 0;
  exec.curRange = range;
  exec.iniRange = range;
}

private void TT_Clear_CodeRange(
  TT_ExecContext exec,
  FT_Int range
) in (range >= 1 && range <= 3) {
  exec.codeRangeTable[range - 1].base = null;
  exec.codeRangeTable[range - 1].size = 0;
}

private void TT_Done_Context(
  TT_ExecContext exec
) {
  FT_Memory memory = exec.memory;

  exec.maxPoints = 0;
  exec.maxContours = 0;

  exec.glyfCvt = null;
  exec.glyfCvtSize = 0;

  exec.glyfStorage = null;
  exec.glyfStoreSize = 0;

  exec.callStack = null;
  exec.callSize = 0;
  exec.callTop = 0;

  exec.glyphIns = null;
  exec.glyphSize = 0;

  exec.size = null;
  exec.face = null;
}

private FT_Error TT_Load_Context(
  TT_ExecContext exec,
  TT_Face face,
  TT_Size size
) {
  exec.face = face;
  exec.size = size;

  exec.storage = exec.stack + exec.stackSize;
  exec.cvt = exec.storage + exec.storeSize;

  exec.glyphIns = null;
  exec.glyphSize = 0;

  exec.pointSize = size.point_size;
  exec.tt_metrics = size.ttmetrics;
  exec.metrics = *size.metrics;

  exec.twilight = size.twilight;

  return FT_Error.FT_Err_Ok;
}

private void TT_Save_Context(
  TT_ExecContext exec,
  TT_Size size
) {
  size.GS.minimum_distance = exec.GS.minimum_distance;
  size.GS.control_value_cutin = exec.GS.control_value_cutin;
  size.GS.single_width_cutin = exec.GS.single_width_cutin;
  size.GS.single_width_value = exec.GS.single_width_value;
  size.GS.delta_base = exec.GS.delta_base;
  size.GS.delta_shift = exec.GS.delta_shift;
  size.GS.auto_flip = exec.GS.auto_flip;
  size.GS.instruct_control = exec.GS.instruct_control;
  size.GS.scan_control = exec.GS.scan_control;
  size.GS.scan_type = exec.GS.scan_type;
}

private TT_ExecContext TT_Save_Context(
  TT_Driver driver
) {
    TT_ExecContext exec = null;
    FT_DebugHook_Func interp;

    if (!driver) return null;
  
    exec = new TT_ExecContextRec;

    interp = driver.root.root.library.debug_hooks[FT_DEBUG_HOOK_TRUETYPE];

    if (interp)
      exec.interpreter = cast(TT_Interpreter) interp;
    else
      exec.interpreter = cast(TT_Interpreter) &TT_RunIns;

    exec.callSize = 32;
    exec.callStack = new TT_CallRec[exec.callSize].ptr;

    return exec;
}

private FT_Error TT_RunIns(
  void* exec
) {
  throw new Exception("uninplemented");

  return FT_Error.FT_Err_Ok;
}

FT_Byte PACK(int x, int y) {
  return cast(ubyte) ((x << 4) | y);
}

private immutable
FT_Byte[256] Pop_Push_Count = [
  /*  SVTCA[0]  */  PACK(0, 0),
  /*  SVTCA[1]  */  PACK(0, 0),
  /*  SPVTCA[0] */  PACK(0, 0),
  /*  SPVTCA[1] */  PACK(0, 0),
  /*  SFVTCA[0] */  PACK(0, 0),
  /*  SFVTCA[1] */  PACK(0, 0),
  /*  SPVTL[0]  */  PACK(2, 0),
  /*  SPVTL[1]  */  PACK(2, 0),
  /*  SFVTL[0]  */  PACK(2, 0),
  /*  SFVTL[1]  */  PACK(2, 0),
  /*  SPVFS     */  PACK(2, 0),
  /*  SFVFS     */  PACK(2, 0),
  /*  GPV       */  PACK(0, 2),
  /*  GFV       */  PACK(0, 2),
  /*  SFVTPV    */  PACK(0, 0),
  /*  ISECT     */  PACK(5, 0),

  /*  SRP0      */  PACK(1, 0),
  /*  SRP1      */  PACK(1, 0),
  /*  SRP2      */  PACK(1, 0),
  /*  SZP0      */  PACK(1, 0),
  /*  SZP1      */  PACK(1, 0),
  /*  SZP2      */  PACK(1, 0),
  /*  SZPS      */  PACK(1, 0),
  /*  SLOOP     */  PACK(1, 0),
  /*  RTG       */  PACK(0, 0),
  /*  RTHG      */  PACK(0, 0),
  /*  SMD       */  PACK(1, 0),
  /*  ELSE      */  PACK(0, 0),
  /*  JMPR      */  PACK(1, 0),
  /*  SCVTCI    */  PACK(1, 0),
  /*  SSWCI     */  PACK(1, 0),
  /*  SSW       */  PACK(1, 0),

  /*  DUP       */  PACK(1, 2),
  /*  POP       */  PACK(1, 0),
  /*  CLEAR     */  PACK(0, 0),
  /*  SWAP      */  PACK(2, 2),
  /*  DEPTH     */  PACK(0, 1),
  /*  CINDEX    */  PACK(1, 1),
  /*  MINDEX    */  PACK(1, 0),
  /*  ALIGNPTS  */  PACK(2, 0),
  /*  INS_$28   */  PACK(0, 0),
  /*  UTP       */  PACK(1, 0),
  /*  LOOPCALL  */  PACK(2, 0),
  /*  CALL      */  PACK(1, 0),
  /*  FDEF      */  PACK(1, 0),
  /*  ENDF      */  PACK(0, 0),
  /*  MDAP[0]   */  PACK(1, 0),
  /*  MDAP[1]   */  PACK(1, 0),

  /*  IUP[0]    */  PACK(0, 0),
  /*  IUP[1]    */  PACK(0, 0),
  /*  SHP[0]    */  PACK(0, 0),
  /*  SHP[1]    */  PACK(0, 0),
  /*  SHC[0]    */  PACK(1, 0),
  /*  SHC[1]    */  PACK(1, 0),
  /*  SHZ[0]    */  PACK(1, 0),
  /*  SHZ[1]    */  PACK(1, 0),
  /*  SHPIX     */  PACK(1, 0),
  /*  IP        */  PACK(0, 0),
  /*  MSIRP[0]  */  PACK(2, 0),
  /*  MSIRP[1]  */  PACK(2, 0),
  /*  ALIGNRP   */  PACK(0, 0),
  /*  RTDG      */  PACK(0, 0),
  /*  MIAP[0]   */  PACK(2, 0),
  /*  MIAP[1]   */  PACK(2, 0),

  /*  NPUSHB    */  PACK(0, 0),
  /*  NPUSHW    */  PACK(0, 0),
  /*  WS        */  PACK(2, 0),
  /*  RS        */  PACK(1, 1),
  /*  WCVTP     */  PACK(2, 0),
  /*  RCVT      */  PACK(1, 1),
  /*  GC[0]     */  PACK(1, 1),
  /*  GC[1]     */  PACK(1, 1),
  /*  SCFS      */  PACK(2, 0),
  /*  MD[0]     */  PACK(2, 1),
  /*  MD[1]     */  PACK(2, 1),
  /*  MPPEM     */  PACK(0, 1),
  /*  MPS       */  PACK(0, 1),
  /*  FLIPON    */  PACK(0, 0),
  /*  FLIPOFF   */  PACK(0, 0),
  /*  DEBUG     */  PACK(1, 0),

  /*  LT        */  PACK(2, 1),
  /*  LTEQ      */  PACK(2, 1),
  /*  GT        */  PACK(2, 1),
  /*  GTEQ      */  PACK(2, 1),
  /*  EQ        */  PACK(2, 1),
  /*  NEQ       */  PACK(2, 1),
  /*  ODD       */  PACK(1, 1),
  /*  EVEN      */  PACK(1, 1),
  /*  IF        */  PACK(1, 0),
  /*  EIF       */  PACK(0, 0),
  /*  AND       */  PACK(2, 1),
  /*  OR        */  PACK(2, 1),
  /*  NOT       */  PACK(1, 1),
  /*  DELTAP1   */  PACK(1, 0),
  /*  SDB       */  PACK(1, 0),
  /*  SDS       */  PACK(1, 0),

  /*  ADD       */  PACK(2, 1),
  /*  SUB       */  PACK(2, 1),
  /*  DIV       */  PACK(2, 1),
  /*  MUL       */  PACK(2, 1),
  /*  ABS       */  PACK(1, 1),
  /*  NEG       */  PACK(1, 1),
  /*  FLOOR     */  PACK(1, 1),
  /*  CEILING   */  PACK(1, 1),
  /*  ROUND[0]  */  PACK(1, 1),
  /*  ROUND[1]  */  PACK(1, 1),
  /*  ROUND[2]  */  PACK(1, 1),
  /*  ROUND[3]  */  PACK(1, 1),
  /*  NROUND[0] */  PACK(1, 1),
  /*  NROUND[1] */  PACK(1, 1),
  /*  NROUND[2] */  PACK(1, 1),
  /*  NROUND[3] */  PACK(1, 1),

  /*  WCVTF     */  PACK(2, 0),
  /*  DELTAP2   */  PACK(1, 0),
  /*  DELTAP3   */  PACK(1, 0),
  /*  DELTAC1   */  PACK(1, 0),
  /*  DELTAC2   */  PACK(1, 0),
  /*  DELTAC3   */  PACK(1, 0),
  /*  SROUND    */  PACK(1, 0),
  /*  S45ROUND  */  PACK(1, 0),
  /*  JROT      */  PACK(2, 0),
  /*  JROF      */  PACK(2, 0),
  /*  ROFF      */  PACK(0, 0),
  /*  INS_$7B   */  PACK(0, 0),
  /*  RUTG      */  PACK(0, 0),
  /*  RDTG      */  PACK(0, 0),
  /*  SANGW     */  PACK(1, 0),
  /*  AA        */  PACK(1, 0),

  /*  FLIPPT    */  PACK(0, 0),
  /*  FLIPRGON  */  PACK(2, 0),
  /*  FLIPRGOFF */  PACK(2, 0),
  /*  INS_$83   */  PACK(0, 0),
  /*  INS_$84   */  PACK(0, 0),
  /*  SCANCTRL  */  PACK(1, 0),
  /*  SDPVTL[0] */  PACK(2, 0),
  /*  SDPVTL[1] */  PACK(2, 0),
  /*  GETINFO   */  PACK(1, 1),
  /*  IDEF      */  PACK(1, 0),
  /*  ROLL      */  PACK(3, 3),
  /*  MAX       */  PACK(2, 1),
  /*  MIN       */  PACK(2, 1),
  /*  SCANTYPE  */  PACK(1, 0),
  /*  INSTCTRL  */  PACK(2, 0),
  /*  INS_$8F   */  PACK(0, 0),

  /*  INS_$90  */   PACK(0, 0),
  /*  GETVAR   */   PACK(0, 0),
  /*  GETDATA  */   PACK(0, 1),
  /*  INS_$93  */   PACK(0, 0),
  /*  INS_$94  */   PACK(0, 0),
  /*  INS_$95  */   PACK(0, 0),
  /*  INS_$96  */   PACK(0, 0),
  /*  INS_$97  */   PACK(0, 0),
  /*  INS_$98  */   PACK(0, 0),
  /*  INS_$99  */   PACK(0, 0),
  /*  INS_$9A  */   PACK(0, 0),
  /*  INS_$9B  */   PACK(0, 0),
  /*  INS_$9C  */   PACK(0, 0),
  /*  INS_$9D  */   PACK(0, 0),
  /*  INS_$9E  */   PACK(0, 0),
  /*  INS_$9F  */   PACK(0, 0),

  /*  INS_$A0  */   PACK(0, 0),
  /*  INS_$A1  */   PACK(0, 0),
  /*  INS_$A2  */   PACK(0, 0),
  /*  INS_$A3  */   PACK(0, 0),
  /*  INS_$A4  */   PACK(0, 0),
  /*  INS_$A5  */   PACK(0, 0),
  /*  INS_$A6  */   PACK(0, 0),
  /*  INS_$A7  */   PACK(0, 0),
  /*  INS_$A8  */   PACK(0, 0),
  /*  INS_$A9  */   PACK(0, 0),
  /*  INS_$AA  */   PACK(0, 0),
  /*  INS_$AB  */   PACK(0, 0),
  /*  INS_$AC  */   PACK(0, 0),
  /*  INS_$AD  */   PACK(0, 0),
  /*  INS_$AE  */   PACK(0, 0),
  /*  INS_$AF  */   PACK(0, 0),

  /*  PUSHB[0]  */  PACK(0, 1),
  /*  PUSHB[1]  */  PACK(0, 2),
  /*  PUSHB[2]  */  PACK(0, 3),
  /*  PUSHB[3]  */  PACK(0, 4),
  /*  PUSHB[4]  */  PACK(0, 5),
  /*  PUSHB[5]  */  PACK(0, 6),
  /*  PUSHB[6]  */  PACK(0, 7),
  /*  PUSHB[7]  */  PACK(0, 8),
  /*  PUSHW[0]  */  PACK(0, 1),
  /*  PUSHW[1]  */  PACK(0, 2),
  /*  PUSHW[2]  */  PACK(0, 3),
  /*  PUSHW[3]  */  PACK(0, 4),
  /*  PUSHW[4]  */  PACK(0, 5),
  /*  PUSHW[5]  */  PACK(0, 6),
  /*  PUSHW[6]  */  PACK(0, 7),
  /*  PUSHW[7]  */  PACK(0, 8),

  /*  MDRP[00]  */  PACK(1, 0),
  /*  MDRP[01]  */  PACK(1, 0),
  /*  MDRP[02]  */  PACK(1, 0),
  /*  MDRP[03]  */  PACK(1, 0),
  /*  MDRP[04]  */  PACK(1, 0),
  /*  MDRP[05]  */  PACK(1, 0),
  /*  MDRP[06]  */  PACK(1, 0),
  /*  MDRP[07]  */  PACK(1, 0),
  /*  MDRP[08]  */  PACK(1, 0),
  /*  MDRP[09]  */  PACK(1, 0),
  /*  MDRP[10]  */  PACK(1, 0),
  /*  MDRP[11]  */  PACK(1, 0),
  /*  MDRP[12]  */  PACK(1, 0),
  /*  MDRP[13]  */  PACK(1, 0),
  /*  MDRP[14]  */  PACK(1, 0),
  /*  MDRP[15]  */  PACK(1, 0),

  /*  MDRP[16]  */  PACK(1, 0),
  /*  MDRP[17]  */  PACK(1, 0),
  /*  MDRP[18]  */  PACK(1, 0),
  /*  MDRP[19]  */  PACK(1, 0),
  /*  MDRP[20]  */  PACK(1, 0),
  /*  MDRP[21]  */  PACK(1, 0),
  /*  MDRP[22]  */  PACK(1, 0),
  /*  MDRP[23]  */  PACK(1, 0),
  /*  MDRP[24]  */  PACK(1, 0),
  /*  MDRP[25]  */  PACK(1, 0),
  /*  MDRP[26]  */  PACK(1, 0),
  /*  MDRP[27]  */  PACK(1, 0),
  /*  MDRP[28]  */  PACK(1, 0),
  /*  MDRP[29]  */  PACK(1, 0),
  /*  MDRP[30]  */  PACK(1, 0),
  /*  MDRP[31]  */  PACK(1, 0),

  /*  MIRP[00]  */  PACK(2, 0),
  /*  MIRP[01]  */  PACK(2, 0),
  /*  MIRP[02]  */  PACK(2, 0),
  /*  MIRP[03]  */  PACK(2, 0),
  /*  MIRP[04]  */  PACK(2, 0),
  /*  MIRP[05]  */  PACK(2, 0),
  /*  MIRP[06]  */  PACK(2, 0),
  /*  MIRP[07]  */  PACK(2, 0),
  /*  MIRP[08]  */  PACK(2, 0),
  /*  MIRP[09]  */  PACK(2, 0),
  /*  MIRP[10]  */  PACK(2, 0),
  /*  MIRP[11]  */  PACK(2, 0),
  /*  MIRP[12]  */  PACK(2, 0),
  /*  MIRP[13]  */  PACK(2, 0),
  /*  MIRP[14]  */  PACK(2, 0),
  /*  MIRP[15]  */  PACK(2, 0),

  /*  MIRP[16]  */  PACK(2, 0),
  /*  MIRP[17]  */  PACK(2, 0),
  /*  MIRP[18]  */  PACK(2, 0),
  /*  MIRP[19]  */  PACK(2, 0),
  /*  MIRP[20]  */  PACK(2, 0),
  /*  MIRP[21]  */  PACK(2, 0),
  /*  MIRP[22]  */  PACK(2, 0),
  /*  MIRP[23]  */  PACK(2, 0),
  /*  MIRP[24]  */  PACK(2, 0),
  /*  MIRP[25]  */  PACK(2, 0),
  /*  MIRP[26]  */  PACK(2, 0),
  /*  MIRP[27]  */  PACK(2, 0),
  /*  MIRP[28]  */  PACK(2, 0),
  /*  MIRP[29]  */  PACK(2, 0),
  /*  MIRP[30]  */  PACK(2, 0),
  /*  MIRP[31]  */  PACK(2, 0)
];

private immutable
string[256] opcode_name = [
  "8 SVTCA[y]",
  "8 SVTCA[x]",
  "9 SPVTCA[y]",
  "9 SPVTCA[x]",
  "9 SFVTCA[y]",
  "9 SFVTCA[x]",
  "9 SPVTL[||]",
  "8 SPVTL[+]",
  "9 SFVTL[||]",
  "8 SFVTL[+]",
  "5 SPVFS",
  "5 SFVFS",
  "3 GPV",
  "3 GFV",
  "6 SFVTPV",
  "5 ISECT",

  "4 SRP0",
  "4 SRP1",
  "4 SRP2",
  "4 SZP0",
  "4 SZP1",
  "4 SZP2",
  "4 SZPS",
  "5 SLOOP",
  "3 RTG",
  "4 RTHG",
  "3 SMD",
  "4 ELSE",
  "4 JMPR",
  "6 SCVTCI",
  "5 SSWCI",
  "3 SSW",

  "3 DUP",
  "3 POP",
  "5 CLEAR",
  "4 SWAP",
  "5 DEPTH",
  "6 CINDEX",
  "6 MINDEX",
  "8 ALIGNPTS",
  "7 INS_$28",
  "3 UTP",
  "8 LOOPCALL",
  "4 CALL",
  "4 FDEF",
  "4 ENDF",
  "6 MDAP[]",
  "9 MDAP[rnd]",

  "6 IUP[y]",
  "6 IUP[x]",
  "8 SHP[rp2]",
  "8 SHP[rp1]",
  "8 SHC[rp2]",
  "8 SHC[rp1]",
  "8 SHZ[rp2]",
  "8 SHZ[rp1]",
  "5 SHPIX",
  "2 IP",
  "7 MSIRP[]",
  "A MSIRP[rp0]",
  "7 ALIGNRP",
  "4 RTDG",
  "6 MIAP[]",
  "9 MIAP[rnd]",

  "6 NPUSHB",
  "6 NPUSHW",
  "2 WS",
  "2 RS",
  "5 WCVTP",
  "4 RCVT",
  "8 GC[curr]",
  "8 GC[orig]",
  "4 SCFS",
  "8 MD[curr]",
  "8 MD[orig]",
  "5 MPPEM",
  "3 MPS",
  "6 FLIPON",
  "7 FLIPOFF",
  "5 DEBUG",

  "2 LT",
  "4 LTEQ",
  "2 GT",
  "4 GTEQ",
  "2 EQ",
  "3 NEQ",
  "3 ODD",
  "4 EVEN",
  "2 IF",
  "3 EIF",
  "3 AND",
  "2 OR",
  "3 NOT",
  "7 DELTAP1",
  "3 SDB",
  "3 SDS",

  "3 ADD",
  "3 SUB",
  "3 DIV",
  "3 MUL",
  "3 ABS",
  "3 NEG",
  "5 FLOOR",
  "7 CEILING",
  "8 ROUND[G]",
  "8 ROUND[B]",
  "8 ROUND[W]",
  "7 ROUND[]",
  "9 NROUND[G]",
  "9 NROUND[B]",
  "9 NROUND[W]",
  "8 NROUND[]",

  "5 WCVTF",
  "7 DELTAP2",
  "7 DELTAP3",
  "7 DELTAC1",
  "7 DELTAC2",
  "7 DELTAC3",
  "6 SROUND",
  "8 S45ROUND",
  "4 JROT",
  "4 JROF",
  "4 ROFF",
  "7 INS_$7B",
  "4 RUTG",
  "4 RDTG",
  "5 SANGW",
  "2 AA",

  "6 FLIPPT",
  "8 FLIPRGON",
  "9 FLIPRGOFF",
  "7 INS_$83",
  "7 INS_$84",
  "8 SCANCTRL",
  "A SDPVTL[||]",
  "9 SDPVTL[+]",
  "7 GETINFO",
  "4 IDEF",
  "4 ROLL",
  "3 MAX",
  "3 MIN",
  "8 SCANTYPE",
  "8 INSTCTRL",
  "7 INS_$8F",

  "7 INS_$90",
  TT_CONFIG_OPTION_GX_VAR_SUPPORT
    ? "C GETVARIATION"
    : "7 INS_$91",
  TT_CONFIG_OPTION_GX_VAR_SUPPORT
    ? "7 GETDATA"
    : "7 INS_$92",
  "7 INS_$93",
  "7 INS_$94",
  "7 INS_$95",
  "7 INS_$96",
  "7 INS_$97",
  "7 INS_$98",
  "7 INS_$99",
  "7 INS_$9A",
  "7 INS_$9B",
  "7 INS_$9C",
  "7 INS_$9D",
  "7 INS_$9E",
  "7 INS_$9F",

  "7 INS_$A0",
  "7 INS_$A1",
  "7 INS_$A2",
  "7 INS_$A3",
  "7 INS_$A4",
  "7 INS_$A5",
  "7 INS_$A6",
  "7 INS_$A7",
  "7 INS_$A8",
  "7 INS_$A9",
  "7 INS_$AA",
  "7 INS_$AB",
  "7 INS_$AC",
  "7 INS_$AD",
  "7 INS_$AE",
  "7 INS_$AF",

  "8 PUSHB[0]",
  "8 PUSHB[1]",
  "8 PUSHB[2]",
  "8 PUSHB[3]",
  "8 PUSHB[4]",
  "8 PUSHB[5]",
  "8 PUSHB[6]",
  "8 PUSHB[7]",
  "8 PUSHW[0]",
  "8 PUSHW[1]",
  "8 PUSHW[2]",
  "8 PUSHW[3]",
  "8 PUSHW[4]",
  "8 PUSHW[5]",
  "8 PUSHW[6]",
  "8 PUSHW[7]",

  "7 MDRP[G]",
  "7 MDRP[B]",
  "7 MDRP[W]",
  "6 MDRP[]",
  "8 MDRP[rG]",
  "8 MDRP[rB]",
  "8 MDRP[rW]",
  "7 MDRP[r]",
  "8 MDRP[mG]",
  "8 MDRP[mB]",
  "8 MDRP[mW]",
  "7 MDRP[m]",
  "9 MDRP[mrG]",
  "9 MDRP[mrB]",
  "9 MDRP[mrW]",
  "8 MDRP[mr]",

  "8 MDRP[pG]",
  "8 MDRP[pB]",
  "8 MDRP[pW]",
  "7 MDRP[p]",
  "9 MDRP[prG]",
  "9 MDRP[prB]",
  "9 MDRP[prW]",
  "8 MDRP[pr]",
  "9 MDRP[pmG]",
  "9 MDRP[pmB]",
  "9 MDRP[pmW]",
  "8 MDRP[pm]",
  "A MDRP[pmrG]",
  "A MDRP[pmrB]",
  "A MDRP[pmrW]",
  "9 MDRP[pmr]",

  "7 MIRP[G]",
  "7 MIRP[B]",
  "7 MIRP[W]",
  "6 MIRP[]",
  "8 MIRP[rG]",
  "8 MIRP[rB]",
  "8 MIRP[rW]",
  "7 MIRP[r]",
  "8 MIRP[mG]",
  "8 MIRP[mB]",
  "8 MIRP[mW]",
  "7 MIRP[m]",
  "9 MIRP[mrG]",
  "9 MIRP[mrB]",
  "9 MIRP[mrW]",
  "8 MIRP[mr]",

  "8 MIRP[pG]",
  "8 MIRP[pB]",
  "8 MIRP[pW]",
  "7 MIRP[p]",
  "9 MIRP[prG]",
  "9 MIRP[prB]",
  "9 MIRP[prW]",
  "8 MIRP[pr]",
  "9 MIRP[pmG]",
  "9 MIRP[pmB]",
  "9 MIRP[pmW]",
  "8 MIRP[pm]",
  "A MIRP[pmrG]",
  "A MIRP[pmrB]",
  "A MIRP[pmrW]",
  "9 MIRP[pmr]"
];

private immutable
FT_Char[256] opcode_length = [
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,  
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,  
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,

  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,  
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,  
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,

  -0x1, -0x2, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,  
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,  
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,

  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,  
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,  
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,

  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,

  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,
  0x02, 0x03, 0x04, 0x05,  0x06, 0x07, 0x08, 0x09,
  0x03, 0x05, 0x07, 0x09,  0x0b, 0x0d, 0x0f, 0x11,

  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,  
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,  
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,
  
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,  
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01,  
  0x01, 0x01, 0x01, 0x01,  0x01, 0x01, 0x01, 0x01
];
