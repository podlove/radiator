import { CollapseParams } from "../types";
import { getItemById } from "../item";

export function keydown(event: KeyboardEvent) {
  if (event.key == "Tab") {
    event.preventDefault();
  }
}

export function toggleCollapse({ detail: { uuid } }: CollapseParams) {
  const item = getItemById(uuid);
  item!.toggleAttribute("data-collapsed");

  const collapsedStatus = localStorage.getItem(this.el.id) || "{}";
  const collapsed = JSON.parse(collapsedStatus);

  collapsed[uuid] = !collapsed[uuid];
  localStorage.setItem(this.el.id, JSON.stringify(collapsed));
}
