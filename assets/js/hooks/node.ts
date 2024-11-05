import { NodeData, UUID } from "./types";

export function moveNode(node: HTMLDivElement): NodeData {
  const { uuid, parent_id, prev_id } = getNodeData(node);
  const parentNode = getNodeById(parent_id);
  const prevNode = getNodeById(prev_id);

  if (prevNode) {
    prevNode.after(node);
  } else if (parentNode) {
    parentNode.querySelector(".children")!.prepend(node);
  }

  return { uuid, parent_id, prev_id };
}

function getNodeData(node: HTMLDivElement): NodeData {
  const uuid = getUUID(node);
  const parent_id = getData(node, "parent");
  const prev_id = getData(node, "prev");
  const content = getContent(node);

  return { uuid, parent_id, prev_id, content };
}

function getUUID(node: HTMLDivElement) {
  return node.id.split("nodes-form-")[1] as UUID;
}

function getContent(node: HTMLDivElement) {
  const content = node.querySelector(".editor") as HTMLDivElement;
  return content.innerHTML;
}

function getData(node: HTMLDivElement, selector: string) {
  const content = node.querySelector(".editor") as HTMLDivElement;
  if (!content) return undefined;

  return content.getAttribute(`data-${selector}`) as UUID;
}

export function setData(node: HTMLDivElement, selector: string, value: string) {
  const content = node.querySelector(".editor") as HTMLDivElement;
  content.setAttribute(`data-${selector}`, value);
}

export function getNodeById(uuid: UUID | undefined) {
  if (!uuid) return null;

  return document.getElementById(`nodes-form-${uuid}`) as HTMLDivElement;
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

export function removeEditingUserLabel(
  node: HTMLDivElement,
  user_name: string
) {
  const span = node!.querySelector(`#${user_name}`)!;
  span.remove();
}
