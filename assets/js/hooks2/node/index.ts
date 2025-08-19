import { DataNode, DomNode, UUID } from "../types";

export function moveDomNodeToDataPosition(node: DomNode) {
  const { parent_id, prev_id } = getDataNodeFromDomNode(node);

  const parentNode = getDomNodeById(parent_id);
  const prevNode = getDomNodeById(prev_id);

  if (prevNode) {
    prevNode.after(node);
    //insertBefore
  } else if (parentNode) {
    parentNode.querySelector(".children")!.prepend(node);
    //appendChild
  }

  return node;
}

function getDomNodeById(uuid: UUID | undefined) {
  return document.getElementById(`nodes-form-${uuid}`) as DomNode | null;
}

function getDataNodeFromDomNode(node: DomNode): DataNode {
  const uuid = getUUID(node);
  const parent_id = getAttribute(node, "parent");
  const prev_id = getAttribute(node, "prev");

  return { uuid, parent_id, prev_id };
}

function getUUID(node: DomNode) {
  return getAttribute(node, "uuid")!;
}

function getAttribute(node: DomNode, attribute: string) {
  return node.dataset[attribute] as UUID | undefined;
}
