import { NodeData, Node } from "./types";

import { getNodeData, getNodeById, getNodeDataByNode } from "./node";
import { getCollapsedStatus } from "./store";

import Sortable from "../../vendor/sortable";

export function moveNodesToCorrectPosition() {
  this.el.querySelectorAll(".node").forEach((node: Node) => {
    moveNode.call(this, node);
  });
}

export function restoreCollapsedStatus() {
  const status = getCollapsedStatus(this.el.id);
  this.el.querySelectorAll(".node").forEach((node: Node) => {
    const { uuid } = getNodeDataByNode(node);

    status[uuid] && node.classList.add("collapsed");
  });
}

export function moveNode(node: Node): NodeData {
  const { uuid, parent_id, prev_id } = getNodeData(node);
  //const parentNode = getNodeById(parent_id);
  //const prevNode = getNodeById(prev_id);

  const parentNode = this.el.querySelector(
    `#nodes-form-${parent_id}`
  ) as Node | null;
  const prevNode = this.el.querySelector(
    `#nodes-form-${prev_id}`
  ) as Node | null;

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

export function getNodeAbove(node: Node) {
  const prevNode = node.previousSibling as Node | null;
  return prevNode?.querySelectorAll(".node");
}

export function getNodeBelow(node: Node) {}

export function initSortableOutline() {
  const nestedSortables = [...this.el.querySelectorAll(".children"), this.el];
  nestedSortables.forEach((element) => {
    new Sortable(element, {
      group: this.el.dataset.group,
      animation: 150,
      // delay: 100,
      dragClass: "drag-item",
      ghostClass: "drag-ghost",
      handle: ".handle",
      fallbackOnBody: true,
      swapThreshold: 0.65,
      onEnd: ({ item }) => {
        const { uuid } = getNodeDataByNode(item);

        const parentNode = getParentNode(item);
        const prevNode = getPrevNode(item);

        const parent_id = parentNode && getNodeDataByNode(parentNode).uuid;
        const prev_id = prevNode && getNodeDataByNode(prevNode).uuid;

        this.pushEventTo(this.el, "move", { uuid, parent_id, prev_id });
      },
    });
  });
}

export function initSortableInbox() {
  const nestedSortables = [...this.el.querySelectorAll(".children")];
  nestedSortables.forEach((element) => {
    new Sortable(element, {
      group: this.el.dataset.group,
      animation: 150,
      // delay: 100,
      dragClass: "drag-item",
      ghostClass: "drag-ghost",
      handle: ".handle",

      put: false,
      sort: false,

      fallbackOnBody: true,
      swapThreshold: 0.65,
      onEnd: ({ item }) => {
        const container_id = item.closest(".stream").dataset.container;
        const { uuid } = getNodeDataByNode(item);

        const parentNode = getParentNode(item);
        const prevNode = getPrevNode(item);

        const parent_id = parentNode && getNodeDataByNode(parentNode).uuid;
        const prev_id = prevNode && getNodeDataByNode(prevNode).uuid;

        this.pushEventTo(this.el, "move_node_to_container", {
          container_id,
          uuid,
          parent_id,
          prev_id,
        });
      },
    });
  });
}
