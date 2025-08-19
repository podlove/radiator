import { DomContainer, DomNode } from "../types";

export function setCursorToEndOfFirstChildNode(container: DomContainer) {
  const node = container.querySelector(".node:first-child") as DomNode;

  setCursorPosition(node);
}

function setCursorPosition(node: DomNode, position: number | null = null) {
  const content = node.querySelector(".content");
  const range = document.createRange();

  if (position) {
    range.setStart(content!.childNodes[0], position!);
    range.collapse(true);
  } else {
    range.selectNodeContents(content!);
    range.collapse();
  }

  const selection = window.getSelection();
  selection?.removeAllRanges();
  selection?.addRange(range);
}
