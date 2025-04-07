import { processEvent } from "./listener/process";
import {
  getNodeByTarget,
  getNodeDataByNode,
  getNodeDataByTarget,
} from "../node";
import { setCollapse } from "../store";

import mapping from "./../mapping.json";

// let watchdog;
const watchdogInterval = 400;

export function click(event: MouseEvent) {
  let action: string | undefined;

  for (const conf of mapping["click"]) {
    if (conf["metaKey"] != event.metaKey) continue;

    action = conf.action;
  }

  action && processEvent.call(this, event, action);
}

export function input(event: KeyboardEvent) {
  const target = event.target as HTMLDivElement;
  const { uuid } = getNodeDataByTarget(target);
  const content = target.innerHTML;

  // clearTimeout(watchdog);
  // watchdog = setTimeout(() => {
  this.pushEventTo(this.el, "save", { uuid, content });
  // }, watchdogInterval);
}

export function keydown(event: KeyboardEvent) {
  let action: string | undefined;

  for (const conf of mapping["keydown"]) {
    if (conf["shiftKey"] && conf["shiftKey"] != event.shiftKey) continue;
    if (conf["altKey"] && conf["altKey"] != event.altKey) continue;
    if (conf.key != event.key) continue;

    action = conf.action;
  }

  action && processEvent.call(this, event, action);
}

export function toggleCollapse(event: MouseEvent) {
  const target = event.target as HTMLDivElement;
  const node = getNodeByTarget(target);
  node.classList.toggle("collapsed");
  const { uuid, collapsed } = getNodeDataByNode(node);

  setCollapse.call(this, uuid, collapsed);
}

export function selectTree(event: MouseEvent) {
  const target = event.target as HTMLElement;
  const node = target.closest(".node");

  if (!node) return;

  const children = node.querySelectorAll(".node");
  children.forEach((child) => {
    const input = child.querySelector("input.selected") as HTMLInputElement;
    input.checked = true;
  });
}
