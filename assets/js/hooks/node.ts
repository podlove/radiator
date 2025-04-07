import { NodeData, Node, UUID } from "./types";

export function getCursorPosition() {
  const selection = window.getSelection();
  if (selection && selection.rangeCount) {
    const range = selection.getRangeAt(0);

    return { start: range.startOffset, stop: range.endOffset };
  }

  return { start: 0, stop: 0 };
}

export function setCursorPosition(node: Node, position: number) {
  const content = node.querySelector(".content");

  const range = document.createRange();
  range.setStart(content!, position);
  range.collapse(true);
  const selection = window.getSelection();
  selection?.removeAllRanges();
  selection?.addRange(range);
}

export function getNodeDataByTarget(target: HTMLDivElement): NodeData {
  const node = getNodeByTarget(target);

  return getNodeDataByNode(node);
}

export function getNodeDataByNode(node: Node): NodeData {
  const uuid = getUUID(node);
  const parent_id = getData(node, "parent") as UUID | undefined;
  const prev_id = getData(node, "prev") as UUID | undefined;
  const collapsed = node.classList.contains("collapsed");
  const content = getContent(node);

  return { uuid, parent_id, prev_id, collapsed, content };
}

export function getNodeData(node: Node): NodeData {
  const uuid = getUUID(node);
  const parent_id = getData(node, "parent") as UUID;
  const prev_id = getData(node, "prev") as UUID;
  const content = getContent(node);

  return { uuid, parent_id, prev_id, content };
}

export function getUUID(node: Node) {
  return node.dataset.uuid as UUID;
}

function getData(node: Node, selector: string) {
  return node.dataset[selector];
}

function getContent(node: Node) {
  const content = node.querySelector(".content") as HTMLDivElement;
  // return content.innerHTML;
  return content.innerText;
}

export function setData(node: Node, selector: string, value: string) {
  node.dataset[selector] = value;

  return node;
}

export function setContent(uuid: UUID, value: string) {
  const node = getNodeById(uuid);
  const content = node?.querySelector(".content") as HTMLDivElement;
  content.innerHTML = value;

  return node;
}

export function focusNode(node: Node, toEnd: boolean = false) {
  const content = node.querySelector(".content") as HTMLDivElement;

  const offset = content.childNodes.length;

  const range = document.createRange();
  const selection = window.getSelection();
  range.setStart(content, offset);
  range.collapse(true);
  selection?.removeAllRanges();
  selection?.addRange(range);

  return node;
}

export function getNodeById(uuid: UUID | undefined) {
  return document.getElementById(`nodes-form-${uuid}`) as Node | null;
}

export function getNodeByTarget(target: HTMLDivElement) {
  return target.closest(".node") as Node;
}

export function getPrevNode(node: Node) {
  return node.previousSibling as Node | null;
}

export function getNextNode(node: Node) {
  return node.nextSibling as Node | null;
}

/*
  Showing which users are editing a node.
  The color is based on the ascii of user's name first char and the length of user's name.
  The tailwindcss color names are build dynamically.
*/

const colors = [
  "indigo",
  "violet",
  "purple",
  "fuchsia",
  "pink",
  "sky",
  "orange",
  "lime",
  "amber",
  "emerald",
  "teal",
  "cyan",
];
const intesities = ["500", "600", "700"];

function pickColor(user_name: string) {
  const colorIndex = user_name.charCodeAt(0) % 12;
  const intesity = user_name.length % 3;
  return `bg-${colors[colorIndex]}-${intesities[intesity]}`;
}

export function addEditingUserLabel(node: HTMLDivElement, user_name: string) {
  node!.querySelector(
    ".editing"
  )!.innerHTML += `<span id="${user_name}" class="mr-1 px-1 rounded ${pickColor(
    user_name
  )}">${user_name}</span>`;
}

export function removeEditingUserLabel(user_name: string) {
  const span = document.getElementById(user_name);
  span && span.remove();
}
