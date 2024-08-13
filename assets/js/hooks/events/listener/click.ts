import { upsertItem } from "../../item";
import { getNodeByEvent } from "../../node";

export function click(event: MouseEvent) {
  const container: HTMLDivElement = this.el.querySelector(".children");

  const node = getNodeByEvent(event);
  node.collapsed = !node.collapsed;

  upsertItem(node, container);

  if (node.collapsed) {
    this.pushEvent("set_expanded", node.uuid);
  } else {
    this.pushEvent("set_collapsed", node.uuid);
  }
}
