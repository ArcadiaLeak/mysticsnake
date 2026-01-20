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
