import { UUID, Node } from "./types";
import { getItemByEvent } from "./item";

export function getNodeByEvent(event: Event): Node {
  const item = getItemByEvent(event);

  return getNodeByItem(item);
}

export function getNodeByItem(item: HTMLDivElement): Node {
  const uuid = getUUID(item);
  const content = getContent(item);
  const parent_id = getAttribute(item, "parent");
  const prev_id = getAttribute(item, "prev");
  const collapsed = isSet(item, "collapsed");
  const dirty = isSet(item, "dirty");

  return { uuid, content, parent_id, prev_id, collapsed, dirty };
}

function getUUID(item: HTMLDivElement) {
  return item.id.split("outline-node-")[1] as UUID;
}

function getContent(item: HTMLDivElement) {
  const input = item.querySelector("input") as HTMLInputElement;
  return input.value;
}

function getAttribute(item: HTMLDivElement, key: string) {
  return (item.getAttribute(`data-${key}`) as UUID) || undefined;
}

function isSet(item: HTMLDivElement, key: string) {
  return item.getAttribute(`data-${key}`) == "true" ? true : false;
}
