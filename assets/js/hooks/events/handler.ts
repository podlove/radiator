import { NodeData, UserAction } from "../types";
import {
  getNodeById,
  moveNode,
  setData,
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
    `form-${uuid}_content`
  ) as HTMLDivElement;
  input.focus();
}

export function handleMoveNodes({ nodes }: { nodes: NodeData[] }) {
  nodes.forEach(({ uuid, parent_id, prev_id }: NodeData) => {
    const node = getNodeById(uuid)!;
    setData(node, "parent", parent_id || "");
    setData(node, "prev", prev_id || "");

    moveNode(node);
  });
}

export function handleSetContent({ uuid, content }: any) {
  // const node = getNodeById(uuid)!;
  // setValue(node, `#form-${uuid}_content`, content);

  document.getElementById(`nodes-form-${uuid}-editor`)!.innerHTML = content;
}
