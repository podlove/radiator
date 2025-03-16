import { moveNode } from "./node";

export function moveNodesToCorrectPosition() {
  const nodes = this.el.querySelectorAll(this.selector);
  nodes.forEach((node: HTMLDivElement) => {
    moveNode(node);
  });
}
