export function toKebabCase(str: string) {
  return str
    .replace(/[\s_]+/g, '-') // Replace spaces and underscores with -
    .toLowerCase(); // Convert to lowercase
}