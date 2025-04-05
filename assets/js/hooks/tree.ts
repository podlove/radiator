import { moveNode } from "./node";

export function moveNodesToCorrectPosition() {
  const nodes = this.el.querySelectorAll(this.selector);
  nodes.forEach((node: HTMLDivElement) => {
    moveNode(node);
  });
}

export function getDomNodeBefore(node: HTMLDivElement) {
  const prevNode = node.previousSibling as HTMLDivElement | null;
  return prevNode?.querySelectorAll(".node");
}

export function getDomNodeAfter(node: Node) {}
