import { NodeData, UUID } from "./types";

export function getNodeDataByTarget(target: HTMLDivElement): NodeData {
  const domNode = getDomNodeByTarget(target);

  return getNodeDataByDomNode(domNode);
}

export function getNodeDataByDomNode(node: HTMLDivElement): NodeData {
  const uuid = getUUID(node);
  const collapsed = node.classList.contains("collapsed");

  return { uuid, collapsed };
}

export function moveNode(node: HTMLDivElement): NodeData {
  const { uuid, parent_id, prev_id } = getNodeData(node);
  const parentNode = getNodeById(parent_id);
  const prevNode = getNodeById(prev_id);

  if (prevNode) {
    prevNode.after(node);
    //insertBefore
  } else if (parentNode) {
    parentNode.querySelector(".children")!.prepend(node);
    //appendChild
  }

  return { uuid, parent_id, prev_id };
}

export function getNodeData(node: HTMLDivElement): NodeData {
  const uuid = getUUID(node);
  const parent_id = getData(node, "parent");
  const prev_id = getData(node, "prev");
  const content = getContent(node);

  return { uuid, parent_id, prev_id, content };
}

export function getUUID(node: HTMLDivElement) {
  return node.dataset.uuid as UUID;
}

function getData(node: HTMLDivElement, selector: string) {
  const data = node.getAttribute(`data-${selector}`);
  if (!data) return undefined;
  return data as UUID;
}

function getContent(node: HTMLDivElement) {
  // const content = node.querySelector(".content") as HTMLDivElement;
  const content = node.querySelector(".content") as HTMLDivElement;
  return content.innerHTML;
}

export function setData(node: HTMLDivElement, selector: string, value: string) {
  node.setAttribute(`data-${selector}`, value);
  return node;
}

export function setContent(uuid: UUID, value: string) {
  const domNode = getNodeById(uuid);
  const content = domNode?.querySelector(".content") as HTMLDivElement;
  content.innerHTML = value;

  return domNode;
}

export function focusNode(node: HTMLDivElement, toEnd: boolean = false) {
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
  if (!uuid) return null;

  //return document.querySelector(`[data-uuid="${uuid}"]`) as HTMLDivElement;
  return document.getElementById(`nodes-form-${uuid}`) as HTMLDivElement;
}

export function getDomNodeByTarget(target: HTMLDivElement) {
  return target.closest(".node") as HTMLDivElement;
}

export function getParentNode(node: HTMLDivElement) {
  return node.closest(".node") as HTMLDivElement | null;
}

export function getPrevNode(node: HTMLDivElement) {
  return node.previousSibling as HTMLDivElement | null;
}

export function getNextNode(node: HTMLDivElement) {
  return node.nextSibling as HTMLDivElement | null;
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

/*
private getCursorPosition = (): number => {
  const selection: Selection | null = window.getSelection();
  if (!selection) {
      return 0;
  }

  if (selection.rangeCount) {
      const range: Range = selection.getRangeAt(0);
      if (range.commonAncestorContainer.parentNode === this.tasktext) {
          return range.endOffset;
      }
  }

  return 0;
}

private setCursorPosition = (pos: number): void => {
  if (!this.tasktext.childNodes || !this.tasktext.childNodes.length) {
      return;
  }

  const range: Range = document.createRange();
  range.setStart(this.tasktext.childNodes[0], pos);
  range.collapse(true);

  const sel: Selection | null = window.getSelection();
  if (!sel) {
      return;
  }

  sel.removeAllRanges();
  sel.addRange(range);
}
*/
