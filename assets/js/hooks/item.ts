import { UUID } from "./types";

export function getItemById(uuid: UUID | undefined) {
  if (!uuid) return null;

  return document.getElementById(`nodes-form-${uuid}`) as HTMLDivElement;
}

export function setAttribute(
  item: HTMLDivElement,
  key: string,
  value: string | number | boolean | undefined
) {
  const attrValue = value === undefined ? "" : String(value);
  item.setAttribute(`data-${key}`, attrValue);
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

export function addEditingUserLabel(item: HTMLDivElement, user_name: string) {
  item!.querySelector(
    ".editing"
  )!.innerHTML += `<span id="${user_name}" class="mr-1 px-1 rounded ${pickColor(
    user_name
  )}">${user_name}</span>`;
}

export function removeEditingUserLabel(
  item: HTMLDivElement,
  user_name: string
) {
  const span = item!.querySelector(`#${user_name}`)!;
  span.remove();
}
