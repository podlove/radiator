import { getNodeData, getPrevNode, getNextNode, focusNode } from "../../node";

export function processEvent(action, event) {
  const node = event.target.parentNode as HTMLDivElement;
  const { uuid, content } = getNodeData(node);

  const selection = window.getSelection();
  const range = selection?.getRangeAt(0);
  const start = range!.startOffset;
  const stop = range!.endOffset;

  const cursorAtStart = start == 0 && stop == 0;
  const cursorAtEnd = start == content?.length && stop == content?.length;

  switch (action) {
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
      const prevNode = getPrevNode(node);
      if (cursorAtStart && prevNode) {
        event.preventDefault();
        this.pushEventTo(this.el, "merge_prev", { uuid, content });
        focusNode(prevNode);
      }
      break;

    case "merge_next":
      const nextNode = getNextNode(node);
      if (cursorAtEnd && nextNode) {
        event.preventDefault();
        this.pushEventTo(this.el, "merge_next", { uuid, content });
        focusNode(nextNode);
      }
      break;

    case "focus_prev":
      if (cursorAtStart) {
        event.preventDefault();
        const prevNode = getPrevNode(node);
        prevNode && focusNode(prevNode);
      }
      break;
    case "focus_next":
      if (cursorAtEnd) {
        event.preventDefault();
        const nextNode = getNextNode(node);
        nextNode && focusNode(nextNode, true);
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