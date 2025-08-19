import { DomContainer, DomNode, DataNode, UUID } from "../types";
import { moveDomNodeToDataPosition } from "../node";

export { setCursorToEndOfFirstChildNode } from "./cursor";

export function moveHtmlChildNodesToDataPosition(container: DomContainer) {
  container.querySelectorAll(".node").forEach((node) => {
    moveDomNodeToDataPosition(node as DomNode);
  });
}

