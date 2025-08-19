import {
  moveHtmlChildNodesToDataPosition,
  setCursorToEndOfFirstChildNode,
} from "./tree";

import { toggleCollapse } from "./node";

import { DomContainer } from "./types";

export const Hooks = {
  outline: {
    mounted() {
      const container: DomContainer = this.el;

      container.addEventListener("toggle_collapse", toggleCollapse);

      moveHtmlChildNodesToDataPosition(container);
      setCursorToEndOfFirstChildNode(container);
    },
    //updated() {},
  },
};
