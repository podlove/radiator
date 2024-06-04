import { UUID, Node } from "./types";
import { getItemByEvent } from "./item";

export function getNodeByEvent(event: Event): Node {
  const item = getItemByEvent(event);

  return getNodeByItem(item);
}

export function getNodeByItem(item: HTMLDivElement): Node {
  const uuid = item.id.split("outline-node-")[1] as UUID;
  const span = item.querySelector(".innerContent") as HTMLSpanElement;
  const content = span.textContent || "";

  const parent_id = (item.getAttribute("data-parent") as UUID) || undefined;
  const prev_id = (item.getAttribute("data-prev") as UUID) || undefined;
  const dirty = item.getAttribute("data-dirty") == "true" ? true : false;

  return { uuid, content, parent_id, prev_id, dirty };
}
