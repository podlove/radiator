import { CollapseParams } from "../types";
import {
  getNodeById,
  getNodeData,
  getPrevNode,
  getNextNode,
  focusNode,
} from "../node";

let watchdog;
const watchdogInterval = 400;

export function input(event: KeyboardEvent) {
  const target = event.target as HTMLDivElement;
  const node = target.parentNode as HTMLDivElement;
  const { uuid, content } = getNodeData(node);

  clearTimeout(watchdog);
  watchdog = setTimeout(() => {
    this.pushEventTo(this.el.phxHookId, "save", { uuid, content });
  }, watchdogInterval);
}

export function keydown(event: KeyboardEvent) {
  const target = event.target as HTMLDivElement;
  const node = target.parentNode as HTMLDivElement;
  const { uuid, content } = getNodeData(node);

  const selection = window.getSelection();
  const range = selection?.getRangeAt(0);
  const start = range!.startOffset;
  const end = range!.endOffset;

  const cursorAtStart = start == 0 && end == 0;
  const cursorAtEnd = start == content?.length && end == content?.length;

  if (event.key == "Tab") {
    event.preventDefault();

    if (event.shiftKey) {
      this.pushEventTo(this.el.phxHookId, "outdent", { uuid });
    } else {
      this.pushEventTo(this.el.phxHookId, "indent", { uuid });
    }
  }

  if (event.key == "Enter" && !event.shiftKey) {
    event.preventDefault();

    this.pushEventTo(this.el.phxHookId, "new", {
      uuid,
      content,
      selection: { start, end },
    });
  }

  if (event.key == "Backspace" && cursorAtStart) {
    event.preventDefault();

    const prevNode = getPrevNode(node);
    if (prevNode) {
      this.pushEventTo(this.el.phxHookId, "merge_prev", { uuid, content });
      focusNode(prevNode);
    }
  }

  if (event.key == "Delete" && cursorAtEnd) {
    event.preventDefault();

    const nextNode = getNextNode(node);
    if (nextNode) {
      this.pushEventTo(this.el.phxHookId, "merge_next", { uuid, content });
      focusNode(nextNode);
    }
  }

  if (event.key == "ArrowUp") {
    if (event.altKey == true) {
      this.pushEventTo(this.el.phxHookId, "move_up", { uuid });
    } else if (cursorAtStart) {
      const prevNode = getPrevNode(node);
      prevNode && focusNode(prevNode);
    }
  }

  if (event.key == "ArrowDown") {
    if (event.altKey == true) {
      this.pushEventTo(this.el.phxHookId, "move_down", { uuid });
    } else if (cursorAtEnd) {
      const nextNode = getNextNode(node);
      nextNode && focusNode(nextNode, true);
    }
  }
}

export function toggleCollapse({ detail: { uuid } }: CollapseParams) {
  const node = getNodeById(uuid);
  node?.toggleAttribute("data-collapsed");

  const collapsedStatus = localStorage.getItem(this.el.id) || "{}";
  const collapsed = JSON.parse(collapsedStatus);

  collapsed[uuid] = !collapsed[uuid];
  localStorage.setItem(this.el.id, JSON.stringify(collapsed));
}
