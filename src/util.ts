export function toCamelCase(str: string) {
  return str
    .replace(/[\s-]+/g, '_') // Replace spaces and underscores with -
    .toLowerCase(); // Convert to lowercase
}