import { upsertItem } from "../../item";
import { getNodeByEvent } from "../../node";

export function click(event: MouseEvent) {
  const container: HTMLDivElement = this.el.querySelector(".nodes");

  const node = getNodeByEvent(event);
  node.collapsed = !node.collapsed;

  upsertItem(node, container);

  if (node.collapsed) {
    this.pushEventTo(this.el, "set_expanded", node.uuid);
  } else {
    this.pushEventTo(this.el, "set_collapsed", node.uuid);
  }
}
