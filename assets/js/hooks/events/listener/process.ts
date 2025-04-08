import {
  getNodeData,
  getPrevNode,
  getNextNode,
  focusNode,
  getNodeByTarget,
  getCursorPosition,
  getNodeDataByNode,
} from "../../node";

import { getNodeAbove, getNodeBelow } from "../../tree";

export function processEvent(
  event: KeyboardEvent | MouseEvent,
  action: string | undefined
) {
  const target = event.target as HTMLDivElement;
  const node = getNodeByTarget(target);
  const { uuid, content } = getNodeDataByNode(node);
  const { start, stop } = getCursorPosition();
  const cursorAtStart = start == 0 && stop == 0;
  const cursorAtEnd = start == content?.length && stop == content?.length;

  // pushEventTo(selectorOrTarget, event, payload, (reply, ref) => ...)

  switch (action) {
    case "toggle_select":
      event.preventDefault();
      node.classList.toggle("selected");
      break;

    case "split":
      event.preventDefault();
      this.pushEventTo(this.el, "split", { uuid, start, stop });
      break;

    case "indent":
      event.preventDefault();
      this.pushEventTo(this.el, "indent", { uuid });
      break;

    case "outdent":
      event.preventDefault();
      this.pushEventTo(this.el, "outdent", { uuid });
      break;

    case "move_up":
      event.preventDefault();
      this.pushEventTo(this.el, "move_up", { uuid });
      break;

    case "move_down":
      event.preventDefault();
      this.pushEventTo(this.el, "move_down", { uuid });
      break;

    case "merge_prev":
      if (cursorAtStart) {
        event.preventDefault();
        this.pushEventTo(this.el, "merge_prev", { uuid });
      }
      break;

    case "merge_next":
      if (cursorAtEnd) {
        event.preventDefault();
        this.pushEventTo(this.el, "merge_next", { uuid });
      }
      break;

    case "focus_prev":
      if (cursorAtStart) {
        //event.preventDefault();
        //const prevNode = getPrevNode(node);
        //prevNode && focusNode(prevNode);
      }
      break;

    case "focus_next":
      if (cursorAtEnd) {
        //event.preventDefault();
        //const nextNode = getNextNode(node);
        //nextNode && focusNode(nextNode, true);
      }
      break;

    case "collapse":
      if (cursorAtStart) {
        //event.preventDefault();
      }
      break;

    case "expand":
      if (cursorAtStart) {
        //event.preventDefault();
      }
      break;

    case "delete":
      event.preventDefault();
      const nodes = this.el.querySelectorAll(".node:has(> .selected:checked)");
      nodes.forEach((node: HTMLDivElement) => {
        const { uuid } = getNodeData(node);
        this.pushEventTo(this.el, "delete", { uuid });
      });
      break;

    default:
      console.error(`MISSING MAPPING FOR ACTION: ${action}`);
      break;
  }
}
