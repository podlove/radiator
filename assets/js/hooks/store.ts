import { UUID } from "./types";
import { getNodeDataByDomNode } from "./node";

export function restoreCollapsedStatus() {
  const status = getCollapsedStatus(this.el.id);
  const nodes = this.el.querySelectorAll(this.selector);
  nodes.forEach((node: HTMLDivElement) => {
    const { uuid } = getNodeDataByDomNode(node);

    status[uuid] && node.classList.add("collapsed");
  });
}

export function setCollapse(uuid: UUID, collapsed: boolean) {
  const status = getCollapsedStatus(this.el.id);
  status[uuid] = collapsed;
  localStorage.setItem(this.el.id, JSON.stringify(status));
}

function getCollapsedStatus(id: string) {
  const collapsedStatus = localStorage.getItem(id) || "{}";
  return JSON.parse(collapsedStatus);
}
