import { createContext } from "react";

export const TranslationsContext = createContext({});

export function interpolate(template, vars) {
  if (!template) return "";
  return template.replace(/%\{(\w+)\}/g, (_, key) => vars[key]);
}