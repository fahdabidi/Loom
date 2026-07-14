/// Removes JSONC comments while preserving strings and line positions.
String stripJsonComments(String content) {
  // String-aware JSONC comment stripper. The naive regex approach
  // (RegExp(r'//.*')) corrupts gs:// URLs and other // inside string
  // literals. This scanner tracks quote state inline (single pass)
  // because comment text itself often contains " characters that would
  // throw off a separate pre-scan of the unmodified content.
  final buf = StringBuffer();
  var i = 0;
  var inString = false;
  const space = ' '; // preserve line/column positions

  while (i < content.length) {
    // Escaped character inside a string — write both, don't toggle state
    if (inString && content[i] == '\\' && i + 1 < content.length) {
      buf.write(content[i]);
      i++;
      buf.write(content[i]);
      i++;
      continue;
    }

    // Quote — toggle string state
    if (content[i] == '"') {
      inString = !inString;
      buf.write(content[i]);
      i++;
      continue;
    }

    // Block comments /* ... */ (only when outside a string)
    if (!inString &&
        i + 1 < content.length &&
        content[i] == '/' &&
        content[i + 1] == '*') {
      buf.write(space); // first /
      buf.write(space); // second *
      i += 2;
      while (i + 1 < content.length) {
        if (content[i] == '*' && content[i + 1] == '/') {
          buf.write(space); // *
          buf.write(space); // /
          i += 2;
          break;
        }
        buf.write(content[i] == '\n' ? '\n' : space);
        i++;
      }
      continue;
    }

    // Single-line comments // (only when outside a string)
    if (!inString &&
        i + 1 < content.length &&
        content[i] == '/' &&
        content[i + 1] == '/') {
      buf.write(space); // first /
      buf.write(space); // second /
      i += 2;
      while (i < content.length && content[i] != '\n') {
        buf.write(space);
        i++;
      }
      if (i < content.length && content[i] == '\n') {
        buf.write('\n');
        i++;
      }
      continue;
    }

    buf.write(content[i]);
    i++;
  }

  return buf.toString().trim();
}
