import { CollapseParams } from "../types";
import { processEvent } from "./listener/process";
import { getNodeById, getNodeData } from "../node";

import mapping from "./../mapping.json";

// let watchdog;
const watchdogInterval = 400;

export function click(event: MouseEvent) {
  const target = event.target as HTMLDivElement;
  const select = target!.querySelector("input.selected") as HTMLInputElement;

  select && (select.checked = !select.checked);
}

export function input(event: KeyboardEvent) {
  const target = event.target as HTMLDivElement;
  const node = target.parentNode as HTMLDivElement;
  const { uuid, content } = getNodeData(node);

  // clearTimeout(watchdog);
  // watchdog = setTimeout(() => {
  this.pushEventTo(this.el, "save", { uuid, content });
  // }, watchdogInterval);
}

export function keydown(event: KeyboardEvent) {
  const target = event.target as HTMLDivElement;

  let action: string | undefined;
  const type = target == this.el ? "node" : "content";
  for (const conf of mapping[type]) {
    if (conf["shiftKey"] && conf["shiftKey"] != event.shiftKey) continue;
    if (conf["altKey"] && conf["altKey"] != event.altKey) continue;
    if (conf.key != event.key) continue;

    action = conf.action;
  }

  action && processEvent.call(this, action, event);
}

export function toggleCollapse({ detail: { uuid } }: CollapseParams) {
  const node = getNodeById(uuid);
  node?.toggleAttribute("data-collapsed");

  const collapsedStatus = localStorage.getItem(this.el.id) || "{}";
  const collapsed = JSON.parse(collapsedStatus);

  collapsed[uuid] = !collapsed[uuid];
  localStorage.setItem(this.el.id, JSON.stringify(collapsed));
}

export function selectTree(event: MouseEvent) {
  const target = event.target as HTMLElement
  const node = target.closest(".node")

  if (!node) return;

  const children = node.querySelectorAll(".node");
  children.forEach((child) => {
    const input = child.querySelector("input.selected") as HTMLInputElement;
    input.checked = true;
  });
}
