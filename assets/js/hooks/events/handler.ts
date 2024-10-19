import { NodeData, UserAction } from "../types";
import {
  getNodeById,
  moveNode,
  setValue,
  addEditingUserLabel,
  removeEditingUserLabel,
} from "../node";

export function handleBlur({ uuid, user_name }: UserAction) {
  const node = getNodeById(uuid)!;
  removeEditingUserLabel(node, user_name);
}

export function handleFocus({ uuid, user_name }: UserAction) {
  const node = getNodeById(uuid)!;
  addEditingUserLabel(node, user_name);
}

export function handleFocusNode({ uuid }: NodeData) {
  const input = document.getElementById(
    `form-${uuid}_content`,
  ) as HTMLDivElement;
  input.focus();
}

export function handleMoveNodes({ nodes }: { nodes: NodeData[] }) {
  nodes.forEach(({ uuid, parent_id, prev_id }: NodeData) => {
    const node = getNodeById(uuid)!;
    setValue(node, ".parent_id", parent_id || "");
    setValue(node, ".prev_id", prev_id || "");

    moveNode(node);
  });
}

export function handleSetContent({ uuid, content }: any) {
  const node = getNodeById(uuid)!;
  setValue(node, `#form-${uuid}_content`, content);
}

export function connectRaindrop({ url, client_id, redirect_uri }: any) {
  console.log(url, client_id, redirect_uri);
  alert(redirect_uri);
}
