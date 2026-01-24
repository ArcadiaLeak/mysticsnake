module glslang.machine_independent.scan;

import glslang;

import std.algorithm.searching;
import std.range;

enum int EndOfInput = -1;

class TInputScanner {
  protected {
    const string[] sources;
    int currentSource;
    size_t currentChar;

    TSourceLoc[] loc;

    int stringBias;
    int finale;

    TSourceLoc logicalSourceLoc;
    bool singleLogical;

    bool endOfFileReached;
  }

  bool scanVersion(
    out int version_,
    out glslang_profile_t profile,
    out bool notFirstToken
  ) {
    bool versionNotFirst = false;
    notFirstToken = false;
    version_ = 0;
    profile = glslang_profile_t.NO_PROFILE;

    bool foundNonSpaceTab = false;
    bool lookingInMiddle = false;
    int c;
    do {
      if (lookingInMiddle) {
        notFirstToken = true;
        
        if (!this.startsWith('\n', '\r'))
          this.find!(c => c == '\n' || c == '\r')();

        this.find!(c => c != '\n' && c != '\r')();

        if (this.empty) return true;
      }
      lookingInMiddle = true;


    } while (true);
  }

  void consumeWhitespaceComment(out bool foundNonSpaceTab) {
    do {
      consumeWhiteSpace(foundNonSpaceTab);

      if (!this.startsWith('/')) return;

      foundNonSpaceTab = true;

      if (!consumeComment) return;
    } while (true);
  }

  void consumeWhiteSpace(out bool foundNonSpaceTab) {
    auto whitespace = this.until!
      (c => !c.only.startsWith(' ', '\t', '\r', '\n'))
      (OpenRight.no);
    auto n = whitespace.count!
      (c => c.only.startsWith('\r', '\n'));

    foundNonSpaceTab = n > 0;
  }

  bool empty() {
    return front == EndOfInput;
  }

  int front() {
    if (currentSource >= sources.length) {
      endOfFileReached = true;
      return EndOfInput;
    }

    int sourceToRead = currentSource;
    size_t charToRead = currentChar;
    while (charToRead >= sources[sourceToRead].length) {
      charToRead = 0;
      sourceToRead += 1;
      if (sourceToRead >= sources.length) {
        return EndOfInput;
      }
    }

    return sources[sourceToRead][charToRead];
  }

  void popFront() {
    int head = front;
    if (head == EndOfInput) return;

    ++loc[currentSource].column;
    ++logicalSourceLoc.column;
    if (head == '\n') {
      ++loc[currentSource].line;
      ++logicalSourceLoc.line;
      logicalSourceLoc.column = 0;
      loc[currentSource].column = 0;
    }
    advance();
  }

  int get() {
    scope (exit) popFront;
    return front;
  }

  protected void advance() {
    ++currentChar;
    if (currentChar >= sources[currentSource].length) {
      ++currentSource;
      if (currentSource < sources.length) {
        loc[currentSource].string_ = loc[currentSource - 1].string_ + 1;
        loc[currentSource].line = 1;
        loc[currentSource].column = 0;
      }
      while (currentSource < sources.length && sources[currentSource].length == 0) {
        ++currentSource;
        if (currentSource < sources.length) {
          loc[currentSource].string_ = loc[currentSource - 1].string_ + 1;
          loc[currentSource].line = 1;
          loc[currentSource].column = 0;
        }
      }
      currentChar = 0;
    }
  }
}