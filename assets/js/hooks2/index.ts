import {
  moveHtmlChildNodesToDataPosition,
  setCursorToEndOfFirstChildNode,
} from "./tree";

import { DomContainer } from "./types";

export const Hooks = {
  outline: {
    mounted() {
      const container: DomContainer = this.el;

      moveHtmlChildNodesToDataPosition(container);
      setCursorToEndOfFirstChildNode(container);
    },
    //updated() {},
  },
};
