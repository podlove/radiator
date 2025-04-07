import { UUID } from "./types";

export function setCollapse(uuid: UUID, collapsed: boolean) {
  const status = getCollapsedStatus(this.el.id);
  status[uuid] = collapsed;
  localStorage.setItem(this.el.id, JSON.stringify(status));
}

export function getCollapsedStatus(id: string) {
  const status = localStorage.getItem(id) || "{}";
  return JSON.parse(status);
}
