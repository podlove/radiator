import { UUID, Node } from "./types";
import { getItemById } from "./item";

export function moveNode(node: HTMLDivElement): Node {
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

export function setAttribute(
  node: HTMLDivElement,
  key: string,
  value: string | number | boolean | undefined
) {
  const attrValue = value === undefined ? "" : String(value);
  node.setAttribute(`data-${key}`, attrValue);
}
