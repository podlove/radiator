import { DomContainer } from "./types";

export const Hooks = {
  outline: {
    mounted() {
      const container: DomContainer = this.el;
    },
    //updated() {},
  },
};
