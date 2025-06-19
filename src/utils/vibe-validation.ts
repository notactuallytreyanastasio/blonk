// Valid vibe name formats:
// - SCREAMING_SNAKE_CASE
// - snake_case  
// - SCREAMINGCASE
// - lowercase
// Must be alphanumeric with underscores only, no spaces

export function isValidVibeName(name: string): boolean {
  // Must not be empty
  if (!name || name.length === 0) return false;
  
  // Must not contain spaces
  if (name.includes(' ')) return false;
  
  // Must only contain letters, numbers, and underscores
  if (!/^[a-zA-Z0-9_]+$/.test(name)) return false;
  
  // Must be between 3 and 30 characters
  if (name.length < 3 || name.length > 30) return false;
  
  return true;
}

export function normalizeVibeName(name: string): string {
  // Convert to lowercase for consistency in storage
  return name.toLowerCase();
}

export function extractVibeFromHashtag(text: string): string | null {
  // Match #vibe-SOMETHING pattern
  const match = text.match(/#vibe-([a-zA-Z0-9_]+)/i);
  
  if (match && match[1]) {
    const vibeName = match[1];
    if (isValidVibeName(vibeName)) {
      return normalizeVibeName(vibeName);
    }
  }
  
  return null;
}