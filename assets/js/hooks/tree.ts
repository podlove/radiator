import { NodeData, Node } from "./types";

import { getNodeData, getNodeById, getNodeDataByNode } from "./node";
import { getCollapsedStatus } from "./store";

export function moveNodesToCorrectPosition() {
  this.el.querySelectorAll(this.selector).forEach((node: Node) => {
    moveNode(node);
  });
}

export function restoreCollapsedStatus() {
  const status = getCollapsedStatus(this.el.id);
  this.el.querySelectorAll(this.selector).forEach((node: Node) => {
    const { uuid } = getNodeDataByNode(node);

    status[uuid] && node.classList.add("collapsed");
  });
}

export function moveNode(node: Node): NodeData {
  const { uuid, parent_id, prev_id } = getNodeData(node);
  const parentNode = getNodeById(parent_id);
  const prevNode = getNodeById(prev_id);

  if (prevNode) {
    prevNode.after(node);
    //insertBefore
  } else if (parentNode) {
    parentNode.querySelector(".children")!.prepend(node);
    //appendChild
  }

  return { uuid, parent_id, prev_id };
}

export function getParentNode(node: Node) {
  const parentNode = node.parentNode as HTMLDivElement | null;
  return parentNode?.closest(".node") as Node | null;
}
export function getPrevNode(node: Node) {
  return node.previousElementSibling as Node | null;
}

export function getNodeBefore(node: Node) {
  const prevNode = node.previousSibling as Node | null;
  return prevNode?.querySelectorAll(".node");
}

export function getNodeAfter(node: Node) {}
