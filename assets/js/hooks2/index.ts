import { moveHtmlChildNodesToDataPosition } from "./tree";

import { DomContainer } from "./types";

export const Hooks = {
  outline: {
    mounted() {
      const container: DomContainer = this.el;

      moveHtmlChildNodesToDataPosition(container);
    },
    //updated() {},
  },
};
