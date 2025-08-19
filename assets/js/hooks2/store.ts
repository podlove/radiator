import { UUID } from "./types";

export function saveCollapseStatus(id: string, uuid: UUID, collapsed: boolean) {
  const status = loadCollapsedStatus(id);
  status[uuid] = collapsed;
  localStorage.setItem(id, JSON.stringify(status));
}

export function loadCollapsedStatus(id: string) {
  const status = localStorage.getItem(id) || "{}";

  return JSON.parse(status);
}
