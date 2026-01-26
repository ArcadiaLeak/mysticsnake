module glslang.machine_independent.scan;

import glslang;

import core.stdc.string;

enum int EndOfInput = -1;

class TInputScanner {
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

  this(
    string[] s, string[] names = null,
    int b = 0, int f = 0, bool single = false
  ) {
    sources = s;
    currentSource = 0;
    currentChar = 0;
    stringBias = b;
    finale = f;
    singleLogical = single;
    endOfFileReached = false;

    loc = new TSourceLoc[sources.length];
    for (int i = 0; i < sources.length; ++i) {
      loc[i].init(i - stringBias);
    }
    if (names != null) {
      for (int i = 0; i < sources.length; ++i)
        loc[i].name = names[i];
    }
    loc[currentSource].line = 1;
    logicalSourceLoc.init(1);
    logicalSourceLoc.name = loc[0].name;
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
      if (foundNonSpaceTab) versionNotFirst = true;

      if (takeFront != '#') {
        versionNotFirst = true;
        continue;
      }

      do c = takeFront; while (c == ' ' || c == '\t');

      if (
        c != 'v' ||
        takeFront != 'e' ||
        takeFront != 'r' ||
        takeFront != 's' ||
        takeFront != 'i' ||
        takeFront != 'o' ||
        takeFront != 'n'
      ) {
        versionNotFirst = true;
        continue;
      }

      do c = takeFront; while (c == ' ' || c == '\t');

      while (c >= '0' && c <= '9') {
        version_ = 10 * version_ + (c - '0');
        c = takeFront;
      }
      if (version_ == 0) {
        versionNotFirst = true;
        continue;
      }

      while (c == ' ' || c == '\t') c = takeFront;

      const int maxProfileLength = 13;
      char[maxProfileLength] profileString;
      int profileLength;
      for (profileLength = 0; profileLength < maxProfileLength; ++profileLength) {
        if (c == EndOfInput || c == ' ' || c == '\t' || c == '\n' || c == '\r')
          break;
        profileString[profileLength] = cast(char) c;
        c = takeFront;
      }
      if (c != EndOfInput && c != ' ' && c != '\t' && c != '\n' && c != '\r') {
        versionNotFirst = true;
        continue;
      }

      if (profileLength == 2 && strncmp(profileString.ptr, "es", profileLength) == 0)
        profile = glslang_profile_t.ES_PROFILE;
      else if (profileLength == 4 && strncmp(profileString.ptr, "core", profileLength) == 0)
        profile = glslang_profile_t.CORE_PROFILE;
      else if (profileLength == 13 && strncmp(profileString.ptr, "compatibility", profileLength) == 0)
        profile = glslang_profile_t.COMPATIBILITY_PROFILE;

      return versionNotFirst;
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