/// Utility class for handling API responses that may contain PHP warnings
class ResponseUtils {
  /// Cleans PHP warnings from response body and extracts valid JSON
  static String cleanResponseBody(String responseBody) {
    String cleanBody = responseBody.trim();

    // If the response is clean JSON, return as-is
    if (cleanBody.startsWith('{') || cleanBody.startsWith('[')) {
      return cleanBody;
    }

    // Look for the start of the JSON (first '{' or '[')
    int jsonStartIndex = cleanBody.indexOf('{');
    if (jsonStartIndex == -1) {
      jsonStartIndex = cleanBody.indexOf('[');
    }

    // If we found JSON content, extract everything from that point onwards
    if (jsonStartIndex != -1) {
      cleanBody = cleanBody.substring(jsonStartIndex);

      // Additional cleaning: look for the corresponding closing brace/bracket
      int braceCount = 0;
      bool inString = false;
      bool escaped = false;
      String quoteChar = '';

      for (int i = 0; i < cleanBody.length; i++) {
        String char = cleanBody[i];

        // Handle string literals and escape sequences
        if (!escaped && (char == '"' || char == "'")) {
          if (!inString) {
            inString = true;
            quoteChar = char;
          } else if (char == quoteChar) {
            inString = false;
          }
        }

        // Only count braces/brackets outside of strings
        if (!inString) {
          if (char == '{') {
            braceCount++;
          } else if (char == '}') {
            braceCount--;
            if (braceCount == 0 &&
                (i == cleanBody.length - 1 ||
                    cleanBody.substring(i + 1).trim().isEmpty)) {
              // Found the end of the JSON object
              return cleanBody.substring(0, i + 1);
            }
          } else if (char == '[') {
            braceCount++;
          } else if (char == ']') {
            braceCount--;
            if (braceCount == 0 &&
                (i == cleanBody.length - 1 ||
                    cleanBody.substring(i + 1).trim().isEmpty)) {
              // Found the end of the JSON array
              return cleanBody.substring(0, i + 1);
            }
          }
        }

        escaped = char == '\\' && !escaped;
      }

      return cleanBody;
    }

    // If no JSON found, return the original (this will likely cause a parsing error)
    return responseBody;
  }
}
