import { saveCollapseStatus } from "../store";
import { DataNode, DomNode, UUID } from "../types";

export function toggleCollapse(event: Event) {
  const target = event.target as HTMLDivElement;
  const node = getDomNodeByTarget(target);
  node.classList.toggle("collapsed");
  const { uuid, collapsed } = getDataNodeFromDomNode(node);

  saveCollapseStatus(this.id, uuid, collapsed);
}

function getDomNodeByTarget(target: HTMLDivElement) {
  return target.closest(".node") as DomNode;
}

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

export function getDataNodeFromDomNode(node: DomNode): DataNode {
  const uuid = getUUID(node);
  const parent_id = getAttribute(node, "parent");
  const prev_id = getAttribute(node, "prev");
  const content = getContent(node);
  const collapsed = node.classList.contains("collapsed");

  return { uuid, parent_id, prev_id, content, collapsed };
}

function getUUID(node: DomNode) {
  return getAttribute(node, "uuid")!;
}

function getAttribute(node: DomNode, attribute: string) {
  return node.dataset[attribute] as UUID | undefined;
}

function getContent(node: DomNode) {
  const content = node.querySelector(".content") as HTMLDivElement;

  return content.innerHTML;
}
