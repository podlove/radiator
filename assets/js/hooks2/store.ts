import { getDataNodeFromDomNode } from "./node";
import { DomContainer, DomNode, UUID } from "./types";

export function restoreCollapsedStatus(container: DomContainer) {
  const status = loadCollapsedStatus(container.id);

  container.querySelectorAll(".node").forEach((node) => {
    const { uuid } = getDataNodeFromDomNode(node as DomNode);
    status[uuid] && node.classList.add("collapsed");
  });
}

export function saveCollapseStatus(id: string, uuid: UUID, collapsed: boolean) {
  const status = loadCollapsedStatus(id);
  status[uuid] = collapsed;
  localStorage.setItem(id, JSON.stringify(status));
}

export function loadCollapsedStatus(id: string) {
  const status = localStorage.getItem(id) || "{}";

  return JSON.parse(status);
}
