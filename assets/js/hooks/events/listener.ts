import { CollapseParams } from "../types";
import { getNodeById } from "../node";

export function keydown(event: KeyboardEvent) {
  if (event.key == "Tab") {
    event.preventDefault();
  }
}

export function toggleCollapse({ detail: { uuid } }: CollapseParams) {
  const node = getNodeById(uuid);
  node!.toggleAttribute("data-collapsed");

  const collapsedStatus = localStorage.getItem(this.el.id) || "{}";
  const collapsed = JSON.parse(collapsedStatus);

  collapsed[uuid] = !collapsed[uuid];
  localStorage.setItem(this.el.id, JSON.stringify(collapsed));
}
