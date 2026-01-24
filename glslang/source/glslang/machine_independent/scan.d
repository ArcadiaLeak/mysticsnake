module glslang.machine_independent.scan;

import glslang;

enum int EndOfInput = -1;

struct TInputScanner {
  protected {
    string[] sources;
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
        if (front != '\n' && front != '\r') {
          do c = takeFront; while (
            c != EndOfInput &&
            c != '\n' &&
            c != '\r'
          );
        }
        while (front == '\n' || front == '\r') popFront;
        if (front == EndOfInput) return true;
      }
      lookingInMiddle = true;

      consumeWhitespaceComment(foundNonSpaceTab);
    } while (true);
  }

  void consumeWhitespaceComment(out bool foundNonSpaceTab) {
    do {
      consumeWhiteSpace(foundNonSpaceTab);

      int c = front;
      if (c != '/' || c == EndOfInput) return;

      foundNonSpaceTab = true;
      if (!consumeComment) return;
    } while (true);
  }

  void consumeWhiteSpace(out bool foundNonSpaceTab) {
    int c = front;
    while (c == ' ' || c == '\t' || c == '\r' || c == '\n') {
      if (c == '\r' || c == '\n') foundNonSpaceTab = true;
      popFront;
      c = front;
    }
  }

  bool consumeComment() {
    if (front != '/') return false;

    popFront;
    int c = front;
    if (c == '/') {
      popFront;
      c = takeFront;
      do {
        while (c != EndOfInput && c != '\\' && c != '\r' && c != '\n')
          c = takeFront;

        if (c == EndOfInput || c == '\r' || c == '\n') {
          while (c == '\r' || c == '\n') c = takeFront;

          break;
        } else {
          c = takeFront;

          if (c == '\r' && front == '\n') popFront;
          c = takeFront;
        }
      } while (true);

      if (c != EndOfInput) refuseFront;

      return true;
    } else if (c == '*') {
      popFront;
      c = takeFront;
      do {
        while (c != EndOfInput && c != '*') c = takeFront;
        if (c == '*') {
          c = takeFront;
          if (c == '/') break;
        } else break;
      } while (true);
    
      return true;
    } else {
      refuseFront;

      return false;
    }
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

  int takeFront() {
    scope (exit) popFront;
    return front;
  }

  void refuseFront() {
    if (endOfFileReached) return;

    if (currentChar > 0) {
      --currentChar;
      --loc[currentSource].column;
      --logicalSourceLoc.column;
      if (loc[currentSource].column < 0) {
        size_t chIndex = currentChar;
        while (chIndex > 0) {
          if (sources[currentSource][chIndex] == '\n') {
            break;
          }
          --chIndex;
        }
        logicalSourceLoc.column = cast(int) (currentChar - chIndex);
        loc[currentSource].column = cast(int) (currentChar - chIndex);
      }
    } else {
      do {
        --currentSource;
      } while (currentSource > 0 && sources[currentSource].length == 0);
      if (sources[currentSource].length == 0)
        currentChar = 0;
      else
        currentChar = sources[currentSource].length - 1;
    }
    if (front == '\n') {
      --loc[currentSource].line;
      --logicalSourceLoc.line;
    }
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