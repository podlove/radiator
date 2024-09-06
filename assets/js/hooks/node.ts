import { UUID, Node } from "./types";
import { getItemByEvent, getItemById } from "./item";

export function moveNode(node: HTMLDivElement) {
  const { uuid, parent_id, prev_id } = getNodeData(node);
  const parentNode = getItemById(parent_id);
  const prevNode = getItemById(prev_id);

  if (prevNode) {
    prevNode.after(node);
  } else if (parentNode) {
    parentNode.querySelector(".children")!.append(node);
  }

  return { uuid, parent_id, prev_id };
}

function getNodeData(node: HTMLDivElement) {
  const uuid = getUUID(node);
  const parent_id = getAttribute(node, "parent");
  const prev_id = getAttribute(node, "prev");
  const content = getContent(node);

  return { uuid, parent_id, prev_id, content };
}

export function setAttribute(
  node: HTMLDivElement,
  key: string,
  value: string | number | boolean | undefined
) {
  const attrValue = value === undefined ? "" : String(value);
  node.setAttribute(`data-${key}`, attrValue);
}

//// //// //// ////

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
  return item.id.split("nodes-form-")[1] as UUID;
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
