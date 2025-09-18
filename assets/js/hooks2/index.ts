import {
  moveHtmlChildNodesToDataPosition,
  setCursorToEndOfFirstChildNode,
} from "./tree";

import { toggleCollapse } from "./node";
import { restoreCollapsedStatus } from "./store";

import { DomContainer } from "./types";

export const Hooks = {
  outline: {
    mounted() {
      const container: DomContainer = this.el;

      container.addEventListener("toggle_collapse", toggleCollapse);

      moveHtmlChildNodesToDataPosition(container);
      restoreCollapsedStatus(container);
      setCursorToEndOfFirstChildNode(container);
    },
    //updated() {},
  },
};
