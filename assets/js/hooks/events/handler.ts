import { NodeData, UserAction } from "../types";

import {
  setData,
  setContent,
  focusNode,
  addEditingUserLabel,
  removeEditingUserLabel,
} from "../node";
import { getNodeById, moveNode } from "../tree";

export function handleBlur({ uuid, user_name }: UserAction) {
  //const node = getNodeById(uuid)!;
  //removeEditingUserLabel(user_name);
}

export function handleFocus({ uuid, user_name }: UserAction) {
  //const node = getNodeById(uuid)!;
  //removeEditingUserLabel(user_name);
  //addEditingUserLabel(node, user_name);
}

export function handleFocusNode({ uuid }: NodeData) {
  const node = getNodeById.call(this, uuid);
  node && focusNode(node);
}

export function handleMoveNodes({ nodes }: { nodes: NodeData[] }) {
  nodes.forEach(({ uuid, parent_id, prev_id }: NodeData) => {
    const node = getNodeById.call(this, uuid)!;
    setData(node, "parent", parent_id || "");
    setData(node, "prev", prev_id || "");

    moveNode.call(this, node);
  });
}

export function handleSetContent({ uuid, content }: NodeData) {
  const node = getNodeById.call(this, uuid);

  node && setContent(node, content || "");
}
